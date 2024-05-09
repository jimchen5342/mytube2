import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// https://cloud.tencent.com/developer/ask/sof/106892920

import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mytube2/system/module.dart';

class YouTube {
  var yt = YoutubeExplode();
  String url = "Dpp1sIL1m5Q", audioName = "", mb = "";
  bool stop = false;

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
    // duration: , id: ,  title: , author: , channelId: ,  publishDate: , description: 
  }

  getAudioStream() async {
    var manifest = await yt.videos.streamsClient.getManifest(url);
    return manifest.audioOnly.toList();
  }

  dispose(){
    stop = true;
    yt.close();
  }

  Future<String> execute(var audio, {required Function(int) onProcessing}) async {
    stop = false;
    String fileName = "";
    try {
      String path = await Archive.home();
      mb = "${audio.size.totalMegaBytes.toStringAsFixed(2) + 'MB'}";
      if(Directory(path).existsSync() == false)
        Directory(path).createSync();
      
      fileName = '${path}youtube.${audio.container.name.toString()}';
      audioName = fileName;
      var file = File(fileName);
      removeFile(fileName);
      // print("fileName: $fileName");

      var audioStream = yt.videos.streamsClient.get(audio); 
      var output = file.openWrite(mode: FileMode.writeOnlyAppend);
      var len = audio.size.totalBytes;
      var count = 0, oldValue = -1;

      await for (final data in audioStream) {
        count += data.length;
        var progress = ((count / len) * 100).ceil();
        if(stop == false) {
          if(oldValue != progress) {
            onProcessing(progress);            
          }
          oldValue = progress;
        } else {
          break;
        }
        output.add(data);
      }
      if(stop == true) {
        removeFile(fileName);
      } else {
        await output.close();
        return fileName;
      }
    } catch(e) {
      print(e);
      throw e;
    }
    return fileName;
  }
  removeFile(String fileName) {
    if(fileName.contains("youtube.")) {
      var i = fileName.lastIndexOf(".");
      List f1 = ['3gpp', 'webm', 'mp4'];
      String f2 = fileName.substring(0, i + 1);
      for(var i = 0; i < f1.length; i++) {
        String fn = f2 + f1[i];
        var f3 = File(fn);
        if (f3.existsSync()) {
          f3.deleteSync();
        }
      }
    } else {
      var file = File(fileName);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }
}