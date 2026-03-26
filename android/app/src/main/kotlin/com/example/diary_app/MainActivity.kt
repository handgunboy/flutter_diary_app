package com.example.diary_app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        // 尝试设置为最高刷新率
        window?.let { window ->
            val params = window.attributes
            params.preferredDisplayModeId = 0 // 使用默认模式，让系统选择最高可用刷新率
            window.attributes = params
        }
    }
}
