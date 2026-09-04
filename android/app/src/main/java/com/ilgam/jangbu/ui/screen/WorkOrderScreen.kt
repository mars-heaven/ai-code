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
import com.ilgam.jangbu.ui.theme.Alert
import com.ilgam.jangbu.ui.theme.Dimens
import com.ilgam.jangbu.ui.theme.InkSoft
import com.ilgam.jangbu.util.VoiceCandidate
import com.ilgam.jangbu.util.matchByName
import com.ilgam.jangbu.util.parseQtyFromSpeech
import com.ilgam.jangbu.util.rememberSpeaker
import com.ilgam.jangbu.util.removeMatched
import com.ilgam.jangbu.util.toMoneyWon
import java.time.LocalDate

/**
 * 일감 접수 — "현미사에서 바지 100장 들어왔다"를 기록합니다.
 * 거래처나 품목이 없으면 저장하면서 함께 만들어집니다.
 */
@Composable
fun WorkOrderScreen(onBack: () -> Unit) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { WorkOrderViewModel(repo) }
    val clients by vm.clients.collectAsState()
    val items by vm.items.collectAsState()
    val message by vm.message.collectAsState()
    val saved by vm.saved.collectAsState()

    var clientName by remember { mutableStateOf("") }
    var itemName by remember { mutableStateOf("") }
    var qty by remember { mutableStateOf("") }
    var charge by remember { mutableStateOf("") }
    var wage by remember { mutableStateOf("") }
    var unitLabel by remember { mutableStateOf("장") }
    var dueInDays by remember { mutableStateOf<Int?>(null) }
    var heard by remember { mutableStateOf<String?>(null) }
    var voiceNote by remember { mutableStateOf<String?>(null) }

    /**
     * 말한 문장에서 거래처·품목·수량을 채웁니다.
     * 이미 등록된 이름만 알아들으므로, 처음 거래하는 곳은 손으로 적어야 합니다.
     */
    fun applyVoice(spoken: String) {
        heard = spoken

        val clientMatch = matchByName(
            spoken, clients.map { VoiceCandidate(it.name, listOf(it.name)) }
        )
        val itemMatch = matchByName(
            spoken, items.map { VoiceCandidate(it, listOf(it.name)) }
        )

        clientMatch?.let { (name, _) -> clientName = name }
        itemMatch?.let { (item, _) ->
            itemName = item.name
            // 등록된 품목이면 단가까지 같이 채웁니다.
            charge = item.chargeUnitPrice.toString()
            wage = item.defaultWageUnitPrice.toString()
            unitLabel = item.unitLabel
            if (clientMatch == null) clientName = item.clientName
        }

        // 이름 글자를 숫자로 잘못 읽지 않도록 알아들은 이름을 걷어낸 뒤 수량을 읽습니다.
        val rest = removeMatched(spoken, clientMatch?.second, itemMatch?.second)
        val amount = parseQtyFromSpeech(rest)
        if (amount != null && amount > 0) qty = amount.toString()

        voiceNote = when {
            clientMatch == null && itemMatch == null ->
                "등록된 거래처·품목을 못 찾았습니다. 직접 적어 주세요"
            itemMatch == null -> "품목을 못 알아들었습니다. 직접 적어 주세요"
            amount == null || amount <= 0 -> "수량을 못 알아들었습니다. 직접 적어 주세요"
            else -> null
        }
    }

    // 접수 결과를 소리로도 알려 줍니다(설정에서 끌 수 있습니다).
    val speaker = rememberSpeaker()
    LaunchedEffect(message) { message?.let { speaker.say(it) } }

    // 저장이 끝나면 이전 화면으로 돌아갑니다.
    LaunchedEffect(saved) {
        if (saved) {
            vm.clearSaved()
            onBack()
        }
    }

    val itemsOfClient = items.filter { it.clientName == clientName.trim() }

    JangbuScreen(
        title = "일감 접수",
        subtitle = "들어온 물건을 적습니다",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "접수하기",
                sub = if (qty.isNotBlank() && charge.isNotBlank()) {
                    val total = (qty.toLongOrNull() ?: 0L) * (charge.toLongOrNull() ?: 0L)
                    "받을 금액 ${total.toMoneyWon()}"
                } else null,
                onClick = {
                    vm.save(clientName, itemName, qty, charge, wage, unitLabel, dueInDays)
                },
                kind = BigButtonKind.Primary,
                enabled = clientName.isNotBlank() && itemName.isNotBlank() &&
                    qty.isNotBlank() && charge.isNotBlank()
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        // 말로 한 번에 넣기 — 이미 등록된 거래처·품목이면 단가까지 채워집니다.
        VoiceInputButton(
            text = "🎤 말로 넣기",
            sub = "예) 현미사 바지 백 장",
            onHeard = { applyVoice(it) }
        )
        if (heard != null) {
            Text(
                "들은 말: $heard",
                style = MaterialTheme.typography.bodyMedium,
                color = InkSoft
            )
        }
        voiceNote?.let {
            Text(it, style = MaterialTheme.typography.bodyMedium, color = Alert)
        }

        // 1. 거래처
        SectionTitle("1. 어느 거래처인가요?")
        BigField(
            label = "거래처",
            value = clientName,
            onValueChange = { clientName = it },
            hint = "예) 현미사"
        )
        if (clients.isNotEmpty()) {
            clients.chunked(2).forEach { pair ->
                Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
                    pair.forEach { c ->
                        BigButton(
                            text = c.name,
                            onClick = { clientName = c.name },
                            modifier = Modifier.weight(1f),
                            selected = clientName.trim() == c.name
                        )
                    }
                    if (pair.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }

        // 2. 품목
        SectionTitle("2. 무슨 품목인가요?")
        BigField(
            label = "품목",
            value = itemName,
            onValueChange = { itemName = it },
            hint = "예) 바지"
        )
        if (itemsOfClient.isNotEmpty()) {
            Text(
                "누르면 단가까지 채워집니다",
                style = MaterialTheme.typography.bodySmall,
                color = InkSoft
            )
            itemsOfClient.forEach { item ->
                BigButton(
                    text = item.name,
                    sub = "받을 ${item.chargeUnitPrice.toMoneyWon()} · 공임 ${item.defaultWageUnitPrice.toMoneyWon()}",
                    onClick = {
                        itemName = item.name
                        charge = item.chargeUnitPrice.toString()
                        wage = item.defaultWageUnitPrice.toString()
                        unitLabel = item.unitLabel
                    },
                    selected = itemName.trim() == item.name
                )
            }
        }

        // 3. 수량과 단가
        SectionTitle("3. 얼마나 들어왔나요?")
        BigField(
            label = "수량",
            value = qty,
            onValueChange = { qty = it },
            hint = "예) 100",
            numberOnly = true,
            suffix = unitLabel
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

        // 4. 납기 (선택)
        SectionTitle("4. 언제까지인가요? (안 정해도 됩니다)")
        Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
            BigButton(
                text = "없음",
                onClick = { dueInDays = null },
                modifier = Modifier.weight(1f),
                selected = dueInDays == null
            )
            BigButton(
                text = "3일 뒤",
                onClick = { dueInDays = 3 },
                modifier = Modifier.weight(1f),
                selected = dueInDays == 3
            )
            BigButton(
                text = "7일 뒤",
                onClick = { dueInDays = 7 },
                modifier = Modifier.weight(1f),
                selected = dueInDays == 7
            )
        }
        if (dueInDays != null) {
            Text(
                "납기 ${LocalDate.now().plusDays(dueInDays!!.toLong())}",
                style = MaterialTheme.typography.bodyMedium,
                color = InkSoft
            )
        }

        Spacer(Modifier.height(8.dp))
    }
}
