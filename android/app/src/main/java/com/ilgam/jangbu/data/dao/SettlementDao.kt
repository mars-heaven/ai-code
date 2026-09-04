package com.ilgam.jangbu.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.ilgam.jangbu.data.entity.Invoice
import com.ilgam.jangbu.data.entity.InvoicePhoto
import com.ilgam.jangbu.data.entity.Payroll
import kotlinx.coroutines.flow.Flow

/** 아직 지급 정산되지 않은 직원별 공임 합계 */
data class UnpaidWageRow(
    val employeeId: String,
    val employeeName: String,
    val totalQty: Int,
    val totalWage: Long
)

/** 이미 마감된 정산서의 품목별 명세 한 줄 (급여·계산서 공용) */
data class SettledDetailRow(
    val itemName: String,
    val unitLabel: String,
    val qty: Int,
    val unitPrice: Long,
    val amount: Long
)

/** 급여 지급 이력 한 줄 */
data class PayrollRow(
    val id: String,
    val employeeId: String,
    val employeeName: String,
    /** 정산서를 문자로 보낼 때 씁니다. 없으면 빈 글자 */
    val employeePhone: String,
    val periodStart: Int,
    val periodEnd: Int,
    val totalAmount: Long,
    val closedDate: Int,
    val paid: Boolean,
    val paidDate: Int?
)

@Dao
interface PayrollDao {

    /**
     * 기간 안에서 아직 정산되지 않은(payrollId 가 비어 있는) 작업만 직원별로 모읍니다.
     * 이미 마감된 건은 자동으로 빠지므로 중복 지급이 생기지 않습니다.
     */
    @Query(
        """
        SELECT e.id AS employeeId, e.name AS employeeName,
               SUM(wl.qty) AS totalQty,
               SUM(wl.qty * wl.wageUnitPrice) AS totalWage
        FROM work_logs wl
        JOIN employees e ON e.id = wl.employeeId
        WHERE wl.payrollId IS NULL AND wl.workDate BETWEEN :from AND :to
        GROUP BY e.id, e.name
        HAVING SUM(wl.qty) > 0
        ORDER BY e.name
        """
    )
    fun observeUnpaidWages(from: Int, to: Int): Flow<List<UnpaidWageRow>>

    @Query(
        """
        SELECT IFNULL(SUM(wl.qty * wl.wageUnitPrice), 0)
        FROM work_logs wl
        WHERE wl.payrollId IS NULL AND wl.employeeId = :employeeId
          AND wl.workDate BETWEEN :from AND :to
        """
    )
    suspend fun sumUnpaidWage(employeeId: String, from: Int, to: Int): Long

    @Query(
        """
        SELECT p.id, p.employeeId, e.name AS employeeName, e.phone AS employeePhone,
               p.periodStart, p.periodEnd,
               p.totalAmount, p.closedDate, p.paid, p.paidDate
        FROM payrolls p JOIN employees e ON e.id = p.employeeId
        ORDER BY p.closedDate DESC, p.id DESC
        """
    )
    fun observeHistory(): Flow<List<PayrollRow>>

    /** 마감된 급여에 묶인 작업을 품목별로 모읍니다(정산서에 적을 명세). */
    @Query(
        """
        SELECT i.name AS itemName, i.unitLabel,
               SUM(wl.qty) AS qty, wl.wageUnitPrice AS unitPrice,
               SUM(wl.qty * wl.wageUnitPrice) AS amount
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN items i ON i.id = wo.itemId
        WHERE wl.payrollId = :payrollId
        GROUP BY i.id, i.name, i.unitLabel, wl.wageUnitPrice
        ORDER BY i.name
        """
    )
    suspend fun details(payrollId: String): List<SettledDetailRow>

    @Insert
    suspend fun insert(payroll: Payroll)

    @Update
    suspend fun update(payroll: Payroll)

    @Query("SELECT * FROM payrolls WHERE id = :id")
    suspend fun getById(id: String): Payroll?

    @Query("UPDATE payrolls SET paid = 1, paidDate = :paidDate WHERE id = :id")
    suspend fun markPaid(id: String, paidDate: Int)

    @Query("DELETE FROM payrolls WHERE id = :id")
    suspend fun delete(id: String)
}

/** 아직 청구되지 않은 거래처별 금액 합계 */
data class UnbilledRow(
    val clientId: String,
    val clientName: String,
    val totalQty: Int,
    val totalAmount: Long
)

/** 계산서에 넣을 품목별 명세 한 줄 */
data class BillingDetailRow(
    val itemName: String,
    val unitLabel: String,
    val qty: Int,
    val chargeUnitPrice: Long,
    val amount: Long
)

/** 계산서 이력 한 줄 */
data class InvoiceRow(
    val id: String,
    val clientId: String,
    val clientName: String,
    /** 명세서를 문자로 보낼 때 씁니다. 없으면 빈 글자 */
    val clientPhone: String,
    val periodStart: Int,
    val periodEnd: Int,
    val totalAmount: Long,
    val issuedDate: Int,
    val paid: Boolean,
    val paidDate: Int?
)

@Dao
interface InvoiceDao {

    /** 아직 계산서에 안 들어간 작업만 거래처별로 모읍니다. */
    @Query(
        """
        SELECT c.id AS clientId, c.name AS clientName,
               SUM(wl.qty) AS totalQty,
               SUM(wl.qty * wo.chargeUnitPrice) AS totalAmount
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN clients c ON c.id = wo.clientId
        WHERE wl.invoiceId IS NULL AND wl.workDate BETWEEN :from AND :to
        GROUP BY c.id, c.name
        HAVING SUM(wl.qty) > 0
        ORDER BY c.name
        """
    )
    fun observeUnbilled(from: Int, to: Int): Flow<List<UnbilledRow>>

    /** 계산서 발행 화면에서 보여줄 품목별 명세 */
    @Query(
        """
        SELECT i.name AS itemName, i.unitLabel,
               SUM(wl.qty) AS qty, wo.chargeUnitPrice,
               SUM(wl.qty * wo.chargeUnitPrice) AS amount
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN items i ON i.id = wo.itemId
        WHERE wl.invoiceId IS NULL AND wo.clientId = :clientId
          AND wl.workDate BETWEEN :from AND :to
        GROUP BY i.id, i.name, i.unitLabel, wo.chargeUnitPrice
        ORDER BY i.name
        """
    )
    fun observeUnbilledDetail(clientId: String, from: Int, to: Int): Flow<List<BillingDetailRow>>

    @Query(
        """
        SELECT IFNULL(SUM(wl.qty * wo.chargeUnitPrice), 0)
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        WHERE wl.invoiceId IS NULL AND wo.clientId = :clientId
          AND wl.workDate BETWEEN :from AND :to
        """
    )
    suspend fun sumUnbilled(clientId: String, from: Int, to: Int): Long

    @Query(
        """
        SELECT inv.id, inv.clientId, c.name AS clientName, c.phone AS clientPhone,
               inv.periodStart, inv.periodEnd,
               inv.totalAmount, inv.issuedDate, inv.paid, inv.paidDate
        FROM invoices inv JOIN clients c ON c.id = inv.clientId
        ORDER BY inv.issuedDate DESC, inv.id DESC
        """
    )
    fun observeHistory(): Flow<List<InvoiceRow>>

    /** 아직 입금 안 된 계산서(미수금) */
    @Query(
        """
        SELECT inv.id, inv.clientId, c.name AS clientName, c.phone AS clientPhone,
               inv.periodStart, inv.periodEnd,
               inv.totalAmount, inv.issuedDate, inv.paid, inv.paidDate
        FROM invoices inv JOIN clients c ON c.id = inv.clientId
        WHERE inv.paid = 0
        ORDER BY inv.issuedDate
        """
    )
    fun observeUnpaid(): Flow<List<InvoiceRow>>

    /** 발행된 계산서에 묶인 작업을 품목별로 모읍니다(계산서에 적을 명세). */
    @Query(
        """
        SELECT i.name AS itemName, i.unitLabel,
               SUM(wl.qty) AS qty, wo.chargeUnitPrice AS unitPrice,
               SUM(wl.qty * wo.chargeUnitPrice) AS amount
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN items i ON i.id = wo.itemId
        WHERE wl.invoiceId = :invoiceId
        GROUP BY i.id, i.name, i.unitLabel, wo.chargeUnitPrice
        ORDER BY i.name
        """
    )
    suspend fun details(invoiceId: String): List<SettledDetailRow>

    @Insert
    suspend fun insert(invoice: Invoice)

    @Update
    suspend fun update(invoice: Invoice)

    @Query("SELECT * FROM invoices WHERE id = :id")
    suspend fun getById(id: String): Invoice?

    @Query("UPDATE invoices SET paid = 1, paidDate = :paidDate WHERE id = :id")
    suspend fun markPaid(id: String, paidDate: Int)

    @Query("DELETE FROM invoices WHERE id = :id")
    suspend fun delete(id: String)

    // 계산서 사진
    @Query("SELECT * FROM invoice_photos WHERE invoiceId = :invoiceId ORDER BY takenAt")
    fun observePhotos(invoiceId: String): Flow<List<InvoicePhoto>>

    @Query("SELECT * FROM invoice_photos WHERE invoiceId = :invoiceId")
    suspend fun getPhotos(invoiceId: String): List<InvoicePhoto>

    @Insert
    suspend fun insertPhoto(photo: InvoicePhoto)

    @Query("DELETE FROM invoice_photos WHERE id = :id")
    suspend fun deletePhoto(id: String)
}
