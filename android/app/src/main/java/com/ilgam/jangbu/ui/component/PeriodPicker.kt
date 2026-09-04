package com.ilgam.jangbu.ui.component

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.ui.theme.Accent
import com.ilgam.jangbu.ui.theme.CardBg
import com.ilgam.jangbu.ui.theme.Dimens
import com.ilgam.jangbu.ui.theme.InkSoft
import com.ilgam.jangbu.util.*
import java.time.LocalDate
import java.time.YearMonth

/**
 * 기간 고르기.
 * 달로 끊는 것이 가장 흔하니 달 넘기기를 먼저 두고,
 * 15일 마감처럼 달과 안 맞는 경우를 위해 날짜를 직접 고르는 길도 둡니다.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PeriodPicker(
    period: Period,
    onChange: (Period) -> Unit,
    /** 정산 화면에서는 '전체'(정산 안 된 것 모두)가 쓸모 있고, 요약 화면에서는 아닙니다. */
    showAll: Boolean = true
) {
    // 어느 쪽 날짜를 고르는 중인지 (null 이면 창이 닫힌 상태)
    var picking by remember { mutableStateOf<PickTarget?>(null) }

    val thisMonth = YearMonth.now()
    val onMonth = period.kind == PeriodKind.MONTH

    Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
        BigButton(
            text = "◀ 이전 달",
            onClick = { onChange(monthPeriod(period.month.minusMonths(1))) },
            modifier = Modifier.weight(1f)
        )
        BigButton(
            text = "다음 달 ▶",
            onClick = { onChange(monthPeriod(period.month.plusMonths(1))) },
            modifier = Modifier.weight(1f),
            // 아직 오지 않은 달은 볼 것이 없습니다.
            enabled = period.month < thisMonth
        )
    }

    Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
        BigButton(
            text = "이번 달",
            onClick = { onChange(monthPeriod(thisMonth)) },
            modifier = Modifier.weight(1f),
            selected = onMonth && period.month == thisMonth
        )
        if (showAll) {
            BigButton(
                text = "전체",
                onClick = { onChange(allPeriod()) },
                modifier = Modifier.weight(1f),
                selected = period.kind == PeriodKind.ALL
            )
        }
        BigButton(
            text = "날짜 고르기",
            onClick = {
                // 처음 누르면 지금 보고 있는 기간을 그대로 가져와 시작 날짜부터 고릅니다.
                if (period.kind != PeriodKind.CUSTOM) {
                    onChange(customPeriod(period.from, period.to))
                }
                picking = PickTarget.START
            },
            modifier = Modifier.weight(1f),
            selected = period.kind == PeriodKind.CUSTOM
        )
    }

    if (period.kind == PeriodKind.CUSTOM) {
        Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
            BigButton(
                text = "시작 ${period.from.toDisplay()}",
                onClick = { picking = PickTarget.START },
                modifier = Modifier.weight(1f)
            )
            BigButton(
                text = "끝 ${period.to.toDisplay()}",
                onClick = { picking = PickTarget.END },
                modifier = Modifier.weight(1f)
            )
        }
    }

    val target = picking
    if (target != null) {
        val initial = if (target == PickTarget.START) period.from else period.to
        val state = rememberDatePickerState(initialSelectedDateMillis = initial.toUtcMillis())

        DatePickerDialog(
            onDismissRequest = { picking = null },
            colors = androidx.compose.material3.DatePickerDefaults.colors(
                containerColor = CardBg
            ),
            confirmButton = {
                TextButton(onClick = {
                    val picked = state.selectedDateMillis?.utcMillisToLocalDate()
                    if (picked != null) {
                        val next = if (target == PickTarget.START) {
                            customPeriod(picked, period.to)
                        } else {
                            customPeriod(period.from, picked)
                        }
                        onChange(next)
                        // 시작을 고르면 이어서 끝 날짜를 묻습니다.
                        picking = if (target == PickTarget.START) PickTarget.END else null
                    } else {
                        picking = null
                    }
                }) {
                    Text(
                        if (target == PickTarget.START) "다음 (끝 날짜)" else "이 날짜로",
                        style = MaterialTheme.typography.labelLarge,
                        color = Accent
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { picking = null }) {
                    Text("그만두기", style = MaterialTheme.typography.labelLarge, color = InkSoft)
                }
            }
        ) {
            Text(
                if (target == PickTarget.START) "시작 날짜를 고르세요" else "끝 날짜를 고르세요",
                style = MaterialTheme.typography.titleMedium,
                color = InkSoft,
                modifier = Modifier.padding(start = 24.dp, top = 16.dp)
            )
            DatePicker(state = state, title = null)
        }
    }
}

private enum class PickTarget { START, END }
