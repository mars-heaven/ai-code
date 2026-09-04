package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.ui.theme.InkSoft
import com.ilgam.jangbu.util.toMoneyWon

/**
 * 직원 한 사람의 품목별 공임 단가.
 * 비워 두면 품목에 정해 둔 기본 공임을 그대로 씁니다.
 */
@Composable
fun EmployeeRateScreen(
    employeeId: String,
    employeeName: String,
    onBack: () -> Unit
) {
    val repo = rememberRepository()
    val vm = jangbuViewModel(key = "rate-$employeeId") { EmployeeRateViewModel(repo, employeeId) }
    val rates by vm.rates.collectAsState()
    val message by vm.message.collectAsState()

    // 입력 중인 값. 저장 버튼을 눌러야 반영됩니다.
    var inputs by remember { mutableStateOf<Map<String, String>>(emptyMap()) }
    var loadedFor by remember { mutableStateOf<List<String>>(emptyList()) }

    // 목록이 처음 들어왔을 때만 현재 값으로 채웁니다(입력 중 덮어쓰지 않도록).
    LaunchedEffect(rates.map { it.itemId }) {
        val ids = rates.map { it.itemId }
        if (ids != loadedFor) {
            inputs = rates.associate { it.itemId to (it.customWageUnitPrice?.toString() ?: "") }
            loadedFor = ids
        }
    }

    JangbuScreen(
        title = "$employeeName 공임",
        subtitle = "품목마다 다르게 정할 수 있습니다",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "공임 저장",
                onClick = {
                    inputs.forEach { (itemId, value) -> vm.setRate(itemId, value) }
                },
                kind = BigButtonKind.Primary,
                enabled = rates.isNotEmpty()
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        if (rates.isEmpty()) {
            EmptyMessage("먼저 품목을 등록해 주세요.\n품목이 있어야 공임을 정할 수 있습니다.")
        } else {
            Text(
                "칸을 비워 두면 품목의 기본 공임을 그대로 씁니다",
                style = MaterialTheme.typography.bodyMedium,
                color = InkSoft
            )

            rates.forEach { row ->
                BigField(
                    label = "${row.clientName} · ${row.itemName}",
                    value = inputs[row.itemId] ?: "",
                    onValueChange = { inputs = inputs + (row.itemId to it) },
                    hint = "기본 ${row.defaultWageUnitPrice.toMoneyWon()}",
                    numberOnly = true,
                    suffix = "원"
                )
            }
        }
        Spacer(Modifier.height(8.dp))
    }
}
