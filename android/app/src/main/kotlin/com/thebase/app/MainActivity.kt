package com.thebase.app

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.thebase.app/gallery"
    private val subDir = "TheBase_Transferencias"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToGallery" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        if (sourcePath == null || fileName == null) {
                            result.error("ARG", "sourcePath/fileName required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(saveImageToGallery(sourcePath, fileName))
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Copies [sourcePath] into the public Pictures/TheBase_Transferencias folder
    /// so the photo is visible in the device gallery. Uses MediaStore on
    /// Android 10+ (no permission required) and the legacy public dir + media
    /// scan on older versions.
    private fun saveImageToGallery(sourcePath: String, fileName: String): String {
        val source = File(sourcePath)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    Environment.DIRECTORY_PICTURES + "/" + subDir
                )
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values
            ) ?: throw IllegalStateException("MediaStore insert returned null")

            resolver.openOutputStream(uri).use { out ->
                FileInputStream(source).use { input -> input.copyTo(out!!) }
            }
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        }

        // Android 9 and below — legacy public storage + media scan.
        val picturesDir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            subDir
        )
        if (!picturesDir.exists()) picturesDir.mkdirs()
        val dest = File(picturesDir, fileName)
        FileInputStream(source).use { input ->
            dest.outputStream().use { out -> input.copyTo(out) }
        }
        MediaScannerConnection.scanFile(
            applicationContext, arrayOf(dest.absolutePath), arrayOf("image/jpeg"), null
        )
        return dest.absolutePath
    }
}
