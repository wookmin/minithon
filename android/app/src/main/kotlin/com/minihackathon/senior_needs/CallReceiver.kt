package com.minihackathon.senior_needs

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager

/** 통화 상태 변화를 받아, 통화가 끝나면(IDLE) 최근 녹음 분석 알림을 띄운다. */
class CallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        when (intent.getStringExtra(TelephonyManager.EXTRA_STATE)) {
            TelephonyManager.EXTRA_STATE_OFFHOOK,
            TelephonyManager.EXTRA_STATE_RINGING -> sawCall = true
            TelephonyManager.EXTRA_STATE_IDLE -> {
                if (sawCall) {
                    sawCall = false
                    CallNotifier.notifyCallEnded(context)
                }
            }
        }
    }

    companion object {
        private var sawCall = false
    }
}
