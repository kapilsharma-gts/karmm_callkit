package com.connectycube.flutter.connectycube_flutter_call_kit_example

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity


class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        /*Handler(Looper.getMainLooper()).postDelayed({
            checkBattery()
        }, 2000)*/
    }


    private fun checkBattery() {
        if (!isIgnoringBatteryOptimizations(this) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val name = "karmm callkit"
            Toast.makeText(
                applicationContext,
                "Battery optimization -> All apps -> $name -> Don't optimize",
                Toast.LENGTH_LONG
            ).show()

            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            startActivity(intent)
        }
    }

    private fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val pwrm =
            context.applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        val name = context.applicationContext.packageName
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return pwrm.isIgnoringBatteryOptimizations(name)
        }
        return true
    }
}