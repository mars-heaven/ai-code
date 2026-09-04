package com.ilgam.jangbu.data.dao

import androidx.room.*
import com.ilgam.jangbu.data.entity.Client
import com.ilgam.jangbu.data.entity.Employee
import com.ilgam.jangbu.data.entity.EmployeeRate
import com.ilgam.jangbu.data.entity.Item
import kotlinx.coroutines.flow.Flow

@Dao
interface ClientDao {

    @Query("SELECT * FROM clients WHERE active = 1 ORDER BY name")
    fun observeAll(): Flow<List<Client>>

    @Query("SELECT * FROM clients WHERE id = :id")
    suspend fun getById(id: Long): Client?

    @Query("SELECT * FROM clients WHERE name = :name LIMIT 1")
    suspend fun findByName(name: String): Client?

    @Insert
    suspend fun insert(client: Client): Long

    @Update
    suspend fun update(client: Client)

    @Query("UPDATE clients SET active = 0 WHERE id = :id")
    suspend fun deactivate(id: Long)

    /** 이름으로 찾고 없으면 새로 만듭니다 — 일감 등록 중 자동 등록에 씁니다. */
    @Transaction
    suspend fun findOrCreate(name: String): Long {
        val trimmed = name.trim()
        findByName(trimmed)?.let { return it.id }
        return insert(Client(name = trimmed))
    }
}

/** 품목을 거래처 이름과 함께 보여주기 위한 조회 결과 */
data class ItemRow(
    val id: Long,
    val clientId: Long,
    val clientName: String,
    val name: String,
    val chargeUnitPrice: Long,
    val defaultWageUnitPrice: Long,
    val unitLabel: String
)

@Dao
interface ItemDao {

    @Query(
        """
        SELECT i.id, i.clientId, c.name AS clientName, i.name,
               i.chargeUnitPrice, i.defaultWageUnitPrice, i.unitLabel
        FROM items i JOIN clients c ON c.id = i.clientId
        WHERE i.active = 1
        ORDER BY c.name, i.name
        """
    )
    fun observeAll(): Flow<List<ItemRow>>

    @Query(
        """
        SELECT i.id, i.clientId, c.name AS clientName, i.name,
               i.chargeUnitPrice, i.defaultWageUnitPrice, i.unitLabel
        FROM items i JOIN clients c ON c.id = i.clientId
        WHERE i.active = 1 AND i.clientId = :clientId
        ORDER BY i.name
        """
    )
    fun observeByClient(clientId: Long): Flow<List<ItemRow>>

    @Query("SELECT * FROM items WHERE id = :id")
    suspend fun getById(id: Long): Item?

    @Query("SELECT * FROM items WHERE clientId = :clientId AND name = :name LIMIT 1")
    suspend fun findByClientAndName(clientId: Long, name: String): Item?

    @Insert
    suspend fun insert(item: Item): Long

    @Update
    suspend fun update(item: Item)

    @Query("UPDATE items SET active = 0 WHERE id = :id")
    suspend fun deactivate(id: Long)

    /** 거래처+품목명으로 찾고 없으면 만듭니다. */
    @Transaction
    suspend fun findOrCreate(
        clientId: Long,
        name: String,
        chargeUnitPrice: Long,
        defaultWageUnitPrice: Long,
        unitLabel: String = "장"
    ): Long {
        val trimmed = name.trim()
        findByClientAndName(clientId, trimmed)?.let { return it.id }
        return insert(
            Item(
                clientId = clientId,
                name = trimmed,
                chargeUnitPrice = chargeUnitPrice,
                defaultWageUnitPrice = defaultWageUnitPrice,
                unitLabel = unitLabel
            )
        )
    }
}

@Dao
interface EmployeeDao {

    @Query("SELECT * FROM employees WHERE active = 1 ORDER BY name")
    fun observeAll(): Flow<List<Employee>>

    @Query("SELECT * FROM employees WHERE id = :id")
    suspend fun getById(id: Long): Employee?

    @Query("SELECT * FROM employees WHERE name = :name LIMIT 1")
    suspend fun findByName(name: String): Employee?

    @Insert
    suspend fun insert(employee: Employee): Long

    @Update
    suspend fun update(employee: Employee)

    @Query("UPDATE employees SET active = 0 WHERE id = :id")
    suspend fun deactivate(id: Long)

    @Transaction
    suspend fun findOrCreate(name: String): Long {
        val trimmed = name.trim()
        findByName(trimmed)?.let { return it.id }
        return insert(Employee(name = trimmed))
    }
}

/** 직원별 공임 화면에 쓰는 조회 결과 — 지정 단가가 없으면 기본공임을 보여줍니다. */
data class EmployeeRateRow(
    val itemId: Long,
    val itemName: String,
    val clientName: String,
    val unitLabel: String,
    val defaultWageUnitPrice: Long,
    /** 이 직원에게 따로 지정한 단가. 없으면 null */
    val customWageUnitPrice: Long?
)

@Dao
interface EmployeeRateDao {

    @Query(
        """
        SELECT i.id AS itemId, i.name AS itemName, c.name AS clientName, i.unitLabel,
               i.defaultWageUnitPrice,
               (SELECT r.wageUnitPrice FROM employee_rates r
                 WHERE r.employeeId = :employeeId AND r.itemId = i.id) AS customWageUnitPrice
        FROM items i JOIN clients c ON c.id = i.clientId
        WHERE i.active = 1
        ORDER BY c.name, i.name
        """
    )
    fun observeForEmployee(employeeId: Long): Flow<List<EmployeeRateRow>>

    /**
     * 실제 적용할 공임 단가.
     * 직원별 지정 단가가 있으면 그 값, 없으면 품목 기본공임.
     */
    @Query(
        """
        SELECT COALESCE(
            (SELECT r.wageUnitPrice FROM employee_rates r
              WHERE r.employeeId = :employeeId AND r.itemId = :itemId),
            (SELECT i.defaultWageUnitPrice FROM items i WHERE i.id = :itemId)
        )
        """
    )
    suspend fun effectiveWage(employeeId: Long, itemId: Long): Long?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(rate: EmployeeRate)

    @Query("DELETE FROM employee_rates WHERE employeeId = :employeeId AND itemId = :itemId")
    suspend fun clear(employeeId: Long, itemId: Long)
}
