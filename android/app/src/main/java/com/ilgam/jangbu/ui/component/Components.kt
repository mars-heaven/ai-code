package com.ilgam.jangbu.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.ui.theme.*

/** 화면 공통 틀 — 큰 제목 막대와 뒤로가기. */
@Composable
fun JangbuScreen(
    title: String,
    onBack: (() -> Unit)? = null,
    subtitle: String? = null,
    bottomBar: @Composable (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(Modifier.fillMaxSize().background(Paper)) {
        Row(
            Modifier
                .fillMaxWidth()
                .background(Accent)
                .padding(horizontal = 8.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (onBack != null) {
                IconButton(onClick = onBack, modifier = Modifier.size(56.dp)) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "뒤로",
                        tint = OnAccent,
                        modifier = Modifier.size(34.dp)
                    )
                }
            } else {
                Spacer(Modifier.width(12.dp))
            }
            Column(Modifier.weight(1f)) {
                Text(
                    title,
                    style = MaterialTheme.typography.titleLarge,
                    color = OnAccent
                )
                if (subtitle != null) {
                    Text(
                        subtitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = OnAccent.copy(alpha = 0.85f)
                    )
                }
            }
            Spacer(Modifier.width(12.dp))
        }

        Column(
            Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(Dimens.ScreenPadding),
            verticalArrangement = Arrangement.spacedBy(Dimens.Gap),
            content = content
        )

        if (bottomBar != null) {
            Surface(color = Paper, shadowElevation = 8.dp) {
                Box(Modifier.padding(Dimens.ScreenPadding)) { bottomBar() }
            }
        }
    }
}

enum class BigButtonKind { Primary, Normal, Danger }

/** 손가락으로 눌러도 빗나가지 않는 큰 버튼. */
@Composable
fun BigButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    sub: String? = null,
    kind: BigButtonKind = BigButtonKind.Normal,
    enabled: Boolean = true,
    big: Boolean = false
) {
    val bg = when (kind) {
        BigButtonKind.Primary -> Accent
        BigButtonKind.Normal -> CardBg
        BigButtonKind.Danger -> AlertBg
    }
    val fg = when (kind) {
        BigButtonKind.Primary -> OnAccent
        BigButtonKind.Normal -> Ink
        BigButtonKind.Danger -> Alert
    }
    val borderColor = when (kind) {
        BigButtonKind.Primary -> Accent
        BigButtonKind.Normal -> Line
        BigButtonKind.Danger -> Alert
    }

    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(Dimens.Radius),
        color = if (enabled) bg else SurfaceAlt,
        contentColor = if (enabled) fg else InkFaint,
        border = androidx.compose.foundation.BorderStroke(
            Dimens.Border,
            if (enabled) borderColor else Line
        ),
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = if (big) Dimens.ButtonHeightBig else Dimens.ButtonHeight)
    ) {
        Column(
            Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text,
                style = MaterialTheme.typography.labelLarge,
                textAlign = TextAlign.Center
            )
            if (sub != null) {
                Spacer(Modifier.height(2.dp))
                Text(
                    sub,
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center,
                    color = if (kind == BigButtonKind.Primary) OnAccent.copy(alpha = 0.88f) else InkSoft
                )
            }
        }
    }
}

/** 큰 글씨 입력창. 라벨을 위에 크게 두어 무엇을 넣는 칸인지 분명히 합니다. */
@Composable
fun BigField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    hint: String? = null,
    numberOnly: Boolean = false,
    suffix: String? = null,
    isError: Boolean = false,
    errorText: String? = null
) {
    Column(modifier.fillMaxWidth()) {
        Text(
            label,
            style = MaterialTheme.typography.titleMedium,
            color = Ink
        )
        Spacer(Modifier.height(6.dp))
        OutlinedTextField(
            value = value,
            onValueChange = { new ->
                if (numberOnly) {
                    onValueChange(new.filter { it.isDigit() })
                } else {
                    onValueChange(new)
                }
            },
            singleLine = true,
            isError = isError,
            placeholder = hint?.let {
                { Text(it, style = MaterialTheme.typography.bodyLarge, color = InkFaint) }
            },
            suffix = suffix?.let {
                { Text(it, style = MaterialTheme.typography.bodyLarge, color = InkSoft) }
            },
            textStyle = MaterialTheme.typography.bodyLarge,
            keyboardOptions = KeyboardOptions(
                keyboardType = if (numberOnly) KeyboardType.Number else KeyboardType.Text
            ),
            shape = RoundedCornerShape(Dimens.Radius),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Accent,
                unfocusedBorderColor = Line,
                focusedContainerColor = CardBg,
                unfocusedContainerColor = CardBg
            ),
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = Dimens.FieldHeight)
        )
        if (isError && errorText != null) {
            Spacer(Modifier.height(4.dp))
            Text(errorText, style = MaterialTheme.typography.bodySmall, color = Alert)
        }
    }
}

/** 목록 한 줄 — 왼쪽 이름/설명, 오른쪽 숫자나 배지. */
@Composable
fun ListRow(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    trailing: String? = null,
    trailingColor: Color = Ink,
    badge: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null
) {
    val base = Modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Dimens.Radius))
        .background(CardBg)
        .border(1.dp, Line, RoundedCornerShape(Dimens.Radius))
        .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier)
        .padding(horizontal = 16.dp, vertical = 14.dp)

    Row(
        modifier.then(base).heightIn(min = Dimens.RowHeight),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold, color = Ink)
            if (subtitle != null) {
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = InkSoft)
            }
        }
        if (badge != null) {
            Spacer(Modifier.width(10.dp))
            badge()
        }
        if (trailing != null) {
            Spacer(Modifier.width(10.dp))
            Text(
                trailing,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Bold,
                color = trailingColor
            )
        }
    }
}

enum class PillKind { Good, Warn, Alert, Neutral }

/** 상태 배지 — 색과 글자를 함께 써서 색약이어도 구분됩니다. */
@Composable
fun StatusPill(text: String, kind: PillKind) {
    val (bg, fg) = when (kind) {
        PillKind.Good -> GoodBg to Good
        PillKind.Warn -> WarnBg to Warn
        PillKind.Alert -> AlertBg to Alert
        PillKind.Neutral -> SurfaceAlt to InkSoft
    }
    Box(
        Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(bg)
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(text, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = fg)
    }
}

/** 구역 제목 */
@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = MaterialTheme.typography.titleMedium,
        color = InkSoft,
        modifier = modifier.padding(top = Dimens.GapSmall)
    )
}

/** 내용이 없을 때 — 무엇을 해야 하는지 알려줍니다. */
@Composable
fun EmptyMessage(text: String, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Dimens.Radius))
            .background(CardBg)
            .border(1.dp, Line, RoundedCornerShape(Dimens.Radius))
            .padding(28.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text,
            style = MaterialTheme.typography.bodyLarge,
            color = InkSoft,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * 방금 한 일을 알려 주는 안내 띠.
 * 작은 토스트 대신 화면 안에 크게 띄우고, 몇 초 뒤 스스로 사라집니다.
 */
@Composable
fun MessageBanner(message: String?, onDismiss: () -> Unit) {
    if (message == null) return

    LaunchedEffect(message) {
        kotlinx.coroutines.delay(2500)
        onDismiss()
    }

    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Dimens.Radius))
            .background(AccentSoft)
            .border(Dimens.Border, Accent, RoundedCornerShape(Dimens.Radius))
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            message,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            color = AccentDark,
            modifier = Modifier.weight(1f)
        )
    }
}

/** 예/아니오 확인 — 글자를 크게 하고 버튼도 크게 둡니다. */
@Composable
fun ConfirmDialog(
    title: String,
    message: String,
    confirmText: String = "예",
    dismissText: String = "아니오",
    danger: Boolean = false,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title, style = MaterialTheme.typography.titleLarge) },
        text = { Text(message, style = MaterialTheme.typography.bodyLarge) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(
                    confirmText,
                    style = MaterialTheme.typography.labelLarge,
                    color = if (danger) Alert else Accent
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(dismissText, style = MaterialTheme.typography.labelLarge, color = InkSoft)
            }
        },
        containerColor = CardBg
    )
}
