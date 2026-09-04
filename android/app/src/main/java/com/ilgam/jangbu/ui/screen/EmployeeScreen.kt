package com.ilgam.jangbu.ui.screen

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ilgam.jangbu.data.entity.Employee
import com.ilgam.jangbu.ui.component.*
import com.ilgam.jangbu.ui.jangbuViewModel
import com.ilgam.jangbu.ui.rememberRepository

@Composable
fun EmployeeScreen(
    onBack: () -> Unit,
    onOpenRates: (employeeId: Long, employeeName: String) -> Unit
) {
    val repo = rememberRepository()
    val vm = jangbuViewModel { EmployeeViewModel(repo) }
    val employees by vm.employees.collectAsState()
    val message by vm.message.collectAsState()

    var editing by remember { mutableStateOf<Employee?>(null) }

    val target = editing
    if (target != null) {
        EmployeeEditScreen(
            employee = target,
            message = message,
            onClearMessage = vm::clearMessage,
            onSave = { name, phone, memo ->
                vm.save(target.id, name, phone, memo)
                editing = null
            },
            onOpenRates = if (target.id == 0L) null else {
                { onOpenRates(target.id, target.name) }
            },
            onBack = { editing = null }
        )
        return
    }

    JangbuScreen(
        title = "직원",
        subtitle = "${employees.size}명",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "새 직원 등록",
                onClick = { editing = Employee(name = "") },
                kind = BigButtonKind.Primary
            )
        }
    ) {
        MessageBanner(message, vm::clearMessage)

        if (employees.isEmpty()) {
            EmptyMessage("아직 등록된 직원이 없습니다.\n아래 파란 버튼을 눌러 등록해 주세요.")
        } else {
            employees.forEach { employee ->
                ListRow(
                    title = employee.name,
                    subtitle = employee.phone.ifBlank { "전화번호 없음" },
                    onClick = { editing = employee }
                )
            }
        }
        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun EmployeeEditScreen(
    employee: Employee,
    message: String?,
    onClearMessage: () -> Unit,
    onSave: (name: String, phone: String, memo: String) -> Unit,
    onOpenRates: (() -> Unit)?,
    onBack: () -> Unit
) {
    val isNew = employee.id == 0L
    var name by remember(employee.id) { mutableStateOf(employee.name) }
    var phone by remember(employee.id) { mutableStateOf(employee.phone) }
    var memo by remember(employee.id) { mutableStateOf(employee.memo) }

    JangbuScreen(
        title = if (isNew) "새 직원" else "직원 수정",
        onBack = onBack,
        bottomBar = {
            BigButton(
                text = "저장",
                onClick = { onSave(name, phone, memo) },
                kind = BigButtonKind.Primary,
                enabled = name.isNotBlank()
            )
        }
    ) {
        MessageBanner(message, onClearMessage)

        BigField(
            label = "직원 이름",
            value = name,
            onValueChange = { name = it },
            hint = "예) 홍길동"
        )
        BigField(
            label = "전화번호",
            value = phone,
            onValueChange = { phone = it },
            hint = "예) 010-1234-5678"
        )
        BigField(
            label = "메모",
            value = memo,
            onValueChange = { memo = it },
            hint = "적어 둘 내용이 있으면"
        )

        if (onOpenRates != null) {
            Spacer(Modifier.height(8.dp))
            SectionTitle("이 직원의 공임 단가")
            BigButton(
                text = "품목별 공임 정하기",
                sub = "정하지 않으면 품목 기본 공임을 따릅니다",
                onClick = onOpenRates
            )
        }
        Spacer(Modifier.height(8.dp))
    }
}
