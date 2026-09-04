package com.ilgam.jangbu.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.ilgam.jangbu.data.dao.*
import com.ilgam.jangbu.data.entity.*

@Database(
    entities = [
        Client::class,
        Item::class,
        Employee::class,
        EmployeeRate::class,
        WorkOrder::class,
        WorkLog::class,
        Invoice::class,
        InvoicePhoto::class,
        Payroll::class
    ],
    version = 2,
    exportSchema = true
)
abstract class JangbuDatabase : RoomDatabase() {

    abstract fun clientDao(): ClientDao
    abstract fun itemDao(): ItemDao
    abstract fun employeeDao(): EmployeeDao
    abstract fun employeeRateDao(): EmployeeRateDao
    abstract fun workOrderDao(): WorkOrderDao
    abstract fun workLogDao(): WorkLogDao
    abstract fun payrollDao(): PayrollDao
    abstract fun invoiceDao(): InvoiceDao
    abstract fun summaryDao(): SummaryDao

    companion object {
        private const val NAME = "jangbu.db"

        fun build(context: Context): JangbuDatabase =
            Room.databaseBuilder(context.applicationContext, JangbuDatabase::class.java, NAME)
                // 외래키 제약을 켜서 잘못된 참조가 저장되지 않게 합니다.
                .setJournalMode(JournalMode.WRITE_AHEAD_LOGGING)
                // 자료 번호를 폰 안 일련번호에서 세상에 하나뿐인 번호로 바꾸면서
                // 표 모양이 달라졌습니다. 아직 시험용 자료뿐이라 옛 장부는 비우고 시작합니다.
                .fallbackToDestructiveMigration()
                .build()
    }
}
