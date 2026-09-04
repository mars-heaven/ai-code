package com.ilgam.jangbu.server

import com.google.firebase.firestore.DocumentSnapshot
import com.ilgam.jangbu.data.entity.*

/**
 * 장부의 표 하나하나를 서버에 담을 모양으로 옮기고, 다시 되돌립니다.
 *
 * 서버에는 숫자와 글자만 올립니다. 계산서 사진은 폰에만 두므로 여기 없습니다.
 * 되돌릴 때 값이 비어 있으면 기본값으로 채워, 오래된 자료가 있어도 앱이 죽지 않습니다.
 */

/** 서버에 자리를 나눠 두는 이름들 */
object Collections {
    const val CLIENTS = "clients"
    const val ITEMS = "items"
    const val EMPLOYEES = "employees"
    const val RATES = "rates"
    const val ORDERS = "workOrders"
    const val LOGS = "workLogs"
    const val INVOICES = "invoices"
    const val PAYROLLS = "payrolls"

    val all = listOf(CLIENTS, ITEMS, EMPLOYEES, RATES, ORDERS, LOGS, INVOICES, PAYROLLS)
}

// 서버에서 읽을 때 쓰는 작은 도우미들
private fun DocumentSnapshot.str(key: String): String = getString(key).orEmpty()
private fun DocumentSnapshot.num(key: String): Long = getLong(key) ?: 0L
private fun DocumentSnapshot.int(key: String): Int = (getLong(key) ?: 0L).toInt()
private fun DocumentSnapshot.intOrNull(key: String): Int? = getLong(key)?.toInt()
private fun DocumentSnapshot.strOrNull(key: String): String? = getString(key)
private fun DocumentSnapshot.bool(key: String): Boolean = getBoolean(key) ?: false
private fun DocumentSnapshot.boolTrue(key: String): Boolean = getBoolean(key) ?: true

// ----------------------------------------------------------------------
// 거래처
// ----------------------------------------------------------------------
fun Client.toMap(): Map<String, Any?> = mapOf(
    "name" to name, "phone" to phone, "memo" to memo,
    "active" to active, "createdAt" to createdAt
)

fun DocumentSnapshot.toClient() = Client(
    id = id, name = str("name"), phone = str("phone"), memo = str("memo"),
    active = boolTrue("active"), createdAt = num("createdAt")
)

// ----------------------------------------------------------------------
// 품목
// ----------------------------------------------------------------------
fun Item.toMap(): Map<String, Any?> = mapOf(
    "clientId" to clientId, "name" to name,
    "chargeUnitPrice" to chargeUnitPrice, "defaultWageUnitPrice" to defaultWageUnitPrice,
    "unitLabel" to unitLabel, "active" to active, "createdAt" to createdAt
)

fun DocumentSnapshot.toItem() = Item(
    id = id, clientId = str("clientId"), name = str("name"),
    chargeUnitPrice = num("chargeUnitPrice"), defaultWageUnitPrice = num("defaultWageUnitPrice"),
    unitLabel = str("unitLabel").ifBlank { "장" },
    active = boolTrue("active"), createdAt = num("createdAt")
)

// ----------------------------------------------------------------------
// 직원
// ----------------------------------------------------------------------
fun Employee.toMap(): Map<String, Any?> = mapOf(
    "name" to name, "phone" to phone, "memo" to memo,
    "active" to active, "createdAt" to createdAt
)

fun DocumentSnapshot.toEmployee() = Employee(
    id = id, name = str("name"), phone = str("phone"), memo = str("memo"),
    active = boolTrue("active"), createdAt = num("createdAt")
)

// ----------------------------------------------------------------------
// 직원별 공임
// ----------------------------------------------------------------------
fun EmployeeRate.toMap(): Map<String, Any?> = mapOf(
    "employeeId" to employeeId, "itemId" to itemId, "wageUnitPrice" to wageUnitPrice
)

fun DocumentSnapshot.toRate() = EmployeeRate(
    id = id, employeeId = str("employeeId"), itemId = str("itemId"),
    wageUnitPrice = num("wageUnitPrice")
)

// ----------------------------------------------------------------------
// 일감
// ----------------------------------------------------------------------
fun WorkOrder.toMap(): Map<String, Any?> = mapOf(
    "clientId" to clientId, "itemId" to itemId, "targetQty" to targetQty,
    "chargeUnitPrice" to chargeUnitPrice, "receivedDate" to receivedDate,
    "dueDate" to dueDate, "status" to status, "memo" to memo, "createdAt" to createdAt
)

fun DocumentSnapshot.toOrder() = WorkOrder(
    id = id, clientId = str("clientId"), itemId = str("itemId"),
    targetQty = int("targetQty"), chargeUnitPrice = num("chargeUnitPrice"),
    receivedDate = int("receivedDate"), dueDate = intOrNull("dueDate"),
    status = int("status"), memo = str("memo"), createdAt = num("createdAt")
)

// ----------------------------------------------------------------------
// 작업 기록
// ----------------------------------------------------------------------
fun WorkLog.toMap(): Map<String, Any?> = mapOf(
    "workOrderId" to workOrderId, "employeeId" to employeeId, "qty" to qty,
    "wageUnitPrice" to wageUnitPrice, "workDate" to workDate,
    "payrollId" to payrollId, "invoiceId" to invoiceId,
    "memo" to memo, "createdAt" to createdAt
)

fun DocumentSnapshot.toLog() = WorkLog(
    id = id, workOrderId = str("workOrderId"), employeeId = str("employeeId"),
    qty = int("qty"), wageUnitPrice = num("wageUnitPrice"), workDate = int("workDate"),
    payrollId = strOrNull("payrollId"), invoiceId = strOrNull("invoiceId"),
    memo = str("memo"), createdAt = num("createdAt")
)

// ----------------------------------------------------------------------
// 계산서
// ----------------------------------------------------------------------
fun Invoice.toMap(): Map<String, Any?> = mapOf(
    "clientId" to clientId, "periodStart" to periodStart, "periodEnd" to periodEnd,
    "totalAmount" to totalAmount, "issuedDate" to issuedDate,
    "paid" to paid, "paidDate" to paidDate, "memo" to memo, "createdAt" to createdAt
)

fun DocumentSnapshot.toInvoice() = Invoice(
    id = id, clientId = str("clientId"), periodStart = int("periodStart"),
    periodEnd = int("periodEnd"), totalAmount = num("totalAmount"),
    issuedDate = int("issuedDate"), paid = bool("paid"), paidDate = intOrNull("paidDate"),
    memo = str("memo"), createdAt = num("createdAt")
)

// ----------------------------------------------------------------------
// 급여
// ----------------------------------------------------------------------
fun Payroll.toMap(): Map<String, Any?> = mapOf(
    "employeeId" to employeeId, "periodStart" to periodStart, "periodEnd" to periodEnd,
    "totalAmount" to totalAmount, "closedDate" to closedDate,
    "paid" to paid, "paidDate" to paidDate, "memo" to memo, "createdAt" to createdAt
)

fun DocumentSnapshot.toPayroll() = Payroll(
    id = id, employeeId = str("employeeId"), periodStart = int("periodStart"),
    periodEnd = int("periodEnd"), totalAmount = num("totalAmount"),
    closedDate = int("closedDate"), paid = bool("paid"), paidDate = intOrNull("paidDate"),
    memo = str("memo"), createdAt = num("createdAt")
)
