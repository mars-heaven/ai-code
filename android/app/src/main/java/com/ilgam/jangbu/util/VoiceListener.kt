package com.ilgam.jangbu.util

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/**
 * 직접 마이크를 열어 듣습니다.
 *
 * 구글 음성 검색 창을 그대로 띄우면 잠깐 뜸을 들이는 사이 저절로 끝나 버려서,
 * 말이 느린 분은 다음 낱말을 꺼내기도 전에 잘립니다.
 * 그래서 여기서는 조용해도 한참(기본 4초) 기다리고,
 * 무엇보다 다 말했을 때 사람이 직접 버튼을 눌러 끝내게 합니다.
 */
class VoiceListener(context: Context) : RecognitionListener {

    private val appContext = context.applicationContext
    private var recognizer: SpeechRecognizer? = null

    /** 지금 듣고 있는지 */
    var listening by mutableStateOf(false)
        private set

    /** 말하는 중에 실시간으로 보여 줄 글 */
    var partial by mutableStateOf("")
        private set

    /** 다 듣고 나온 문장. 화면이 가져간 뒤 [consumeResult] 로 비웁니다. */
    var result by mutableStateOf<String?>(null)
        private set

    var error by mutableStateOf<String?>(null)
        private set

    /** 목소리 크기(0~1). 듣고 있다는 것을 눈으로 보여 주는 데 씁니다. */
    var level by mutableStateOf(0f)
        private set

    fun available(): Boolean = SpeechRecognizer.isRecognitionAvailable(appContext)

    fun start() {
        if (listening) return
        error = null
        partial = ""
        result = null

        val r = recognizer ?: runCatching {
            SpeechRecognizer.createSpeechRecognizer(appContext)
        }.getOrNull()
        if (r == null) {
            error = "음성 인식을 시작할 수 없습니다"
            return
        }
        recognizer = r
        r.setRecognitionListener(this)

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ko-KR")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            // 조용해져도 바로 끊지 않고 넉넉히 기다립니다.
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS,
                SILENCE_MS
            )
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS,
                SILENCE_MS
            )
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, MIN_MS)
        }

        listening = true
        runCatching { r.startListening(intent) }.onFailure {
            listening = false
            error = "음성 인식을 시작할 수 없습니다"
        }
    }

    /** "다 말했어요" — 지금까지 들은 것으로 끝냅니다. */
    fun stop() {
        runCatching { recognizer?.stopListening() }
        listening = false
    }

    fun cancel() {
        runCatching { recognizer?.cancel() }
        listening = false
        partial = ""
        level = 0f
    }

    fun consumeResult(): String? {
        val r = result
        result = null
        return r
    }

    fun clearError() { error = null }

    fun release() {
        runCatching { recognizer?.destroy() }
        recognizer = null
        listening = false
    }

    // ------------------------------------------------------------------
    // RecognitionListener — 안드로이드가 알려 주는 것들
    // ------------------------------------------------------------------
    override fun onReadyForSpeech(params: Bundle?) { listening = true }

    override fun onBeginningOfSpeech() {}

    override fun onRmsChanged(rmsdB: Float) {
        // 대략 -2 ~ 10 dB 범위를 0~1 로 옮깁니다.
        level = ((rmsdB + 2f) / 12f).coerceIn(0f, 1f)
    }

    override fun onBufferReceived(buffer: ByteArray?) {}

    override fun onEndOfSpeech() { listening = false }

    override fun onError(code: Int) {
        listening = false
        level = 0f
        // 아무 말도 못 알아들은 경우는 조용히 넘깁니다(다시 누르면 됩니다).
        error = when (code) {
            SpeechRecognizer.ERROR_NO_MATCH,
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "잘 못 들었습니다. 다시 말씀해 주세요"
            SpeechRecognizer.ERROR_NETWORK,
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "인터넷이 안 되어 알아듣지 못했습니다"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "마이크 사용을 허용해 주세요"
            SpeechRecognizer.ERROR_BUSY -> "잠시 뒤에 다시 눌러 주세요"
            else -> "음성 인식에 실패했습니다"
        }
    }

    override fun onResults(results: Bundle?) {
        listening = false
        level = 0f
        val best = results
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?: partial.ifBlank { null }
        if (best.isNullOrBlank()) {
            error = "잘 못 들었습니다. 다시 말씀해 주세요"
        } else {
            result = best
        }
    }

    override fun onPartialResults(partialResults: Bundle?) {
        partialResults
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?.let { if (it.isNotBlank()) partial = it }
    }

    override fun onEvent(eventType: Int, params: Bundle?) {}

    private companion object {
        const val SILENCE_MS = 4000L
        const val MIN_MS = 8000L
    }
}
