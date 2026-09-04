package com.ilgam.jangbu.data.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.ilgam.jangbu.data.entity.*

/**
 * 서버에서 내려받은 것을 장부에 적고, 서버에 올릴 것을 꺼내 오는 통로.
 *
 * 화면이 쓰는 조회와는 성격이 달라 한곳에 모아 두었습니다.
 * 여기서 넣고 지우는 것은 서버와 맞추는 일뿐입니다.
 */
@Dao
interface SyncDao {

    // ------------------------------------------------------------------
    // 서버 → 장부
    // ------------------------------------------------------------------
    @Upsert suspend fun putClients(rows: List<Client>)
    @Upsert suspend fun putItems(rows: List<Item>)
    @Upsert suspend fun putEmployees(rows: List<Employee>)
    @Upsert suspend fun putRates(rows: List<EmployeeRate>)
    @Upsert suspend fun putOrders(rows: List<WorkOrder>)
    @Upsert suspend fun putLogs(rows: List<WorkLog>)
    @Upsert suspend fun putInvoices(rows: List<Invoice>)
    @Upsert suspend fun putPayrolls(rows: List<Payroll>)

    @Query("DELETE FROM clients WHERE id = :id") suspend fun dropClient(id: String)
    @Query("DELETE FROM items WHERE id = :id") suspend fun dropItem(id: String)
    @Query("DELETE FROM employees WHERE id = :id") suspend fun dropEmployee(id: String)
    @Query("DELETE FROM employee_rates WHERE id = :id") suspend fun dropRate(id: String)
    @Query("DELETE FROM work_orders WHERE id = :id") suspend fun dropOrder(id: String)
    @Query("DELETE FROM work_logs WHERE id = :id") suspend fun dropLog(id: String)
    @Query("DELETE FROM invoices WHERE id = :id") suspend fun dropInvoice(id: String)
    @Query("DELETE FROM payrolls WHERE id = :id") suspend fun dropPayroll(id: String)

    // ------------------------------------------------------------------
    // 장부 → 서버 (바뀐 줄을 다시 읽어 올릴 때)
    // ------------------------------------------------------------------
    @Query("SELECT * FROM work_logs WHERE id = :id") suspend fun logById(id: String): WorkLog?
    @Query("SELECT * FROM work_logs WHERE payrollId = :payrollId") suspend fun logsByPayroll(payrollId: String): List<WorkLog>
    @Query("SELECT * FROM work_logs WHERE invoiceId = :invoiceId") suspend fun logsByInvoice(invoiceId: String): List<WorkLog>
    @Query("SELECT * FROM work_logs WHERE id IN (:ids)") suspend fun logsByIds(ids: List<String>): List<WorkLog>
    @Query("SELECT * FROM employee_rates WHERE employeeId = :employeeId AND itemId = :itemId LIMIT 1")
    suspend fun rateOf(employeeId: String, itemId: String): EmployeeRate?

    // 첫 로그인 때 지금 장부를 통째로 서버에 올리기 위한 것
    @Query("SELECT * FROM clients") suspend fun allClients(): List<Client>
    @Query("SELECT * FROM items") suspend fun allItems(): List<Item>
    @Query("SELECT * FROM employees") suspend fun allEmployees(): List<Employee>
    @Query("SELECT * FROM employee_rates") suspend fun allRates(): List<EmployeeRate>
    @Query("SELECT * FROM work_orders") suspend fun allOrders(): List<WorkOrder>
    @Query("SELECT * FROM work_logs") suspend fun allLogs(): List<WorkLog>
    @Query("SELECT * FROM invoices") suspend fun allInvoices(): List<Invoice>
    @Query("SELECT * FROM payrolls") suspend fun allPayrolls(): List<Payroll>
}
