package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.util.Prefs
import com.ilgam.jangbu.util.backupIsStale
import com.ilgam.jangbu.util.toBackupDisplay
import com.ilgam.jangbu.util.toDbInt
import com.ilgam.jangbu.util.toMoneyWon
import com.ilgam.jangbu.util.toShortDisplay
import com.ilgam.jangbu.util.withUnit
import kotlinx.coroutines.flow.*
import java.time.LocalDate

class HomeViewModel(repo: JangbuRepository) : ViewModel() {

    private val today = LocalDate.now().toDbInt()

    val clientCount = repo.clients.observeAll()
        .map { it.size }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    val itemCount = repo.items.observeAll()
        .map { it.size }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    val employeeCount = repo.employees.observeAll()
        .map { it.size }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    /** 오늘 직원들이 처리한 수량 합계 */
    val todayQty = repo.logs.observeQtySum(today, today)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    /** 아직 끝나지 않은 일감의 남은 수량 */
    val remainQty = repo.orders.observeInProgress()
        .map { list -> list.sumOf { it.remainQty } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    /** 기간과 상관없이 아직 마감하지 않은 공임 전부 */
    val unpaidWage = repo.payrolls.observeUnpaidWages(ALL_FROM, ALL_TO)
        .map { list -> list.sumOf { it.totalWage } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0L)

    /** 계산서는 냈는데 아직 못 받은 돈 */
    val receivable = repo.invoices.observeUnpaid()
        .map { list -> list.sumOf { it.totalAmount } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0L)

    private companion object {
        const val ALL_FROM = 20000101
        const val ALL_TO = 99991231
    }
}

@Composable
fun HomeScreen(
    onWorkLog: () -> Unit,
    onWorkOrder: () -> Unit,
    onProgress: () -> Unit,
    onClients: () -> Unit,
    onItems: () -> Unit,
    onEmployees: () -> Unit,
    onPayroll: () -> Unit,
    onInvoice: () -> Unit,
    onBackup: () -> Unit
) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { HomeViewModel(repo) }

    // 화면에 들어올 때마다 마지막 백업 시각을 다시 읽습니다.
    val context = LocalContext.current
    val lastBackupAt = remember { Prefs(context).lastBackupAt }

    val todayQty by vm.todayQty.collectAsState()
    val remainQty by vm.remainQty.collectAsState()
    val clientCount by vm.clientCount.collectAsState()
    val itemCount by vm.itemCount.collectAsState()
    val employeeCount by vm.employeeCount.collectAsState()
    val unpaidWage by vm.unpaidWage.collectAsState()
    val receivable by vm.receivable.collectAsState()

    JangbuScreen(
        title = "일감장부",
        subtitle = LocalDate.now().toShortDisplay()
    ) {
        // 오늘 숫자 — 가장 먼저 눈에 들어와야 하는 두 가지
        ListRow(
            title = "오늘 처리",
            subtitle = "직원들이 오늘 끝낸 수량",
            trailing = todayQty.withUnit("장")
        )
        ListRow(
            title = "남은 일감",
            subtitle = "아직 끝나지 않은 수량",
            trailing = remainQty.withUnit("장"),
            trailingColor = com.ilgam.jangbu.ui.theme.Alert
        )

        Spacer(Modifier.height(4.dp))

        BigButton(
            text = "작업 등록",
            sub = "누가 · 무엇을 · 몇 장",
            onClick = onWorkLog,
            kind = BigButtonKind.Primary,
            big = true
        )

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            BigButton("일감 접수", onWorkOrder, Modifier.weight(1f))
            BigButton("진행 현황", onProgress, Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            BigButton(
                text = "급여 정산",
                sub = if (unpaidWage > 0L) "줄 돈 ${unpaidWage.toMoneyWon()}" else "정산할 공임 없음",
                onClick = onPayroll,
                modifier = Modifier.weight(1f)
            )
            BigButton(
                text = "거래처 정산",
                sub = if (receivable > 0L) "받을 돈 ${receivable.toMoneyWon()}" else "받을 돈 없음",
                onClick = onInvoice,
                modifier = Modifier.weight(1f)
            )
        }

        SectionTitle("기초 등록")

        BigButton(
            text = "거래처",
            sub = if (clientCount == 0) "먼저 등록해 주세요" else "${clientCount}곳",
            onClick = onClients
        )
        BigButton(
            text = "품목과 단가",
            sub = if (itemCount == 0) "받을 단가와 공임을 정합니다" else "${itemCount}개",
            onClick = onItems
        )
        BigButton(
            text = "직원",
            sub = if (employeeCount == 0) "먼저 등록해 주세요" else "${employeeCount}명",
            onClick = onEmployees
        )

        SectionTitle("자료 지키기")

        BigButton(
            text = "백업과 복원",
            sub = lastBackupAt.toBackupDisplay(),
            onClick = onBackup,
            // 오래 미뤄 두면 눈에 띄게 해서 잊지 않도록 합니다.
            kind = if (lastBackupAt.backupIsStale()) BigButtonKind.Danger
                   else BigButtonKind.Normal
        )

        Spacer(Modifier.height(8.dp))
    }
}
