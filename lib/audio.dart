import 'package:flutter/material.dart';

class Audio extends StatefulWidget {
  const Audio({Key? key}) : super(key: key);
  @override
  _AudioState createState() => _AudioState();
}

class _AudioState extends State<Audio>{
  String href = "";
  int local = -1;
  Map<String, dynamic> playItem = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var arg = ModalRoute.of(context)!.settings.arguments;
      href = "$arg";
      setState(() { });
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
   
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}