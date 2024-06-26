import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mytube2/system/youtube.dart';
import 'package:mytube2/system/system.dart';
import 'package:mytube2/system/module.dart';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

AudioPlayerHandler? _audioHandler;

String home = "";
class Player extends StatefulWidget {
  const Player({Key? key}) : super(key: key);
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player>  with WidgetsBindingObserver{
  String href = "";
  int qualityMedium = -1, processing = -1;
  Map<String, dynamic> playItem = {};
  late YouTube youTube;
  dynamic video;
  List streams = [];
  late PlayList playList;
  bool isPlayList = false;
  Timer? timerChoice;
  int counter = -1;
  bool destroied = false;
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var arg = ModalRoute.of(context)!.settings.arguments;
      href = "$arg";
      // print("href: $href");
      home = await Archive.home();
      playList = PlayList();
      if(playList.datas.isNotEmpty) {
        for(var i = 0; i < playList.datas.length; i++) {
          if(href.contains(playList.datas[i]["id"])) {
            isPlayList = true;
            video = playList.datas[i];
            break;
          }
        }
      }
      if(isPlayList == false) {
        initial();
      } else {
        startToPlayer();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  void reassemble() async { // develope mode
    super.reassemble();
    // initial();
  }

  initial() async {
    await EasyLoading.show(status: 'loading...');
    try {
      youTube = YouTube(url: href);
      video = await youTube.getData();
      streams = await youTube.getAudioStream();
      var size = 0.0, index = 0;
      for(int i = 0; i < streams.length; i++){
        if(streams[i].size.totalMegaBytes == 0) continue;
        // print("MyTube.audio $i: ${streams[i].size.totalMegaBytes.toStringAsFixed(2) + 'MB'} ==");
        if(streams[i].size.totalMegaBytes < size || i == 0) {
          size = streams[i].size.totalMegaBytes;
          index = i;
        }
      }
      if(index > -1) {
        qualityMedium = index;
      }

      setState(() {});
      
      if(index == -1) {
        alert("沒有串流檔");
      } else {
        EasyLoading.dismiss();
        // timerChoice = Timer(Duration(seconds: sec), () => choiceVideo(qualityMedium));
        startTimer();
      }
    } catch(e) {
      await EasyLoading.dismiss();
      if(destroied == false) {
        alert(e.toString());
      }
    } finally {
    }
  }

  @override
  dispose() {
    super.dispose();
    destroied = true;
    WidgetsBinding.instance.removeObserver(this);
    if(isPlayList == false) {
      youTube.dispose();
    }

    if(_audioHandler != null) {
      _audioHandler!.stop();
    }
    stopTimer();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state)  {
    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon( Icons.arrow_back_ios_sharp, color: Colors.white,),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('MyTube2', 
            style: TextStyle(
              color: Colors.white,
              // fontSize: 20,
            )
          ),
          // actions: [],
          backgroundColor: Colors.blue, 
          // backgroundColor: const Color.fromRGBO(192, 25, 33, 0), 
        ),
        body: _buildBody(), 
      )
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded( flex: 1, 
            child: Scrollbar(
              child: SingleChildScrollView(
                child: video == null ? Container() : _buildInformation()
              )
            )
          ),
          if(processing == 100 || isPlayList) 
            _buildPlayerController(),
          if(qualityMedium > -1 && counter > 0)
            Text("$counter 秒後，自動選取第 ${qualityMedium + 1} 個選項!!",style: const TextStyle(
              color: Colors.red,
              fontSize: 22,
            )),
          if(video != null && processing == -1) 
            _buildBtnGrid(),
        ],
      )
    );
  }

  Widget _buildInformation() {    
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("標題：${video["title"]}", 
           style: const TextStyle(
              // color: Colors.white,
              fontSize: 20,
            )
          ),
          const SizedBox(height: 5),
          Text("作者：${video["author"]}", 
           style: const TextStyle(
              // color: Colors.white,
              fontSize: 20,
            )
          ),
          const SizedBox(height: 5),
          Text("日期：${video["publishDate"]}", 
            style: const TextStyle(
              // color: Colors.white,
              fontSize: 20,
            )
          ),
          const SizedBox(height: 5),
          Text("長度：${video["duration"]}", 
            style: const TextStyle(
              // color: Colors.white,
              fontSize: 20,
            )
          ),
          const SizedBox(height: 5),
          if("${video["mb"]}".isNotEmpty) 
            Text("容量：${video["mb"]}", 
              style: const TextStyle(
                  // color: Colors.white,
                  fontSize: 20,
                )
            ),
          if(processing < 100 && processing > -1) // 下載進度
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(height: 30,),
                LinearProgressIndicator(  
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                  value: processing.toDouble() / 100,  
                ),
                Container(height: 10,),
                Text(processing.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                  )
                ),
              ]
            )
        ]
      )
    );
  }

  Widget _buildBtnGrid(){
    double width = MediaQuery.of(context).size.width;
    int w = width < 800 ? 150 : 180;
    int cells = (width / w).ceil();
    return Container(
      // decoration: BoxDecoration(
      //   // border: Border.all(color: Colors.lightBlue)
      // ),
      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0), 
      // padding: EdgeInsets.all(0.0),
      child:  GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cells,
            childAspectRatio: 1.2,
            mainAxisSpacing: 5.0,
            crossAxisSpacing: 5.0,
        ),
        itemCount: streams.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          String mb = "${streams[index].size.totalMegaBytes.toStringAsFixed(1) + 'MB'}";
          Color bg = Colors.grey.shade200, color = Colors.black;
          double fontSize = width < 800 ? 16 : 24;
          if(qualityMedium == index) {
            bg = Colors.green.shade500; 
            color = Colors.white;
          }
          
          return Material(
            color: bg,
            child: InkWell(
              onTap: () async {
                choiceVideo(index);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text( mb,
                    style: TextStyle(
                      color: color,
                      fontSize: fontSize,
                    ),
                  ),
                  Container(height: 2,),
                  Text(streams[index].container.name.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              )
            )
          );
        }
      )
    );
  }

  Widget _buildPlayerController() {
    return Container(
      // decoration: BoxDecoration(
      //   border: Border.all(color: Colors.blueAccent),
      //   borderRadius: BorderRadius.circular(10),
      // ),
      padding: const EdgeInsets.all(5),
      child: _audioHandler == null ? null : 
        Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            _buildSlider(),
          // const SizedBox(height: 5),
            _buildControls()
        ]
      )
    );
  }

  Widget _controllerBtn(IconData iconData, VoidCallback onPressed, {bool visible = true}){
    Widget btn = IconButton(
      icon: Icon(iconData, 
        // color: Colors.white, 
        size: 30),
      onPressed: onPressed,
    );

    return Container(
      width: 60,
      height: 60,
      // decoration: BoxDecoration(
      //   border: Border.all(color: Colors.blueAccent),
      //   borderRadius: BorderRadius.circular(10),
      // ),
      child: visible ? btn : null
    );
  }

  Widget _buildControls() {
    return StreamBuilder<bool>(
      stream: _audioHandler!.playbackState.map((state) => state.playing).distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (playing)
              _controllerBtn(Icons.pause, _audioHandler!.pause)
            else
              _controllerBtn(Icons.play_arrow, _audioHandler!.play),
            _controllerBtn(Icons.stop, _audioHandler!.stop),
          ],
        );
      },
    );
  }

  Widget _buildSlider() {
    return StreamBuilder<Duration>(
      stream: _audioHandler!.currentPosition,
      builder: (context, snapshot) {
        var currentPosition = (snapshot.data ?? const Duration(seconds: 0)).inSeconds.toDouble();

        final xx = (duration ?? const Duration(seconds: 0)).inSeconds.toDouble();
        if(currentPosition > xx) currentPosition = 0;

        return Row(
          children: [
            Expanded(flex: 1, 
              child:  Slider(
                value: currentPosition,
                max: xx,
                // divisions: 5,
                // label: currentPosition.format(),
                onChanged: (double value) {
                  setState(() {
                    _audioHandler!.seek(Duration(seconds: value.toInt()));
                  });
                },
              )
            ),
            // if(currentPosition > 0)
              Text("-${Duration(seconds: (xx - currentPosition).toInt()).format()}", 
                style: const TextStyle(
                  // color: Colors.white,
                  fontSize: 20,
                )
              )
          ]
        )
        ;
      }
    );
  }

  void choiceVideo(index) async {
    if(timerChoice != null) {
      stopTimer();
    }
    EasyLoading.dismiss();
  
    var audio = streams.elementAt(index);
    try {
      await getVideo(audio);
    } catch(e) {
      print(e);
    }
  }

  Future<void> getVideo(dynamic audio) async {
    try{
      await youTube.execute(audio, 
        onProcessing: (int process) async {
          processing = process;
          if(processing == 100) {
            video["mb"] = youTube.mb;
            video["audioName"] = youTube.audioName;
            playList.add(video);
            startToPlayer();
          } else {
            setState(() { });
          }
        }
      );
    } catch(e) {
      print(e);
      if(destroied == false) {
        String result = await alert("重新載入？\n\n${e.toString().substring(0, 500)}", btn: AlertButtonStyle.yesNo);
        if(result == "yes") {
          video = null;
          counter = -1;
          qualityMedium = -1;
          setState(() {
            initial();
          });
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  Duration? duration;
  startToPlayer() async {
      // Audio(fileName: video["audioName"], title: video["title"], author: video["author"]),
     final player = AudioPlayer();
      duration = await player.setUrl(video["audioName"]);

      var item = MediaItem(
        id: video["audioName"],
        title: video["title"],
        album: video["author"],
        duration: duration,
      );
      _audioHandler ??= await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.flutter.mytube2',
          androidNotificationChannelName: 'MyTube2',
          androidNotificationOngoing: true,
          androidNotificationIcon: "drawable/ic_stat_music_note"
        ),
      );
      _audioHandler!.init(item);
      setState(() {});
  }

  void startTimer() {
    counter = 5; setState(() { });
    timerChoice = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      counter--;

      if (counter == 0) {
        choiceVideo(qualityMedium);
        stopTimer();
      }
      setState(() { });
    });
  }

  // 停止計時器
  void stopTimer() {
    counter = -1;
    if (timerChoice != null) {
      timerChoice!.cancel();
      timerChoice = null;
    }
  }
}

class PlayList {
  List datas = [];

  PlayList() {
    String s = Archive.readText("${home}playlist.txt");
    if(s.isNotEmpty) {
      datas = jsonDecode(s);
    }
  }

  write() {
    Archive.writeText("${home}playlist.txt", jsonEncode(datas));
  }

  add(dynamic data) {
    int index = -1;
    for(var i = 0; i < datas.length; i++) {
      if(datas[i]["id"] == data["id"]) {
        index = i;
        break;
      }
    }
    if(index == -1) {
      datas.add(data);
    }
    write();
  }
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();
  final currentSong = BehaviorSubject<MediaItem>();
  final currentPosition = BehaviorSubject<Duration>();
  int _oldSeconds = 0;
  List<MediaItem> songs = [];

  void init(MediaItem mediaItem) async {
    _player.playbackEventStream.listen(_broadcastState);
    currentPosition.add(Duration.zero);

    AudioService.position.listen((Duration position) {
      if(position.inSeconds != _oldSeconds) {
        currentPosition.add(position);
        _oldSeconds = position.inSeconds;
      }
    });

    if(queue.value.isNotEmpty) {
      songs = [];
      stop();
      queue.value.clear();
    }
    songs.add(mediaItem);
    queue.add(songs);
    _player.processingStateStream.listen((state) {
      print("processingStateStream: $state");
      if (state == ProcessingState.completed) skipToNext();
    });

    setSong(songs.first);
    play();
  }

  Future<void> setSong(MediaItem song) async {
    currentSong.add(song);
    mediaItem.add(song);
    await _player.setAudioSource(
      ProgressiveAudioSource(Uri.parse(song.id)), // 
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    await playbackState.firstWhere(
        (state) => state.processingState == AudioProcessingState.idle);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) {
      return;
    }
    await setSong(songs[index]);
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) {
    // print("PlaybackEvent: $event");
    final playing = _player.playing;
    final queueIndex = songs.indexOf(currentSong.value);

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: queueIndex,
    ));
  }

}
