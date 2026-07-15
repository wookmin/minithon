package com.minihackathon.senior_needs

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import androidx.work.BackoffPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkRequest
import androidx.work.workDataOf
import java.util.concurrent.TimeUnit

/**
 * 통화 상태 변화를 받아, 통화가 끝나면(IDLE):
 * 1. 백그라운드 자동 분석 워커([CallAnalysisWorker])를 예약한다(앱 종료 상태에서도 실행).
 * 2. 폴백으로 "탭하면 분석" 안내 알림도 띄운다(워커 실패/절전 대비).
 */
class CallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        when (intent.getStringExtra(TelephonyManager.EXTRA_STATE)) {
            TelephonyManager.EXTRA_STATE_OFFHOOK,
            TelephonyManager.EXTRA_STATE_RINGING -> sawCall = true
            TelephonyManager.EXTRA_STATE_IDLE -> {
                if (sawCall) {
                    sawCall = false
                    scheduleBackgroundAnalysis(context)
                    CallNotifier.notifyCallEnded(context)
                }
            }
        }
    }

    /** 녹음이 저장·색인될 시간을 준 뒤 백그라운드 분석을 실행한다. */
    private fun scheduleBackgroundAnalysis(context: Context) {
        // 통화가 끝난 시각(ms). 녹음 생성 시각과 비교해 과거 녹음 오분석을 막는다.
        val callEndedAt = System.currentTimeMillis()
        val request = OneTimeWorkRequestBuilder<CallAnalysisWorker>()
            .setInitialDelay(RECORDING_WRITE_DELAY_SECONDS, TimeUnit.SECONDS)
            .setInputData(workDataOf(KEY_CALL_ENDED_AT to callEndedAt))
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS,
            )
            .build()
        // 중복 broadcast로 인한 중복 분석을 막기 위해 유니크 워크(KEEP)로 예약한다.
        WorkManager.getInstance(context.applicationContext)
            .enqueueUniqueWork(WORK_NAME, ExistingWorkPolicy.KEEP, request)
    }

    companion object {
        const val KEY_CALL_ENDED_AT = "callEndedAt"
        private var sawCall = false
        private const val RECORDING_WRITE_DELAY_SECONDS = 8L
        private const val WORK_NAME = "call_analysis"
    }
}
