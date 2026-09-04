package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.data.dao.InvoiceRow
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.*

/**
 * 거래처 정산.
 * 아직 계산서에 넣지 않은 일감만 모아 보여 주므로, 같은 일을 두 번 청구하지 않습니다.
 */
@Composable
fun InvoiceScreen(
    onBack: () -> Unit,
    onOpenInvoice: (Long) -> Unit
) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { InvoiceViewModel(repo) }

    val period by vm.period.collectAsState()
    val unbilled by vm.unbilled.collectAsState()
    val openClientId by vm.openClientId.collectAsState()
    val detail by vm.openDetail.collectAsState()
    val unpaidInvoices by vm.unpaidInvoices.collectAsState()
    val history by vm.history.collectAsState()
    val message by vm.message.collectAsState()

    val unbilledTotal = unbilled.sumOf { it.totalAmount }
    val receivable = unpaidInvoices.sumOf { it.totalAmount }

    JangbuScreen(
        title = "거래처 정산",
        subtitle = period.displayRange(),
        onBack = onBack
    ) {
        MessageBanner(message, vm::clearMessage)

        // 아직 못 받은 돈부터 크게 보여 줍니다.
        Row(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Dimens.Radius))
                .background(if (receivable > 0L) WarnBg else GoodBg)
                .border(
                    Dimens.Border,
                    if (receivable > 0L) Warn else Good,
                    RoundedCornerShape(Dimens.Radius)
                )
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    "아직 못 받은 돈",
                    style = MaterialTheme.typography.titleMedium,
                    color = if (receivable > 0L) Warn else Good
                )
                Text(
                    if (unpaidInvoices.isEmpty()) "밀린 계산서가 없습니다"
                    else "계산서 ${unpaidInvoices.size}장",
                    style = MaterialTheme.typography.bodyMedium,
                    color = InkSoft
                )
            }
            Text(
                receivable.toMoneyWon(),
                style = MaterialTheme.typography.titleLarge,
                color = if (receivable > 0L) Warn else Good
            )
        }

        PeriodPicker(period = period, onChange = vm::setPeriod)

        // 아직 계산서를 내지 않은 거래처
        SectionTitle("아직 계산서 안 낸 거래처")
        if (unbilled.isEmpty()) {
            EmptyMessage("이 기간에 청구할 내역이 없습니다.")
        } else {
            unbilled.forEach { row ->
                val open = openClientId == row.clientId
                Column(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(Dimens.Radius))
                        .background(CardBg)
                        .border(
                            if (open) Dimens.Border else 1.dp,
                            if (open) Accent else Line,
                            RoundedCornerShape(Dimens.Radius)
                        )
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(
                                row.clientName,
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.SemiBold,
                                color = Ink
                            )
                            Text(
                                "처리 ${row.totalQty.withUnit("장")}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = InkSoft
                            )
                        }
                        Text(
                            row.totalAmount.toMoneyWon(),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Bold,
                            color = Ink
                        )
                    }

                    BigButton(
                        text = if (open) "명세 접기" else "명세 보기",
                        onClick = { vm.toggleClient(row.clientId) },
                        selected = open
                    )

                    if (open) {
                        // 무엇을 얼마에 청구하는지 발행 전에 확인합니다.
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(Dimens.Radius))
                                .background(SurfaceAlt)
                                .padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            if (detail.isEmpty()) {
                                Text(
                                    "명세를 불러오는 중입니다",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = InkSoft
                                )
                            } else {
                                detail.forEach { d ->
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Column(Modifier.weight(1f)) {
                                            Text(
                                                d.itemName,
                                                style = MaterialTheme.typography.bodyLarge,
                                                color = Ink
                                            )
                                            Text(
                                                "${d.qty.withUnit(d.unitLabel)} × " +
                                                    "${d.chargeUnitPrice.toMoney()}원",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = InkSoft
                                            )
                                        }
                                        Text(
                                            d.amount.toMoneyWon(),
                                            style = MaterialTheme.typography.bodyLarge,
                                            fontWeight = FontWeight.SemiBold,
                                            color = Ink
                                        )
                                    }
                                }
                            }
                        }

                        BigButton(
                            text = "계산서 발행",
                            sub = row.totalAmount.toMoneyWon(),
                            onClick = { vm.issue(row.clientId, row.clientName) },
                            kind = BigButtonKind.Primary
                        )
                    }
                }
            }

            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Dimens.Radius))
                    .background(AccentSoft)
                    .border(Dimens.Border, Accent, RoundedCornerShape(Dimens.Radius))
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("합계", style = MaterialTheme.typography.titleMedium, color = AccentDark)
                Text(
                    unbilledTotal.toMoneyWon(),
                    style = MaterialTheme.typography.titleLarge,
                    color = AccentDark
                )
            }
        }

        // 낸 계산서
        SectionTitle("낸 계산서")
        if (history.isEmpty()) {
            EmptyMessage("아직 발행한 계산서가 없습니다.")
        } else {
            history.take(20).forEach { row ->
                InvoiceHistoryRow(row = row, onClick = { onOpenInvoice(row.id) })
            }
        }

        Spacer(Modifier.height(8.dp))
    }
}

/** 계산서 이력 한 줄 — 눌러서 사진·입금 확인 화면으로 들어갑니다. */
@Composable
private fun InvoiceHistoryRow(row: InvoiceRow, onClick: () -> Unit) {
    ListRow(
        title = row.clientName,
        subtitle = "${row.periodStart.toLocalDate().toShortDisplay()} ~ " +
            "${row.periodEnd.toLocalDate().toShortDisplay()}  ·  ${row.totalAmount.toMoneyWon()}",
        badge = {
            StatusPill(
                if (row.paid) "입금완료" else "미수금",
                if (row.paid) PillKind.Good else PillKind.Warn
            )
        },
        onClick = onClick
    )
}
