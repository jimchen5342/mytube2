import 'package:flutter/material.dart';
import 'package:mytube2/audio.dart';
import 'package:mytube2/system/youtube.dart';

class Player extends StatefulWidget {
  const Player({Key? key}) : super(key: key);
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player>  with WidgetsBindingObserver{
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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
  }
    @override
  void didChangeAppLifecycleState(AppLifecycleState state)  {
    switch (state) {
      case AppLifecycleState.paused:
        // if(local != 1 && this.controller!.noAD == false) {
        //   timer = Timer(Duration(minutes: 30), () { // broswer.dart 要 pause
        //     Navigator.pop(context);
        //   });          
        // }
        break;
      case AppLifecycleState.resumed:
        // if(timer != null) timer.cancel();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon( Icons.arrow_back_ios_sharp, color: Colors.white,),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('MyTube2', 
            style: TextStyle(
              color: Colors.white,
              // fontSize: 20,
            )
          ),
          // actions: [],
          backgroundColor: Colors.blue, 
        ),
        body: Container(child: Text(href, 
            style: TextStyle(
              // color: Colors.white,
              // fontSize: 20,
            )
          )
        ), 
      )
    );
  }

}