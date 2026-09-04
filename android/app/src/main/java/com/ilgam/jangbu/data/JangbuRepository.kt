package com.ilgam.jangbu.data

import androidx.room.withTransaction
import com.ilgam.jangbu.data.entity.*
import com.ilgam.jangbu.util.deletePhotoFile
import com.ilgam.jangbu.util.newId
import com.ilgam.jangbu.util.toDbInt
import java.io.File
import java.time.LocalDate

/**
 * 화면과 DB 사이의 창구.
 * 마감처럼 여러 표를 한꺼번에 바꾸는 일은 반드시 트랜잭션으로 묶어,
 * 중간에 끊겨도 장부가 어긋나지 않게 합니다.
 */
class JangbuRepository(
    private val db: JangbuDatabase,
    /** 계산서 사진을 두는 곳. 장부에는 이 안의 파일 이름만 담습니다. */
    private val photoDir: File
) {

    /**
     * 서버에 함께 비출 거울. 서버를 안 쓰면 비어 있습니다.
     * 로그인해서 업체에 붙으면 그때 끼워집니다.
     */
    @Volatile
    var mirror: JangbuMirror? = null

    val clients = db.clientDao()
    val items = db.itemDao()
    val employees = db.employeeDao()
    val rates = db.employeeRateDao()
    val orders = db.workOrderDao()
    val logs = db.workLogDao()
    val payrolls = db.payrollDao()
    val invoices = db.invoiceDao()
    val summary = db.summaryDao()
    private val sync = db.syncDao()

    // ------------------------------------------------------------------
    // 일감 접수 — 거래처·품목이 없으면 같이 만들어 줍니다.
    // ------------------------------------------------------------------
    suspend fun receiveWorkOrder(
        clientName: String,
        itemName: String,
        targetQty: Int,
        chargeUnitPrice: Long,
        defaultWageUnitPrice: Long,
        unitLabel: String = "장",
        receivedDate: LocalDate = LocalDate.now(),
        dueDate: LocalDate? = null,
        memo: String = ""
    ): String = db.withTransaction {
        val clientId = clients.findOrCreate(clientName)
        val itemId = items.findOrCreate(
            clientId = clientId,
            name = itemName,
            chargeUnitPrice = chargeUnitPrice,
            defaultWageUnitPrice = defaultWageUnitPrice,
            unitLabel = unitLabel
        )
        val order = WorkOrder(
            clientId = clientId,
            itemId = itemId,
            targetQty = targetQty,
            chargeUnitPrice = chargeUnitPrice,
            receivedDate = receivedDate.toDbInt(),
            dueDate = dueDate?.toDbInt(),
            memo = memo
        )
        orders.insert(order)
        order
    }.also { order ->
        mirror?.let { m ->
            clients.getById(order.clientId)?.let(m::onClient)
            items.getById(order.itemId)?.let(m::onItem)
            m.onOrder(order)
        }
    }.id

    // ------------------------------------------------------------------
    // 직원 작업 등록 — 적용할 공임 단가를 자동으로 찾아 넣습니다.
    // ------------------------------------------------------------------
    suspend fun addWorkLog(
        workOrderId: String,
        employeeId: String,
        qty: Int,
        workDate: LocalDate = LocalDate.now(),
        memo: String = ""
    ): String = db.withTransaction {
        val order = orders.getById(workOrderId)
            ?: throw IllegalArgumentException("일감을 찾을 수 없습니다")
        val wage = rates.effectiveWage(employeeId, order.itemId) ?: 0L

        val log = WorkLog(
            workOrderId = workOrderId,
            employeeId = employeeId,
            qty = qty,
            wageUnitPrice = wage,
            workDate = workDate.toDbInt(),
            memo = memo
        )
        logs.insert(log)

        // 목표 수량을 다 채웠으면 자동으로 완료 처리합니다.
        refreshOrderStatus(workOrderId)
        log.id
    }.also { id ->
        mirror?.let { m ->
            sync.logById(id)?.let(m::onLog)
            orders.getById(workOrderId)?.let(m::onOrder)
        }
    }

    /** 처리 수량이 목표에 닿았는지 보고 일감 상태를 맞춥니다. */
    suspend fun refreshOrderStatus(workOrderId: String) {
        val order = orders.getById(workOrderId) ?: return
        if (order.status == WorkOrderStatus.CANCELED) return

        val doneQty = logs.sumQtyByOrder(workOrderId)
        val newStatus =
            if (doneQty >= order.targetQty) WorkOrderStatus.DONE else WorkOrderStatus.IN_PROGRESS
        if (order.status != newStatus) {
            orders.updateStatus(workOrderId, newStatus)
            mirror?.onOrder(order.copy(status = newStatus))
        }
    }

    /** 잘못 넣은 작업 기록 지우기 — 이미 정산된 건은 지울 수 없습니다. */
    suspend fun deleteWorkLog(logId: String, workOrderId: String): Boolean = db.withTransaction {
        val deleted = logs.deleteIfNotSettled(logId)
        if (deleted > 0) refreshOrderStatus(workOrderId)
        deleted > 0
    }.also { removed ->
        if (removed) mirror?.onLogRemoved(logId)
    }

    /** 적용될 공임 단가 미리 보기 (저장 전에 금액을 보여 주기 위함) */
    suspend fun previewWage(employeeId: String, itemId: String): Long =
        rates.effectiveWage(employeeId, itemId) ?: 0L

    // ------------------------------------------------------------------
    // 급여 마감 — 아직 정산 안 된 작업만 묶습니다(중복 지급 방지).
    // ------------------------------------------------------------------

    /** 한 사람만 마감. 정산할 금액이 없으면 null 을 돌려줍니다. */
    suspend fun closePayrollFor(
        employeeId: String,
        from: LocalDate,
        to: LocalDate,
        closedDate: LocalDate = LocalDate.now()
    ): String? = db.withTransaction {
        val f = from.toDbInt()
        val t = to.toDbInt()
        val total = payrolls.sumUnpaidWage(employeeId, f, t)
        if (total <= 0L) return@withTransaction null

        val payroll = Payroll(
            employeeId = employeeId,
            periodStart = f,
            periodEnd = t,
            totalAmount = total,
            closedDate = closedDate.toDbInt()
        )
        payrolls.insert(payroll)
        logs.attachToPayroll(payroll.id, employeeId, f, t)
        payroll.id
    }?.also { payrollId ->
        mirror?.let { m ->
            payrolls.getById(payrollId)?.let(m::onPayroll)
            m.onLogs(sync.logsByPayroll(payrollId))
        }
    }

    /** 전 직원 일괄 마감. 마감된 급여 id 목록을 돌려줍니다. */
    suspend fun closePayrollForAll(
        employeeIds: List<String>,
        from: LocalDate,
        to: LocalDate,
        closedDate: LocalDate = LocalDate.now()
    ): List<String> = db.withTransaction {
        employeeIds.mapNotNull { closePayrollFor(it, from, to, closedDate) }
    }

    /** 마감 취소 — 묶음을 풀고 급여 줄을 지웁니다. */
    suspend fun cancelPayroll(payrollId: String) {
        val attachedIds = sync.logsByPayroll(payrollId).map { it.id }
        db.withTransaction {
            logs.detachFromPayroll(payrollId)
            payrolls.delete(payrollId)
        }
        mirror?.let { m ->
            m.onLogs(sync.logsByIds(attachedIds))
            m.onPayrollRemoved(payrollId)
        }
    }

    suspend fun markPayrollPaid(payrollId: String, paidDate: LocalDate = LocalDate.now()) {
        payrolls.markPaid(payrollId, paidDate.toDbInt())
        mirror?.let { m -> payrolls.getById(payrollId)?.let(m::onPayroll) }
    }

    // ------------------------------------------------------------------
    // 거래처 계산서 — 아직 청구 안 된 작업만 묶습니다(중복 청구 방지).
    // ------------------------------------------------------------------
    suspend fun issueInvoice(
        clientId: String,
        from: LocalDate,
        to: LocalDate,
        issuedDate: LocalDate = LocalDate.now(),
        memo: String = ""
    ): String? = db.withTransaction {
        val f = from.toDbInt()
        val t = to.toDbInt()
        val total = invoices.sumUnbilled(clientId, f, t)
        if (total <= 0L) return@withTransaction null

        val invoice = Invoice(
            clientId = clientId,
            periodStart = f,
            periodEnd = t,
            totalAmount = total,
            issuedDate = issuedDate.toDbInt(),
            memo = memo
        )
        invoices.insert(invoice)
        logs.attachToInvoice(invoice.id, clientId, f, t)
        invoice.id
    }?.also { invoiceId ->
        mirror?.let { m ->
            invoices.getById(invoiceId)?.let(m::onInvoice)
            m.onLogs(sync.logsByInvoice(invoiceId))
        }
    }

    /** 계산서 취소 — 묶음을 풀고 붙여 둔 사진 파일까지 정리합니다. */
    suspend fun cancelInvoice(invoiceId: String) {
        val fileNames = invoices.getPhotos(invoiceId).map { it.filePath }
        val attachedIds = sync.logsByInvoice(invoiceId).map { it.id }
        db.withTransaction {
            logs.detachFromInvoice(invoiceId)
            // invoice_photos 는 CASCADE 로 함께 지워집니다.
            invoices.delete(invoiceId)
        }
        fileNames.forEach { deletePhotoFile(File(photoDir, it)) }
        mirror?.let { m ->
            m.onLogs(sync.logsByIds(attachedIds))
            m.onInvoiceRemoved(invoiceId)
        }
    }

    suspend fun markInvoicePaid(invoiceId: String, paidDate: LocalDate = LocalDate.now()) {
        invoices.markPaid(invoiceId, paidDate.toDbInt())
        mirror?.let { m -> invoices.getById(invoiceId)?.let(m::onInvoice) }
    }

    // ------------------------------------------------------------------
    // 계산서 사진
    // ------------------------------------------------------------------
    suspend fun addInvoicePhoto(invoiceId: String, fileName: String, memo: String = "") {
        invoices.insertPhoto(
            InvoicePhoto(invoiceId = invoiceId, filePath = fileName, memo = memo)
        )
    }

    /** 목록에서 지우고 휴대폰에 저장된 사진 파일도 함께 지웁니다. */
    suspend fun removeInvoicePhoto(photoId: String, fileName: String) {
        invoices.deletePhoto(photoId)
        deletePhotoFile(File(photoDir, fileName))
    }

    // ------------------------------------------------------------------
    // 직원별 공임 단가
    // ------------------------------------------------------------------
    suspend fun setEmployeeRate(employeeId: String, itemId: String, wageUnitPrice: Long?) {
        if (wageUnitPrice == null) {
            val existing = sync.rateOf(employeeId, itemId)
            rates.clear(employeeId, itemId)
            existing?.let { mirror?.onRateRemoved(it.id) }
        } else {
            // 이미 있던 줄이면 그 번호를 그대로 써서 서버에 두 줄이 생기지 않게 합니다.
            val existing = sync.rateOf(employeeId, itemId)
            val rate = EmployeeRate(
                id = existing?.id ?: newId(),
                employeeId = employeeId,
                itemId = itemId,
                wageUnitPrice = wageUnitPrice
            )
            rates.upsert(rate)
            mirror?.onRate(rate)
        }
    }

    // ------------------------------------------------------------------
    // 기초 등록 — 거래처·품목·직원
    // 서버에도 함께 비추기 위해 화면이 아니라 여기를 거치게 합니다.
    // ------------------------------------------------------------------
    suspend fun saveClient(client: Client, isNew: Boolean) {
        if (isNew) clients.insert(client) else clients.update(client)
        mirror?.onClient(client)
    }

    suspend fun deactivateClient(id: String) {
        clients.deactivate(id)
        mirror?.let { m -> clients.getById(id)?.let(m::onClient) }
    }

    suspend fun saveEmployee(employee: Employee, isNew: Boolean) {
        if (isNew) employees.insert(employee) else employees.update(employee)
        mirror?.onEmployee(employee)
    }

    suspend fun deactivateEmployee(id: String) {
        employees.deactivate(id)
        mirror?.let { m -> employees.getById(id)?.let(m::onEmployee) }
    }

    suspend fun saveItem(item: Item, isNew: Boolean) {
        if (isNew) items.insert(item) else items.update(item)
        mirror?.let { m ->
            clients.getById(item.clientId)?.let(m::onClient)
            m.onItem(item)
        }
    }

    suspend fun deactivateItem(id: String) {
        items.deactivate(id)
        mirror?.let { m -> items.getById(id)?.let(m::onItem) }
    }
}
