import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:device_info_plus/device_info_plus.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var status = await Permission.storage.status;
      if (status.isGranted) {
        // 還沒寫
      }
    });
  }

  @override
  void reassemble() async { // develope mode
    super.reassemble();
    var status = await Permission.manageExternalStorage.status; // Android 11 (API 30)
      if (status.isGranted) {
        // 還沒寫
        
      }
      print("manageExternalStorage: " + status.isGranted.toString());

      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      Map<String, dynamic> _deviceData = <String, dynamic>{};
      print(_readAndroidBuildData(await deviceInfoPlugin.androidInfo),);

  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    // https://pub.dev/packages/device_info_plus/example
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'serialNumber': build.serialNumber,
      // 'isLowRamDevice': build.isLowRamDevice,
    };
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
    return Container(child: Text('單腳擺動',
            style: TextStyle( color:Colors.white,)
    ));
  }
}