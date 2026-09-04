package com.ilgam.jangbu.util

import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneOffset

/**
 * 정산 기간.
 *
 * 달로 끊는 경우가 가장 많지만 늘 그렇지는 않아서(15일 마감, 주 단위 등)
 * 달을 앞뒤로 넘기는 방법과 날짜를 직접 고르는 방법을 둘 다 둡니다.
 */
enum class PeriodKind { MONTH, ALL, CUSTOM }

data class Period(
    val kind: PeriodKind,
    /** MONTH 일 때 보고 있는 달. 다른 경우에는 앞뒤로 넘길 때의 기준으로만 씁니다. */
    val month: YearMonth,
    val from: LocalDate,
    val to: LocalDate
)

/** 한 달 전체 */
fun monthPeriod(month: YearMonth = YearMonth.now()): Period =
    Period(PeriodKind.MONTH, month, month.atDay(1), month.atEndOfMonth())

/** 기간을 따지지 않고 아직 정산 안 된 것 전부 */
fun allPeriod(today: LocalDate = LocalDate.now()): Period =
    Period(PeriodKind.ALL, YearMonth.from(today), LocalDate.of(2000, 1, 1), today)

/** 날짜를 직접 고른 기간. 거꾸로 고르면 바로잡아 줍니다. */
fun customPeriod(from: LocalDate, to: LocalDate): Period {
    val start = minOf(from, to)
    val end = maxOf(from, to)
    return Period(PeriodKind.CUSTOM, YearMonth.from(start), start, end)
}

fun Period.displayRange(): String = when (kind) {
    PeriodKind.ALL -> "지금까지 정산 안 된 전부"
    PeriodKind.MONTH -> "${month.year}년 ${month.monthValue}월"
    PeriodKind.CUSTOM -> "${from.toDisplay()} ~ ${to.toDisplay()}"
}

/** 정산서에 적을 기간 문구 (전체일 때도 실제 날짜를 적습니다) */
fun Period.rangeText(): String = "${from.toDisplay()} ~ ${to.toDisplay()}"

// 날짜 고르기 창은 시간대 없는 UTC 밀리초를 씁니다.
fun Long.utcMillisToLocalDate(): LocalDate =
    Instant.ofEpochMilli(this).atZone(ZoneOffset.UTC).toLocalDate()

fun LocalDate.toUtcMillis(): Long =
    atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
