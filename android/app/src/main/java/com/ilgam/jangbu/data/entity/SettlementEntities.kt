package com.ilgam.jangbu.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.ilgam.jangbu.util.newId

/**
 * 거래처 계산서(청구) 묶음.
 * 마감 한 번이 한 줄이고, 묶인 작업 기록들의 invoiceId 가 이 id 를 가리킵니다.
 */
@Entity(
    tableName = "invoices",
    foreignKeys = [
        ForeignKey(
            entity = Client::class,
            parentColumns = ["id"],
            childColumns = ["clientId"],
            onDelete = ForeignKey.RESTRICT
        )
    ],
    indices = [Index(value = ["clientId"]), Index(value = ["issuedDate"])]
)
data class Invoice(
    @PrimaryKey val id: String = newId(),
    val clientId: String,
    /** 집계에 사용한 기간 (기록용) yyyyMMdd */
    val periodStart: Int,
    val periodEnd: Int,
    val totalAmount: Long,
    val issuedDate: Int,
    /** 입금 완료 여부 */
    val paid: Boolean = false,
    val paidDate: Int? = null,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)

/** 발행한 계산서·영수증 사진. 휴대폰 안에 파일로 저장하고 경로만 담습니다. */
@Entity(
    tableName = "invoice_photos",
    foreignKeys = [
        ForeignKey(
            entity = Invoice::class,
            parentColumns = ["id"],
            childColumns = ["invoiceId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["invoiceId"])]
)
data class InvoicePhoto(
    @PrimaryKey val id: String = newId(),
    val invoiceId: String,
    val filePath: String,
    val takenAt: Long = System.currentTimeMillis(),
    val memo: String = ""
)

/**
 * 급여 정산 묶음.
 * 전 직원 일괄 마감이면 직원 수만큼 줄이 생기고, 한 사람만 마감하면 한 줄만 생깁니다.
 */
@Entity(
    tableName = "payrolls",
    foreignKeys = [
        ForeignKey(
            entity = Employee::class,
            parentColumns = ["id"],
            childColumns = ["employeeId"],
            onDelete = ForeignKey.RESTRICT
        )
    ],
    indices = [Index(value = ["employeeId"]), Index(value = ["closedDate"])]
)
data class Payroll(
    @PrimaryKey val id: String = newId(),
    val employeeId: String,
    /** 집계에 사용한 기간 (기록용) yyyyMMdd */
    val periodStart: Int,
    val periodEnd: Int,
    val totalAmount: Long,
    /** 마감한 날 */
    val closedDate: Int,
    /** 지급 완료 여부 */
    val paid: Boolean = false,
    val paidDate: Int? = null,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
