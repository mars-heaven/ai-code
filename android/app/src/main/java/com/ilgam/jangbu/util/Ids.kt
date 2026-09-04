package com.ilgam.jangbu.util

import java.util.UUID

/**
 * 자료마다 붙는 번호.
 *
 * 예전에는 폰 안에서만 1, 2, 3 으로 세었는데, 서버에 모으면 두 폰에서 만든
 * 1번끼리 부딪칩니다. 그래서 세상에 하나뿐인 번호를 만들어 씁니다.
 *
 * 아직 저장하지 않은 것은 빈 글자로 두어 '새것' 임을 나타냅니다.
 */
fun newId(): String = UUID.randomUUID().toString()

const val NEW_ID = ""
