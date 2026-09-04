package com.ilgam.jangbu.ui.screen

import android.content.Context
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ilgam.jangbu.JangbuApplication
import com.ilgam.jangbu.server.*
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.theme.*
import com.ilgam.jangbu.util.Prefs
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * 서버에 함께 보기.
 *
 * 사장님이 업체를 열고 초대 번호를 만들면, 가족이 그 번호로 들어와 장부를 봅니다.
 * 서버가 준비되지 않은 앱에서는 이 화면이 안내만 보여 주고, 앱은 그대로 돌아갑니다.
 */
class ServerViewModel(private val context: Context) : ViewModel() {

    private val auth = AuthRepository(context)
    private val shops = ShopRepository()
    private val prefs = Prefs(context)
    private val app = context.applicationContext as JangbuApplication

    private val _user = MutableStateFlow(auth.currentUser())
    val user: StateFlow<SignedInUser?> = _user

    private val _shop = MutableStateFlow<ShopMembership?>(null)
    val shop: StateFlow<ShopMembership?> = _shop

    private val _members = MutableStateFlow<List<ShopMember>>(emptyList())
    val members: StateFlow<List<ShopMember>> = _members

    private val _invite = MutableStateFlow<Invite?>(null)
    val invite: StateFlow<Invite?> = _invite

    private val _busy = MutableStateFlow(false)
    val busy: StateFlow<Boolean> = _busy

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    /**
     * 서버와 맞추는 일이 잘 되고 있는지.
     * 맞추기는 나중에 시작될 수도 있어서, 시작될 때마다 그쪽 소식을 따라 옮겨 담습니다.
     */
    private val _syncState = MutableStateFlow(SyncState.STOPPED)
    val syncState: StateFlow<SyncState> = _syncState

    private var syncWatch: Job? = null

    private fun watchSync() {
        syncWatch?.cancel()
        val worker = app.sync
        if (worker == null) {
            _syncState.value = SyncState.STOPPED
            return
        }
        syncWatch = viewModelScope.launch {
            worker.state.collect { _syncState.value = it }
        }
    }

    val serverReady: Boolean get() = ServerAvailability.ready(context)
    val unavailableReason: String get() = ServerAvailability.unavailableReason(context)

    init {
        watchSync()
        if (serverReady && _user.value != null) refreshShop()
    }

    fun signIn() {
        _busy.value = true
        viewModelScope.launch {
            when (val r = auth.signIn()) {
                is SignInResult.Ok -> {
                    _user.value = r.user
                    _message.value = "${r.user.name} 님으로 로그인했습니다"
                    refreshShop()
                }
                is SignInResult.Fail -> _error.value = r.reason
                SignInResult.Canceled -> Unit
            }
            _busy.value = false
        }
    }

    fun signOut() {
        viewModelScope.launch {
            auth.signOut()
            app.stopSync()
            watchSync()
            prefs.clearShop()
            _user.value = null
            _shop.value = null
            _members.value = emptyList()
            _invite.value = null
            _message.value = "로그아웃했습니다"
        }
    }

    fun refreshShop() {
        val uid = _user.value?.uid ?: return
        _busy.value = true
        viewModelScope.launch {
            val membership = shops.myShop(uid)
            _shop.value = membership
            if (membership == null) {
                prefs.clearShop()
                app.stopSync()
                watchSync()
                _members.value = emptyList()
            } else {
                prefs.shopId = membership.shopId
                prefs.shopName = membership.shopName
                prefs.shopIsOwner = membership.isOwner
                _members.value = shops.members(membership.shopId)

                app.startSync(membership.shopId)
                watchSync()
                // 사장님이 처음 붙었고 서버가 비어 있으면, 지금 폰의 장부를 통째로 올립니다.
                val worker = app.sync
                if (membership.isOwner && worker != null && !worker.serverHasData()) {
                    worker.pushEverything()
                    _message.value = "지금 장부를 서버에 올렸습니다"
                }
            }
            _busy.value = false
        }
    }

    fun createShop(shopName: String) {
        val me = _user.value ?: return
        _busy.value = true
        viewModelScope.launch {
            when (val r = shops.createShop(me.uid, me.name, shopName)) {
                is ShopResult.Ok -> {
                    _message.value = "${r.value.shopName} 업체를 만들었습니다"
                    refreshShop()
                }
                is ShopResult.Fail -> { _error.value = r.reason; _busy.value = false }
            }
        }
    }

    fun join(code: String) {
        val me = _user.value ?: return
        _busy.value = true
        viewModelScope.launch {
            when (val r = shops.joinWithInvite(me.uid, me.name, code)) {
                is ShopResult.Ok -> {
                    _message.value = "${r.value.shopName} 에 들어갔습니다"
                    refreshShop()
                }
                is ShopResult.Fail -> { _error.value = r.reason; _busy.value = false }
            }
        }
    }

    fun makeInvite() {
        val me = _user.value ?: return
        val shopId = _shop.value?.shopId ?: return
        _busy.value = true
        viewModelScope.launch {
            when (val r = shops.createInvite(shopId, me.uid)) {
                is ShopResult.Ok -> _invite.value = r.value
                is ShopResult.Fail -> _error.value = r.reason
            }
            _busy.value = false
        }
    }

    fun removeMember(uid: String, name: String) {
        val shopId = _shop.value?.shopId ?: return
        _busy.value = true
        viewModelScope.launch {
            when (val r = shops.removeMember(shopId, uid)) {
                is ShopResult.Ok -> { _message.value = "$name 님을 내보냈습니다"; refreshShop() }
                is ShopResult.Fail -> { _error.value = r.reason; _busy.value = false }
            }
        }
    }

    fun clearMessage() { _message.value = null }
    fun clearError() { _error.value = null }
    fun clearInvite() { _invite.value = null }
}

@Composable
fun ServerScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val vm = jangbuViewModel { ServerViewModel(context) }

    val user by vm.user.collectAsState()
    val shop by vm.shop.collectAsState()
    val members by vm.members.collectAsState()
    val invite by vm.invite.collectAsState()
    val busy by vm.busy.collectAsState()
    val syncState by vm.syncState.collectAsState()
    val message by vm.message.collectAsState()
    val error by vm.error.collectAsState()

    var shopName by remember { mutableStateOf("") }
    var inviteCode by remember { mutableStateOf("") }
    var removeTarget by remember { mutableStateOf<ShopMember?>(null) }

    JangbuScreen(
        title = "함께 보기",
        subtitle = shop?.shopName ?: "가족과 장부를 같이 봅니다",
        onBack = onBack
    ) {
        MessageBanner(message, vm::clearMessage)

        if (!vm.serverReady) {
            EmptyMessage(vm.unavailableReason)
            Spacer(Modifier.height(8.dp))
            return@JangbuScreen
        }

        val me = user
        when {
            // 1) 아직 로그인 전
            me == null -> {
                InfoBox(
                    title = "먼저 로그인해 주세요",
                    body = "휴대폰에 들어 있는 구글 계정을 한 번 누르면 됩니다.\n" +
                        "비밀번호를 새로 만들지 않아도 됩니다."
                )
                BigButton(
                    text = "구글 계정으로 로그인",
                    onClick = { vm.signIn() },
                    kind = BigButtonKind.Primary,
                    enabled = !busy,
                    big = true
                )
            }

            // 2) 로그인은 했는데 아직 업체가 없음
            shop == null -> {
                InfoBox(
                    title = "${me.name} 님",
                    body = "장부를 새로 열거나, 사장님께 받은 초대 번호로 들어가세요."
                )

                SectionTitle("사장님이시면")
                BigField(
                    label = "업체 이름",
                    value = shopName,
                    onValueChange = { shopName = it },
                    hint = "예) 현미사"
                )
                BigButton(
                    text = "장부 새로 열기",
                    onClick = { vm.createShop(shopName) },
                    kind = BigButtonKind.Primary,
                    enabled = !busy && shopName.isNotBlank()
                )

                SectionTitle("초대를 받으셨으면")
                BigField(
                    label = "초대 번호",
                    value = inviteCode,
                    onValueChange = { if (it.length <= 6) inviteCode = it },
                    hint = "숫자 여섯 자리",
                    numberOnly = true
                )
                BigButton(
                    text = "들어가기",
                    onClick = { vm.join(inviteCode) },
                    enabled = !busy && inviteCode.length == 6
                )
            }

            // 3) 업체에 붙어 있음
            else -> {
                val membership = shop!!
                InfoBox(
                    title = membership.shopName,
                    body = if (membership.isOwner) {
                        "${me.name} 님은 사장님입니다.\n적고 마감하는 일은 사장님만 할 수 있습니다."
                    } else {
                        "${me.name} 님은 보기만 할 수 있습니다.\n적거나 마감하는 것은 사장님이 합니다."
                    }
                )

                SectionTitle("함께 보는 사람")
                members.forEach { member ->
                    ListRow(
                        title = member.name.ifBlank { "이름 없음" },
                        badge = {
                            StatusPill(
                                if (member.role == ShopRole.OWNER) "사장님" else "보기만",
                                if (member.role == ShopRole.OWNER) PillKind.Good else PillKind.Neutral
                            )
                        }
                    )
                    if (membership.isOwner && member.uid != me.uid) {
                        BigButton(
                            text = "${member.name.ifBlank { "이 사람" }} 내보내기",
                            onClick = { removeTarget = member },
                            kind = BigButtonKind.Danger
                        )
                    }
                }

                if (membership.isOwner) {
                    SectionTitle("가족 부르기")
                    if (invite == null) {
                        BigButton(
                            text = "초대 번호 만들기",
                            sub = "사흘 동안 쓸 수 있습니다",
                            onClick = { vm.makeInvite() },
                            kind = BigButtonKind.Primary,
                            enabled = !busy
                        )
                    } else {
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(Dimens.Radius))
                                .background(AccentSoft)
                                .border(Dimens.Border, Accent, RoundedCornerShape(Dimens.Radius))
                                .padding(20.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Text(
                                "초대 번호",
                                style = MaterialTheme.typography.titleMedium,
                                color = AccentDark
                            )
                            Text(
                                invite!!.code,
                                style = MaterialTheme.typography.headlineLarge,
                                fontWeight = FontWeight.Bold,
                                color = AccentDark
                            )
                            Text(
                                "가족에게 이 번호를 알려 주세요.\n" +
                                    "가족이 앱에서 이 번호를 넣으면 장부를 볼 수 있습니다.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Ink
                            )
                        }
                        BigButton(text = "새 번호 만들기", onClick = { vm.makeInvite() }, enabled = !busy)
                    }
                }

                SectionTitle("맞추기")
                ListRow(
                    title = "서버와 맞추는 중",
                    subtitle = when (syncState) {
                        SyncState.RUNNING -> "잘 되고 있습니다"
                        SyncState.CONNECTING -> "연결하는 중입니다"
                        SyncState.ERROR -> "연결이 끊겼습니다. 인터넷을 확인해 주세요"
                        SyncState.STOPPED -> "멈춰 있습니다"
                    },
                    badge = {
                        StatusPill(
                            when (syncState) {
                                SyncState.RUNNING -> "연결됨"
                                SyncState.CONNECTING -> "연결 중"
                                SyncState.ERROR -> "끊김"
                                SyncState.STOPPED -> "멈춤"
                            },
                            when (syncState) {
                                SyncState.RUNNING -> PillKind.Good
                                SyncState.ERROR -> PillKind.Alert
                                else -> PillKind.Neutral
                            }
                        )
                    }
                )

                SectionTitle("계정")
                BigButton(text = "다시 불러오기", onClick = { vm.refreshShop() }, enabled = !busy)
                BigButton(text = "로그아웃", onClick = { vm.signOut() }, kind = BigButtonKind.Danger)
            }
        }

        if (busy) EmptyMessage("잠시만 기다려 주세요.")

        Spacer(Modifier.height(8.dp))
    }

    val target = removeTarget
    if (target != null) {
        ConfirmDialog(
            title = "내보낼까요?",
            message = "${target.name.ifBlank { "이 사람" }} 은 더 이상 장부를 볼 수 없습니다.",
            confirmText = "내보내기",
            dismissText = "그대로 두기",
            danger = true,
            onConfirm = { vm.removeMember(target.uid, target.name); removeTarget = null },
            onDismiss = { removeTarget = null }
        )
    }

    val err = error
    if (err != null) {
        ConfirmDialog(
            title = "하지 못했습니다",
            message = err,
            confirmText = "알겠습니다",
            dismissText = "닫기",
            onConfirm = { vm.clearError() },
            onDismiss = { vm.clearError() }
        )
    }
}

@Composable
private fun InfoBox(title: String, body: String) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Dimens.Radius))
            .background(CardBg)
            .border(1.dp, Line, RoundedCornerShape(Dimens.Radius))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = Ink
        )
        Text(body, style = MaterialTheme.typography.bodyMedium, color = InkSoft)
    }
}
