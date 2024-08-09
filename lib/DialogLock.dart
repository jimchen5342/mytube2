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

  changeState() async { // 沒有效
    try {
      var result = await platform.invokeMethod('lock', '1');
      print(result);
    } on PlatformException catch (e) {
      print("Failed to show toast: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity, width: double.infinity,
      color: Colors.transparent,
            // decoration: BoxDecoration(
      //   border: Border.all(color: Colors.blueAccent),
      //   borderRadius: BorderRadius.circular(10),
      // ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Expanded(flchild: Container()),
          button(),
          const SizedBox(height: 30,)
        ]
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: const Text( "長按解鎖",
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