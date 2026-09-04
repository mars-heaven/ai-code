package com.ilgam.jangbu.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

/**
 * 어두운 화면은 어르신 가독성에 불리해 밝은 화면 하나로 고정합니다.
 * (기기가 다크 모드여도 앱은 항상 같은 밝은 화면으로 보입니다.)
 */
private val JangbuColors = lightColorScheme(
    primary = Accent,
    onPrimary = OnAccent,
    primaryContainer = AccentSoft,
    onPrimaryContainer = AccentDark,

    secondary = InkSoft,
    onSecondary = OnAccent,

    background = Paper,
    onBackground = Ink,

    surface = CardBg,
    onSurface = Ink,
    surfaceVariant = SurfaceAlt,
    onSurfaceVariant = InkSoft,

    error = Alert,
    onError = OnAccent,
    errorContainer = AlertBg,
    onErrorContainer = Alert,

    outline = Line,
    outlineVariant = Line
)

@Composable
fun JangbuTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = JangbuColors,
        typography = JangbuTypography,
        content = content
    )
}
