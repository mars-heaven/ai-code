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
 */
private const val PHOTO_DIR = "invoice_photos"

fun invoicePhotoDir(context: Context): File =
    File(context.filesDir, PHOTO_DIR).apply { if (!exists()) mkdirs() }

fun newInvoicePhotoFile(context: Context): File {
    val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.KOREA).format(Date())
    return File(invoicePhotoDir(context), "inv_$stamp.jpg")
}

/** 카메라 앱에 "여기에 저장해 달라"고 넘겨 줄 주소를 만듭니다. */
fun fileProviderUri(context: Context, file: File): Uri =
    FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)

fun deletePhotoFile(path: String) {
    runCatching { File(path).takeIf { it.exists() }?.delete() }
}
