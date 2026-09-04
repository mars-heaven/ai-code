package com.ilgam.jangbu.ui.screen

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.JangbuApplication
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.*
import kotlinx.coroutines.launch

/**
 * 백업과 복원.
 * 자료는 이 휴대폰 안에만 있으므로, 가끔 밖으로 한 벌 빼 두는 것이 가장 확실한 대비입니다.
 */
@Composable
fun BackupScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val app = context.applicationContext as JangbuApplication
    val scope = rememberCoroutineScope()
    val prefs = remember { Prefs(context) }

    var lastBackupAt by remember { mutableStateOf(prefs.lastBackupAt) }
    var message by remember { mutableStateOf<String?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    var pendingRestore by remember { mutableStateOf<Uri?>(null) }
    var restoreDone by remember { mutableStateOf(false) }

    val saveLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("application/zip")
    ) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        busy = true
        scope.launch {
            when (val r = exportBackup(context, app.database, uri)) {
                is BackupResult.Ok -> {
                    prefs.lastBackupAt = System.currentTimeMillis()
                    lastBackupAt = prefs.lastBackupAt
                    message = "백업을 저장했습니다 (사진 ${r.photoCount}장 포함)"
                }
                is BackupResult.Fail -> error = r.reason
            }
            busy = false
        }
    }

    val openLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        // 되돌릴 수 없는 일이므로 고른 뒤에 한 번 더 묻습니다.
        if (uri != null) pendingRestore = uri
    }

    JangbuScreen(
        title = "백업과 복원",
        subtitle = lastBackupAt.toBackupDisplay(),
        onBack = onBack
    ) {
        MessageBanner(message) { message = null }

        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Dimens.Radius))
                .background(if (lastBackupAt.backupIsStale()) WarnBg else GoodBg)
                .border(
                    Dimens.Border,
                    if (lastBackupAt.backupIsStale()) Warn else Good,
                    RoundedCornerShape(Dimens.Radius)
                )
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                if (lastBackupAt.backupIsStale()) "백업을 해 두세요"
                else "백업이 되어 있습니다",
                style = MaterialTheme.typography.titleMedium,
                color = if (lastBackupAt.backupIsStale()) Warn else Good
            )
            Text(
                "장부와 계산서 사진이 이 휴대폰 안에만 있습니다.\n" +
                    "휴대폰을 잃어버리거나 앱을 지우면 함께 사라집니다.\n" +
                    "한 달에 한 번쯤 백업 파일을 만들어 두세요.",
                style = MaterialTheme.typography.bodyMedium,
                color = Ink
            )
        }

        SectionTitle("백업 만들기")
        BigButton(
            text = "백업 파일 저장",
            sub = "장부와 사진을 한 파일로 묶어 내보냅니다",
            onClick = { saveLauncher.launch(defaultBackupFileName()) },
            kind = BigButtonKind.Primary,
            enabled = !busy,
            big = true
        )
        Text(
            "저장할 곳을 고르는 창이 뜹니다.\n" +
                "‘드라이브’ 나 ‘내 파일’ 에 저장해 두면 휴대폰이 고장 나도 안전합니다.",
            style = MaterialTheme.typography.bodyMedium,
            color = InkSoft
        )

        SectionTitle("백업에서 되살리기")
        BigButton(
            text = "백업 파일 불러오기",
            sub = "지금 장부를 백업한 내용으로 바꿉니다",
            onClick = { openLauncher.launch(arrayOf("application/zip", "*/*")) },
            enabled = !busy
        )
        Text(
            "지금 이 휴대폰에 있는 장부와 사진은 모두 지워지고,\n" +
                "고른 백업 파일의 내용으로 바뀝니다.",
            style = MaterialTheme.typography.bodyMedium,
            color = Alert
        )

        if (busy) {
            EmptyMessage("작업 중입니다. 잠시만 기다려 주세요.")
        }

        Spacer(Modifier.height(8.dp))
    }

    val restoreUri = pendingRestore
    if (restoreUri != null) {
        ConfirmDialog(
            title = "정말 되살릴까요?",
            message = "지금 장부와 사진은 모두 지워지고 백업 파일의 내용으로 바뀝니다.\n" +
                "되돌릴 수 없습니다.",
            confirmText = "되살리기",
            dismissText = "그만두기",
            danger = true,
            onConfirm = {
                pendingRestore = null
                busy = true
                scope.launch {
                    when (val r = importBackup(context, app.database, restoreUri)) {
                        is BackupResult.Ok -> {
                            message = "되살렸습니다 (사진 ${r.photoCount}장)"
                            restoreDone = true
                        }
                        is BackupResult.Fail -> error = r.reason
                    }
                    busy = false
                }
            },
            onDismiss = { pendingRestore = null }
        )
    }

    if (restoreDone) {
        ConfirmDialog(
            title = "되살렸습니다",
            message = "바뀐 장부를 열기 위해 앱을 다시 시작합니다.",
            confirmText = "다시 시작",
            dismissText = "잠시 후에",
            onConfirm = { restartApp(context) },
            onDismiss = { restoreDone = false }
        )
    }

    val err = error
    if (err != null) {
        ConfirmDialog(
            title = "하지 못했습니다",
            message = err,
            confirmText = "알겠습니다",
            dismissText = "닫기",
            onConfirm = { error = null },
            onDismiss = { error = null }
        )
    }
}
