package com.minihackathon.senior_needs

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * 통화 종료 후 헤드리스 [FlutterEngine]을 부팅해 Dart 진입점 `backgroundCallAnalysisMain`을 실행한다.
 * 앱이 완전히 종료된 상태에서도 WorkManager가 이 워커를 실행하므로 백그라운드 자동 분석이 가능하다.
 *
 * Dart 쪽과 `senior_needs/bg_analysis` 채널로 통신:
 * - getPending: 최근 녹음 메타데이터 목록 전달
 * - readBytes(uri): 매칭된 녹음 바이트를 캐시 임시파일로 복사 후 경로 반환
 * - done: 분석 완료 신호 → 엔진 종료 + 임시파일 정리
 */
class CallAnalysisWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    override fun doWork(): Result {
        val callEndedAt = inputData.getLong(CallReceiver.KEY_CALL_ENDED_AT, 0L)
        val recordings = RecordingStore.recent(applicationContext, RECENT_LIMIT)
        if (recordings.isEmpty()) return Result.success()

        val latch = CountDownLatch(1)
        val mainHandler = Handler(Looper.getMainLooper())
        val temps = ArrayList<File>()
        var engine: FlutterEngine? = null
        // Dart가 일시적 실패(503 등)를 알리면 재시도한다.
        val shouldRetry = AtomicBoolean(false)

        mainHandler.post {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)

            val flutterEngine = FlutterEngine(applicationContext)
            engine = flutterEngine

            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL,
            )
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPending" -> {
                        val list = recordings.map {
                            mapOf(
                                "uri" to it.uri,
                                "name" to it.name,
                                "relativePath" to it.relativePath,
                                "dateAdded" to it.dateAdded,
                            )
                        }
                        result.success(
                            mapOf(
                                "recordings" to list,
                                "callEndedAt" to callEndedAt,
                            ),
                        )
                    }
                    "readBytes" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.success(null)
                        } else {
                            val temp = RecordingStore.copyToCache(applicationContext, uri)
                            if (temp != null) temps.add(temp)
                            result.success(temp?.absolutePath)
                        }
                    }
                    "done" -> {
                        shouldRetry.set(call.argument<Boolean>("retry") ?: false)
                        result.success(true)
                        latch.countDown()
                    }
                    else -> result.notImplemented()
                }
            }

            flutterEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    ENTRYPOINT,
                ),
            )
        }

        // Dart의 done 신호 또는 타임아웃까지 이 워커 스레드를 유지한다.
        runCatching { latch.await(TIMEOUT_MINUTES, TimeUnit.MINUTES) }

        mainHandler.post {
            engine?.destroy()
            temps.forEach { file -> runCatching { file.delete() } }
        }
        // 일시적 실패면 backoff 재시도(최대 시도 초과 시 포기).
        return if (shouldRetry.get() && runAttemptCount < MAX_ATTEMPTS) {
            Result.retry()
        } else {
            Result.success()
        }
    }

    private companion object {
        const val CHANNEL = "senior_needs/bg_analysis"
        const val ENTRYPOINT = "backgroundCallAnalysisMain"
        const val RECENT_LIMIT = 10
        const val TIMEOUT_MINUTES = 3L
        const val MAX_ATTEMPTS = 3
    }
}
