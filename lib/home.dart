import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:external_path/external_path.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      await initial();

      final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
            const PlatformWebViewControllerCreationParams());

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // context.read<WebviewManager>().changeLoadingProgress(progress);
          },
          onPageStarted: (String url) {
            // context.read<WebviewManager>().changeLoadingStatus(true);
          },
          onPageFinished: (String url) {
            // context.read<WebviewManager>().changeLoadingStatus(false);
          },
          onWebResourceError: (WebResourceError error) {
            // context
            //     .read<DialogManager>()
            //     .setErrorDialog(error, DialogType.webviewError);
          },
        ),
      )
      ..loadRequest(Uri.parse("https://www.youtube.com"));

    _controller = controller;
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
      child: (permission == false)  ? null : web()
    );
  }

  Widget web() {
    return WebViewWidget(controller: _controller);
  }
}