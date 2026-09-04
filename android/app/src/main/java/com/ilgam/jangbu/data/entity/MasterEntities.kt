package com.ilgam.jangbu.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.ilgam.jangbu.util.newId

/** 거래처. 일감을 등록하다가 없는 이름이 나오면 그 자리에서 만들어집니다. */
@Entity(
    tableName = "clients",
    indices = [Index(value = ["name"], unique = true)]
)
data class Client(
    @PrimaryKey val id: String = newId(),
    val name: String,
    val phone: String = "",
    val memo: String = "",
    val active: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)

/**
 * 거래처별 품목.
 * 청구단가(거래처에서 받을 돈)와 기본공임(직원에게 줄 돈)을 따로 둡니다.
 */
@Entity(
    tableName = "items",
    foreignKeys = [
        ForeignKey(
            entity = Client::class,
            parentColumns = ["id"],
            childColumns = ["clientId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["clientId"]),
        Index(value = ["clientId", "name"], unique = true)
    ]
)
data class Item(
    @PrimaryKey val id: String = newId(),
    val clientId: String,
    val name: String,
    /** 거래처에 청구하는 단가 (예: 바지 100원) */
    val chargeUnitPrice: Long,
    /** 직원 공임 기본값. 직원별 단가가 없으면 이 값을 씁니다. */
    val defaultWageUnitPrice: Long,
    /** 세는 단위 — 장, 개, 벌 등 */
    val unitLabel: String = "장",
    val active: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)

/** 직원(작업자). */
@Entity(
    tableName = "employees",
    indices = [Index(value = ["name"], unique = true)]
)
data class Employee(
    @PrimaryKey val id: String = newId(),
    val name: String,
    val phone: String = "",
    val memo: String = "",
    val active: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)

/**
 * 직원별 품목 공임 단가.
 * 여기에 값이 있으면 품목의 기본공임 대신 이 단가를 씁니다.
 */
@Entity(
    tableName = "employee_rates",
    foreignKeys = [
        ForeignKey(
            entity = Employee::class,
            parentColumns = ["id"],
            childColumns = ["employeeId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Item::class,
            parentColumns = ["id"],
            childColumns = ["itemId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["employeeId"]),
        Index(value = ["itemId"]),
        Index(value = ["employeeId", "itemId"], unique = true)
    ]
)
data class EmployeeRate(
    @PrimaryKey val id: String = newId(),
    val employeeId: String,
    val itemId: String,
    val wageUnitPrice: Long
)
