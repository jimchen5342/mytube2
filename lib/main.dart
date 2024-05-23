import 'package:flutter/material.dart';
import 'package:mytube2/home.dart';
import 'package:mytube2/player.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(const MyApp());
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..userInteractions = false
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..loadingStyle = EasyLoadingStyle.dark
    ..toastPosition = EasyLoadingToastPosition.bottom
    // ..loadingStyle = EasyLoadingStyle.custom
    // ..backgroundColor = Colors.green
    // ..indicatorColor = Colors.yellow
    // ..textColor = Colors.yellow
    // dismissOnTap
    ..maskType = EasyLoadingMaskType.custom
    ..maskColor = Colors.black12.withOpacity(0.3);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/home',
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => const Home(),
          '/player': (BuildContext context) => const Player(),
        },
        builder: EasyLoading.init(),
      )
    );
  }
}
// bool dirty = await Navigator.pushNamed(context, '/swing', arguments: "") as bool;