package com.ilgam.jangbu.util

import android.content.Context
import android.content.Intent
import com.ilgam.jangbu.data.dao.InvoiceRow
import com.ilgam.jangbu.data.dao.MonthTotals
import com.ilgam.jangbu.data.dao.PayrollRow
import com.ilgam.jangbu.data.dao.SettledDetailRow
import com.ilgam.jangbu.data.dao.SummaryLineRow

/**
 * 정산서를 글로 만들어 카카오톡·문자 등으로 보냅니다.
 *
 * 그림이나 첨부 파일이 아니라 그냥 글로 보냅니다.
 * 받는 쪽이 무슨 앱을 쓰든 열리고, 문자로도 그대로 갈 수 있어서입니다.
 */
fun shareText(context: Context, subject: String, body: String): Boolean {
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_SUBJECT, subject)
        putExtra(Intent.EXTRA_TEXT, body)
    }
    val chooser = Intent.createChooser(send, "어디로 보낼까요?").apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    return runCatching { context.startActivity(chooser) }.isSuccess
}

private const val LINE = "─────────────"

/** 급여 정산서 — 직원에게 보냅니다. */
fun payrollStatementText(row: PayrollRow, details: List<SettledDetailRow>): String = buildString {
    appendLine("[급여 정산서]")
    appendLine("${row.employeeName} 님")
    appendLine(
        "${row.periodStart.toLocalDate().toDisplay()} ~ " +
            row.periodEnd.toLocalDate().toDisplay()
    )
    appendLine(LINE)
    if (details.isEmpty()) {
        appendLine("(명세 없음)")
    } else {
        details.forEach { d ->
            appendLine("${d.itemName}  ${d.qty.withUnit(d.unitLabel)}")
            appendLine("  ${d.unitPrice.toMoney()}원 × ${d.qty} = ${d.amount.toMoneyWon()}")
        }
    }
    appendLine(LINE)
    appendLine("합계  ${row.totalAmount.toMoneyWon()}")
    appendLine(if (row.paid) "지급 완료 ${row.paidDate?.toLocalDate()?.toDisplay() ?: ""}" else "지급 예정")
}

/** 거래처 계산서 — 거래처에 보냅니다. */
fun invoiceStatementText(row: InvoiceRow, details: List<SettledDetailRow>): String = buildString {
    appendLine("[거래 명세서]")
    appendLine("${row.clientName} 귀중")
    appendLine(
        "${row.periodStart.toLocalDate().toDisplay()} ~ " +
            row.periodEnd.toLocalDate().toDisplay()
    )
    appendLine(LINE)
    if (details.isEmpty()) {
        appendLine("(명세 없음)")
    } else {
        details.forEach { d ->
            appendLine("${d.itemName}  ${d.qty.withUnit(d.unitLabel)}")
            appendLine("  ${d.unitPrice.toMoney()}원 × ${d.qty} = ${d.amount.toMoneyWon()}")
        }
    }
    appendLine(LINE)
    appendLine("합계  ${row.totalAmount.toMoneyWon()}")
    appendLine("발행 ${row.issuedDate.toLocalDate().toDisplay()}")
    appendLine(if (row.paid) "입금 완료" else "입금 부탁드립니다")
}

/** 월별 요약 — 내가 보관하거나 가족에게 보냅니다. */
fun monthSummaryText(
    monthLabel: String,
    totals: MonthTotals,
    byClient: List<SummaryLineRow>,
    byEmployee: List<SummaryLineRow>
): String = buildString {
    appendLine("[$monthLabel 요약]")
    appendLine(LINE)
    appendLine("처리 수량  ${totals.qty.withUnit("장")}")
    appendLine("받을 돈    ${totals.revenue.toMoneyWon()}")
    appendLine("줄 공임    ${totals.wage.toMoneyWon()}")
    appendLine("남는 돈    ${(totals.revenue - totals.wage).toMoneyWon()}")
    if (byClient.isNotEmpty()) {
        appendLine(LINE)
        appendLine("거래처별")
        byClient.forEach { appendLine("  ${it.name}  ${it.amount.toMoneyWon()}") }
    }
    if (byEmployee.isNotEmpty()) {
        appendLine(LINE)
        appendLine("직원별 공임")
        byEmployee.forEach {
            appendLine("  ${it.name}  ${it.qty.withUnit("장")}  ${it.amount.toMoneyWon()}")
        }
    }
}
