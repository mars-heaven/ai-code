package com.ilgam.jangbu.server

import android.content.Context
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import kotlinx.coroutines.tasks.await

/** 지금 로그인한 사람 */
data class SignedInUser(
    val uid: String,
    val name: String,
    val email: String
)

sealed interface SignInResult {
    data class Ok(val user: SignedInUser) : SignInResult
    data class Fail(val reason: String) : SignInResult
    /** 사용자가 계정 고르기를 그만둔 경우 — 잘못된 것이 아니므로 따로 둡니다. */
    data object Canceled : SignInResult
}

/**
 * 구글 계정으로 로그인.
 *
 * 비밀번호를 만들거나 외울 필요가 없도록, 휴대폰에 이미 들어 있는 구글 계정을
 * 한 번 눌러 고르는 방식만 씁니다.
 */
class AuthRepository(private val context: Context) {

    private val auth: FirebaseAuth get() = FirebaseAuth.getInstance()

    fun currentUser(): SignedInUser? = runCatching {
        auth.currentUser?.let {
            SignedInUser(
                uid = it.uid,
                name = it.displayName.orEmpty().ifBlank { it.email.orEmpty() },
                email = it.email.orEmpty()
            )
        }
    }.getOrNull()

    suspend fun signIn(): SignInResult {
        if (!ServerAvailability.ready(context)) {
            return SignInResult.Fail(ServerAvailability.unavailableReason(context))
        }
        val webClientId = ServerAvailability.webClientId(context)
            ?: return SignInResult.Fail(ServerAvailability.unavailableReason(context))

        return try {
            val option = GetGoogleIdOption.Builder()
                // 처음 쓰는 사람도 계정을 고를 수 있게 이미 쓴 계정만 보여 주지 않습니다.
                .setFilterByAuthorizedAccounts(false)
                .setServerClientId(webClientId)
                .build()

            val request = GetCredentialRequest.Builder()
                .addCredentialOption(option)
                .build()

            val response = CredentialManager.create(context).getCredential(context, request)
            val credential = response.credential

            if (credential !is CustomCredential ||
                credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
            ) {
                return SignInResult.Fail("구글 계정을 가져오지 못했습니다")
            }

            val googleToken = GoogleIdTokenCredential.createFrom(credential.data).idToken
            val firebaseCredential = GoogleAuthProvider.getCredential(googleToken, null)
            auth.signInWithCredential(firebaseCredential).await()

            currentUser()?.let { SignInResult.Ok(it) }
                ?: SignInResult.Fail("로그인은 됐지만 계정을 읽지 못했습니다")
        } catch (e: androidx.credentials.exceptions.GetCredentialCancellationException) {
            SignInResult.Canceled
        } catch (e: androidx.credentials.exceptions.NoCredentialException) {
            SignInResult.Fail(
                "이 휴대폰에 구글 계정이 없습니다.\n" +
                    "설정에서 구글 계정을 추가한 뒤 다시 해 주세요."
            )
        } catch (e: Exception) {
            SignInResult.Fail(e.message ?: "로그인하지 못했습니다")
        }
    }

    suspend fun signOut() {
        runCatching { auth.signOut() }
        // 다음에 다시 계정을 고를 수 있도록 고른 기록을 지웁니다.
        runCatching {
            CredentialManager.create(context)
                .clearCredentialState(ClearCredentialStateRequest())
        }
    }
}
