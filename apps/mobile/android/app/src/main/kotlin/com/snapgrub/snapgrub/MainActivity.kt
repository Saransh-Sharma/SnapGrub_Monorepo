package com.snapgrub.snapgrub

import android.net.Uri
import android.os.PowerManager
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "snapgrub/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isLowPowerMode" -> {
                        val power = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(power.isPowerSaveMode)
                    }
                    "supportsAlternateIcons" -> result.success(false)
                    "setAlternateIcon" -> result.success(false)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "snapgrub/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("invalid_image", "A label photo path is required.", null)
                    return@setMethodCallHandler
                }
                val image = try {
                    InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                } catch (error: Exception) {
                    result.error("invalid_image", error.localizedMessage, null)
                    return@setMethodCallHandler
                }
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                recognizer.process(image)
                    .addOnSuccessListener { recognized -> result.success(recognized.text) }
                    .addOnFailureListener { error ->
                        result.error("mlkit_ocr", error.localizedMessage, null)
                    }
                    .addOnCompleteListener { recognizer.close() }
            }
    }
}
