package com.ilgam.jangbu.ui.screen

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.data.dao.ItemRow
import com.ilgam.jangbu.data.dao.WorkLogRow
import com.ilgam.jangbu.data.dao.WorkOrderRow
import com.ilgam.jangbu.data.entity.Client
import com.ilgam.jangbu.data.entity.Employee
import com.ilgam.jangbu.util.VoiceCandidate
import com.ilgam.jangbu.util.matchByName
import com.ilgam.jangbu.util.parseQtyFromSpeech
import com.ilgam.jangbu.util.removeMatched
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.LocalDate

private const val STOP = 5_000L

/** 일감 접수 — 거래처에서 물건이 들어왔을 때 */
class WorkOrderViewModel(private val repo: JangbuRepository) : ViewModel() {

    val clients: StateFlow<List<Client>> = repo.clients.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP), emptyList())

    val items: StateFlow<List<ItemRow>> = repo.items.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    private val _saved = MutableStateFlow(false)
    val saved: StateFlow<Boolean> = _saved

    fun save(
        clientName: String,
        itemName: String,
        qtyText: String,
        chargeText: String,
        wageText: String,
        unitLabel: String,
        dueInDays: Int?
    ) {
        val client = clientName.trim()
        val item = itemName.trim()
        val qty = qtyText.trim().toIntOrNull() ?: 0
        val charge = chargeText.trim().toLongOrNull() ?: 0L
        val wage = wageText.trim().toLongOrNull() ?: 0L

        when {
            client.isEmpty() -> { _message.value = "거래처를 골라 주세요"; return }
            item.isEmpty() -> { _message.value = "품목을 골라 주세요"; return }
            qty <= 0 -> { _message.value = "수량을 적어 주세요"; return }
            charge <= 0L -> { _message.value = "받을 단가를 적어 주세요"; return }
        }

        viewModelScope.launch {
            repo.receiveWorkOrder(
                clientName = client,
                itemName = item,
                targetQty = qty,
                chargeUnitPrice = charge,
                defaultWageUnitPrice = wage,
                unitLabel = unitLabel.trim().ifEmpty { "장" },
                dueDate = dueInDays?.let { LocalDate.now().plusDays(it.toLong()) }
            )
            _message.value = "$client $item ${qty}${unitLabel} 접수했습니다"
            _saved.value = true
        }
    }

    fun clearMessage() { _message.value = null }
    fun clearSaved() { _saved.value = false }
}

/** 직원 작업 등록 — 누가 무엇을 몇 장 했는지 */
class WorkLogViewModel(private val repo: JangbuRepository) : ViewModel() {

    val employees: StateFlow<List<Employee>> = repo.employees.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP), emptyList())

    /** 아직 끝나지 않은 일감만 고를 수 있게 합니다. */
    val orders: StateFlow<List<WorkOrderRow>> = repo.orders.observeInProgress()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP), emptyList())

    private val _employeeId = MutableStateFlow<Long?>(null)
    val employeeId: StateFlow<Long?> = _employeeId

    private val _orderId = MutableStateFlow<Long?>(null)
    val orderId: StateFlow<Long?> = _orderId

    private val _qty = MutableStateFlow("")
    val qty: StateFlow<String> = _qty

    /** 오늘이 기본, 어제 것도 넣을 수 있게 합니다. */
    private val _workDate = MutableStateFlow(LocalDate.now())
    val workDate: StateFlow<LocalDate> = _workDate

    /** 이 직원에게 이 품목의 적용 공임 */
    private val _wageUnitPrice = MutableStateFlow(0L)
    val wageUnitPrice: StateFlow<Long> = _wageUnitPrice

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    fun selectEmployee(id: Long) {
        _employeeId.value = id
        refreshWage()
    }

    fun selectOrder(id: Long) {
        _orderId.value = id
        refreshWage()
    }

    fun setQty(value: String) { _qty.value = value.filter { it.isDigit() } }

    fun setWorkDate(date: LocalDate) { _workDate.value = date }

    /** 말로 넣은 내용을 화면 상태로 옮깁니다. 저장은 사람이 눈으로 보고 누르게 둡니다. */
    private val _heard = MutableStateFlow<String?>(null)
    val heard: StateFlow<String?> = _heard

    fun applyVoice(spoken: String) {
        _heard.value = spoken

        val employeeMatch = matchByName(
            spoken,
            employees.value.map { VoiceCandidate(it.id, listOf(it.name)) }
        )
        // 일감은 거래처와 품목 어느 쪽으로 불러도 찾히게 합니다.
        val orderMatch = matchByName(
            spoken,
            orders.value.map {
                VoiceCandidate(it.id, listOf(it.itemName, it.clientName, "${it.clientName} ${it.itemName}"))
            }
        )

        employeeMatch?.let { (id, _) -> selectEmployee(id) }
        orderMatch?.let { (id, _) -> selectOrder(id) }

        // 이름 글자를 숫자로 잘못 읽지 않도록, 알아들은 이름을 걷어낸 뒤 수량을 읽습니다.
        val rest = removeMatched(spoken, employeeMatch?.second, orderMatch?.second)
        val amount = parseQtyFromSpeech(rest)
        if (amount != null && amount > 0) _qty.value = amount.toString()

        val empName = employeeMatch?.let { m -> employees.value.firstOrNull { it.id == m.first }?.name }
        val order = orderMatch?.let { m -> orders.value.firstOrNull { it.id == m.first } }

        _message.value = when {
            empName == null && order == null ->
                "‘$spoken’ 은 알아듣지 못했습니다. 직접 골라 주세요"
            empName == null -> "직원을 알아듣지 못했습니다. 직원만 골라 주세요"
            order == null -> "일감을 알아듣지 못했습니다. 일감만 골라 주세요"
            amount == null || amount <= 0 -> "$empName · ${order.itemName} — 수량을 알아듣지 못했습니다"
            else -> "$empName · ${order.itemName} ${amount}${order.unitLabel} — 맞으면 저장을 누르세요"
        }
    }

    fun clearHeard() { _heard.value = null }

    private fun refreshWage() {
        val emp = _employeeId.value
        val ord = _orderId.value ?: return
        if (emp == null) return
        val itemId = orders.value.firstOrNull { it.id == ord }?.itemId ?: return
        viewModelScope.launch {
            _wageUnitPrice.value = repo.previewWage(emp, itemId)
        }
    }

    fun save() {
        val emp = _employeeId.value
        val ord = _orderId.value
        val amount = _qty.value.toIntOrNull() ?: 0

        when {
            emp == null -> { _message.value = "직원을 골라 주세요"; return }
            ord == null -> { _message.value = "일감을 골라 주세요"; return }
            amount <= 0 -> { _message.value = "수량을 적어 주세요"; return }
        }

        val row = orders.value.firstOrNull { it.id == ord }
        // 남은 수량보다 많이 넣으면 알려만 주고 저장은 허용합니다(현장에서 초과 처리가 있을 수 있음).
        val over = row != null && amount > row.remainQty

        viewModelScope.launch {
            repo.addWorkLog(
                workOrderId = ord!!,
                employeeId = emp!!,
                qty = amount,
                workDate = _workDate.value
            )
            val name = employees.value.firstOrNull { it.id == emp }?.name ?: "직원"
            val unit = row?.unitLabel ?: "장"
            _message.value = if (over) {
                "$name ${amount}$unit 저장했습니다 (남은 수량보다 많습니다)"
            } else {
                "$name ${amount}$unit 저장했습니다"
            }
            // 같은 직원으로 이어서 넣는 경우가 많아 직원 선택은 남겨 둡니다.
            _qty.value = ""
        }
    }

    fun clearMessage() { _message.value = null }
}

/** 진행 현황 — 대상 수량 대비 처리 수량 */
class ProgressViewModel(private val repo: JangbuRepository) : ViewModel() {

    val orders: StateFlow<List<WorkOrderRow>> = repo.orders.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP), emptyList())

    private val _openOrderId = MutableStateFlow<Long?>(null)
    val openOrderId: StateFlow<Long?> = _openOrderId

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    val openOrderLogs: StateFlow<List<WorkLogRow>> = _openOrderId
        .flatMapLatest { id ->
            if (id == null) flowOf(emptyList()) else repo.logs.observeByOrder(id)
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    fun toggleOrder(id: Long) {
        _openOrderId.value = if (_openOrderId.value == id) null else id
    }

    /** 잘못 넣은 작업 지우기 (정산 전에만 가능) */
    fun deleteLog(logId: Long, workOrderId: Long) {
        viewModelScope.launch {
            val ok = repo.deleteWorkLog(logId, workOrderId)
            _message.value =
                if (ok) "지웠습니다" else "이미 정산된 작업이라 지울 수 없습니다"
        }
    }

    fun clearMessage() { _message.value = null }
}
