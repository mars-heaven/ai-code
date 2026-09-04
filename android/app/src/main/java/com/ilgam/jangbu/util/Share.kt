package com.ilgam.jangbu.util

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
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
fun shareText(context: Context, subject: String, body: String, phone: String = ""): Boolean =
    shareTextAndPhotos(context, subject, body, emptyList(), phone)

/**
 * 정산서와 계산서 사진을 함께 보냅니다.
 *
 * 사진이 있으면 사진 첨부로 보내고 글은 함께 실어 보냅니다.
 * 문자로 보내면 사진이 붙는 순간 MMS 로 나가므로 요금이 다를 수 있습니다.
 */
fun shareTextAndPhotos(
    context: Context,
    subject: String,
    body: String,
    photos: List<Uri>,
    phone: String = ""
): Boolean {
    val send = when {
        photos.isEmpty() -> Intent(Intent.ACTION_SEND).apply { type = "text/plain" }
        photos.size == 1 -> Intent(Intent.ACTION_SEND).apply {
            type = "image/jpeg"
            putExtra(Intent.EXTRA_STREAM, photos.first())
        }
        else -> Intent(Intent.ACTION_SEND_MULTIPLE).apply {
            type = "image/jpeg"
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(photos))
        }
    }

    send.putExtra(Intent.EXTRA_SUBJECT, subject)
    send.putExtra(Intent.EXTRA_TEXT, body)
    // 문자 앱은 이 값을 받는 사람 자리에 넣어 줍니다(무시하는 앱도 있습니다).
    if (phone.isNotBlank()) send.putExtra("address", phone.digitsForCall())

    if (photos.isNotEmpty()) {
        // 받는 앱이 우리 앱 안의 사진을 읽을 수 있게 잠깐 권한을 넘깁니다.
        send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        send.clipData = ClipData.newUri(context.contentResolver, subject, photos.first()).also { clip ->
            photos.drop(1).forEach { clip.addItem(ClipData.Item(it)) }
        }
    }

    val chooser = Intent.createChooser(send, "어디로 보낼까요?").apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    return runCatching { context.startActivity(chooser) }.isSuccess
}

/**
 * 저장해 둔 전화번호로 곧장 문자 앱을 엽니다.
 * 번호와 내용이 미리 채워지므로 보내기만 누르면 됩니다(사진은 붙지 않습니다).
 */
fun sendSms(context: Context, phone: String, body: String): Boolean {
    val number = phone.digitsForCall()
    if (number.isBlank()) return false
    val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$number")).apply {
        putExtra("sms_body", body)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    return runCatching { context.startActivity(intent) }.isSuccess
}

/** 010-1234-5678 처럼 적어 둔 번호에서 걸 수 있는 숫자만 남깁니다. */
fun String.digitsForCall(): String = filter { it.isDigit() || it == '+' }

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
