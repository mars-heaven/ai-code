package com.ilgam.jangbu.server

import com.google.firebase.firestore.CollectionReference
import com.google.firebase.firestore.DocumentChange
import com.google.firebase.firestore.FirebaseFirestore
import com.ilgam.jangbu.data.JangbuDatabase
import com.ilgam.jangbu.data.JangbuMirror
import com.ilgam.jangbu.data.entity.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import com.google.firebase.firestore.ListenerRegistration

/**
 * 폰 장부와 서버를 맞춥니다.
 *
 * 장부의 진짜 주인은 폰 안의 Room 입니다. 화면은 늘 Room 만 봅니다.
 * 서버는 그 장부를 다른 사람 폰으로 옮겨 주는 통로일 뿐입니다.
 *
 *   적을 때  : Room 에 적고 → 서버에도 적습니다
 *   볼 때    : 서버가 바뀌면 → Room 에 받아 적습니다 → 화면이 저절로 바뀝니다
 *
 * 인터넷이 끊겨도 파이어베이스가 보낼 것을 알아서 쌓아 두었다가 연결되면 보냅니다.
 * 그래서 따로 기다리는 줄을 만들지 않았습니다.
 */
class SyncRepository(
    private val db: JangbuDatabase,
    private val shopId: String
) : JangbuMirror {
    private val sync = db.syncDao()
    private val firestore: FirebaseFirestore get() = FirebaseFirestore.getInstance()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val listeners = mutableListOf<ListenerRegistration>()

    private val _state = MutableStateFlow(SyncState.STOPPED)
    val state: StateFlow<SyncState> = _state

    private val _lastError = MutableStateFlow<String?>(null)
    val lastError: StateFlow<String?> = _lastError

    private fun col(name: String): CollectionReference =
        firestore.collection("shops").document(shopId).collection(name)

    // ------------------------------------------------------------------
    // 장부 → 서버
    // ------------------------------------------------------------------
    override fun onClient(row: Client) = push(Collections.CLIENTS, row.id, row.toMap())
    override fun onItem(row: Item) = push(Collections.ITEMS, row.id, row.toMap())
    override fun onEmployee(row: Employee) = push(Collections.EMPLOYEES, row.id, row.toMap())
    override fun onRate(row: EmployeeRate) = push(Collections.RATES, row.id, row.toMap())
    override fun onOrder(row: WorkOrder) = push(Collections.ORDERS, row.id, row.toMap())
    override fun onLog(row: WorkLog) = push(Collections.LOGS, row.id, row.toMap())
    override fun onInvoice(row: Invoice) = push(Collections.INVOICES, row.id, row.toMap())
    override fun onPayroll(row: Payroll) = push(Collections.PAYROLLS, row.id, row.toMap())

    override fun onLogs(rows: List<WorkLog>) = rows.forEach { onLog(it) }

    override fun onRateRemoved(id: String) = drop(Collections.RATES, id)
    override fun onLogRemoved(id: String) = drop(Collections.LOGS, id)
    override fun onInvoiceRemoved(id: String) = drop(Collections.INVOICES, id)
    override fun onPayrollRemoved(id: String) = drop(Collections.PAYROLLS, id)

    private fun push(collection: String, id: String, data: Map<String, Any?>) {
        if (id.isBlank()) return
        // 보내는 것을 기다리지 않습니다. 파이어베이스가 알아서 쌓아 두고 보냅니다.
        runCatching { col(collection).document(id).set(data) }
            .onFailure { _lastError.value = it.message }
    }

    private fun drop(collection: String, id: String) {
        if (id.isBlank()) return
        runCatching { col(collection).document(id).delete() }
            .onFailure { _lastError.value = it.message }
    }

    /** 서버를 처음 쓸 때, 지금 폰에 있는 장부를 통째로 올립니다. */
    suspend fun pushEverything() {
        runCatching {
            sync.allClients().forEach { onClient(it) }
            sync.allItems().forEach { onItem(it) }
            sync.allEmployees().forEach { onEmployee(it) }
            sync.allRates().forEach { onRate(it) }
            sync.allOrders().forEach { onOrder(it) }
            sync.allLogs().forEach { onLog(it) }
            sync.allInvoices().forEach { onInvoice(it) }
            sync.allPayrolls().forEach { onPayroll(it) }
        }.onFailure { _lastError.value = it.message }
    }

    // ------------------------------------------------------------------
    // 서버 → 장부
    // ------------------------------------------------------------------
    fun start() {
        if (listeners.isNotEmpty()) return
        _state.value = SyncState.CONNECTING

        Collections.all.forEach { name ->
            val reg = col(name).addSnapshotListener { snapshot, error ->
                if (error != null) {
                    _state.value = SyncState.ERROR
                    _lastError.value = error.message
                    return@addSnapshotListener
                }
                if (snapshot == null) return@addSnapshotListener

                _state.value = SyncState.RUNNING
                scope.launch { apply(name, snapshot.documentChanges) }
            }
            listeners += reg
        }
    }

    fun stop() {
        listeners.forEach { runCatching { it.remove() } }
        listeners.clear()
        _state.value = SyncState.STOPPED
    }

    fun release() {
        stop()
        runCatching { scope.cancel() }
    }

    /**
     * 서버에서 온 변경분을 장부에 적습니다.
     *
     * 표마다 따로 소식이 오므로 거래처보다 품목이 먼저 닿을 수 있고,
     * 그러면 '없는 거래처를 가리킨다' 며 거부됩니다.
     * 잠시 뒤 부모가 닿으면 되므로 몇 번 다시 시도합니다.
     */
    private suspend fun apply(collection: String, changes: List<DocumentChange>) {
        if (changes.isEmpty()) return

        repeat(RETRY_TIMES) { attempt ->
            if (applyOnce(collection, changes)) return
            delay(RETRY_DELAY_MS)
        }
        _lastError.value = "서버 자료를 장부에 옮기지 못했습니다"
    }

    /** 한 번 시도해 보고 됐는지 알려 줍니다. */
    private suspend fun applyOnce(collection: String, changes: List<DocumentChange>): Boolean {
        val added = changes.filter { it.type != DocumentChange.Type.REMOVED }.map { it.document }
        val removed = changes.filter { it.type == DocumentChange.Type.REMOVED }.map { it.document.id }

        return runCatching {
            when (collection) {
                Collections.CLIENTS -> {
                    sync.putClients(added.map { it.toClient() })
                    removed.forEach { sync.dropClient(it) }
                }
                Collections.ITEMS -> {
                    sync.putItems(added.map { it.toItem() })
                    removed.forEach { sync.dropItem(it) }
                }
                Collections.EMPLOYEES -> {
                    sync.putEmployees(added.map { it.toEmployee() })
                    removed.forEach { sync.dropEmployee(it) }
                }
                Collections.RATES -> {
                    sync.putRates(added.map { it.toRate() })
                    removed.forEach { sync.dropRate(it) }
                }
                Collections.ORDERS -> {
                    sync.putOrders(added.map { it.toOrder() })
                    removed.forEach { sync.dropOrder(it) }
                }
                Collections.LOGS -> {
                    sync.putLogs(added.map { it.toLog() })
                    removed.forEach { sync.dropLog(it) }
                }
                Collections.INVOICES -> {
                    sync.putInvoices(added.map { it.toInvoice() })
                    removed.forEach { sync.dropInvoice(it) }
                }
                Collections.PAYROLLS -> {
                    sync.putPayrolls(added.map { it.toPayroll() })
                    removed.forEach { sync.dropPayroll(it) }
                }
            }
            true
        }.getOrDefault(false)
    }

    private companion object {
        const val RETRY_TIMES = 5
        const val RETRY_DELAY_MS = 1_500L
    }

    /** 서버에 이미 자료가 있는지 — 첫 로그인 때 올릴지 받을지 정하는 데 씁니다. */
    suspend fun serverHasData(): Boolean = runCatching {
        col(Collections.CLIENTS).limit(1).get().await().isEmpty.not() ||
            col(Collections.LOGS).limit(1).get().await().isEmpty.not()
    }.getOrDefault(false)
}

enum class SyncState { STOPPED, CONNECTING, RUNNING, ERROR }
