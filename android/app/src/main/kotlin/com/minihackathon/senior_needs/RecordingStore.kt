package com.minihackathon.senior_needs

import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import java.io.File

/** MediaStore 녹음 메타데이터. */
data class RecordingInfo(
    val uri: String,
    val name: String,
    val relativePath: String,
    val dateAdded: Long,
)

/**
 * MediaStore 오디오 조회 및 바이트 복사 헬퍼.
 * MainActivity(포그라운드)와 CallAnalysisWorker(백그라운드)가 공통으로 쓸 수 있는 순수 로직.
 */
object RecordingStore {
    fun recent(context: Context, limit: Int = 10): List<RecordingInfo> {
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val hasRelativePath = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATE_ADDED,
        )
        if (hasRelativePath) projection.add(MediaStore.Audio.Media.RELATIVE_PATH)

        val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"
        val items = ArrayList<RecordingInfo>()
        context.contentResolver.query(
            collection,
            projection.toTypedArray(),
            null,
            null,
            sortOrder,
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val dateCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
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
                val relPath = if (pathCol >= 0) cursor.getString(pathCol) ?: "" else ""
                items.add(RecordingInfo(uri, name, relPath, date))
            }
        }
        return items
    }

    /** content:// URI의 바이트를 캐시 임시파일로 복사하고 그 파일을 돌려준다. 실패 시 null. */
    fun copyToCache(context: Context, uriString: String): File? = runCatching {
        val uri = Uri.parse(uriString)
        val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: return null
        val temp = File.createTempFile("call_", ".audio", context.cacheDir)
        temp.writeBytes(bytes)
        temp
    }.getOrNull()
}
