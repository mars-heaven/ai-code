package com.ilgam.jangbu.data

import androidx.room.withTransaction
import com.ilgam.jangbu.data.entity.*
import com.ilgam.jangbu.util.deletePhotoFile
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

    val clients = db.clientDao()
    val items = db.itemDao()
    val employees = db.employeeDao()
    val rates = db.employeeRateDao()
    val orders = db.workOrderDao()
    val logs = db.workLogDao()
    val payrolls = db.payrollDao()
    val invoices = db.invoiceDao()

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
    ): Long = db.withTransaction {
        val clientId = clients.findOrCreate(clientName)
        val itemId = items.findOrCreate(
            clientId = clientId,
            name = itemName,
            chargeUnitPrice = chargeUnitPrice,
            defaultWageUnitPrice = defaultWageUnitPrice,
            unitLabel = unitLabel
        )
        orders.insert(
            WorkOrder(
                clientId = clientId,
                itemId = itemId,
                targetQty = targetQty,
                chargeUnitPrice = chargeUnitPrice,
                receivedDate = receivedDate.toDbInt(),
                dueDate = dueDate?.toDbInt(),
                memo = memo
            )
        )
    }

    // ------------------------------------------------------------------
    // 직원 작업 등록 — 적용할 공임 단가를 자동으로 찾아 넣습니다.
    // ------------------------------------------------------------------
    suspend fun addWorkLog(
        workOrderId: Long,
        employeeId: Long,
        qty: Int,
        workDate: LocalDate = LocalDate.now(),
        memo: String = ""
    ): Long = db.withTransaction {
        val order = orders.getById(workOrderId)
            ?: throw IllegalArgumentException("일감을 찾을 수 없습니다")
        val wage = rates.effectiveWage(employeeId, order.itemId) ?: 0L

        val id = logs.insert(
            WorkLog(
                workOrderId = workOrderId,
                employeeId = employeeId,
                qty = qty,
                wageUnitPrice = wage,
                workDate = workDate.toDbInt(),
                memo = memo
            )
        )

        // 목표 수량을 다 채웠으면 자동으로 완료 처리합니다.
        refreshOrderStatus(workOrderId)
        id
    }

    /** 처리 수량이 목표에 닿았는지 보고 일감 상태를 맞춥니다. */
    suspend fun refreshOrderStatus(workOrderId: Long) {
        val order = orders.getById(workOrderId) ?: return
        if (order.status == WorkOrderStatus.CANCELED) return

        val doneQty = logs.sumQtyByOrder(workOrderId)
        val newStatus =
            if (doneQty >= order.targetQty) WorkOrderStatus.DONE else WorkOrderStatus.IN_PROGRESS
        if (order.status != newStatus) {
            orders.updateStatus(workOrderId, newStatus)
        }
    }

    /** 잘못 넣은 작업 기록 지우기 — 이미 정산된 건은 지울 수 없습니다. */
    suspend fun deleteWorkLog(logId: Long, workOrderId: Long): Boolean = db.withTransaction {
        val deleted = logs.deleteIfNotSettled(logId)
        if (deleted > 0) refreshOrderStatus(workOrderId)
        deleted > 0
    }

    /** 적용될 공임 단가 미리 보기 (저장 전에 금액을 보여 주기 위함) */
    suspend fun previewWage(employeeId: Long, itemId: Long): Long =
        rates.effectiveWage(employeeId, itemId) ?: 0L

    // ------------------------------------------------------------------
    // 급여 마감 — 아직 정산 안 된 작업만 묶습니다(중복 지급 방지).
    // ------------------------------------------------------------------

    /** 한 사람만 마감. 정산할 금액이 없으면 null 을 돌려줍니다. */
    suspend fun closePayrollFor(
        employeeId: Long,
        from: LocalDate,
        to: LocalDate,
        closedDate: LocalDate = LocalDate.now()
    ): Long? = db.withTransaction {
        val f = from.toDbInt()
        val t = to.toDbInt()
        val total = payrolls.sumUnpaidWage(employeeId, f, t)
        if (total <= 0L) return@withTransaction null

        val payrollId = payrolls.insert(
            Payroll(
                employeeId = employeeId,
                periodStart = f,
                periodEnd = t,
                totalAmount = total,
                closedDate = closedDate.toDbInt()
            )
        )
        logs.attachToPayroll(payrollId, employeeId, f, t)
        payrollId
    }

    /** 전 직원 일괄 마감. 마감된 급여 id 목록을 돌려줍니다. */
    suspend fun closePayrollForAll(
        employeeIds: List<Long>,
        from: LocalDate,
        to: LocalDate,
        closedDate: LocalDate = LocalDate.now()
    ): List<Long> = db.withTransaction {
        employeeIds.mapNotNull { closePayrollFor(it, from, to, closedDate) }
    }

    /** 마감 취소 — 묶음을 풀고 급여 줄을 지웁니다. */
    suspend fun cancelPayroll(payrollId: Long) = db.withTransaction {
        logs.detachFromPayroll(payrollId)
        payrolls.delete(payrollId)
    }

    suspend fun markPayrollPaid(payrollId: Long, paidDate: LocalDate = LocalDate.now()) {
        payrolls.markPaid(payrollId, paidDate.toDbInt())
    }

    // ------------------------------------------------------------------
    // 거래처 계산서 — 아직 청구 안 된 작업만 묶습니다(중복 청구 방지).
    // ------------------------------------------------------------------
    suspend fun issueInvoice(
        clientId: Long,
        from: LocalDate,
        to: LocalDate,
        issuedDate: LocalDate = LocalDate.now(),
        memo: String = ""
    ): Long? = db.withTransaction {
        val f = from.toDbInt()
        val t = to.toDbInt()
        val total = invoices.sumUnbilled(clientId, f, t)
        if (total <= 0L) return@withTransaction null

        val invoiceId = invoices.insert(
            Invoice(
                clientId = clientId,
                periodStart = f,
                periodEnd = t,
                totalAmount = total,
                issuedDate = issuedDate.toDbInt(),
                memo = memo
            )
        )
        logs.attachToInvoice(invoiceId, clientId, f, t)
        invoiceId
    }

    /** 계산서 취소 — 묶음을 풀고 붙여 둔 사진 파일까지 정리합니다. */
    suspend fun cancelInvoice(invoiceId: Long) {
        val fileNames = invoices.getPhotos(invoiceId).map { it.filePath }
        db.withTransaction {
            logs.detachFromInvoice(invoiceId)
            // invoice_photos 는 CASCADE 로 함께 지워집니다.
            invoices.delete(invoiceId)
        }
        fileNames.forEach { deletePhotoFile(File(photoDir, it)) }
    }

    suspend fun markInvoicePaid(invoiceId: Long, paidDate: LocalDate = LocalDate.now()) {
        invoices.markPaid(invoiceId, paidDate.toDbInt())
    }

    // ------------------------------------------------------------------
    // 계산서 사진
    // ------------------------------------------------------------------
    suspend fun addInvoicePhoto(invoiceId: Long, fileName: String, memo: String = "") {
        invoices.insertPhoto(
            InvoicePhoto(invoiceId = invoiceId, filePath = fileName, memo = memo)
        )
    }

    /** 목록에서 지우고 휴대폰에 저장된 사진 파일도 함께 지웁니다. */
    suspend fun removeInvoicePhoto(photoId: Long, fileName: String) {
        invoices.deletePhoto(photoId)
        deletePhotoFile(File(photoDir, fileName))
    }

    // ------------------------------------------------------------------
    // 직원별 공임 단가
    // ------------------------------------------------------------------
    suspend fun setEmployeeRate(employeeId: Long, itemId: Long, wageUnitPrice: Long?) {
        if (wageUnitPrice == null) {
            rates.clear(employeeId, itemId)
        } else {
            rates.upsert(EmployeeRate(employeeId = employeeId, itemId = itemId, wageUnitPrice = wageUnitPrice))
        }
    }
}
