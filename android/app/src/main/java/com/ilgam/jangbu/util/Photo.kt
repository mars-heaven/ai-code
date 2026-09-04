package com.ilgam.jangbu.util

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 계산서·영수증 사진은 앱 내부 저장소에만 보관합니다.
 * (다른 앱이나 갤러리에서 보이지 않아, 거래 자료가 밖으로 새지 않습니다.)
 *
 * 장부에는 전체 경로가 아니라 파일 이름만 담습니다.
 * 그래야 휴대폰을 바꿔 백업을 복원해도 사진을 그대로 찾을 수 있습니다.
 */
private const val PHOTO_DIR = "invoice_photos"

fun invoicePhotoDir(context: Context): File =
    File(context.filesDir, PHOTO_DIR).apply { if (!exists()) mkdirs() }

fun newInvoicePhotoFile(context: Context): File {
    val stamp = SimpleDateFormat("yyyyMMdd_HHmmss_SSS", Locale.KOREA).format(Date())
    return File(invoicePhotoDir(context), "inv_$stamp.jpg")
}

/** 장부에 담아 둔 파일 이름으로 실제 사진을 찾습니다. */
fun photoFile(context: Context, fileName: String): File =
    File(invoicePhotoDir(context), fileName)

/** 카메라 앱에 "여기에 저장해 달라"고 넘겨 줄 주소를 만듭니다. */
fun fileProviderUri(context: Context, file: File): Uri =
    FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)

fun deletePhotoFile(file: File) {
    runCatching { if (file.exists()) file.delete() }
}
