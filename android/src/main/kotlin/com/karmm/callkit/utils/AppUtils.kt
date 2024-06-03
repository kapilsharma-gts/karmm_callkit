package com.karmm.callkit.utils

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context

/**
 * Identify if the application is currently in a state where user interaction is possible. This
 * method is called when a remote message is received to determine how the incoming message should
 * be handled.
 *
 * @param context context.
 * @return True if the application is currently in a state where user interaction is possible,
 * false otherwise.
 */
fun isApplicationForeground(context: Context): Boolean {
    var keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE)
    if (keyguardManager == null) {
        return false
    } else {
        keyguardManager = keyguardManager as KeyguardManager
    }

    if (keyguardManager.isKeyguardLocked) {
        return false
    }

    var activityManager = context.getSystemService(Context.ACTIVITY_SERVICE)
    if (activityManager == null) {
        return false
    } else {
        activityManager = activityManager as ActivityManager
    }


    val appProcesses = activityManager.runningAppProcesses ?: return false
    val packageName = context.packageName
    for (appProcess in appProcesses) {
        if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            && appProcess.processName == packageName
        ) {
            return true
        }
    }
    return false
}

// check is app is active or not
fun isAppIsInBackground(context: Context): Boolean {
    var isInBackground = true
    val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    val runningProcesses = am.runningAppProcesses
    for (processInfo in runningProcesses) {
        if (processInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
            for (activeProcess in processInfo.pkgList) {
                if (activeProcess == context.packageName) {
                    isInBackground = false
                }
            }
        }
    }
    return isInBackground
}