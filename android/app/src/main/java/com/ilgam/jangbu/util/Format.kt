package com.ilgam.jangbu.util

import java.text.NumberFormat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

private val numberFormat: NumberFormat = NumberFormat.getIntegerInstance(Locale.KOREA)

/** 1293000 -> "1,293,000" */
fun Long.toMoney(): String = numberFormat.format(this)

/** 1293000 -> "1,293,000원" */
fun Long.toMoneyWon(): String = "${numberFormat.format(this)}원"

/** 620 -> "620장" 처럼 단위를 붙입니다. */
fun Int.withUnit(unit: String): String = "${numberFormat.format(this)}$unit"

private val dateFmt = DateTimeFormatter.ofPattern("yyyy.MM.dd")
private val dateShortFmt = DateTimeFormatter.ofPattern("M월 d일")

fun LocalDate.toDisplay(): String = format(dateFmt)
fun LocalDate.toShortDisplay(): String = format(dateShortFmt)

/** 저장용 정수 날짜(20261021) <-> LocalDate */
fun LocalDate.toDbInt(): Int = year * 10000 + monthValue * 100 + dayOfMonth

fun Int.toLocalDate(): LocalDate =
    LocalDate.of(this / 10000, (this / 100) % 100, this % 100)
