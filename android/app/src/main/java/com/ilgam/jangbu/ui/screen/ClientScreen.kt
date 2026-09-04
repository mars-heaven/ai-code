package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.data.entity.Client
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository

@Composable
fun ClientScreen(onBack: () -> Unit) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { ClientViewModel(repo) }
    val clients by vm.clients.collectAsState()
    val message by vm.message.collectAsState()

    // null 이면 목록, 값이 있으면 등록/수정 화면
    var editing by remember { mutableStateOf<Client?>(null) }

    val target = editing
    if (target != null) {
        ClientEditScreen(
            client = target,
            message = message,
            onClearMessage = vm::clearMessage,
            onSave = { name, phone, memo ->
                vm.save(target.id, name, phone, memo)
                editing = null
            },
            onBack = { editing = null }
        )
        return
    }

    JangbuScreen(
        title = "거래처",
        subtitle = "${clients.size}곳",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "새 거래처 등록",
                onClick = { editing = Client(name = "") },
                kind = BigButtonKind.Primary
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        if (clients.isEmpty()) {
            EmptyMessage("아직 등록된 거래처가 없습니다.\n아래 파란 버튼을 눌러 등록해 주세요.")
        } else {
            clients.forEach { client ->
                ListRow(
                    title = client.name,
                    subtitle = client.phone.ifBlank { "전화번호 없음" },
                    onClick = { editing = client }
                )
            }
        }
        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun ClientEditScreen(
    client: Client,
    message: String?,
    onClearMessage: () -> Unit,
    onSave: (name: String, phone: String, memo: String) -> Unit,
    onBack: () -> Unit
) {
    val isNew = client.id == 0L
    var name by remember(client.id) { mutableStateOf(client.name) }
    var phone by remember(client.id) { mutableStateOf(client.phone) }
    var memo by remember(client.id) { mutableStateOf(client.memo) }

    JangbuScreen(
        title = if (isNew) "새 거래처" else "거래처 수정",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "저장",
                onClick = { onSave(name, phone, memo) },
                kind = BigButtonKind.Primary,
                enabled = name.isNotBlank()
            )
        }
    ) {
        MessageBanner(message, onClearMessage)

        BigField(
            label = "거래처 이름",
            value = name,
            onValueChange = { name = it },
            hint = "예) 현미사"
        )
        BigField(
            label = "전화번호",
            value = phone,
            onValueChange = { phone = it },
            hint = "예) 010-1234-5678"
        )
        BigField(
            label = "메모",
            value = memo,
            onValueChange = { memo = it },
            hint = "적어 둘 내용이 있으면"
        )
        Spacer(Modifier.height(8.dp))
    }
}
