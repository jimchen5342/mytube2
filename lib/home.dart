import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:device_info/device_info.dart';

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
      print(_deviceData);

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