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
      await changeScreenBrightness("1");
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
  dispose() async {
    super.dispose();
    await changeScreenBrightness("0");
  }

  changeScreenBrightness(state) async {
    try {
      var result = await platform.invokeMethod('ScreenBrightness', state);
    } on PlatformException catch (e) {
      print("Failed to show toast: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // onPopInvoked: (bool didPop) async {
      //   if (didPop) {
      //     return;
      //   }
      // },
      child: Container(
        height: double.infinity, width: double.infinity,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            button(),
            const SizedBox(height: 30,)
          ]
        ),
      )
    );
  }

  Widget button() {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.red, width: 1),
      ),
      child: InkWell(
        onLongPress: () {
          Navigator.pop(context);
        },
        // onTap: () async {
        // },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 60),
          child: const Text("長按解鎖",
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
            ),
          )
        )
      )
    );
  }
}