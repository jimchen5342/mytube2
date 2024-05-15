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

  static Future<List<String>> getFiles(String directoryPath) async {
    List<String> list = [];
    var dirList1 = Directory(directoryPath).list();
    await for (final FileSystemEntity f1 in dirList1) {
      if(f1 is File && isMusic(f1)) {
        var paths = f1.path.split('/');
        String title = paths[paths.length - 1];
        list.add(title);
      }
    }
    // return list..sort();
    return list..sort((b, a) => a.compareTo(b));
  }

  static bool isMusic(File file) {
    return file.path.toLowerCase().endsWith('.mp3') 
      || file.path.toLowerCase().endsWith('.mp4')
      || file.path.toLowerCase().endsWith('.3gpp')
      || file.path.toLowerCase().endsWith('.webm');
  }

}