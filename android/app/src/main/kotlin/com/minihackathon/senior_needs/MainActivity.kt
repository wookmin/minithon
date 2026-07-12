package com.minihackathon.senior_needs

import android.content.ContentUris
import android.content.Intent
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingAnalyze = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingAnalyze = intent?.getBooleanExtra(EXTRA_ANALYZE, false) ?: false

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "latestRecording" -> latestRecording(result)
                "consumePendingAnalyze" -> {
                    result.success(pendingAnalyze)
                    pendingAnalyze = false
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_ANALYZE, false)) {
            pendingAnalyze = true
            channel?.invokeMethod("analyzeLatest", null)
        }
    }

    /** MediaStore에서 가장 최근 오디오 파일을 읽어 이름·MIME·바이트로 돌려준다. */
    private fun latestRecording(result: MethodChannel.Result) {
        try {
            val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.MIME_TYPE,
            )
            val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"
            contentResolver.query(collection, projection, null, null, sortOrder)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val id = cursor.getLong(
                        cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID),
                    )
                    val name = cursor.getString(
                        cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME),
                    ) ?: "recording"
                    val mime = cursor.getString(
                        cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE),
                    ) ?: "audio/mpeg"
                    val uri = ContentUris.withAppendedId(collection, id)
                    val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    if (bytes != null) {
                        result.success(
                            mapOf("name" to name, "mimeType" to mime, "bytes" to bytes),
                        )
                        return
                    }
                }
                result.success(null)
            } ?: result.success(null)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", e.message, null)
        }
    }

    companion object {
        private const val CHANNEL = "senior_needs/recordings"
        const val EXTRA_ANALYZE = "analyze_latest"
    }
}
