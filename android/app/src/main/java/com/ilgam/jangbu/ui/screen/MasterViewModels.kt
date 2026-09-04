package com.ilgam.jangbu.ui.screen

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.data.dao.EmployeeRateRow
import com.ilgam.jangbu.data.dao.ItemRow
import com.ilgam.jangbu.data.entity.Client
import com.ilgam.jangbu.data.entity.Employee
import com.ilgam.jangbu.data.entity.Item
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

private const val STOP_TIMEOUT = 5_000L

class ClientViewModel(private val repo: JangbuRepository) : ViewModel() {

    val clients: StateFlow<List<Client>> = repo.clients.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    fun save(id: Long, name: String, phone: String, memo: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) {
            _message.value = "거래처 이름을 적어 주세요"
            return
        }
        viewModelScope.launch {
            val duplicate = repo.clients.findByName(trimmed)
            if (duplicate != null && duplicate.id != id) {
                _message.value = "이미 있는 거래처입니다"
                return@launch
            }
            if (id == 0L) {
                repo.clients.insert(Client(name = trimmed, phone = phone.trim(), memo = memo.trim()))
                _message.value = "$trimmed 등록했습니다"
            } else {
                val current = repo.clients.getById(id) ?: return@launch
                repo.clients.update(current.copy(name = trimmed, phone = phone.trim(), memo = memo.trim()))
                _message.value = "$trimmed 수정했습니다"
            }
        }
    }

    fun remove(client: Client) {
        viewModelScope.launch {
            repo.clients.deactivate(client.id)
            _message.value = "${client.name} 목록에서 뺐습니다"
        }
    }

    fun clearMessage() { _message.value = null }
}

class EmployeeViewModel(private val repo: JangbuRepository) : ViewModel() {

    val employees: StateFlow<List<Employee>> = repo.employees.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    fun save(id: Long, name: String, phone: String, memo: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) {
            _message.value = "직원 이름을 적어 주세요"
            return
        }
        viewModelScope.launch {
            val duplicate = repo.employees.findByName(trimmed)
            if (duplicate != null && duplicate.id != id) {
                _message.value = "이미 있는 직원입니다"
                return@launch
            }
            if (id == 0L) {
                repo.employees.insert(Employee(name = trimmed, phone = phone.trim(), memo = memo.trim()))
                _message.value = "$trimmed 등록했습니다"
            } else {
                val current = repo.employees.getById(id) ?: return@launch
                repo.employees.update(current.copy(name = trimmed, phone = phone.trim(), memo = memo.trim()))
                _message.value = "$trimmed 수정했습니다"
            }
        }
    }

    fun remove(employee: Employee) {
        viewModelScope.launch {
            repo.employees.deactivate(employee.id)
            _message.value = "${employee.name} 목록에서 뺐습니다"
        }
    }

    fun clearMessage() { _message.value = null }
}

class ItemViewModel(private val repo: JangbuRepository) : ViewModel() {

    val items: StateFlow<List<ItemRow>> = repo.items.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), emptyList())

    val clients: StateFlow<List<Client>> = repo.clients.observeAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    /** 거래처 이름을 직접 적어도 되고(없으면 새로 만듭니다), 목록에서 골라도 됩니다. */
    fun save(
        id: Long,
        clientName: String,
        itemName: String,
        chargePrice: String,
        wagePrice: String,
        unitLabel: String
    ) {
        val client = clientName.trim()
        val item = itemName.trim()
        val charge = chargePrice.toLongOrNull() ?: 0L
        val wage = wagePrice.toLongOrNull() ?: 0L
        val unit = unitLabel.trim().ifEmpty { "장" }

        when {
            client.isEmpty() -> { _message.value = "거래처를 적어 주세요"; return }
            item.isEmpty() -> { _message.value = "품목 이름을 적어 주세요"; return }
            charge <= 0L -> { _message.value = "받을 단가를 적어 주세요"; return }
        }

        viewModelScope.launch {
            val clientId = repo.clients.findOrCreate(client)
            if (id == 0L) {
                val exists = repo.items.findByClientAndName(clientId, item)
                if (exists != null) {
                    _message.value = "$client $item 은 이미 있습니다"
                    return@launch
                }
                repo.items.insert(
                    Item(
                        clientId = clientId,
                        name = item,
                        chargeUnitPrice = charge,
                        defaultWageUnitPrice = wage,
                        unitLabel = unit
                    )
                )
                _message.value = "$client $item 등록했습니다"
            } else {
                val current = repo.items.getById(id) ?: return@launch
                repo.items.update(
                    current.copy(
                        clientId = clientId,
                        name = item,
                        chargeUnitPrice = charge,
                        defaultWageUnitPrice = wage,
                        unitLabel = unit
                    )
                )
                _message.value = "$client $item 수정했습니다"
            }
        }
    }

    fun remove(row: ItemRow) {
        viewModelScope.launch {
            repo.items.deactivate(row.id)
            _message.value = "${row.name} 목록에서 뺐습니다"
        }
    }

    fun clearMessage() { _message.value = null }
}

class EmployeeRateViewModel(
    private val repo: JangbuRepository,
    private val employeeId: Long
) : ViewModel() {

    val rates: StateFlow<List<EmployeeRateRow>> = repo.rates.observeForEmployee(employeeId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    /** 빈 값으로 저장하면 지정 단가를 지우고 품목 기본공임을 따릅니다. */
    fun setRate(itemId: Long, wage: String) {
        val value = wage.trim().toLongOrNull()
        viewModelScope.launch {
            repo.setEmployeeRate(employeeId, itemId, value)
            _message.value = if (value == null) "기본 공임을 따릅니다" else "공임을 저장했습니다"
        }
    }

    fun clearMessage() { _message.value = null }
}
