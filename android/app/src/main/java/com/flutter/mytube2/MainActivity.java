package com.flutter.mytube2;

import android.os.Build;
import android.provider.Settings;
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
    int brightness = 0;
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
            if(call.method.equals("ScreenBrightness")) {
               if(call.arguments.toString().equals("1")) {
                   brightness = getScreenBrightness();
                   setScreenBrightness(0);
               } else {
                   setScreenBrightness(brightness);
               }
               result.success("OK");
            }
            else if(call.method.equals("information")) {

            } else {
                result.notImplemented();
            }
        }
    };

    int getScreenBrightness() {
        int brightness = 0;
        try {
            // 讀取當前系統亮度設置（範圍是 0 - 255）
            brightness = Settings.System.getInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS);
        } catch (Settings.SettingNotFoundException e) {
            e.printStackTrace();
        }
        return brightness;
    }

    void setScreenBrightness(int brightness) {
        WindowManager.LayoutParams layoutParams = getWindow().getAttributes();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.CUPCAKE) {
            layoutParams.screenBrightness = brightness / 255.0f;
        }
        getWindow().setAttributes(layoutParams);


        /* 還沒試過
        // 設定亮度範圍必須在 0 到 255 之間
        if (brightness < 0) brightness = 0;
        if (brightness > 255) brightness = 255;

        WindowManager.LayoutParams layoutParams = getWindow().getAttributes();
        layoutParams.screenBrightness = brightness / 255.0f;
        getWindow().setAttributes(layoutParams);

        // 更新系統亮度設置
        Settings.System.putInt(
                getWindow().getContext().getContentResolver(),
                Settings.System.SCREEN_BRIGHTNESS,
                brightness
        );

         */
    }
}
