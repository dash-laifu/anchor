package com.dash_laifu.anchor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup native alarm service
        NativeAlarmService.setupNativeAlarms(flutterEngine, this)
    }
}
