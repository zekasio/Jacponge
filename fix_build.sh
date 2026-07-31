#!/bin/bash
set -e

WORKSPACE=/workspaces/Jacponge
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$WORKSPACE/android_sdk
export PATH=$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$WORKSPACE/flutter/bin:$PATH

echo "Creating standard Flutter scaffold..."
cd $WORKSPACE
flutter create --platforms=android --org com.jacponge liquid_clean_app

echo "Copying custom code..."
# Copy custom lib files
cp $WORKSPACE/liquid_clean_flutter/lib/*.dart $WORKSPACE/liquid_clean_app/lib/

# Copy pubspec
cp $WORKSPACE/liquid_clean_flutter/pubspec.yaml $WORKSPACE/liquid_clean_app/

# Copy custom MainActivity
mkdir -p $WORKSPACE/liquid_clean_app/android/app/src/main/kotlin/com/jacponge/liquid_clean_app/
# Wait, flutter create with org com.jacponge creates MainActivity in com.jacponge.liquid_clean_app
# So I'll just write the custom Kotlin file directly there to ensure package name matches.

cat << 'EOF' > $WORKSPACE/liquid_clean_app/android/app/src/main/kotlin/com/jacponge/liquid_clean_app/MainActivity.kt
package com.jacponge.liquid_clean_app

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
EOF

# Update AndroidManifest to add permissions
sed -i '/<application/i \
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>\
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />\
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>\
    <uses-permission android:name="android.permission.VIBRATE"/>\
' $WORKSPACE/liquid_clean_app/android/app/src/main/AndroidManifest.xml

# Update build.gradle to ensure minSdk is at least 21 for the plugins (e.g. photo_manager requires higher minsdk)
sed -i 's/flutter.minSdkVersion/21/g' $WORKSPACE/liquid_clean_app/android/app/build.gradle

echo "Building APK..."
cd $WORKSPACE/liquid_clean_app
flutter pub get
flutter build apk --release

echo "Build complete! APK should be in liquid_clean_app/build/app/outputs/flutter-apk/"
cp build/app/outputs/flutter-apk/app-release.apk $WORKSPACE/LiquidClean-PRO.apk
