import 'package:external_path/external_path.dart';
import 'dart:io';
/*
await ExternalPath.getExternalStorageDirectories();

await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_MUSIC);
ExternalPath.DIRECTORY_PICTURES
ExternalPath.DIRECTORY_DOWNLOADS
ExternalPath.DIRECTORY_DCIM
ExternalPath.DIRECTORY_DOCUMENTS
 */

class Archive {
  static Future<String> root() async {
    var pathes = await ExternalPath.getExternalStorageDirectories();
    return "${pathes[0]}";
  }

  static Future<String> home() async {
    var path = (await Archive.root()) + "/MyTube2";
    if(! await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }
    return path + "/";
  }

  writeFile() async { // 測好了，可以用
  /*
    var path = await ExternalPath.getExternalStorageDirectories();
    var file = File('${path[0]}/counter.txt');

    file.writeAsString('jim'); 
    */
    
    /* 測好了，可以用
    var path = await ExternalPath.getExternalStorageDirectories();
    print("path: ${path[0]}");
    var path2 = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_MUSIC);
    print("DIRECTORY_MUSIC: ${path2}");
    */
  }

}

