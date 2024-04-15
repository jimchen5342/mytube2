import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:external_path/external_path.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool permission = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
            const PlatformWebViewControllerCreationParams());

      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // context.read<WebviewManager>().changeLoadingProgress(progress);
              print("onProgress: $progress");
            },
            onPageStarted: (String url) {
              // context.read<WebviewManager>().changeLoadingStatus(true);
              print("onPageStarted: $url");
            },
            onPageFinished: (String url) {
              print("onPageFinished: $url");
            },
            onWebResourceError: (WebResourceError error) {
             
            },
            onNavigationRequest: (NavigationRequest request) {
              // if (request.url.startsWith('https://www.youtube.com/')) {
              //   debugPrint('blocking navigation to ${request.url}');
              //   return NavigationDecision.prevent;
              // }
              Fluttertoast.showToast(
                  msg: 'allowing navigation to ${request.url}',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0
              );
              
              print('allowing navigation to ${request.url}');
              return NavigationDecision.navigate;
            },
            onUrlChange: (UrlChange change) {
              print('url change to ${change.url}');
            },
            onHttpAuthRequest: (HttpAuthRequest request) {
              // openDialog(request);
            },
          ),
        )
        ..loadRequest(Uri.parse("https://m.youtube.com/"));

      _controller = controller;
      // _controller.runJavaScript(javaScript)

      await initial();
    });
  }

  initial() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;

    Map<Permission, PermissionStatus> statuses = await [
          build.version.sdkInt < 30 
          ? Permission.storage
          : Permission.manageExternalStorage
    ].request();
    var status = build.version.sdkInt < 30 
      ? await Permission.storage.status
      : await Permission.manageExternalStorage.status;
    permission = status.isGranted;
    setState(() {});
    // writeFile();
  }

  writeFile() async { // 測好了，可以用
    var path = await ExternalPath.getExternalStorageDirectories();
    var file = File('${path[0]}/counter.txt');

    file.writeAsString('jim'); 
    /* 測好了，可以用
    var path = await ExternalPath.getExternalStorageDirectories();
    print("path: ${path[0]}");
    var path2 = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_MUSIC);
    print("DIRECTORY_MUSIC: ${path2}");
    */
  }

  @override
  void reassemble() async { // develope mode
    super.reassemble();
    // initial();
    debugPrint("test");

    Future.delayed(const Duration(milliseconds: 100), () {
      
        // _controller.loadRequest(Uri.parse("https://api.flutter.dev/flutter/dart-async/Future/timeout.html"));
    }); 
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: (permission == false)  ? null : WebViewWidget(controller: _controller)
    );
  }
}