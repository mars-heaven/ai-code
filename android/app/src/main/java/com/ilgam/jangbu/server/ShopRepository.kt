package com.ilgam.jangbu.server

import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import kotlin.random.Random

/** 업체에서 이 사람이 무엇을 할 수 있는지 */
object ShopRole {
    /** 사장님 — 모두 가능 */
    const val OWNER = "owner"
    /** 가족 — 보기만 */
    const val VIEWER = "viewer"
}

data class ShopMembership(
    val shopId: String,
    val shopName: String,
    val role: String
) {
    val isOwner: Boolean get() = role == ShopRole.OWNER
}

data class ShopMember(
    val uid: String,
    val name: String,
    val role: String
)

/** 가족을 부를 때 쓰는 여섯 자리 번호 */
data class Invite(
    val code: String,
    val expiresAt: Long
)

sealed interface ShopResult<out T> {
    data class Ok<T>(val value: T) : ShopResult<T>
    data class Fail(val reason: String) : ShopResult<Nothing>
}

/**
 * 업체 하나에 사장님과 가족이 붙는 구조.
 *
 *   업체/{업체번호}                     이름, 사장님
 *   업체/{업체번호}/식구/{계정}          이름, 역할
 *   초대/{여섯자리}                      어느 업체인지, 언제까지 쓸 수 있는지
 *   사람/{계정}                          지금 붙어 있는 업체
 *
 * 보안 규칙에서 '식구' 에 있는 계정만 그 업체 자료를 읽고 쓰게 막습니다.
 */
class ShopRepository {

    private val db: FirebaseFirestore get() = FirebaseFirestore.getInstance()

    /** 이 계정이 지금 붙어 있는 업체 */
    suspend fun myShop(uid: String): ShopMembership? = runCatching {
        val userDoc = db.collection(USERS).document(uid).get().await()
        val shopId = userDoc.getString("shopId") ?: return@runCatching null

        val shop = db.collection(SHOPS).document(shopId).get().await()
        if (!shop.exists()) return@runCatching null

        val member = db.collection(SHOPS).document(shopId)
            .collection(MEMBERS).document(uid).get().await()
        if (!member.exists()) return@runCatching null

        ShopMembership(
            shopId = shopId,
            shopName = shop.getString("name").orEmpty(),
            role = member.getString("role") ?: ShopRole.VIEWER
        )
    }.getOrNull()

    /** 사장님이 업체를 새로 엽니다. */
    suspend fun createShop(uid: String, userName: String, shopName: String): ShopResult<ShopMembership> {
        val name = shopName.trim()
        if (name.isEmpty()) return ShopResult.Fail("업체 이름을 적어 주세요")

        return runCatching {
            val shopRef = db.collection(SHOPS).document()
            db.runBatch { batch ->
                batch.set(
                    shopRef,
                    mapOf(
                        "name" to name,
                        "ownerUid" to uid,
                        "createdAt" to FieldValue.serverTimestamp()
                    )
                )
                batch.set(
                    shopRef.collection(MEMBERS).document(uid),
                    mapOf(
                        "name" to userName,
                        "role" to ShopRole.OWNER,
                        "joinedAt" to FieldValue.serverTimestamp()
                    )
                )
                batch.set(
                    db.collection(USERS).document(uid),
                    mapOf("shopId" to shopRef.id)
                )
            }.await()

            ShopResult.Ok(ShopMembership(shopRef.id, name, ShopRole.OWNER))
        }.getOrElse { ShopResult.Fail(it.message ?: "업체를 만들지 못했습니다") }
    }

    /**
     * 초대 번호 만들기 (사장님만).
     * 사흘 동안 쓸 수 있고, 한 번 쓰면 없어집니다.
     */
    suspend fun createInvite(shopId: String, uid: String): ShopResult<Invite> = runCatching {
        val code = (1..6).map { Random.nextInt(0, 10) }.joinToString("")
        val expiresAt = System.currentTimeMillis() + INVITE_VALID_MS

        db.collection(INVITES).document(code).set(
            mapOf(
                "shopId" to shopId,
                "createdBy" to uid,
                "expiresAt" to expiresAt
            )
        ).await()

        ShopResult.Ok(Invite(code, expiresAt))
    }.getOrElse { ShopResult.Fail(it.message ?: "초대 번호를 만들지 못했습니다") }

    /** 가족이 초대 번호를 넣고 업체에 붙습니다. 붙으면 보기만 할 수 있습니다. */
    suspend fun joinWithInvite(
        uid: String,
        userName: String,
        code: String
    ): ShopResult<ShopMembership> {
        val trimmed = code.trim()
        if (trimmed.length != 6 || trimmed.any { !it.isDigit() }) {
            return ShopResult.Fail("초대 번호는 숫자 여섯 자리입니다")
        }

        return runCatching {
            val inviteRef = db.collection(INVITES).document(trimmed)
            val invite = inviteRef.get().await()
            if (!invite.exists()) return ShopResult.Fail("없는 초대 번호입니다")

            val expiresAt = invite.getLong("expiresAt") ?: 0L
            if (expiresAt < System.currentTimeMillis()) {
                return ShopResult.Fail("기한이 지난 초대 번호입니다.\n사장님께 다시 받아 주세요")
            }

            val shopId = invite.getString("shopId")
                ?: return ShopResult.Fail("초대 번호가 잘못되었습니다")

            val shop = db.collection(SHOPS).document(shopId).get().await()
            if (!shop.exists()) return ShopResult.Fail("업체를 찾을 수 없습니다")

            val shopRef = db.collection(SHOPS).document(shopId)
            db.runBatch { batch ->
                batch.set(
                    shopRef.collection(MEMBERS).document(uid),
                    mapOf(
                        "name" to userName,
                        "role" to ShopRole.VIEWER,
                        "joinedAt" to FieldValue.serverTimestamp()
                    )
                )
                batch.set(db.collection(USERS).document(uid), mapOf("shopId" to shopId))
                // 한 번 쓴 번호는 없앱니다.
                batch.delete(inviteRef)
            }.await()

            ShopResult.Ok(
                ShopMembership(shopId, shop.getString("name").orEmpty(), ShopRole.VIEWER)
            )
        }.getOrElse { ShopResult.Fail(it.message ?: "업체에 들어가지 못했습니다") }
    }

    /** 이 업체에 붙어 있는 사람들 */
    suspend fun members(shopId: String): List<ShopMember> = runCatching {
        db.collection(SHOPS).document(shopId).collection(MEMBERS).get().await()
            .documents.map { doc ->
                ShopMember(
                    uid = doc.id,
                    name = doc.getString("name").orEmpty(),
                    role = doc.getString("role") ?: ShopRole.VIEWER
                )
            }
            // 사장님을 맨 위에
            .sortedByDescending { it.role == ShopRole.OWNER }
    }.getOrDefault(emptyList())

    /** 가족을 내보냅니다 (사장님만). */
    suspend fun removeMember(shopId: String, uid: String): ShopResult<Unit> = runCatching {
        db.runBatch { batch ->
            batch.delete(
                db.collection(SHOPS).document(shopId).collection(MEMBERS).document(uid)
            )
            batch.delete(db.collection(USERS).document(uid))
        }.await()
        ShopResult.Ok(Unit)
    }.getOrElse { ShopResult.Fail(it.message ?: "내보내지 못했습니다") }

    private companion object {
        const val SHOPS = "shops"
        const val MEMBERS = "members"
        const val INVITES = "invites"
        const val USERS = "users"
        const val INVITE_VALID_MS = 3L * 24 * 60 * 60 * 1000
    }
}
