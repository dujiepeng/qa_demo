package com.example.qa_flutter

import android.os.FileObserver
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SDK_LOG_UPDATE_CHANNEL,
        ).setStreamHandler(SdkLogUpdateStreamHandler())
    }

    companion object {
        private const val SDK_LOG_UPDATE_CHANNEL = "qa_flutter/sdk_log_updates"
    }
}

private class SdkLogUpdateStreamHandler : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var fileObserver: FileObserver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val logPath = arguments as? String
        if (logPath.isNullOrBlank()) {
            events.error("invalid_args", "log path is required", null)
            return
        }

        val targetFile = File(logPath)
        val parentDirectory = targetFile.parentFile
        if (parentDirectory == null || !parentDirectory.exists()) {
            events.error("invalid_path", "log parent directory is unavailable", null)
            return
        }

        stopWatching()
        val targetName = targetFile.name
        fileObserver = object : FileObserver(
            parentDirectory.absolutePath,
            MODIFY or
                CLOSE_WRITE or
                MOVED_TO or
                CREATE or
                DELETE or
                FileObserver.DELETE_SELF or
                FileObserver.MOVE_SELF,
        ) {
            override fun onEvent(event: Int, path: String?) {
                if (!shouldEmitEvent(event, path, targetName)) {
                    return
                }

                mainHandler.post {
                    events.success(
                        mapOf(
                            "event" to event,
                            "path" to (path ?: targetName),
                        ),
                    )
                }
            }
        }.also {
            it.startWatching()
        }
    }

    override fun onCancel(arguments: Any?) {
        stopWatching()
    }

    private fun shouldEmitEvent(event: Int, changedPath: String?, targetName: String): Boolean {
        val normalizedEvent = event and FileObserver.ALL_EVENTS
        if (normalizedEvent == 0) {
            return false
        }
        if (changedPath == null) {
            return normalizedEvent == FileObserver.DELETE_SELF ||
                normalizedEvent == FileObserver.MOVE_SELF
        }
        return changedPath == targetName
    }

    private fun stopWatching() {
        fileObserver?.stopWatching()
        fileObserver = null
    }
}
