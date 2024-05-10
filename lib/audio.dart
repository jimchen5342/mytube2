import 'package:flutter/material.dart';

import 'package:mytube2/system/module.dart';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

AudioPlayerHandler? _audioHandler;
List<MediaItem> songs = [];

class Audio extends StatefulWidget {
  final String fileName, title, author;
  const Audio({Key? key, required this.fileName, required this.title, required this.author}) : super(key: key);
  @override
  _AudioState createState() => _AudioState();
}

class _AudioState extends State<Audio>{
  String href = "";
  Map<String, dynamic> playItem = {};
  Duration? duration;
  // Duration(milliseconds: ms)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      songs = [];
      final player = AudioPlayer();
      duration = await player.setUrl(widget.fileName);

      var item = MediaItem(
        id: widget.fileName,
        title: widget.title,
        album: widget.author,
        duration: duration,
      );
      songs.add(item);        
      _audioHandler ??= await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.flutter.mytube2',
          androidNotificationChannelName: 'MyTube2',
          androidNotificationOngoing: true,
        ),
      );
      _audioHandler!.init();
      // _audioHandler!.customAction.
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
    if(_audioHandler != null) {
      _audioHandler!.stop();
    }
    _audioHandler = null;
    songs = [];
  }
   
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:  const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(_audioHandler != null)
            _buildSlider(),
          const SizedBox(height: 5),
          if(_audioHandler != null)
            _buildControls()
        ]
      )
    );
  }

  Widget _button(IconData iconData, VoidCallback onPressed, {bool visible = true}){
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
              _button(Icons.pause, _audioHandler!.pause)
            else
              _button(Icons.play_arrow, _audioHandler!.play),
            _button(Icons.stop, _audioHandler!.stop),
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
            if(currentPosition > 0)
              Text((snapshot.data ?? const Duration(seconds: 0)).format(), 
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
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  final _player = AudioPlayer();
  final currentSong = BehaviorSubject<MediaItem>();
  final currentPosition = BehaviorSubject<Duration>();
  int _oldSeonds = 0;

  void init() async {
    _player.playbackEventStream.listen(_broadcastState);
    currentPosition.add(Duration.zero);

    AudioService.position.listen((Duration position) {
      if(position.inSeconds != _oldSeonds) {
        currentPosition.add(position);
        _oldSeonds = position.inSeconds;
      }
    });

    if(queue.value.isNotEmpty) {
      stop();
      queue.value.clear();
    }
    
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
    print("PlaybackEvent: $event");
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
