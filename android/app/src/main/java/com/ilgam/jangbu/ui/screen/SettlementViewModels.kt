package com.ilgam.jangbu.ui.screen

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.data.dao.*
import com.ilgam.jangbu.data.entity.InvoicePhoto
import com.ilgam.jangbu.util.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

private const val STOP_MS = 5_000L

/** 급여 정산 — 아직 지급하지 않은 공임을 모아 마감합니다. */
@OptIn(ExperimentalCoroutinesApi::class)
class PayrollViewModel(private val repo: JangbuRepository) : ViewModel() {

    private val _period = MutableStateFlow(periodOf(PeriodKind.THIS_MONTH))
    val period: StateFlow<Period> = _period

    /** 기간 안에서 아직 정산 안 된 직원별 공임 */
    val unpaid: StateFlow<List<UnpaidWageRow>> = _period
        .flatMapLatest { p -> repo.payrolls.observeUnpaidWages(p.from.toDbInt(), p.to.toDbInt()) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), emptyList())

    /** 지금까지 마감한 급여 이력 */
    val history: StateFlow<List<PayrollRow>> = repo.payrolls.observeHistory()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    fun setPeriod(kind: PeriodKind) { _period.value = periodOf(kind) }

    /** 한 사람만 마감 */
    fun closeOne(employeeId: Long, employeeName: String) {
        val p = _period.value
        viewModelScope.launch {
            val id = repo.closePayrollFor(employeeId, p.from, p.to)
            _message.value =
                if (id == null) "$employeeName 정산할 금액이 없습니다"
                else "$employeeName 급여를 마감했습니다"
        }
    }

    /** 목록에 있는 사람 전부 마감 */
    fun closeAll() {
        val p = _period.value
        val ids = unpaid.value.map { it.employeeId }
        if (ids.isEmpty()) {
            _message.value = "마감할 내역이 없습니다"
            return
        }
        viewModelScope.launch {
            val done = repo.closePayrollForAll(ids, p.from, p.to)
            _message.value = "${done.size}명 급여를 마감했습니다"
        }
    }

    fun markPaid(payrollId: Long, employeeName: String) {
        viewModelScope.launch {
            repo.markPayrollPaid(payrollId)
            _message.value = "$employeeName 지급 완료로 표시했습니다"
        }
    }

    /** 잘못 마감했을 때 되돌리기 — 묶음이 풀려 다시 미정산이 됩니다. */
    fun cancel(payrollId: Long, employeeName: String) {
        viewModelScope.launch {
            repo.cancelPayroll(payrollId)
            _message.value = "$employeeName 마감을 취소했습니다"
        }
    }

    /**
     * 정산서를 글로 만들어 화면에 넘깁니다.
     * 화면이 이 값을 받아 카카오톡·문자 보내기 창을 엽니다.
     */
    private val _statement = MutableStateFlow<Statement?>(null)
    val statement: StateFlow<Statement?> = _statement

    fun makeStatement(row: PayrollRow) {
        viewModelScope.launch {
            val details = repo.payrolls.details(row.id)
            _statement.value = Statement(
                subject = "${row.employeeName} 급여 정산서",
                body = payrollStatementText(row, details)
            )
        }
    }

    fun clearStatement() { _statement.value = null }

    fun clearMessage() { _message.value = null }
}

/** 카카오톡·문자로 보낼 글 한 벌 */
data class Statement(val subject: String, val body: String)

/** 거래처 정산 — 아직 청구하지 않은 금액을 모아 계산서를 냅니다. */
@OptIn(ExperimentalCoroutinesApi::class)
class InvoiceViewModel(private val repo: JangbuRepository) : ViewModel() {

    private val _period = MutableStateFlow(periodOf(PeriodKind.THIS_MONTH))
    val period: StateFlow<Period> = _period

    val unbilled: StateFlow<List<UnbilledRow>> = _period
        .flatMapLatest { p -> repo.invoices.observeUnbilled(p.from.toDbInt(), p.to.toDbInt()) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), emptyList())

    /** 계산서를 내기 전에 품목별로 얼마인지 펼쳐 봅니다. */
    private val _openClientId = MutableStateFlow<Long?>(null)
    val openClientId: StateFlow<Long?> = _openClientId

    val openDetail: StateFlow<List<BillingDetailRow>> =
        combine(_openClientId, _period) { id, p -> id to p }
            .flatMapLatest { (id, p) ->
                if (id == null) flowOf(emptyList())
                else repo.invoices.observeUnbilledDetail(id, p.from.toDbInt(), p.to.toDbInt())
            }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), emptyList())

    /** 아직 입금 안 된 계산서(미수금) */
    val unpaidInvoices: StateFlow<List<InvoiceRow>> = repo.invoices.observeUnpaid()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), emptyList())

    val history: StateFlow<List<InvoiceRow>> = repo.invoices.observeHistory()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), emptyList())

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    fun setPeriod(kind: PeriodKind) { _period.value = periodOf(kind) }

    fun toggleClient(clientId: Long) {
        _openClientId.value = if (_openClientId.value == clientId) null else clientId
    }

    fun issue(clientId: Long, clientName: String) {
        val p = _period.value
        viewModelScope.launch {
            val id = repo.issueInvoice(clientId, p.from, p.to)
            _message.value =
                if (id == null) "$clientName 청구할 금액이 없습니다"
                else "$clientName 계산서를 발행했습니다"
            if (id != null) _openClientId.value = null
        }
    }

    fun markPaid(invoiceId: Long, clientName: String) {
        viewModelScope.launch {
            repo.markInvoicePaid(invoiceId)
            _message.value = "$clientName 입금 확인했습니다"
        }
    }

    fun cancel(invoiceId: Long, clientName: String) {
        viewModelScope.launch {
            repo.cancelInvoice(invoiceId)
            _message.value = "$clientName 계산서를 취소했습니다"
        }
    }

    fun clearMessage() { _message.value = null }
}

/** 계산서 한 장 — 사진을 찍어 붙이고 입금을 확인합니다. */
class InvoiceDetailViewModel(
    private val repo: JangbuRepository,
    private val invoiceId: Long
) : ViewModel() {

    val photos: StateFlow<List<InvoicePhoto>> = repo.invoices.observePhotos(invoiceId)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), emptyList())

    val invoice: StateFlow<InvoiceRow?> = repo.invoices.observeHistory()
        .map { list -> list.firstOrNull { it.id == invoiceId } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_MS), null)

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    /** 계산서를 취소하면 이 화면은 닫혀야 하므로 따로 알려 줍니다. */
    private val _canceled = MutableStateFlow(false)
    val canceled: StateFlow<Boolean> = _canceled

    fun addPhoto(path: String) {
        viewModelScope.launch {
            repo.addInvoicePhoto(invoiceId, path)
            _message.value = "사진을 보관했습니다"
        }
    }

    fun removePhoto(photo: InvoicePhoto) {
        viewModelScope.launch {
            repo.removeInvoicePhoto(photo.id, photo.filePath)
            _message.value = "사진을 지웠습니다"
        }
    }

    fun markPaid() {
        viewModelScope.launch {
            repo.markInvoicePaid(invoiceId)
            _message.value = "입금 확인했습니다"
        }
    }

    /** 계산서를 글로 만들어 거래처에 보낼 수 있게 합니다. */
    private val _statement = MutableStateFlow<Statement?>(null)
    val statement: StateFlow<Statement?> = _statement

    fun makeStatement() {
        val row = invoice.value ?: return
        viewModelScope.launch {
            val details = repo.invoices.details(invoiceId)
            _statement.value = Statement(
                subject = "${row.clientName} 거래 명세서",
                body = invoiceStatementText(row, details)
            )
        }
    }

    fun clearStatement() { _statement.value = null }

    /** 잘못 낸 계산서 되돌리기 — 묶음이 풀려 다시 '청구 안 함' 으로 돌아갑니다. */
    fun cancel() {
        viewModelScope.launch {
            repo.cancelInvoice(invoiceId)
            _canceled.value = true
        }
    }

    fun clearMessage() { _message.value = null }
}
