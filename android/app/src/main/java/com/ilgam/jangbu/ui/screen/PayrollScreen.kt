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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.*

/**
 * 급여 정산.
 * 아직 지급하지 않은 공임만 모아 보여 주므로, 마감한 건이 다시 계산되지 않습니다.
 */
@Composable
fun PayrollScreen(onBack: () -> Unit) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { PayrollViewModel(repo) }

    val period by vm.period.collectAsState()
    val unpaid by vm.unpaid.collectAsState()
    val history by vm.history.collectAsState()
    val message by vm.message.collectAsState()
    val statement by vm.statement.collectAsState()
    val allUnpaidTotal by vm.allUnpaidTotal.collectAsState()

    // 정산서가 만들어지면 카카오톡·문자 보내기 창을 엽니다.
    val context = LocalContext.current
    LaunchedEffect(statement) {
        statement?.let {
            if (it.viaSms) sendSms(context, it.phone, it.body)
            else shareText(context, it.subject, it.body, it.phone)
            vm.clearStatement()
        }
    }

    val total = unpaid.sumOf { it.totalWage }
    var confirmAll by remember { mutableStateOf(false) }
    var cancelTarget by remember { mutableStateOf<PayrollRowTarget?>(null) }

    JangbuScreen(
        title = "급여 정산",
        subtitle = period.displayRange(),
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "전체 마감",
                sub = if (unpaid.isEmpty()) "마감할 내역이 없습니다"
                      else "${unpaid.size}명 · ${total.toMoneyWon()}",
                onClick = { confirmAll = true },
                kind = BigButtonKind.Primary,
                enabled = unpaid.isNotEmpty()
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        // 기간 고르기 — 주·달로 넘기거나 날짜를 직접 고릅니다.
        PeriodPicker(period = period, onChange = vm::setPeriod)

        // 고른 기간 밖에 남은 것이 있으면 알려 줍니다(주 단위로만 보다 빠뜨리는 것을 막습니다).
        val leftover = allUnpaidTotal - total
        if (period.kind != PeriodKind.ALL && leftover > 0L) {
            LeftoverNotice(
                text = "이 기간 밖에 아직 지급 안 한 공임이 ${leftover.toMoneyWon()} 더 있습니다.",
                onShowAll = { vm.setPeriod(allPeriod()) }
            )
        }

        // 아직 지급 안 한 공임
        SectionTitle("아직 지급 안 한 공임")
        if (unpaid.isEmpty()) {
            EmptyMessage("이 기간에 정산할 내역이 없습니다.")
        } else {
            unpaid.forEach { row ->
                Column(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(Dimens.Radius))
                        .background(CardBg)
                        .border(1.dp, Line, RoundedCornerShape(Dimens.Radius))
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(
                                row.employeeName,
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
                            row.totalWage.toMoneyWon(),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Bold,
                            color = Ink
                        )
                    }
                    BigButton(
                        text = "이 사람만 마감",
                        onClick = { vm.closeOne(row.employeeId, row.employeeName) }
                    )
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
                    total.toMoneyWon(),
                    style = MaterialTheme.typography.titleLarge,
                    color = AccentDark
                )
            }
        }

        // 마감한 급여
        SectionTitle("마감한 급여")
        if (history.isEmpty()) {
            EmptyMessage("아직 마감한 급여가 없습니다.")
        } else {
            history.take(20).forEach { row ->
                Column(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(Dimens.Radius))
                        .background(CardBg)
                        .border(1.dp, Line, RoundedCornerShape(Dimens.Radius))
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(
                                row.employeeName,
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.SemiBold,
                                color = Ink
                            )
                            Text(
                                "${row.periodStart.toLocalDate().toShortDisplay()} ~ " +
                                    row.periodEnd.toLocalDate().toShortDisplay(),
                                style = MaterialTheme.typography.bodyMedium,
                                color = InkSoft
                            )
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                row.totalAmount.toMoneyWon(),
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.Bold,
                                color = Ink
                            )
                            Spacer(Modifier.height(4.dp))
                            StatusPill(
                                if (row.paid) "지급완료" else "미지급",
                                if (row.paid) PillKind.Good else PillKind.Warn
                            )
                        }
                    }
                    if (!row.paid) {
                        Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
                            BigButton(
                                text = "지급 완료",
                                onClick = { vm.markPaid(row.id, row.employeeName) },
                                modifier = Modifier.weight(1f),
                                kind = BigButtonKind.Primary
                            )
                            BigButton(
                                text = "마감 취소",
                                onClick = {
                                    cancelTarget = PayrollRowTarget(row.id, row.employeeName)
                                },
                                modifier = Modifier.weight(1f),
                                kind = BigButtonKind.Danger
                            )
                        }
                    }
                    BigButton(
                        text = "정산서 보내기",
                        sub = "카카오톡 · 메일 등에서 고릅니다",
                        onClick = { vm.makeStatement(row) }
                    )
                    if (row.employeePhone.isNotBlank()) {
                        BigButton(
                            text = "문자로 보내기",
                            sub = row.employeePhone,
                            onClick = { vm.makeStatement(row, viaSms = true) }
                        )
                    }
                }
            }
        }

        Spacer(Modifier.height(8.dp))
    }

    if (confirmAll) {
        ConfirmDialog(
            title = "전체 마감할까요?",
            message = "${unpaid.size}명, 합계 ${total.toMoneyWon()} 을 마감합니다.\n" +
                "마감하면 이 내역은 다음 정산에서 빠집니다.",
            confirmText = "마감",
            onConfirm = { vm.closeAll(); confirmAll = false },
            onDismiss = { confirmAll = false }
        )
    }

    val target = cancelTarget
    if (target != null) {
        ConfirmDialog(
            title = "마감을 취소할까요?",
            message = "${target.name} 의 마감을 취소하면 그 공임이 다시 '지급 안 한 공임' 으로 돌아갑니다.",
            confirmText = "취소하기",
            dismissText = "그대로 두기",
            danger = true,
            onConfirm = { vm.cancel(target.id, target.name); cancelTarget = null },
            onDismiss = { cancelTarget = null }
        )
    }
}

private data class PayrollRowTarget(val id: String, val name: String)
