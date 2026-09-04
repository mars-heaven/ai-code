package com.ilgam.jangbu.data.dao

import androidx.room.Dao
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

/**
 * 한 달 장사가 어땠는지 한눈에 보기 위한 집계.
 * 마감 여부와 상관없이 그 달에 '일한 날짜' 기준으로 모읍니다.
 */
data class MonthTotals(
    val qty: Int,
    /** 거래처에 받을 돈 */
    val revenue: Long,
    /** 직원에게 줄 공임 */
    val wage: Long
)

/** 거래처별·직원별·품목별 순위 한 줄 */
data class SummaryLineRow(
    val name: String,
    val qty: Int,
    val amount: Long
)

@Dao
interface SummaryDao {

    @Query(
        """
        SELECT IFNULL(SUM(wl.qty), 0) AS qty,
               IFNULL(SUM(wl.qty * wo.chargeUnitPrice), 0) AS revenue,
               IFNULL(SUM(wl.qty * wl.wageUnitPrice), 0) AS wage
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        WHERE wl.workDate BETWEEN :from AND :to
        """
    )
    fun observeTotals(from: Int, to: Int): Flow<MonthTotals>

    /** 거래처별 매출 */
    @Query(
        """
        SELECT c.name AS name, SUM(wl.qty) AS qty,
               SUM(wl.qty * wo.chargeUnitPrice) AS amount
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN clients c ON c.id = wo.clientId
        WHERE wl.workDate BETWEEN :from AND :to
        GROUP BY c.id, c.name
        ORDER BY amount DESC
        """
    )
    fun observeByClient(from: Int, to: Int): Flow<List<SummaryLineRow>>

    /** 직원별 공임 */
    @Query(
        """
        SELECT e.name AS name, SUM(wl.qty) AS qty,
               SUM(wl.qty * wl.wageUnitPrice) AS amount
        FROM work_logs wl
        JOIN employees e ON e.id = wl.employeeId
        WHERE wl.workDate BETWEEN :from AND :to
        GROUP BY e.id, e.name
        ORDER BY amount DESC
        """
    )
    fun observeByEmployee(from: Int, to: Int): Flow<List<SummaryLineRow>>

    /** 품목별 처리 수량 */
    @Query(
        """
        SELECT i.name AS name, SUM(wl.qty) AS qty,
               SUM(wl.qty * wo.chargeUnitPrice) AS amount
        FROM work_logs wl
        JOIN work_orders wo ON wo.id = wl.workOrderId
        JOIN items i ON i.id = wo.itemId
        WHERE wl.workDate BETWEEN :from AND :to
        GROUP BY i.id, i.name
        ORDER BY qty DESC
        """
    )
    fun observeByItem(from: Int, to: Int): Flow<List<SummaryLineRow>>
}
