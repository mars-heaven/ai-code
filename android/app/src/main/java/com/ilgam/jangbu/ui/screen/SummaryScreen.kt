package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.data.dao.MonthTotals
import com.ilgam.jangbu.data.dao.SummaryLineRow
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*

/**
 * 기간 요약 — 그동안 얼마나 일하고 얼마가 남았는지.
 * 달이 기본이지만 15일 마감처럼 달과 안 맞는 경우를 위해 날짜도 고를 수 있습니다.
 * 마감 여부와 상관없이 '일한 날짜' 를 기준으로 셉니다.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class SummaryViewModel(private val repo: JangbuRepository) : ViewModel() {

    private val _period = MutableStateFlow(monthPeriod())
    val period: StateFlow<Period> = _period

    private val range: Flow<Pair<Int, Int>> = _period.map { p ->
        p.from.toDbInt() to p.to.toDbInt()
    }

    val totals: StateFlow<MonthTotals> = range
        .flatMapLatest { (f, t) -> repo.summary.observeTotals(f, t) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), MonthTotals(0, 0, 0))

    val byClient: StateFlow<List<SummaryLineRow>> = range
        .flatMapLatest { (f, t) -> repo.summary.observeByClient(f, t) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val byEmployee: StateFlow<List<SummaryLineRow>> = range
        .flatMapLatest { (f, t) -> repo.summary.observeByEmployee(f, t) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val byItem: StateFlow<List<SummaryLineRow>> = range
        .flatMapLatest { (f, t) -> repo.summary.observeByItem(f, t) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun setPeriod(period: Period) { _period.value = period }
}

@Composable
fun SummaryScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val repo = rememberRepository()
    val vm = jangbuViewModel { SummaryViewModel(repo) }

    val period by vm.period.collectAsState()
    val totals by vm.totals.collectAsState()
    val byClient by vm.byClient.collectAsState()
    val byEmployee by vm.byEmployee.collectAsState()
    val byItem by vm.byItem.collectAsState()

    val label = period.displayRange()
    val profit = totals.revenue - totals.wage

    JangbuScreen(
        title = "기간 요약",
        subtitle = period.rangeText(),
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "요약 보내기",
                sub = "카카오톡 · 문자로 보냅니다",
                onClick = {
                    shareText(
                        context,
                        "$label 요약",
                        monthSummaryText(label, totals, byClient, byEmployee)
                    )
                },
                enabled = totals.qty > 0
            )
        }
    ) {
        // 기간 고르기 — 주·달로 넘기거나 날짜를 직접 고릅니다.
        PeriodPicker(period = period, onChange = vm::setPeriod)

        if (totals.qty == 0) {
            EmptyMessage("이 기간에는 기록이 없습니다.")
            Spacer(Modifier.height(8.dp))
            return@JangbuScreen
        }

        // 큰 숫자 넷 — 이 화면에서 가장 먼저 보여야 하는 것
        SummaryBox("처리 수량", totals.qty.withUnit("장"), Accent, AccentSoft)
        SummaryBox("받을 돈", totals.revenue.toMoneyWon(), Good, GoodBg)
        SummaryBox("줄 공임", totals.wage.toMoneyWon(), Warn, WarnBg)
        SummaryBox(
            "남는 돈",
            profit.toMoneyWon(),
            if (profit >= 0) AccentDark else Alert,
            if (profit >= 0) AccentSoft else AlertBg,
            big = true
        )

        SummaryList("거래처별 받을 돈", byClient) { it.amount.toMoneyWon() }
        SummaryList("직원별 공임", byEmployee) { it.amount.toMoneyWon() }
        SummaryList("품목별 처리 수량", byItem) { it.qty.withUnit("장") }

        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun SummaryBox(
    label: String,
    value: String,
    fg: Color,
    bg: Color,
    big: Boolean = false
) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Dimens.Radius))
            .background(bg)
            .border(Dimens.Border, fg, RoundedCornerShape(Dimens.Radius))
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, style = MaterialTheme.typography.titleMedium, color = fg)
        Text(
            value,
            style = if (big) MaterialTheme.typography.headlineLarge
                    else MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = fg
        )
    }
}

@Composable
private fun SummaryList(
    title: String,
    rows: List<SummaryLineRow>,
    trailing: (SummaryLineRow) -> String
) {
    if (rows.isEmpty()) return
    SectionTitle(title)
    rows.forEach { row ->
        ListRow(
            title = row.name,
            subtitle = row.qty.withUnit("장"),
            trailing = trailing(row)
        )
    }
}
