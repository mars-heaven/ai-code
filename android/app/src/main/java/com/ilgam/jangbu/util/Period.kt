package com.ilgam.jangbu.util

import java.time.LocalDate

/**
 * 정산 기간.
 * 달력에서 날짜를 짚는 대신 버튼 몇 개로 고르게 합니다.
 */
enum class PeriodKind { THIS_MONTH, LAST_MONTH, ALL }

data class Period(
    val kind: PeriodKind,
    val from: LocalDate,
    val to: LocalDate,
    val label: String
)

fun periodOf(kind: PeriodKind, today: LocalDate = LocalDate.now()): Period = when (kind) {
    PeriodKind.THIS_MONTH -> {
        val start = today.withDayOfMonth(1)
        Period(kind, start, today.withDayOfMonth(today.lengthOfMonth()), "${today.monthValue}월")
    }
    PeriodKind.LAST_MONTH -> {
        val last = today.minusMonths(1)
        val start = last.withDayOfMonth(1)
        Period(kind, start, last.withDayOfMonth(last.lengthOfMonth()), "${last.monthValue}월")
    }
    // 아직 정산 안 된 것을 기간 상관없이 모두 봅니다.
    PeriodKind.ALL -> Period(kind, LocalDate.of(2000, 1, 1), today, "전체")
}

fun Period.displayRange(): String =
    if (kind == PeriodKind.ALL) "지금까지 정산 안 된 전부"
    else "${from.toDisplay()} ~ ${to.toDisplay()}"
