package com.jacponge.liquidclean

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jacponge.liquidclean/trash"
    private val TRASH_REQUEST_CODE = 101
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "trashPhotos") {
                val urisList = call.argument<List<String>>("uris")
                if (urisList != null) {
                    pendingResult = result
                    requestTrash(urisList)
                } else {
                    result.error("INVALID_ARGS", "URIs list is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestTrash(uriStrings: List<String>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val uris = uriStrings.map { Uri.parse(it) }
            try {
                // Native OS Trash Intent (Android 11+)
                val intent = MediaStore.createTrashRequest(contentResolver, uris, true)
                startIntentSenderForResult(intent.intentSender, TRASH_REQUEST_CODE, null, 0, 0, 0, null)
            } catch (e: Exception) {
                pendingResult?.error("TRASH_ERROR", e.message, null)
                pendingResult = null
            }
        } else {
            pendingResult?.error("UNSUPPORTED_OS", "Trash request requires Android 11 (API 30) or higher.", null)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == TRASH_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }
}
