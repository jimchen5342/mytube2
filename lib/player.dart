import 'package:flutter/material.dart';
import 'package:mytube2/audio.dart';
import 'package:mytube2/system/youtube.dart';
import 'package:mytube2/system/system.dart';
import 'package:mytube2/system/module.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Player extends StatefulWidget {
  const Player({Key? key}) : super(key: key);
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player>  with WidgetsBindingObserver{
  String href = "";
  int local = -1, qualityMedium = -1;
  Map<String, dynamic> playItem = {};
  late YouTube youTube;
  dynamic? video;
  List streams = [];
  late String home;
  var loadingContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var arg = ModalRoute.of(context)!.settings.arguments;
      href = "$arg";
      home = await Archive.home();
      print("home: $home");
      initial();
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
    initial();
  }

  initial() async {
    // print("href: $href");
    loading(context, onReady: (_) {
      loadingContext = _;
    });

    try {
      youTube = YouTube(url: href);
      video = await youTube.getData();
      streams = await youTube.getAudioStream();
      var size = 0.0, index = 0;
      for(int i = 0; i < streams.length; i++){
        print("MyTube.audio $i: ${streams[i].size.totalMegaBytes.toStringAsFixed(2) + 'MB'} ==");
        if(streams[i].size.totalMegaBytes < size || i == 0) {
          size = streams[i].size.totalMegaBytes;
          index = i;
        }
      }
      qualityMedium = index;
      // print(streams);
      setState(() {});
    } catch(e) {
      alert(context, e.toString());
    } finally {
      if(loadingContext != null)
        Navigator.pop(loadingContext);
      loadingContext = null;
    }
  }

  @override
  dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    Fluttertoast.cancel();
  }
    @override
  void didChangeAppLifecycleState(AppLifecycleState state)  {
    switch (state) {
      case AppLifecycleState.paused:
        // if(local != 1 && this.controller!.noAD == false) {
        //   timer = Timer(Duration(minutes: 30), () { // broswer.dart 要 pause
        //     Navigator.pop(context);
        //   });          
        // }
        break;
      case AppLifecycleState.resumed:
        // if(timer != null) timer.cancel();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget child;

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
      padding:  const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        if(video != null)
          _buildInformation(),
        Expanded(flex: 1, child: Container()),
        grid()
      ],)
    );
  }

  Widget _buildInformation() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("標題：${video.title}", 
           style: const TextStyle(
              // color: Colors.white,
              fontSize: 20,
            )
          ),
          Text("作者：${video.author}", 
           style: const TextStyle(
              // color: Colors.white,
              fontSize: 20,
            )
          ),
          Text("日期：${"${video.publishDate}".substring(0, 19)}", 
            style: const TextStyle(
              // color: Colors.white,
              fontSize: 20,
            )
          )
        ]
      )
    );
  }

  grid(){
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
            crossAxisCount: cells, //每行三列
            childAspectRatio: 1.2, //显示区域宽高相等
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
            child: InkWell(
              onTap: () async {
                choiceVideo(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: bg
                ),
                padding: EdgeInsets.all(5),
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
                    Container(height: 5,),
                    Text("${streams[index].container.name.toString()}",
                      style: TextStyle(
                        color: color,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                )
            )
          )
        ); 
        }
      )
    );
  }

  void choiceVideo(index) async {
    // if(timerChoice != null) timerChoice.cancel();
    Fluttertoast.cancel();
    var audio = streams.elementAt(index);
    print(audio);
    try {
      await getVideo();
    } catch(e) {
      print(e);
    }
  }

  Future<void> getVideo() async {
    try{
      // await download.execute(
      //   onProcessing: (int process) async {
      //     processing = process;
      //     if(process == 100 && isPlaylist == false) {
      //       Storage.setString("url", this.widget.url);
      //       Storage.setString("fileName", download.fileName);
      //       Storage.setString("title", download.title);
      //       Storage.setString("author", download.author);
      //       Storage.setString("mb", download.mb);
      //       Storage.setInt("duration", download.duration.inMilliseconds);
      //       if(this.widget.playItem["key"] is String) {
      //         await playlist.initial();
      //       }
      //     }
      //     setState(() { });
      //   }
      // );      
    } catch(e) {
      alert(context, e.toString());
    }
  }
}