package com.ilgam.jangbu

import android.graphics.Color as AndroidColor
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.ilgam.jangbu.ui.screen.*
import com.ilgam.jangbu.ui.theme.JangbuTheme
import com.ilgam.jangbu.ui.theme.Paper
import java.net.URLDecoder
import java.net.URLEncoder

private object Routes {
    const val HOME = "home"
    const val CLIENTS = "clients"
    const val ITEMS = "items"
    const val EMPLOYEES = "employees"
    const val WORK_ORDER = "work_order"
    const val WORK_LOG = "work_log"
    const val PROGRESS = "progress"
    const val RATES = "rates/{employeeId}/{employeeName}"

    fun rates(employeeId: Long, employeeName: String): String {
        val encoded = URLEncoder.encode(employeeName, "UTF-8")
        return "rates/$employeeId/$encoded"
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // 안드로이드 15부터는 앱이 화면 끝까지 그려지므로,
        // 상태바(파란 제목 막대 위)는 흰 아이콘, 아래 네비게이션 바는 어두운 아이콘으로 맞춥니다.
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(AndroidColor.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(
                AndroidColor.TRANSPARENT,
                AndroidColor.TRANSPARENT
            )
        )
        super.onCreate(savedInstanceState)
        setContent {
            JangbuTheme {
                Surface(Modifier.fillMaxSize().background(Paper)) {
                    JangbuApp()
                }
            }
        }
    }
}

@Composable
private fun JangbuApp() {
    val nav = rememberNavController()

    NavHost(navController = nav, startDestination = Routes.HOME) {

        composable(Routes.HOME) {
            HomeScreen(
                onWorkLog = { nav.navigate(Routes.WORK_LOG) },
                onWorkOrder = { nav.navigate(Routes.WORK_ORDER) },
                onProgress = { nav.navigate(Routes.PROGRESS) },
                onClients = { nav.navigate(Routes.CLIENTS) },
                onItems = { nav.navigate(Routes.ITEMS) },
                onEmployees = { nav.navigate(Routes.EMPLOYEES) }
            )
        }

        composable(Routes.WORK_ORDER) {
            WorkOrderScreen(onBack = { nav.popBackStack() })
        }

        composable(Routes.WORK_LOG) {
            WorkLogScreen(onBack = { nav.popBackStack() })
        }

        composable(Routes.PROGRESS) {
            ProgressScreen(onBack = { nav.popBackStack() })
        }

        composable(Routes.CLIENTS) {
            ClientScreen(onBack = { nav.popBackStack() })
        }

        composable(Routes.ITEMS) {
            ItemScreen(onBack = { nav.popBackStack() })
        }

        composable(Routes.EMPLOYEES) {
            EmployeeScreen(
                onBack = { nav.popBackStack() },
                onOpenRates = { id, name -> nav.navigate(Routes.rates(id, name)) }
            )
        }

        composable(
            route = Routes.RATES,
            arguments = listOf(
                navArgument("employeeId") { type = NavType.LongType },
                navArgument("employeeName") { type = NavType.StringType }
            )
        ) { entry ->
            val id = entry.arguments?.getLong("employeeId") ?: 0L
            val rawName = entry.arguments?.getString("employeeName").orEmpty()
            val name = runCatching { URLDecoder.decode(rawName, "UTF-8") }.getOrDefault(rawName)
            EmployeeRateScreen(
                employeeId = id,
                employeeName = name,
                onBack = { nav.popBackStack() }
            )
        }
    }
}
