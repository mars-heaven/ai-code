package com.ilgam.jangbu

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
    const val RATES = "rates/{employeeId}/{employeeName}"

    fun rates(employeeId: Long, employeeName: String): String {
        val encoded = URLEncoder.encode(employeeName, "UTF-8")
        return "rates/$employeeId/$encoded"
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
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
                onClients = { nav.navigate(Routes.CLIENTS) },
                onItems = { nav.navigate(Routes.ITEMS) },
                onEmployees = { nav.navigate(Routes.EMPLOYEES) }
            )
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
