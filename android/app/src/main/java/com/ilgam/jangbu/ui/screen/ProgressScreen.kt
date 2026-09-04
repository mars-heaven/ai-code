package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import com.ilgam.jangbu.data.dao.WorkOrderRow
import com.ilgam.jangbu.data.entity.WorkOrderStatus
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.toLocalDate
import com.ilgam.jangbu.util.toMoneyWon
import com.ilgam.jangbu.util.toShortDisplay
import com.ilgam.jangbu.util.withUnit

/**
 * 진행 현황 — 대상 수량과 처리 수량이 얼마나 차이 나는지 보여 줍니다.
 * 일감을 누르면 누가 얼마나 했는지 펼쳐집니다.
 */
@Composable
fun ProgressScreen(onBack: () -> Unit) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { ProgressViewModel(repo) }

    val orders by vm.orders.collectAsState()
    val openId by vm.openOrderId.collectAsState()
    val logs by vm.openOrderLogs.collectAsState()
    val message by vm.message.collectAsState()

    val inProgress = orders.filter { it.status == WorkOrderStatus.IN_PROGRESS }
    val done = orders.filter { it.status == WorkOrderStatus.DONE }

    JangbuScreen(
        title = "진행 현황",
        subtitle = "남은 ${inProgress.sumOf { it.remainQty }}장",
        onBack = onBack
    ) {
        MessageBanner(message, vm::clearMessage)

        if (orders.isEmpty()) {
            EmptyMessage("아직 접수한 일감이 없습니다.\n일감 접수부터 해 주세요.")
            Spacer(Modifier.height(8.dp))
            return@JangbuScreen
        }

        if (inProgress.isNotEmpty()) {
            SectionTitle("하는 중")
            inProgress.forEach { order ->
                OrderCard(
                    order = order,
                    expanded = openId == order.id,
                    onToggle = { vm.toggleOrder(order.id) },
                    logs = if (openId == order.id) logs else emptyList(),
                    onDeleteLog = { logId -> vm.deleteLog(logId, order.id) }
                )
            }
        }

        if (done.isNotEmpty()) {
            SectionTitle("끝난 일감")
            done.forEach { order ->
                OrderCard(
                    order = order,
                    expanded = openId == order.id,
                    onToggle = { vm.toggleOrder(order.id) },
                    logs = if (openId == order.id) logs else emptyList(),
                    onDeleteLog = { logId -> vm.deleteLog(logId, order.id) }
                )
            }
        }

        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun OrderCard(
    order: WorkOrderRow,
    expanded: Boolean,
    onToggle: () -> Unit,
    logs: List<com.ilgam.jangbu.data.dao.WorkLogRow>,
    onDeleteLog: (String) -> Unit
) {
    val isDone = order.status == WorkOrderStatus.DONE

    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Dimens.Radius))
            .background(CardBg)
            .border(1.dp, Line, RoundedCornerShape(Dimens.Radius))
            .clickable { onToggle() }
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(
                    "${order.clientName} · ${order.itemName}",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = Ink
                )
                Text(
                    buildString {
                        append("접수 ${order.receivedDate.toLocalDate().toShortDisplay()}")
                        order.dueDate?.let { append(" · 납기 ${it.toLocalDate().toShortDisplay()}") }
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = InkSoft
                )
            }
            if (isDone) {
                StatusPill("끝남", PillKind.Good)
            } else {
                StatusPill("${(order.progress * 100).toInt()}%", PillKind.Warn)
            }
        }

        ProgressBar(progress = order.progress, done = isDone)

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                "대상 ${order.targetQty.withUnit(order.unitLabel)}",
                style = MaterialTheme.typography.bodyMedium,
                color = InkSoft
            )
            Text(
                "처리 ${order.doneQty.withUnit(order.unitLabel)} · 남음 ${order.remainQty.withUnit(order.unitLabel)}",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = if (isDone) Good else Alert
            )
        }

        if (expanded) {
            Spacer(Modifier.height(2.dp))
            Text(
                "누가 했나",
                style = MaterialTheme.typography.titleMedium,
                color = InkSoft
            )
            if (logs.isEmpty()) {
                Text(
                    "아직 처리한 사람이 없습니다.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = InkFaint
                )
            } else {
                logs.forEach { log ->
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(SurfaceAlt)
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(
                                log.employeeName,
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.SemiBold,
                                color = Ink
                            )
                            Text(
                                "${log.workDate.toLocalDate().toShortDisplay()} · 공임 ${log.wage.toMoneyWon()}",
                                style = MaterialTheme.typography.bodySmall,
                                color = InkSoft
                            )
                        }
                        Text(
                            log.qty.withUnit(log.unitLabel),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Bold,
                            color = Ink
                        )
                        // 정산 전 기록만 지울 수 있습니다.
                        if (log.payrollId == null && log.invoiceId == null) {
                            Spacer(Modifier.width(10.dp))
                            Text(
                                "지우기",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Bold,
                                color = Alert,
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .clickable { onDeleteLog(log.id) }
                                    .padding(horizontal = 10.dp, vertical = 8.dp)
                            )
                        }
                    }
                }
            }
        } else {
            Text(
                "누르면 누가 했는지 볼 수 있습니다",
                style = MaterialTheme.typography.bodySmall,
                color = InkFaint
            )
        }
    }
}
