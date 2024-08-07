import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class DialogLock extends StatefulWidget {
  DialogLock({Key? key}) : super(key: key);
  @override
  _DialogLockState createState() => _DialogLockState();
}

class _DialogLockState extends State<DialogLock> {
  static const platform = MethodChannel('com.flutter/MethodChannel');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await changeState();
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  void reassemble() async { // develope mode
    super.reassemble();
  }

  @override
  dispose() {
    super.dispose();
  }

  changeState() async {
    try {
      var result = await platform.invokeMethod('lock', '1');
      print(result);
    } on PlatformException catch (e) {
      print("Failed to show toast: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(height: double.infinity, width: double.infinity,
      color: Colors.red,
      
    );
  }
}