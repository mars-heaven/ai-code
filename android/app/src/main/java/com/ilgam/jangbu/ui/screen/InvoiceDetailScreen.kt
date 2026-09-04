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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.ilgam.jangbu.data.entity.InvoicePhoto
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.*
import java.io.File

/**
 * 계산서 한 장.
 * 종이 계산서·영수증을 찍어 두면 나중에 찾을 일이 없습니다.
 */
@Composable
fun InvoiceDetailScreen(invoiceId: Long, onBack: () -> Unit) {
    val context = LocalContext.current
    val repo = rememberRepository()
    val vm = jangbuViewModel(key = "invoice-$invoiceId") {
        InvoiceDetailViewModel(repo, invoiceId)
    }

    val invoice by vm.invoice.collectAsState()
    val photos by vm.photos.collectAsState()
    val message by vm.message.collectAsState()
    val canceled by vm.canceled.collectAsState()
    val statement by vm.statement.collectAsState()

    // 계산서를 취소하면 볼 것이 없으므로 목록으로 돌아갑니다.
    LaunchedEffect(canceled) { if (canceled) onBack() }

    // 명세서가 만들어지면 카카오톡·문자 보내기 창을 엽니다.
    LaunchedEffect(statement) {
        statement?.let { st ->
            if (st.viaSms) {
                // 문자에는 사진이 붙지 않습니다. 번호와 글만 채워 문자 앱을 엽니다.
                sendSms(context, st.phone, st.body)
            } else {
                // 보관해 둔 계산서 사진을 함께 붙여 보냅니다.
                val uris = photos.map { fileProviderUri(context, photoFile(context, it.filePath)) }
                shareTextAndPhotos(context, st.subject, st.body, uris, st.phone)
            }
            vm.clearStatement()
        }
    }

    // 카메라 앱에 넘겨 준 저장 위치. 찍기가 끝나면 이 파일을 목록에 넣습니다.
    var pendingFile by remember { mutableStateOf<File?>(null) }
    var cameraFailed by remember { mutableStateOf(false) }
    var confirmPaid by remember { mutableStateOf(false) }
    var confirmCancel by remember { mutableStateOf(false) }
    var deleteTarget by remember { mutableStateOf<InvoicePhoto?>(null) }

    val takePicture = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { saved ->
        val file = pendingFile
        pendingFile = null
        if (file == null) return@rememberLauncherForActivityResult
        if (saved) {
            // 장부에는 파일 이름만 담습니다(휴대폰을 바꿔 복원해도 찾을 수 있도록).
            vm.addPhoto(file.name)
        } else {
            // 찍다가 취소하면 빈 파일이 남으므로 지웁니다.
            deletePhotoFile(file)
        }
    }

    fun shoot() {
        val file = newInvoicePhotoFile(context)
        pendingFile = file
        val uri: Uri = fileProviderUri(context, file)
        val ok = runCatching { takePicture.launch(uri) }.isSuccess
        if (!ok) {
            pendingFile = null
            deletePhotoFile(file)
            cameraFailed = true
        }
    }

    val inv = invoice

    JangbuScreen(
        title = inv?.clientName ?: "계산서",
        subtitle = inv?.let {
            "${it.periodStart.toLocalDate().toShortDisplay()} ~ " +
                it.periodEnd.toLocalDate().toShortDisplay()
        },
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "계산서 사진 찍기",
                sub = if (photos.isEmpty()) "아직 사진이 없습니다" else "${photos.size}장 보관 중",
                onClick = { shoot() },
                kind = BigButtonKind.Primary
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        if (inv == null) {
            EmptyMessage("계산서를 찾을 수 없습니다.")
        } else {
            // 금액과 입금 여부
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Dimens.Radius))
                    .background(if (inv.paid) GoodBg else WarnBg)
                    .border(
                        Dimens.Border,
                        if (inv.paid) Good else Warn,
                        RoundedCornerShape(Dimens.Radius)
                    )
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(
                            "청구 금액",
                            style = MaterialTheme.typography.titleMedium,
                            color = if (inv.paid) Good else Warn
                        )
                        Text(
                            "발행 ${inv.issuedDate.toLocalDate().toDisplay()}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = InkSoft
                        )
                    }
                    StatusPill(
                        if (inv.paid) "입금완료" else "미수금",
                        if (inv.paid) PillKind.Good else PillKind.Warn
                    )
                }
                Text(
                    inv.totalAmount.toMoneyWon(),
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = Ink
                )
                BigButton(
                    text = "명세서 보내기",
                    sub = if (photos.isEmpty()) "카카오톡 · 메일 등에서 고릅니다"
                          else "사진 ${photos.size}장과 함께 보냅니다",
                    onClick = { vm.makeStatement() }
                )
                if (inv.clientPhone.isNotBlank()) {
                    BigButton(
                        text = "문자로 보내기",
                        sub = "${inv.clientPhone} · 글만 갑니다",
                        onClick = { vm.makeStatement(viaSms = true) }
                    )
                }
                if (inv.paid) {
                    Text(
                        "입금 ${inv.paidDate?.toLocalDate()?.toDisplay() ?: "-"}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = InkSoft
                    )
                } else {
                    BigButton(
                        text = "입금 확인",
                        sub = "돈을 받았으면 눌러 주세요",
                        onClick = { confirmPaid = true },
                        kind = BigButtonKind.Primary
                    )
                    BigButton(
                        text = "계산서 취소",
                        sub = "잘못 냈으면 되돌립니다",
                        onClick = { confirmCancel = true },
                        kind = BigButtonKind.Danger
                    )
                }
            }
        }

        SectionTitle("보관한 사진")
        if (photos.isEmpty()) {
            EmptyMessage("아래 ‘계산서 사진 찍기’ 를 눌러\n종이 계산서를 찍어 두세요.")
        } else {
            photos.forEach { photo ->
                Column(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(Dimens.Radius))
                        .background(CardBg)
                        .border(1.dp, Line, RoundedCornerShape(Dimens.Radius))
                        .padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    AsyncImage(
                        model = photoFile(context, photo.filePath),
                        contentDescription = "계산서 사진",
                        contentScale = ContentScale.Fit,
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 220.dp, max = 420.dp)
                            .clip(RoundedCornerShape(Dimens.Radius))
                            .background(SurfaceAlt)
                    )
                    BigButton(
                        text = "이 사진 지우기",
                        onClick = { deleteTarget = photo },
                        kind = BigButtonKind.Danger
                    )
                }
            }
        }

        Spacer(Modifier.height(8.dp))
    }

    if (confirmPaid && inv != null) {
        ConfirmDialog(
            title = "입금 확인할까요?",
            message = "${inv.clientName} 에서 ${inv.totalAmount.toMoneyWon()} 을 받은 것으로 표시합니다.",
            confirmText = "받았습니다",
            onConfirm = { vm.markPaid(); confirmPaid = false },
            onDismiss = { confirmPaid = false }
        )
    }

    if (confirmCancel && inv != null) {
        ConfirmDialog(
            title = "계산서를 취소할까요?",
            message = "취소하면 그 금액이 다시 ‘계산서 안 낸’ 상태로 돌아가고,\n" +
                "이 계산서에 붙여 둔 사진도 함께 지워집니다.",
            confirmText = "취소하기",
            dismissText = "그대로 두기",
            danger = true,
            onConfirm = { vm.cancel(); confirmCancel = false },
            onDismiss = { confirmCancel = false }
        )
    }

    val target = deleteTarget
    if (target != null) {
        ConfirmDialog(
            title = "사진을 지울까요?",
            message = "지운 사진은 되살릴 수 없습니다.",
            confirmText = "지우기",
            dismissText = "그대로 두기",
            danger = true,
            onConfirm = { vm.removePhoto(target); deleteTarget = null },
            onDismiss = { deleteTarget = null }
        )
    }

    if (cameraFailed) {
        ConfirmDialog(
            title = "카메라를 열 수 없습니다",
            message = "이 휴대폰에서 카메라 앱을 찾지 못했습니다.",
            confirmText = "알겠습니다",
            dismissText = "닫기",
            onConfirm = { cameraFailed = false },
            onDismiss = { cameraFailed = false }
        )
    }
}
