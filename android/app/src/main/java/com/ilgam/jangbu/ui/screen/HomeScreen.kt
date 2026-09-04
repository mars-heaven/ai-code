package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository
import com.ilgam.jangbu.util.toShortDisplay
import com.ilgam.jangbu.util.toDbInt
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
}

@Composable
fun HomeScreen(
    onClients: () -> Unit,
    onItems: () -> Unit,
    onEmployees: () -> Unit
) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { HomeViewModel(repo) }

    val todayQty by vm.todayQty.collectAsState()
    val remainQty by vm.remainQty.collectAsState()
    val clientCount by vm.clientCount.collectAsState()
    val itemCount by vm.itemCount.collectAsState()
    val employeeCount by vm.employeeCount.collectAsState()

    var showComingSoon by remember { mutableStateOf<String?>(null) }

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
            onClick = { showComingSoon = "작업 등록" },
            kind = BigButtonKind.Primary,
            big = true
        )

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            BigButton("일감 접수", { showComingSoon = "일감 접수" }, Modifier.weight(1f))
            BigButton("진행 현황", { showComingSoon = "진행 현황" }, Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            BigButton("급여 정산", { showComingSoon = "급여 정산" }, Modifier.weight(1f))
            BigButton("거래처 정산", { showComingSoon = "거래처 정산" }, Modifier.weight(1f))
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

        Spacer(Modifier.height(8.dp))
    }

    val soon = showComingSoon
    if (soon != null) {
        ConfirmDialog(
            title = "아직 준비 중입니다",
            message = "‘$soon’ 기능은 다음 단계에서 만들어집니다.\n지금은 거래처·품목·직원을 먼저 등록해 주세요.",
            confirmText = "알겠습니다",
            dismissText = "닫기",
            onConfirm = { showComingSoon = null },
            onDismiss = { showComingSoon = null }
        )
    }
}
