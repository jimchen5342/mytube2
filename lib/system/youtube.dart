import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// https://cloud.tencent.com/developer/ask/sof/106892920

class YouTube {
  var yt = YoutubeExplode();
  String url = "Dpp1sIL1m5Q";

  static parselKey(String key){
    return key.replaceAll("https://m.youtube.com/watch?v=", "");
  }

  Future<void> getData() async {
    Video video = await yt.videos.get('https://youtube.com/watch?v=${url}'); // Returns a Video instance.
    print("getData: ${video.id}, duration: ${video.duration}");

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
      // streams = manifest.audioOnly;
      print(manifest);
    } catch(e) {
      print(e);
      throw e;
    }
  }

  getManifest() async {
    var manifest = await yt.videos.streamsClient.getManifest(url);
    print("${manifest}");
  }
}