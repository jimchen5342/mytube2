package com.flutter.mytube2;

import android.util.Log;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.ryanheise.audioservice.AudioServiceActivity;

public class MainActivity extends AudioServiceActivity {
    String TAG = "MyTube2";
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(
                flutterEngine.getDartExecutor(),
                "com.flutter/MethodChannel")
                .setMethodCallHandler(mMethodHandle);

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    MethodChannel.MethodCallHandler mMethodHandle = new MethodChannel.MethodCallHandler() {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
             if(call.method.equals("lock")) {
                 Log.i(TAG, call.arguments.toString());

                 WindowManager.LayoutParams layoutParams = getWindow().getAttributes();
                 layoutParams.screenBrightness = 0.0f;
                 getWindow().setAttributes(layoutParams);

                 result.success("OK");
             }
             else if(call.method.equals("information")) {

             } else {
                 result.notImplemented();
             }
        }
    };
}
