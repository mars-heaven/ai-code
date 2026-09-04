package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.data.dao.ItemRow
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.util.NEW_ID
import com.ilgam.jangbu.util.toMoneyWon

@Composable
fun ItemScreen(onBack: () -> Unit) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { ItemViewModel(repo) }
    val items by vm.items.collectAsState()
    val clients by vm.clients.collectAsState()
    val message by vm.message.collectAsState()

    // null 이면 목록. 번호가 비어 있으면 신규 등록
    var editing by remember { mutableStateOf<ItemRow?>(null) }

    val target = editing
    if (target != null) {
        ItemEditScreen(
            row = target,
            clientNames = clients.map { it.name },
            message = message,
            onClearMessage = vm::clearMessage,
            onSave = { clientName, itemName, charge, wage, unit ->
                vm.save(target.id, clientName, itemName, charge, wage, unit)
                editing = null
            },
            onBack = { editing = null }
        )
        return
    }

    JangbuScreen(
        title = "품목과 단가",
        subtitle = "${items.size}개",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "새 품목 등록",
                onClick = {
                    editing = ItemRow(
                        id = NEW_ID, clientId = NEW_ID, clientName = "", name = "",
                        chargeUnitPrice = 0, defaultWageUnitPrice = 0, unitLabel = "장"
                    )
                },
                kind = BigButtonKind.Primary
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        if (items.isEmpty()) {
            EmptyMessage("아직 등록된 품목이 없습니다.\n거래처와 단가를 함께 등록해 주세요.")
        } else {
            items.forEach { row ->
                ListRow(
                    title = "${row.clientName} · ${row.name}",
                    subtitle = "받을 단가 ${row.chargeUnitPrice.toMoneyWon()} · 공임 ${row.defaultWageUnitPrice.toMoneyWon()}",
                    onClick = { editing = row }
                )
            }
        }
        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun ItemEditScreen(
    row: ItemRow,
    clientNames: List<String>,
    message: String?,
    onClearMessage: () -> Unit,
    onSave: (clientName: String, itemName: String, charge: String, wage: String, unit: String) -> Unit,
    onBack: () -> Unit
) {
    val isNew = row.id.isBlank()
    var clientName by remember(row.id) { mutableStateOf(row.clientName) }
    var itemName by remember(row.id) { mutableStateOf(row.name) }
    var charge by remember(row.id) {
        mutableStateOf(if (row.chargeUnitPrice > 0) row.chargeUnitPrice.toString() else "")
    }
    var wage by remember(row.id) {
        mutableStateOf(if (row.defaultWageUnitPrice > 0) row.defaultWageUnitPrice.toString() else "")
    }
    var unit by remember(row.id) { mutableStateOf(row.unitLabel) }

    JangbuScreen(
        title = if (isNew) "새 품목" else "품목 수정",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "저장",
                onClick = { onSave(clientName, itemName, charge, wage, unit) },
                kind = BigButtonKind.Primary,
                enabled = clientName.isNotBlank() && itemName.isNotBlank() && charge.isNotBlank()
            )
        }
    ) {
        MessageBanner(message, onClearMessage)

        BigField(
            label = "거래처",
            value = clientName,
            onValueChange = { clientName = it },
            hint = "예) 현미사"
        )
        // 이미 있는 거래처는 눌러서 바로 채웁니다.
        if (clientNames.isNotEmpty()) {
            Text(
                "이미 등록된 거래처를 누르면 채워집니다",
                style = MaterialTheme.typography.bodySmall,
                color = com.ilgam.jangbu.ui.theme.InkSoft
            )
            clientNames.chunked(2).forEach { pair ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    pair.forEach { nameOption ->
                        BigButton(
                            text = nameOption,
                            onClick = { clientName = nameOption },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    if (pair.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }

        BigField(
            label = "품목 이름",
            value = itemName,
            onValueChange = { itemName = it },
            hint = "예) 바지"
        )
        BigField(
            label = "거래처에서 받을 단가",
            value = charge,
            onValueChange = { charge = it },
            hint = "예) 100",
            numberOnly = true,
            suffix = "원"
        )
        BigField(
            label = "직원에게 줄 기본 공임",
            value = wage,
            onValueChange = { wage = it },
            hint = "예) 70",
            numberOnly = true,
            suffix = "원"
        )
        BigField(
            label = "세는 단위",
            value = unit,
            onValueChange = { unit = it },
            hint = "장 / 개 / 벌"
        )
        Spacer(Modifier.height(8.dp))
    }
}
