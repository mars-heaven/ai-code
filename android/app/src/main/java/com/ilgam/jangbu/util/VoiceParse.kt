package com.ilgam.jangbu.util

/**
 * 말한 문장에서 이름과 수량을 뽑아냅니다.
 *
 * "김영순 티셔츠 삼백 장" / "영순이 티셔츠 300장 했어" 처럼
 * 말하는 순서나 조사가 달라도 알아듣도록, 문장에서 아는 이름을 먼저 찾아 걷어낸 뒤
 * 남은 말에서 수량을 읽습니다. 이름에 들어간 '삼', '오' 같은 글자를 숫자로
 * 잘못 읽는 일을 막기 위한 순서입니다.
 */

/** 고를 수 있는 후보 하나. [names] 에는 별칭을 같이 넣어 어느 쪽으로 불러도 찾게 합니다. */
data class VoiceCandidate<T>(val key: T, val names: List<String>)

private val UNIT_WORDS = listOf("장", "개", "벌", "매", "점", "켤레", "족", "박스", "세트")

private val SINO_DIGIT = mapOf(
    '영' to 0, '공' to 0, '일' to 1, '이' to 2, '삼' to 3, '사' to 4,
    '오' to 5, '육' to 6, '륙' to 6, '칠' to 7, '팔' to 8, '구' to 9
)
private val SINO_UNIT = mapOf('십' to 10, '백' to 100, '천' to 1000)

/** 하나·둘·셋 계열. 앞자리(스물·서른)와 뒷자리(다섯·여섯)를 따로 둡니다. */
private val NATIVE_TENS = linkedMapOf(
    "아흔" to 90, "여든" to 80, "일흔" to 70, "예순" to 60, "쉰" to 50,
    "마흔" to 40, "서른" to 30, "스물" to 20, "스무" to 20, "열" to 10
)
private val NATIVE_ONES = linkedMapOf(
    "하나" to 1, "다섯" to 5, "여섯" to 6, "일곱" to 7, "여덟" to 8, "아홉" to 9,
    "둘" to 2, "셋" to 3, "넷" to 4, "한" to 1, "두" to 2, "세" to 3, "네" to 4
)

private fun normalize(text: String): String =
    text.lowercase().filterNot { it.isWhitespace() }

/**
 * 말한 문장에서 후보 하나를 고릅니다.
 * 이름이 통째로 들어 있으면 가장 긴 이름을 고르고, 없으면 두 글자 이상 겹치는 것을 찾습니다.
 * 겹치는 글자가 모자라면 아무것도 고르지 않습니다(엉뚱한 것을 고르는 편보다 낫습니다).
 */
fun <T> matchByName(spoken: String, candidates: List<VoiceCandidate<T>>): Pair<T, String>? {
    val text = normalize(spoken)
    if (text.isEmpty()) return null

    var best: Pair<T, String>? = null
    var bestScore = 0

    candidates.forEach { c ->
        c.names.forEach { raw ->
            val name = normalize(raw)
            if (name.isEmpty()) return@forEach
            val score = when {
                text.contains(name) -> name.length + 100   // 통째로 들어 있으면 우선
                else -> longestCommonRun(text, name).takeIf { it >= 2 } ?: 0
            }
            if (score > bestScore) {
                bestScore = score
                best = c.key to raw
            }
        }
    }
    return best
}

/** 두 글자에서 이어져 겹치는 가장 긴 길이 */
private fun longestCommonRun(a: String, b: String): Int {
    if (a.isEmpty() || b.isEmpty()) return 0
    var best = 0
    val prev = IntArray(b.length + 1)
    val cur = IntArray(b.length + 1)
    for (i in 1..a.length) {
        for (j in 1..b.length) {
            cur[j] = if (a[i - 1] == b[j - 1]) prev[j - 1] + 1 else 0
            if (cur[j] > best) best = cur[j]
        }
        System.arraycopy(cur, 0, prev, 0, cur.size)
        cur.fill(0)
    }
    return best
}

/** 문장에서 이미 알아들은 이름을 걷어냅니다(그 글자를 숫자로 잘못 읽지 않도록). */
fun removeMatched(spoken: String, vararg names: String?): String {
    var text = spoken
    names.filterNotNull().filter { it.isNotBlank() }.forEach { name ->
        text = text.replace(name, " ", ignoreCase = true)
        // 띄어 말한 경우도 걷어냅니다.
        val squeezed = name.filterNot { it.isWhitespace() }
        if (squeezed != name) text = text.replace(squeezed, " ", ignoreCase = true)
    }
    return text
}

/**
 * "삼백 장", "300장", "스물다섯 개", "300" 순으로 찾아 수량을 읽습니다.
 * 단위(장·개·벌…)가 붙은 숫자를 가장 믿을 만한 것으로 봅니다.
 */
fun parseQtyFromSpeech(raw: String): Int? {
    val text = raw.replace(",", "")
    val units = UNIT_WORDS.joinToString("|")

    Regex("(\\d+)\\s*(?:$units)").find(text)?.let { m ->
        m.groupValues[1].toIntOrNull()?.let { if (it > 0) return it }
    }
    Regex("([가-힣]+)\\s*(?:$units)").find(text)?.let { m ->
        parseKoreanNumeral(m.groupValues[1])?.let { if (it > 0) return it }
    }
    Regex("(\\d+)").find(text)?.let { m ->
        m.groupValues[1].toIntOrNull()?.let { if (it > 0) return it }
    }
    return parseKoreanNumeral(text)?.takeIf { it > 0 }
}

/** 한글로 말한 수를 숫자로. 못 읽으면 null. */
fun parseKoreanNumeral(raw: String): Int? {
    val text = raw.filterNot { it.isWhitespace() }
    if (text.isEmpty()) return null

    parseNative(text)?.let { return it }
    return parseSino(text)
}

/** 스물다섯 · 서른 · 열두 계열 */
private fun parseNative(text: String): Int? {
    var total = 0
    var rest = text
    var matched = false

    NATIVE_TENS.forEach { (word, value) ->
        if (!matched && rest.contains(word)) {
            total += value
            rest = rest.replaceFirst(word, "")
            matched = true
        }
    }
    NATIVE_ONES.entries.firstOrNull { rest.contains(it.key) }?.let { (word, value) ->
        total += value
        rest = rest.replaceFirst(word, "")
        matched = true
    }
    return if (matched) total else null
}

/** 삼백 · 이천오백 · 만 계열 */
private fun parseSino(text: String): Int? {
    val useful = text.filter { it in SINO_DIGIT || it in SINO_UNIT || it == '만' }
    if (useful.isEmpty()) return null

    var result = 0
    var section = 0
    var digit = 0
    var sawAny = false

    useful.forEach { c ->
        when {
            c in SINO_DIGIT -> { digit = SINO_DIGIT.getValue(c); sawAny = true }
            c in SINO_UNIT -> {
                val unit = SINO_UNIT.getValue(c)
                section += (if (digit == 0) 1 else digit) * unit
                digit = 0
                sawAny = true
            }
            c == '만' -> {
                val head = section + digit
                result += (if (head == 0) 1 else head) * 10000
                section = 0
                digit = 0
                sawAny = true
            }
        }
    }
    if (!sawAny) return null
    return result + section + digit
}
