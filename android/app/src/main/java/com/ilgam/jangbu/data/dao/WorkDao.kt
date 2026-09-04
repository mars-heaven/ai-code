package com.ilgam.jangbu.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.ilgam.jangbu.data.entity.WorkLog
import com.ilgam.jangbu.data.entity.WorkOrder
import kotlinx.coroutines.flow.Flow

/** 일감 목록 한 줄 — 대상 수량과 처리 수량을 함께 담습니다. */
data class WorkOrderRow(
    val id: Long,
    val clientId: Long,
    val clientName: String,
    val itemId: Long,
    val itemName: String,
    val unitLabel: String,
    val targetQty: Int,
    /** 직원들이 처리한 합계 */
    val doneQty: Int,
    val chargeUnitPrice: Long,
    val receivedDate: Int,
    val dueDate: Int?,
    val status: Int
) {
    val remainQty: Int get() = (targetQty - doneQty).coerceAtLeast(0)
    val progress: Float get() = if (targetQty <= 0) 0f else (doneQty.toFloat() / targetQty).coerceIn(0f, 1f)
}

@Dao
interface WorkOrderDao {

    @Query(
        """
        SELECT wo.id, wo.clientId, c.name AS clientName, wo.itemId, i.name AS itemName,
               i.unitLabel, wo.targetQty,
               IFNULL((SELECT SUM(wl.qty) FROM work_logs wl WHERE wl.workOrderId = wo.id), 0) AS doneQty,
               wo.chargeUnitPrice, wo.receivedDate, wo.dueDate, wo.status
        FROM work_orders wo
        JOIN clients c ON c.id = wo.clientId
        JOIN items i ON i.id = wo.itemId
        ORDER BY wo.receivedDate DESC, wo.id DESC
        """
    )
    fun observeAll(): Flow<List<WorkOrderRow>>

    @Query(
        """
        SELECT wo.id, wo.clientId, c.name AS clientName, wo.itemId, i.name AS itemName,
               i.unitLabel, wo.targetQty,
               IFNULL((SELECT SUM(wl.qty) FROM work_logs wl WHERE wl.workOrderId = wo.id), 0) AS doneQty,
               wo.chargeUnitPrice, wo.receivedDate, wo.dueDate, wo.status
        FROM work_orders wo
        JOIN clients c ON c.id = wo.clientId
        JOIN items i ON i.id = wo.itemId
        WHERE wo.status = 0
        ORDER BY (wo.dueDate IS NULL), wo.dueDate, wo.receivedDate
        """
    )
    fun observeInProgress(): Flow<List<WorkOrderRow>>

    @Query("SELECT * FROM work_orders WHERE id = :id")
    suspend fun getById(id: Long): WorkOrder?

    @Insert
    suspend fun insert(order: WorkOrder): Long

    @Update
    suspend fun update(order: WorkOrder)

    @Query("UPDATE work_orders SET status = :status WHERE id = :id")
    suspend fun updateStatus(id: Long, status: Int)
}

/** 작업 기록 한 줄 (직원·품목 이름 포함) */
data class WorkLogRow(
    val id: Long,
    val workOrderId: Long,
    val employeeId: Long,
    val employeeName: String,
    val clientName: String,
    val itemName: String,
    val unitLabel: String,
    val qty: Int,
    val wageUnitPrice: Long,
    val workDate: Int,
    val payrollId: Long?,
    val invoiceId: Long?
) {
    val wage: Long get() = qty * wageUnitPrice
}

@Dao
interface WorkLogDao {

    @Query(
        """
        SELECT wl.id, wl.workOrderId, wl.employeeId, e.name AS employeeName,
               c.name AS clientName, i.name AS itemName, i.unitLabel,
               wl.qty, wl.wageUnitPrice, wl.workDate, wl.payrollId, wl.invoiceId
        FROM work_logs wl
        JOIN employees e ON e.id = wl.employeeId
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN clients c ON c.id = wo.clientId
        JOIN items i ON i.id = wo.itemId
        WHERE wl.workDate BETWEEN :from AND :to
        ORDER BY wl.workDate DESC, wl.id DESC
        """
    )
    fun observeBetween(from: Int, to: Int): Flow<List<WorkLogRow>>

    @Query(
        """
        SELECT wl.id, wl.workOrderId, wl.employeeId, e.name AS employeeName,
               c.name AS clientName, i.name AS itemName, i.unitLabel,
               wl.qty, wl.wageUnitPrice, wl.workDate, wl.payrollId, wl.invoiceId
        FROM work_logs wl
        JOIN employees e ON e.id = wl.employeeId
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN clients c ON c.id = wo.clientId
        JOIN items i ON i.id = wo.itemId
        WHERE wl.workOrderId = :workOrderId
        ORDER BY wl.workDate DESC, wl.id DESC
        """
    )
    fun observeByOrder(workOrderId: Long): Flow<List<WorkLogRow>>

    @Query("SELECT IFNULL(SUM(qty), 0) FROM work_logs WHERE workDate BETWEEN :from AND :to")
    fun observeQtySum(from: Int, to: Int): Flow<Int>

    /** 한 일감에 지금까지 처리된 수량 합계 (완료 여부 판단에 씁니다) */
    @Query("SELECT IFNULL(SUM(qty), 0) FROM work_logs WHERE workOrderId = :workOrderId")
    suspend fun sumQtyByOrder(workOrderId: Long): Int

    @Insert
    suspend fun insert(log: WorkLog): Long

    @Query("DELETE FROM work_logs WHERE id = :id AND payrollId IS NULL AND invoiceId IS NULL")
    suspend fun deleteIfNotSettled(id: Long): Int

    // ---------------------------------------------------------------
    // 정산 묶음 — 여기가 중복 지급·중복 청구를 막는 핵심입니다.
    // 이미 묶인(payrollId/invoiceId 가 채워진) 기록은 조건에서 제외됩니다.
    // ---------------------------------------------------------------

    @Query(
        """
        UPDATE work_logs SET payrollId = :payrollId
        WHERE payrollId IS NULL AND employeeId = :employeeId AND workDate BETWEEN :from AND :to
        """
    )
    suspend fun attachToPayroll(payrollId: Long, employeeId: Long, from: Int, to: Int): Int

    @Query(
        """
        UPDATE work_logs SET invoiceId = :invoiceId
        WHERE invoiceId IS NULL AND workDate BETWEEN :from AND :to
          AND workOrderId IN (SELECT id FROM work_orders WHERE clientId = :clientId)
        """
    )
    suspend fun attachToInvoice(invoiceId: Long, clientId: Long, from: Int, to: Int): Int

    /** 정산 취소 — 묶음을 풀어 다시 미정산 상태로 되돌립니다. */
    @Query("UPDATE work_logs SET payrollId = NULL WHERE payrollId = :payrollId")
    suspend fun detachFromPayroll(payrollId: Long): Int

    @Query("UPDATE work_logs SET invoiceId = NULL WHERE invoiceId = :invoiceId")
    suspend fun detachFromInvoice(invoiceId: Long): Int
}
