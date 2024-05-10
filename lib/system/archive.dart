import 'package:external_path/external_path.dart';
import 'dart:io';

class Archive {
  static Future<String> root() async {
    var pathes = await ExternalPath.getExternalStorageDirectories();
    return pathes[0];
  }

  static Future<String> home() async {
    var path = "${await Archive.root()}/MyTube2";
    if(! await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }
    return "$path/";
  }

  static String readText(String fileName) {
    String s = "";

    File file = File(fileName);
    if(file.existsSync()) {
      s = file.readAsStringSync();
    }
    return s;
  }

  static  writeText(String fileName, String txt) {
    File file = File(fileName);
    file.writeAsStringSync(txt);
  }
}