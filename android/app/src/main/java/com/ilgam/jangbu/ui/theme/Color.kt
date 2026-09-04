package com.ilgam.jangbu.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * 어르신 사용을 전제로 한 고대비 팔레트.
 * 상태는 색만으로 구분하지 않고 항상 글자를 함께 둡니다(색약 대응).
 */
val Ink = Color(0xFF13243A)        // 본문 글자
val InkSoft = Color(0xFF4E5E72)    // 보조 설명
val InkFaint = Color(0xFF7C8A9B)   // 흐린 안내

val Paper = Color(0xFFF4F6F8)      // 화면 바탕
val CardBg = Color(0xFFFFFFFF)    // 카드/입력창
val SurfaceAlt = Color(0xFFEDF1F5) // 눌리는 버튼 바탕
val Line = Color(0xFFD2DAE3)       // 테두리

val Accent = Color(0xFF1F5FA8)     // 주요 동작
val AccentDark = Color(0xFF17497F)
val AccentSoft = Color(0xFFE3EDF8)

// 상태색 — 완료 / 진행 / 주의
val Good = Color(0xFF1F6741)
val GoodBg = Color(0xFFE0F0E7)
val Warn = Color(0xFF8F6210)
val WarnBg = Color(0xFFFAEDD5)
val Alert = Color(0xFFA53826)
val AlertBg = Color(0xFFF8E2DE)

val OnAccent = Color(0xFFFFFFFF)
