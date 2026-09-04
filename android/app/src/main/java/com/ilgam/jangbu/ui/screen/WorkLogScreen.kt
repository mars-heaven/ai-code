package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.ui.theme.Dimens
import com.ilgam.jangbu.ui.theme.InkSoft
import com.ilgam.jangbu.util.toMoneyWon
import com.ilgam.jangbu.util.withUnit
import java.time.LocalDate

/**
 * 직원 작업 등록 — "홍길동이 현미사 바지 10장 했다".
 * 가장 자주 쓰는 화면이라 고르는 순서를 1·2·3 으로 분명히 나눴습니다.
 */
@Composable
fun WorkLogScreen(onBack: () -> Unit) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { WorkLogViewModel(repo) }

    val employees by vm.employees.collectAsState()
    val orders by vm.orders.collectAsState()
    val employeeId by vm.employeeId.collectAsState()
    val orderId by vm.orderId.collectAsState()
    val qty by vm.qty.collectAsState()
    val workDate by vm.workDate.collectAsState()
    val wageUnitPrice by vm.wageUnitPrice.collectAsState()
    val message by vm.message.collectAsState()

    val selectedOrder = orders.firstOrNull { it.id == orderId }
    val amount = qty.toIntOrNull() ?: 0
    val total = amount * wageUnitPrice

    JangbuScreen(
        title = "작업 등록",
        subtitle = "누가 · 무엇을 · 몇 장",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "저장",
                sub = if (amount > 0 && wageUnitPrice > 0) "공임 ${total.toMoneyWon()}" else null,
                onClick = { vm.save() },
                kind = BigButtonKind.Primary,
                enabled = employeeId != null && orderId != null && amount > 0
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        if (employees.isEmpty() || orders.isEmpty()) {
            EmptyMessage(
                when {
                    employees.isEmpty() && orders.isEmpty() ->
                        "먼저 직원을 등록하고 일감을 접수해 주세요."
                    employees.isEmpty() -> "먼저 직원을 등록해 주세요."
                    else -> "처리할 일감이 없습니다.\n먼저 일감을 접수해 주세요."
                }
            )
            Spacer(Modifier.height(8.dp))
            return@JangbuScreen
        }

        // 1. 직원
        SectionTitle("1. 누가 했나요?")
        employees.chunked(2).forEach { pair ->
            Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
                pair.forEach { e ->
                    BigButton(
                        text = e.name,
                        onClick = { vm.selectEmployee(e.id) },
                        modifier = Modifier.weight(1f),
                        selected = employeeId == e.id
                    )
                }
                if (pair.size == 1) Spacer(Modifier.weight(1f))
            }
        }

        // 2. 일감
        SectionTitle("2. 무슨 일감인가요?")
        orders.forEach { o ->
            BigButton(
                text = "${o.clientName} · ${o.itemName}",
                sub = "남은 ${o.remainQty.withUnit(o.unitLabel)} (대상 ${o.targetQty.withUnit(o.unitLabel)})",
                onClick = { vm.selectOrder(o.id) },
                selected = orderId == o.id
            )
        }

        // 3. 수량
        SectionTitle("3. 몇 ${selectedOrder?.unitLabel ?: "장"} 했나요?")
        BigField(
            label = "수량",
            value = qty,
            onValueChange = vm::setQty,
            hint = "예) 10",
            numberOnly = true,
            suffix = selectedOrder?.unitLabel ?: "장"
        )

        if (selectedOrder != null && employeeId != null) {
            val over = amount > selectedOrder.remainQty
            Text(
                buildString {
                    append("공임 단가 ${wageUnitPrice.toMoneyWon()}")
                    if (amount > 0) append(" · 합계 ${total.toMoneyWon()}")
                },
                style = MaterialTheme.typography.bodyMedium,
                color = InkSoft
            )
            if (over) {
                StatusPill("남은 수량보다 많습니다", PillKind.Warn)
            }
        }

        // 4. 날짜 — 오늘이 기본, 어제 것도 넣을 수 있게
        SectionTitle("4. 언제 한 일인가요?")
        Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
            BigButton(
                text = "오늘",
                onClick = { vm.setWorkDate(LocalDate.now()) },
                modifier = Modifier.weight(1f),
                selected = workDate == LocalDate.now()
            )
            BigButton(
                text = "어제",
                onClick = { vm.setWorkDate(LocalDate.now().minusDays(1)) },
                modifier = Modifier.weight(1f),
                selected = workDate == LocalDate.now().minusDays(1)
            )
        }

        Spacer(Modifier.height(8.dp))
    }
}
