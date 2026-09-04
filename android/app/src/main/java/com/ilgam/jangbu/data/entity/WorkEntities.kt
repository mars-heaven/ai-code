package com.ilgam.jangbu.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

object WorkOrderStatus {
    const val IN_PROGRESS = 0
    const val DONE = 1
    const val CANCELED = 2
}

/**
 * 일감(접수) — "현미사 바지 100장 들어옴".
 * 단가는 접수 시점 값을 그대로 저장해서, 나중에 품목 단가를 바꿔도 지난 건이 흔들리지 않습니다.
 */
@Entity(
    tableName = "work_orders",
    foreignKeys = [
        ForeignKey(
            entity = Client::class,
            parentColumns = ["id"],
            childColumns = ["clientId"],
            onDelete = ForeignKey.RESTRICT
        ),
        ForeignKey(
            entity = Item::class,
            parentColumns = ["id"],
            childColumns = ["itemId"],
            onDelete = ForeignKey.RESTRICT
        )
    ],
    indices = [
        Index(value = ["clientId"]),
        Index(value = ["itemId"]),
        Index(value = ["receivedDate"]),
        Index(value = ["status"])
    ]
)
data class WorkOrder(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val clientId: Long,
    val itemId: Long,
    /** 처리해야 할 목표 수량 */
    val targetQty: Int,
    /** 접수 시점의 청구 단가 (스냅샷) */
    val chargeUnitPrice: Long,
    /** yyyyMMdd */
    val receivedDate: Int,
    /** 납기 yyyyMMdd. 없으면 null */
    val dueDate: Int? = null,
    val status: Int = WorkOrderStatus.IN_PROGRESS,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)

/**
 * 직원 작업 기록 — "홍길동 10장 완료".
 *
 * payrollId / invoiceId 가 비어 있으면 아직 정산(지급)·청구되지 않은 건입니다.
 * 마감할 때 이 값이 채워지므로, 다음 마감에서 같은 건이 두 번 계산되지 않습니다.
 */
@Entity(
    tableName = "work_logs",
    foreignKeys = [
        ForeignKey(
            entity = WorkOrder::class,
            parentColumns = ["id"],
            childColumns = ["workOrderId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Employee::class,
            parentColumns = ["id"],
            childColumns = ["employeeId"],
            onDelete = ForeignKey.RESTRICT
        )
    ],
    indices = [
        Index(value = ["workOrderId"]),
        Index(value = ["employeeId"]),
        Index(value = ["workDate"]),
        Index(value = ["payrollId"]),
        Index(value = ["invoiceId"])
    ]
)
data class WorkLog(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val workOrderId: Long,
    val employeeId: Long,
    val qty: Int,
    /** 기록 시점의 공임 단가 (스냅샷) */
    val wageUnitPrice: Long,
    /** yyyyMMdd */
    val workDate: Int,
    /** 급여 정산 묶음. null 이면 아직 지급 정산 안 됨 */
    val payrollId: Long? = null,
    /** 거래처 청구 묶음. null 이면 아직 청구 안 됨 */
    val invoiceId: Long? = null,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
