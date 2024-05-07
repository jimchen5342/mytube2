import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// https://cloud.tencent.com/developer/ask/sof/106892920

import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mytube2/system/module.dart';

class YouTube {
  var yt = YoutubeExplode();
  String url = "Dpp1sIL1m5Q";

  YouTube({required this.url}) {
    url = YouTube.parselKey(url);
    // print("${this.url}");
  }

  static parselKey(String key){
    return key.replaceAll("https://m.youtube.com/watch?v=", "").replaceAll("/watch?v=", "");
  }

  Future<dynamic> getData() async {
    Video video = await yt.videos.get('https://youtube.com/watch?v=${url}');
    return video;
    /*
    duration: 
    id: , 
    title: , 
    author: , 
    channelId: , 
    publishDate: , 
    description: 
    */
  }

  getAudioStream() async {
    try {
      // mode = Mode.audio;  mb = ""; qualityHigh = -1; qualityLow = -1; qualityMedium = -1; selected = -1;
      var manifest = await yt.videos.streamsClient.getManifest(url);
      return manifest.audioOnly.toList();
    } catch(e) {
      rethrow;
    }
  }

  dispose(){
    yt.close();
  }

  Future<void> execute({String fileName = "", String folder = "", required Function(int) onProcessing}) async {
    // stop = false;
    // try {
    //   mb = "${audio.size.totalMegaBytes.toStringAsFixed(2) + 'MB'}";
    //   fileName = ((fileName.length == 0) ? 'youtube' : fileName);
    //   if(fileName.indexOf(".") == -1)
    //     fileName += '.${audio.container.name.toString()}';

    //   path = await Download.folder();
    //   // print("MyTube: $path");
    //   if(Directory(path).existsSync() == false)
    //     Directory(path).createSync();

    //   if(folder.length > 0 && Directory(path + '/$folder').existsSync() == false) {
    //       Directory(path + '/$folder').createSync();
    //   }
      
    //   this.fileName = path + (folder.length > 0 ? '/$folder' : '') + '/$fileName';
    //   var file = File(this.fileName);
    //   removeFile();

    //   var audioStream = yt.videos.streamsClient.get(audio); 
    //   var output = file.openWrite(mode: FileMode.writeOnlyAppend);
    //   var len = audio.size.totalBytes;
    //   var count = 0;

    //   await for (final data in audioStream) {
    //     count += data.length;
    //     var progress = ((count / len) * 100).ceil();
    //     if(stop == false) {
    //       onProcessing(progress);
    //     } else {
          
    //       break;
    //     }
    //     output.add(data);
    //   }
    //   if(stop == true)
    //     removeFile();
    //   else 
    //     await output.close();
    // } catch(e) {
    //   print(e);
    //   throw e;
    // }
  }
  removeFile(String fileName) async {
    String path = await Archive.home();
    var file = File(fileName);
    if(fileName.startsWith("youtube.")) {
      List f1 = ['3gpp', 'webm', 'mp4'];
      for(var i = 0; i < f1.length; i++) {
        var f2 = File('$path/youtube.${f1[i]}');
        if (f2.existsSync()) {
          f2.deleteSync();
        }
      }
    } else if (file.existsSync()) {
      file.deleteSync();
    }
  }
}