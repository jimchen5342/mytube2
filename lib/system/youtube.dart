import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// https://cloud.tencent.com/developer/ask/sof/106892920

class YouTube {
  var yt = YoutubeExplode();
  String url = "Dpp1sIL1m5Q";
  var streams;

  YouTube({required this.url}) {
    this.url = YouTube.parselKey(this.url);
    print("${this.url}");
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
      throw e;
    }
  }

  getManifest() async {
    var manifest = await yt.videos.streamsClient.getManifest(url);
    print("${manifest}");
  }
}