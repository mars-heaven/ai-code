package com.ilgam.jangbu.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.ui.theme.Accent
import com.ilgam.jangbu.ui.theme.CardBg
import com.ilgam.jangbu.ui.theme.Dimens
import com.ilgam.jangbu.ui.theme.InkSoft
import com.ilgam.jangbu.ui.theme.Warn
import com.ilgam.jangbu.ui.theme.WarnBg
import com.ilgam.jangbu.util.*

/**
 * 기간 고르기.
 *
 * 주 단위로 마감하는 일이 가장 많아 '이번 주' 를 먼저 두었습니다.
 * 이전·다음 버튼은 지금 보고 있는 것이 주면 한 주씩, 달이면 한 달씩 움직입니다.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PeriodPicker(
    period: Period,
    onChange: (Period) -> Unit
) {
    // 어느 쪽 날짜를 고르는 중인지 (null 이면 창이 닫힌 상태)
    var picking by remember { mutableStateOf<PickTarget?>(null) }

    val stepLabel = when (period.kind) {
        PeriodKind.WEEK -> "주"
        PeriodKind.MONTH -> "달"
        else -> "기간"
    }

    Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
        BigButton(
            text = "◀ 이전 $stepLabel",
            onClick = { onChange(period.prev()) },
            modifier = Modifier.weight(1f),
            enabled = period.kind != PeriodKind.ALL
        )
        BigButton(
            text = "다음 $stepLabel ▶",
            onClick = { onChange(period.next()) },
            modifier = Modifier.weight(1f),
            enabled = period.canGoNext()
        )
    }

    Row(horizontalArrangement = Arrangement.spacedBy(Dimens.Gap)) {
        BigButton(
            text = "이번 주",
            onClick = { onChange(weekPeriod()) },
            modifier = Modifier.weight(1f),
            selected = period.kind == PeriodKind.WEEK && period == weekPeriod()
        )
        BigButton(
            text = "이번 달",
            onClick = { onChange(monthPeriod()) },
            modifier = Modifier.weight(1f),
            selected = period.kind == PeriodKind.MONTH && period == monthPeriod()
        )
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
            colors = DatePickerDefaults.colors(containerColor = CardBg),
            confirmButton = {
                TextButton(onClick = {
                    val picked = state.selectedDateMillis?.utcMillisToLocalDate()
                    if (picked != null) {
                        onChange(
                            if (target == PickTarget.START) customPeriod(picked, period.to)
                            else customPeriod(period.from, picked)
                        )
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

/**
 * 고른 기간 밖에 아직 정산 안 된 것이 남아 있을 때의 알림.
 * 주 단위로만 보다 보면 지난 주에 빠뜨린 것이 영영 묻힐 수 있어 눈에 띄게 알려 줍니다.
 */
@Composable
fun LeftoverNotice(
    text: String,
    onShowAll: () -> Unit
) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Dimens.Radius))
            .background(WarnBg)
            .border(Dimens.Border, Warn, RoundedCornerShape(Dimens.Radius))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text(text, style = MaterialTheme.typography.bodyLarge, color = Warn)
        BigButton(text = "빠진 것까지 전부 보기", onClick = onShowAll)
    }
}

private enum class PickTarget { START, END }
