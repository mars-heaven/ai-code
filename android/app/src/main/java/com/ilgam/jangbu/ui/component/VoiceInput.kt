package com.ilgam.jangbu.ui.component

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.VoiceListener

/**
 * 말로 넣기 버튼과 듣는 창.
 *
 * 저절로 끊기지 않도록, 다 말했을 때 사람이 직접 "다 말했어요" 를 누르게 합니다.
 * 말하는 동안 들은 글이 그대로 보여서, 잘못 들었으면 바로 다시 할 수 있습니다.
 */
@Composable
fun VoiceInputButton(
    text: String,
    sub: String?,
    onHeard: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val listener = remember { VoiceListener(context) }
    DisposableEffect(listener) { onDispose { listener.release() } }

    var open by remember { mutableStateOf(false) }
    var denied by remember { mutableStateOf(false) }
    var unavailable by remember { mutableStateOf(false) }

    val askMic = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            open = true
            listener.start()
        } else {
            denied = true
        }
    }

    fun begin() {
        if (!listener.available()) {
            unavailable = true
            return
        }
        val granted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) {
            open = true
            listener.start()
        } else {
            askMic.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    // 다 들으면 창을 닫고 결과를 넘깁니다.
    LaunchedEffect(listener.result) {
        listener.consumeResult()?.let {
            open = false
            onHeard(it)
        }
    }

    BigButton(text = text, sub = sub, onClick = { begin() }, modifier = modifier)

    if (open) {
        AlertDialog(
            onDismissRequest = { listener.cancel(); open = false },
            containerColor = CardBg,
            title = {
                Text(
                    if (listener.listening) "듣고 있습니다" else "잠시만요",
                    style = MaterialTheme.typography.titleLarge,
                    color = Ink
                )
            },
            text = {
                Column(
                    Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Text(
                        listener.partial.ifBlank { "천천히 말씀하세요" },
                        style = MaterialTheme.typography.bodyLarge,
                        color = if (listener.partial.isBlank()) InkSoft else Ink,
                        textAlign = TextAlign.Center
                    )
                    // 목소리가 들어오고 있다는 표시
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .height(16.dp)
                            .clip(RoundedCornerShape(999.dp))
                            .background(SurfaceAlt)
                    ) {
                        val ratio = if (listener.listening) listener.level else 0f
                        if (ratio > 0f) {
                            Box(
                                Modifier
                                    .fillMaxWidth(ratio)
                                    .fillMaxHeight()
                                    .clip(RoundedCornerShape(999.dp))
                                    .background(Accent)
                            )
                        }
                    }
                    Text(
                        "다 말씀하시면 아래 ‘다 말했어요’ 를 눌러 주세요.",
                        style = MaterialTheme.typography.bodySmall,
                        color = InkSoft,
                        textAlign = TextAlign.Center
                    )
                    // 버튼을 본문 안에 두어 두 개 모두 크게 세로로 놓습니다.
                    BigButton(
                        text = "다 말했어요",
                        onClick = { listener.stop() },
                        kind = BigButtonKind.Primary
                    )
                    BigButton(
                        text = "그만두기",
                        onClick = { listener.cancel(); open = false }
                    )
                }
            },
            confirmButton = {}
        )
    }

    val err = listener.error
    if (err != null) {
        ConfirmDialog(
            title = "다시 해 주세요",
            message = err,
            confirmText = "알겠습니다",
            dismissText = "닫기",
            onConfirm = { listener.clearError(); open = false },
            onDismiss = { listener.clearError(); open = false }
        )
    }

    if (denied) {
        ConfirmDialog(
            title = "마이크가 필요합니다",
            message = "말로 넣으려면 마이크 사용을 허용해 주세요.\n" +
                "허용하지 않아도 아래에서 직접 고를 수 있습니다.",
            confirmText = "알겠습니다",
            dismissText = "닫기",
            onConfirm = { denied = false },
            onDismiss = { denied = false }
        )
    }

    if (unavailable) {
        ConfirmDialog(
            title = "음성 인식을 쓸 수 없습니다",
            message = "이 휴대폰에 음성 인식 기능이 없습니다.\n" +
                "‘구글’ 앱을 설치하면 쓸 수 있습니다.\n" +
                "지금은 아래에서 직접 골라 주세요.",
            confirmText = "알겠습니다",
            dismissText = "닫기",
            onConfirm = { unavailable = false },
            onDismiss = { unavailable = false }
        )
    }
}
