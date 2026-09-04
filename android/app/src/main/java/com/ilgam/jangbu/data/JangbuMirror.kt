package com.ilgam.jangbu.data

import com.ilgam.jangbu.data.entity.*

/**
 * 장부에 적은 것을 서버에도 그대로 비추는 거울.
 *
 * 장부(Room)는 서버가 있는지 없는지 몰라도 됩니다.
 * 서버를 안 쓰면 거울이 없을 뿐이고, 앱은 지금까지처럼 돌아갑니다.
 */
interface JangbuMirror {
    fun onClient(row: Client)
    fun onItem(row: Item)
    fun onEmployee(row: Employee)

    fun onRate(row: EmployeeRate)
    fun onRateRemoved(id: String)

    fun onOrder(row: WorkOrder)

    fun onLog(row: WorkLog)
    fun onLogs(rows: List<WorkLog>)
    fun onLogRemoved(id: String)

    fun onInvoice(row: Invoice)
    fun onInvoiceRemoved(id: String)

    fun onPayroll(row: Payroll)
    fun onPayrollRemoved(id: String)
}
