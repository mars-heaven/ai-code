package com.ilgam.jangbu.util

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.ilgam.jangbu.data.JangbuDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * 백업과 복원.
 *
 * 자료는 휴대폰 안에만 있으므로, 휴대폰을 잃어버리거나 앱을 지우면 장부도 함께 사라집니다.
 * 그래서 장부(데이터베이스)와 계산서 사진을 통째로 압축 파일 하나로 만들어
 * 카카오톡·구글 드라이브·USB 어디로든 내보낼 수 있게 합니다.
 *
 * 복원은 되돌릴 수 없는 일이라, 압축 파일이 제대로 된 장부인지 먼저 확인한 뒤에
 * 기존 파일을 바꿉니다. 중간에 잘못되면 원래 장부를 그대로 되돌려 놓습니다.
 */
private const val DB_NAME = "jangbu.db"
private const val DB_ENTRY = "jangbu.db"
private const val PHOTO_ENTRY_PREFIX = "photos/"

/** SQLite 파일이면 언제나 이 글자로 시작합니다. 엉뚱한 파일을 복원하지 않기 위한 확인용입니다. */
private val SQLITE_HEADER = "SQLite format 3".toByteArray(Charsets.US_ASCII)

sealed interface BackupResult {
    data class Ok(val photoCount: Int) : BackupResult
    data class Fail(val reason: String) : BackupResult
}

fun defaultBackupFileName(): String {
    val stamp = SimpleDateFormat("yyyyMMdd", Locale.KOREA).format(Date())
    return "일감장부_백업_$stamp.zip"
}

/**
 * 장부와 사진을 압축해 사용자가 고른 위치에 저장합니다.
 * 쓰기 전에 WAL 을 본 파일로 합쳐, 최근에 입력한 내용까지 빠짐없이 담습니다.
 */
suspend fun exportBackup(
    context: Context,
    db: JangbuDatabase,
    target: Uri
): BackupResult = withContext(Dispatchers.IO) {
    runCatching {
        // 아직 본 파일에 반영되지 않은 내용을 합칩니다.
        db.openHelper.writableDatabase.query("PRAGMA wal_checkpoint(TRUNCATE)").use { it.moveToFirst() }

        val dbFile = context.getDatabasePath(DB_NAME)
        if (!dbFile.exists()) return@runCatching BackupResult.Fail("아직 저장된 장부가 없습니다")

        val photos = invoicePhotoDir(context).listFiles()?.filter { it.isFile }.orEmpty()

        val out = context.contentResolver.openOutputStream(target)
            ?: return@runCatching BackupResult.Fail("저장할 위치를 열 수 없습니다")

        ZipOutputStream(out.buffered()).use { zip ->
            zip.putNextEntry(ZipEntry(DB_ENTRY))
            dbFile.inputStream().use { it.copyTo(zip) }
            zip.closeEntry()

            photos.forEach { photo ->
                zip.putNextEntry(ZipEntry(PHOTO_ENTRY_PREFIX + photo.name))
                photo.inputStream().use { it.copyTo(zip) }
                zip.closeEntry()
            }
        }
        BackupResult.Ok(photos.size)
    }.getOrElse { e ->
        BackupResult.Fail(e.message ?: "백업을 저장하지 못했습니다")
    }
}

/**
 * 압축 파일에서 장부와 사진을 되살립니다.
 * 성공하면 앱을 다시 시작해야 하므로, 화면에서 [restartApp] 을 이어서 부릅니다.
 */
suspend fun importBackup(
    context: Context,
    db: JangbuDatabase,
    source: Uri
): BackupResult = withContext(Dispatchers.IO) {
    val work = File(context.cacheDir, "restore").apply {
        deleteRecursively()
        mkdirs()
    }

    runCatching {
        // 1) 먼저 임시 자리에 다 풀어 봅니다. 여기서 실패해도 원래 장부는 그대로입니다.
        val stagedDb = File(work, DB_ENTRY)
        val stagedPhotos = File(work, "photos").apply { mkdirs() }

        val input = context.contentResolver.openInputStream(source)
            ?: return@runCatching BackupResult.Fail("파일을 열 수 없습니다")

        ZipInputStream(input.buffered()).use { zip ->
            var entry = zip.nextEntry
            while (entry != null) {
                val name = entry.name
                when {
                    entry.isDirectory -> Unit
                    name == DB_ENTRY -> stagedDb.outputStream().use { zip.copyTo(it) }
                    name.startsWith(PHOTO_ENTRY_PREFIX) -> {
                        // 압축 파일 안의 '../' 같은 경로로 엉뚱한 곳에 쓰지 못하게 이름만 씁니다.
                        val safe = File(name).name
                        if (safe.isNotBlank()) {
                            File(stagedPhotos, safe).outputStream().use { zip.copyTo(it) }
                        }
                    }
                }
                zip.closeEntry()
                entry = zip.nextEntry
            }
        }

        // 2) 정말 이 앱의 장부가 맞는지 확인합니다.
        if (!stagedDb.exists()) {
            return@runCatching BackupResult.Fail("이 파일에는 장부가 들어 있지 않습니다")
        }
        if (!looksLikeSqlite(stagedDb)) {
            return@runCatching BackupResult.Fail("일감장부 백업 파일이 아닙니다")
        }

        // 3) 장부를 닫고 파일을 바꿉니다. 실패하면 원래 장부로 되돌립니다.
        db.close()

        val dbFile = context.getDatabasePath(DB_NAME)
        val walFile = File(dbFile.parentFile, "$DB_NAME-wal")
        val shmFile = File(dbFile.parentFile, "$DB_NAME-shm")
        val rollback = File(work, "rollback.db")
        if (dbFile.exists()) dbFile.copyTo(rollback, overwrite = true)

        val swapped = runCatching {
            dbFile.parentFile?.mkdirs()
            walFile.delete()
            shmFile.delete()
            stagedDb.copyTo(dbFile, overwrite = true)
        }
        if (swapped.isFailure) {
            if (rollback.exists()) runCatching { rollback.copyTo(dbFile, overwrite = true) }
            return@runCatching BackupResult.Fail("장부를 바꾸지 못했습니다")
        }

        // 4) 사진은 통째로 갈아 끼웁니다(장부와 사진이 서로 맞아야 하므로).
        val photoDir = invoicePhotoDir(context)
        photoDir.listFiles()?.forEach { it.delete() }
        val restored = stagedPhotos.listFiles()?.filter { it.isFile }.orEmpty()
        restored.forEach { it.copyTo(File(photoDir, it.name), overwrite = true) }

        BackupResult.Ok(restored.size)
    }.getOrElse { e ->
        BackupResult.Fail(e.message ?: "복원하지 못했습니다")
    }.also {
        work.deleteRecursively()
    }
}

private fun looksLikeSqlite(file: File): Boolean = runCatching {
    file.inputStream().use { input ->
        val head = ByteArray(SQLITE_HEADER.size)
        input.read(head) == SQLITE_HEADER.size && head.contentEquals(SQLITE_HEADER)
    }
}.getOrDefault(false)

/**
 * 복원한 뒤에는 이미 열려 있던 장부가 옛 내용을 들고 있으므로 앱을 새로 띄웁니다.
 * (어르신께는 "앱이 다시 시작됩니다" 라고 미리 알려 준 뒤에 부릅니다.)
 */
fun restartApp(context: Context) {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
    if (intent != null) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        context.startActivity(intent)
    }
    Runtime.getRuntime().exit(0)
}
