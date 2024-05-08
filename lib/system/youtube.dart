import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// https://cloud.tencent.com/developer/ask/sof/106892920

import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mytube2/system/module.dart';

class YouTube {
  var yt = YoutubeExplode();
  String url = "Dpp1sIL1m5Q";
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

  Future<void> execute(var audio, {required Function(int) onProcessing}) async {
    stop = false;
    try {
      String path = await Archive.home();
      String mb = "${audio.size.totalMegaBytes.toStringAsFixed(2) + 'MB'}";
      if(Directory(path).existsSync() == false)
        Directory(path).createSync();
      
      String fileName = '${path}youtube.${audio.container.name.toString()}';
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
      }
    } catch(e) {
      print(e);
      throw e;
    }
  }
  removeFile(String fileName) {
    var file = File(fileName);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}