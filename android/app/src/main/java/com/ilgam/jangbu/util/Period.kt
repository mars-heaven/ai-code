package com.ilgam.jangbu.util

import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneOffset
import java.time.temporal.ChronoUnit
import java.time.temporal.TemporalAdjusters

/**
 * 정산 기간.
 *
 * 주 단위로 마감하는 경우가 가장 많고 달로 끊기도 해서 둘 다 한 번에 고를 수 있게 하고,
 * 그 어느 쪽도 아닌 마감(예: 15일)을 위해 날짜를 직접 고르는 길을 둡니다.
 */
enum class PeriodKind { WEEK, MONTH, ALL, CUSTOM }

data class Period(
    val kind: PeriodKind,
    val from: LocalDate,
    val to: LocalDate
)

/** 월요일부터 일요일까지 한 주 */
fun weekPeriod(day: LocalDate = LocalDate.now()): Period {
    val monday = day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
    return Period(PeriodKind.WEEK, monday, monday.plusDays(6))
}

/** 한 달 전체 */
fun monthPeriod(month: YearMonth = YearMonth.now()): Period =
    Period(PeriodKind.MONTH, month.atDay(1), month.atEndOfMonth())

/** 기간을 따지지 않고 아직 정산 안 된 것 전부 */
fun allPeriod(today: LocalDate = LocalDate.now()): Period =
    Period(PeriodKind.ALL, LocalDate.of(2000, 1, 1), today)

/** 날짜를 직접 고른 기간. 거꾸로 고르면 바로잡아 줍니다. */
fun customPeriod(from: LocalDate, to: LocalDate): Period =
    Period(PeriodKind.CUSTOM, minOf(from, to), maxOf(from, to))

/**
 * 한 칸 앞으로. 주면 한 주, 달이면 한 달,
 * 직접 고른 기간이면 그 기간 길이만큼 통째로 옮깁니다.
 */
fun Period.prev(): Period = shift(-1)

fun Period.next(): Period = shift(1)

private fun Period.shift(steps: Long): Period = when (kind) {
    PeriodKind.WEEK -> weekPeriod(from.plusWeeks(steps))
    PeriodKind.MONTH -> monthPeriod(YearMonth.from(from).plusMonths(steps))
    PeriodKind.CUSTOM -> {
        val days = ChronoUnit.DAYS.between(from, to) + 1
        customPeriod(from.plusDays(days * steps), to.plusDays(days * steps))
    }
    // 전체는 앞뒤가 없습니다.
    PeriodKind.ALL -> this
}

/** 아직 오지 않은 기간은 볼 것이 없습니다. */
fun Period.canGoNext(today: LocalDate = LocalDate.now()): Boolean =
    kind != PeriodKind.ALL && to.isBefore(today)

fun Period.displayRange(): String = when (kind) {
    PeriodKind.ALL -> "지금까지 정산 안 된 전부"
    PeriodKind.MONTH -> "${from.year}년 ${from.monthValue}월"
    else -> "${from.toShortDisplay()} ~ ${to.toShortDisplay()}"
}

/** 정산서에 적을 기간 문구 (전체일 때도 실제 날짜를 적습니다) */
fun Period.rangeText(): String = "${from.toDisplay()} ~ ${to.toDisplay()}"

// 날짜 고르기 창은 시간대 없는 UTC 밀리초를 씁니다.
fun Long.utcMillisToLocalDate(): LocalDate =
    Instant.ofEpochMilli(this).atZone(ZoneOffset.UTC).toLocalDate()

fun LocalDate.toUtcMillis(): Long =
    atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
