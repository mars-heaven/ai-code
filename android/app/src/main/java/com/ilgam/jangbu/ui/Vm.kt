package com.ilgam.jangbu.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.ilgam.jangbu.JangbuApplication
import com.ilgam.jangbu.data.JangbuRepository

/** 화면에서 저장소를 꺼내 씁니다. */
@Composable
fun rememberRepository(): JangbuRepository {
    val context = LocalContext.current
    return (context.applicationContext as JangbuApplication).repository
}

/** 매번 팩토리를 만들지 않도록 감싼 헬퍼. */
@Composable
inline fun <reified VM : ViewModel> jangbuViewModel(
    key: String? = null,
    crossinline create: () -> VM
): VM = viewModel(
    key = key,
    factory = viewModelFactory { initializer { create() } }
)
