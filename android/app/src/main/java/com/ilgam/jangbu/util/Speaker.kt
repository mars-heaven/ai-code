package com.ilgam.jangbu.util

import android.content.Context
import android.content.Intent
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import java.util.Locale

/**
 * 소리로 알려 주기.
 * 글씨를 키워도 잘 안 보이는 경우가 있어, 방금 무엇을 했는지 말로도 확인시켜 줍니다.
 */
class Speaker(context: Context) {

    private var ready = false
    private val prefs = Prefs(context)
    private val tts = TextToSpeech(context.applicationContext) { status ->
        ready = status == TextToSpeech.SUCCESS
    }.also {
        runCatching { it.language = Locale.KOREAN }
    }

    var enabled: Boolean
        get() = prefs.speakEnabled
        set(value) {
            prefs.speakEnabled = value
            if (!value) stop()
        }

    fun say(text: String) {
        if (!enabled || !ready || text.isBlank()) return
        runCatching {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "jangbu")
        }
    }

    fun stop() {
        runCatching { tts.stop() }
    }

    fun shutdown() {
        runCatching { tts.stop() }
        runCatching { tts.shutdown() }
    }
}

/**
 * 소리 장치는 앱에 하나만 둡니다.
 * 화면마다 새로 만들면 준비하는 데 시간이 걸리고,
 * 저장하자마자 화면이 닫히는 경우 말이 중간에 끊깁니다.
 */
@Composable
fun rememberSpeaker(): Speaker {
    val context = LocalContext.current
    return remember(context) { (context.applicationContext as SpeakerHolder).speaker }
}

/** 앱 클래스가 소리 장치를 하나 들고 있게 합니다. */
interface SpeakerHolder {
    val speaker: Speaker
}

/**
 * 구글 음성 인식 창을 띄우는 요청.
 * 인터넷이 되면 자연스러운 문장까지 알아듣고, 안 되면 기기에 깔린 인식기를 씁니다.
 */
fun speechIntent(prompt: String): Intent =
    Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(
            RecognizerIntent.EXTRA_LANGUAGE_MODEL,
            RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
        )
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ko-KR")
        putExtra(RecognizerIntent.EXTRA_PROMPT, prompt)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
    }

/** 음성 인식 결과에서 후보 문장들을 꺼냅니다(첫 번째가 가장 그럴듯한 것). */
fun speechResults(data: Intent?): List<String> =
    data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS).orEmpty()
