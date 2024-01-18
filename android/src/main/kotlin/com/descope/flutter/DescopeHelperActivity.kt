package com.descope.flutter

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle

const val PENDING_INTENT_KEY = "pendingIntent"
const val REQUEST_CODE = 4327

class DescopeHelperActivity : Activity() {
    private var resultPending = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        @Suppress("DEPRECATION")
        val pendingIntent: PendingIntent? = intent?.getParcelableExtra(PENDING_INTENT_KEY)
        if (pendingIntent == null) {
            finish()
            return
        }

        if (resultPending) {
            finish()
            return
        }

        resultPending = true
        startIntentSenderForResult(pendingIntent.intentSender, REQUEST_CODE, null, 0, 0, 0, null)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        resultPending = false
        activityHelper.onActivityResult(resultCode, data)
        finish()
    }
}

// Helper

interface ActivityHelper {
    fun startHelperActivity(context: Context, pendingIntent: PendingIntent, callback: (Int, Intent?) -> Unit)
    fun onActivityResult(resultCode: Int, intent: Intent?)
}

internal val activityHelper = object : ActivityHelper {
    private var callback: (Int, Intent?) -> Unit = { _, _ -> }

    override fun startHelperActivity(context: Context, pendingIntent: PendingIntent, callback: (Int, Intent?) -> Unit) {
        this.callback = callback
        (context as? Activity)?.let { activity ->
            activity.startActivity(Intent(activity, DescopeHelperActivity::class.java).apply { putExtra(PENDING_INTENT_KEY, pendingIntent) })
            return
        }
        throw Exception("Passkeys require the given context to be an Activity")
    }

    override fun onActivityResult(resultCode: Int, intent: Intent?) {
        callback(resultCode, intent)
    }
}
