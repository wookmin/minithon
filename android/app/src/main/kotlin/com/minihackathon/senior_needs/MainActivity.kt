package com.minihackathon.senior_needs

import android.content.ContentUris
import android.content.Intent
import android.net.Uri
import android.os.Build
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
                "recentRecordings" -> recentRecordings(
                    (call.argument<Int>("limit")) ?: 20,
                    result,
                )
                "readRecording" -> readRecording(call.argument<String>("uri"), result)
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

    /** MediaStore에서 최근 오디오 목록을 최신순으로 돌려준다(바이트 제외). */
    private fun recentRecordings(limit: Int, result: MethodChannel.Result) {
        try {
            val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            val hasRelativePath = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
            val projection = mutableListOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.DATE_ADDED,
            )
            if (hasRelativePath) {
                projection.add(MediaStore.Audio.Media.RELATIVE_PATH)
            }
            val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"
            val items = ArrayList<Map<String, Any?>>()
            contentResolver.query(
                collection,
                projection.toTypedArray(),
                null,
                null,
                sortOrder,
            )?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val nameCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
                val dateCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
                val pathCol = if (hasRelativePath) {
                    cursor.getColumnIndex(MediaStore.Audio.Media.RELATIVE_PATH)
                } else {
                    -1
                }
                while (cursor.moveToNext() && items.size < limit) {
                    val id = cursor.getLong(idCol)
                    val uri = ContentUris.withAppendedId(collection, id).toString()
                    val name = cursor.getString(nameCol) ?: "recording"
                    val date = cursor.getLong(dateCol)
                    val relPath =
                        if (pathCol >= 0) cursor.getString(pathCol) ?: "" else ""
                    items.add(
                        mapOf(
                            "uri" to uri,
                            "name" to name,
                            "dateAdded" to date,
                            "relativePath" to relPath,
                        ),
                    )
                }
            }
            result.success(items)
        } catch (e: Exception) {
            result.error("QUERY_FAILED", e.message, null)
        }
    }

    /** content:// URI의 바이트를 읽어 돌려준다. */
    private fun readRecording(uriString: String?, result: MethodChannel.Result) {
        if (uriString.isNullOrEmpty()) {
            result.success(null)
            return
        }
        try {
            val uri = Uri.parse(uriString)
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            result.success(bytes)
        } catch (e: Exception) {
            result.error("READ_FAILED", e.message, null)
        }
    }

    companion object {
        private const val CHANNEL = "senior_needs/recordings"
        const val EXTRA_ANALYZE = "analyze_latest"
    }
}
