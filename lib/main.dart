import 'package:flutter/material.dart';
import 'package:mytube2/home.dart';
import 'package:mytube2/player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        // debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/home',
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => Home(),
          '/player': (BuildContext context) => Player(),
        },
      )
    );
  }
}
// bool dirty = await Navigator.pushNamed(context, '/swing', arguments: "") as bool;