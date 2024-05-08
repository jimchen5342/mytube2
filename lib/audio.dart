import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

AudioPlayerHandler? _audioHandler;
List<MediaItem> songs = [];

class Audio extends StatefulWidget {
  final String fileName, title;
  const Audio({Key? key, required this.fileName, required this.title}) : super(key: key);
  @override
  _AudioState createState() => _AudioState();
}

class _AudioState extends State<Audio>{
  String href = "";
  int local = -1;
  Map<String, dynamic> playItem = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final player = AudioPlayer();
      var duration = await player.setUrl(widget.fileName);
      var item = MediaItem(
        id: widget.fileName,
        title: widget.title,
        album: "MyTbue",
        duration: duration,
      );
      songs.add(item);

      _audioHandler ??= await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.flutter.mytube2', // 'com.ryanheise.myapp.channel.audio',
          androidNotificationChannelName: '播放器',
          androidNotificationOngoing: true,
        ),
      );
      _audioHandler!.init();
      setState(() { });
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  void reassemble() async { // develope mode
    super.reassemble();
  }

  @override
  dispose() {
    super.dispose();
  }
   
  @override
  Widget build(BuildContext context) {
    return _buildControls();
  }

  Widget _button(IconData iconData, VoidCallback onPressed, {bool visible = true}){
    Widget btn = IconButton(
      icon: Icon(iconData, color: Colors.white, size: 30),
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
        final queueIndex = songs.indexOf(_audioHandler!.currentSong.value);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _button(Icons.skip_previous, _audioHandler!.skipToPrevious, visible: queueIndex > 0),
            if (playing)
              _button(Icons.pause, _audioHandler!.pause)
            else
              _button(Icons.play_arrow, _audioHandler!.play),
            _button(Icons.stop, _audioHandler!.stop),
            _button(Icons.skip_next, _audioHandler!.skipToNext, visible: queueIndex < songs.length -1),
          ],
        );
      },
    );
  }
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();
  final currentSong = BehaviorSubject<MediaItem>();
  final currentPosition = BehaviorSubject<String>();

  void init() async {
    _player.playbackEventStream.listen(_broadcastState);

    // AudioService.position.listen((Duration position) {
    //   var duration = "${position}".split(".")[0];
    //   if(duration.startsWith("0:")) {
    //     duration = duration.substring(2);
    //   }
    //   // currentPosition.add(duration); // 可以用了，但找不到清除的作法
    //   // print("position: $duration");
    // });

    if(queue.value.isNotEmpty) {
      stop();
      queue.value.clear();
    }
    
    queue.add(songs);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) skipToNext();
    });

    setSong(songs.first);
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
