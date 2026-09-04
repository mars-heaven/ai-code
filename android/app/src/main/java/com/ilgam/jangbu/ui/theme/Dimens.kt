package com.ilgam.jangbu.ui.theme

import androidx.compose.ui.unit.dp

/**
 * 손이 떨려도 빗나가지 않도록 터치 영역을 크게 잡습니다.
 * 안드로이드 접근성 최소 권장(48dp)보다 훨씬 크게 둡니다.
 */
object Dimens {
    val ButtonHeight = 72.dp        // 일반 버튼
    val ButtonHeightBig = 92.dp     // 홈 화면 주요 버튼
    val FieldHeight = 68.dp         // 입력창
    val RowHeight = 64.dp           // 목록 한 줄

    val ScreenPadding = 16.dp
    val Gap = 12.dp
    val GapSmall = 8.dp
    val GapLarge = 20.dp

    val Radius = 14.dp
    val Border = 2.dp
}
