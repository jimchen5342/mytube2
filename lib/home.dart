import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:mytube2/system/module.dart';
import 'package:mytube2/system/system.dart';
import 'package:mytube2/DialogLock.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home>  with WidgetsBindingObserver {
  bool permission = false;
  late final WebViewController _controller;
  String url = "";
  DateTime? lastTime;
  bool locked = false;

  @override
  void initState() {
    super.initState();
    lastTime = DateTime.now();
    WidgetsBinding.instance.addObserver(this);

    EasyLoading.show(status: 'loading...');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initial();

      String home = await Archive.home();
      final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
            const PlatformWebViewControllerCreationParams());

      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel("Flutter",
          onMessageReceived: (JavaScriptMessage message) {
            Map<String, dynamic> obj = jsonDecode(message.message);
            if (obj["href"] != null) {
              openPlayer(obj["href"]);
            }
            // print(message.message);
          })
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // print("onProgress: $progress");
            },
            onPageStarted: (String url) {
              print("onPageStarted: $url");
            },
            onPageFinished: onPageFinished,
            onWebResourceError: (WebResourceError error) {
             
            },
            onNavigationRequest: (NavigationRequest request) {
              debugPrint('onNavigationRequest: ${request.url}');
              // if (request.url.startsWith('https://www.youtube.com/')) {
              //   debugPrint('blocking navigation to ${request.url}');
              //   return NavigationDecision.prevent;
              // }
              return NavigationDecision.navigate;
            },
            onUrlChange: (UrlChange change) {
             
            },
            onHttpAuthRequest: (HttpAuthRequest request) {
              // openDialog(request);
            },
          ),
        );
      _controller = controller;

      setState(() {});

      await setTimeoutAsync(300);
      _controller.loadRequest(Uri.parse("https://m.youtube.com/"));

      await PlayList.trim(home);

      await setTimeoutAsync(1000 * 1);
      EasyLoading.dismiss();
    });

  }

  onPageFinished(String url) async {
    if(this.url == url) return;
    this.url = url;
    if(url == "https://m.youtube.com/" ) {
      setLeast();
      setAnchorClick("a.media-item-thumbnail-container");
    } else if(url.contains("/feed/subscriptions")) {
      setAnchorClick(".item a"); // compact-media-item
    } else if(url.contains("/channel/")) {
      setAnchorClick(".item a");
    } else if(url.contains("/user/")) {
      setAnchorClick(".compact-media-item a"); // 
    } else if(url.contains("playlist?list=")) {
      setAnchorClick("a.compact-media-item-image"); 
    } else if(url.contains("#")){
      
    } else if(url.contains("/feed/library") || url.contains("/feed/channels")) {
    
    }
  }

  void openPlayer(String href) async {
    // print(href);
    // href="/watch?v=PwlvLFb1kgk"; // href = "/watch?v=UxMABs3NsUc";
    lastTime = null;
    
    final now = DateTime.now();
    var index = href.indexOf("&t=");
    if(index > -1) {
      href = href.substring(0, index);
    }
    await Navigator.pushNamed(context, '/player', arguments: href.trim());
    reload(now);
    lastTime = DateTime.now();
  }

  void setLeast() async { // 最新上傳
    await _controller.runJavaScript(
    '''
      window.timesToolbar = 0;
      window.onload=function(){
        exeToolbar();
      }

      function exeToolbar() {
        window.timesToolbar++;
        // console.log("exeToolbar: " + (new Date()))
        if(window.timesToolbar > 10) {
          window.timesToolbar = 0;
          return;
        }

        let options = document.querySelectorAll("div.chip-bar-contents > *");
        if(options.length > 2) {
          for(let i = 0; i < options.length; i++) {
            let item = options[i];
            if(!(item.innerText == "最新上傳" || item.innerText == "全部")) {
              item.remove();
            // } else if(item.innerText == "最新上傳") {
            //   item.click();
            //   console.log("成功........................");
            }
          }          
        }
        setTimeout(exeToolbar, 1000 * 3)
      }
    ''');
  }

  void setAnchorClick(String cls) async {
    await _controller.runJavaScript(
    '''
    window.intervalAnchor = setInterval(()=>{
      let xx = document.querySelectorAll("$cls");
      xx.forEach((item, index) =>{
        let href = item.getAttribute("href");
        if(href != null && href.indexOf("javascr") == -1 && href.indexOf("/watch?v=") > -1) {
          // if(index == 2) console.log(href)
          item.setAttribute("href", "javascript:void(0);");
          item.setAttribute("_href", href);
          item.addEventListener("click", onAnchorClick, false)
        }
      })
    }, 1 * 1000);        

    function onAnchorClick(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      e.stopPropagation();
      let tagName = "", parent = e.srcElement;
      do {
        tagName = parent.tagName;
        if(tagName == "A")
          break;
        else
          parent = parent.parentElement;
      } while(tagName != "A")
      let _href = parent.getAttribute("_href");
      Flutter.postMessage(JSON.stringify({href: _href}));
    }
    ''');
  }

  void reload(DateTime last) async {
    Duration difference = DateTime.now().difference(last);
    if(difference.inMinutes >= 30) {
      EasyLoading.show(status: 'loading...');
      url = "";
      _controller.loadRequest(Uri.parse("https://m.youtube.com/"));
      await setTimeoutAsync(1000 * 1);
      EasyLoading.dismiss();
    }
  }
  initial() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;

    Map<Permission, PermissionStatus> statuses = await [
          build.version.sdkInt < 30 
          ? Permission.storage
          : Permission.manageExternalStorage
    ].request();
    var status = build.version.sdkInt < 30 
      ? await Permission.storage.status
      : await Permission.manageExternalStorage.status;
    if(! status.isGranted) {
      exit(0);
    } else {
      permission = status.isGranted;
    }
    // writeFile();
  }

  @override
  void reassemble() async { // develope mode
    super.reassemble();
        // await  PlayList.trim(await Archive.home());
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // print("AppLifecycleState: $state, ${DateTime.now()}");

    if(lastTime == null) return;
    if(AppLifecycleState.resumed == state) {
      reload(lastTime!);
    }
    else if(AppLifecycleState.paused == state) {
      lastTime = DateTime.now();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          // leading: IconButton(
          //   icon: const Icon( Icons.arrow_back_ios_sharp, color: Colors.white,),
          //   onPressed: () => Navigator.pop(context),
          // ),
          title: const Text('MyTube2', 
            style: TextStyle(
              color: Colors.white,
              // fontSize: 20,
            )
          ),
          actions:<Widget>[
            IconButton(
              icon: Icon(locked == true ? Icons.lock_open : Icons.lock, color: Colors.white),
              onPressed: () {
                showListDialog();
              },
            ),
            IconButton(
              icon: const Icon( Icons.refresh_sharp, color: Colors.white),
              onPressed: () {
                reload(DateTime.parse('2024-01-01 00:00:00.000'));
              },
            )
          ],
          backgroundColor: Colors.blue, 
          // backgroundColor: const Color.fromRGBO(192, 25, 33, 0), 
        ),
        body:PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) async {
            if (didPop) {
              return;
            }
            if(await _controller.currentUrl() == "https://m.youtube.com/") {
              exit(0);
            } else {
              await _controller.goBack();
            }
          },
          child: webview()
        ), 
      )
    );
  }

  Widget webview() {
    return Container(
      color: Colors.white,
      child: (permission == false) ? null : WebViewWidget(controller: _controller),
    );
  }

  void showListDialog()  {
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0.0))),
          backgroundColor: Colors.transparent,
          // shadowColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40.0),
          child: DialogLock()
        );
      },
    );
  }
}

class PlayList {

  // PlayList() { }

  static trim(String home) async { // 清除 7 天前的檔案
    String today1 = DateTime.now().formate(pattern: "yyMMdd");
    String today2 = await Storage.getString("trim-date");
    if(today2 == today1) {
      return;
    }

    List datas = [];
    bool b = false;
    String s = Archive.readText("${home}playlist.txt");
    if(s.isNotEmpty) {
      datas = jsonDecode(s);
    }
    var days = DateTime.now().subtract(const Duration(days: 4)).formate(pattern: "yyMMdd"); 
    String key = '${home}yt-$days';
    for(var i = datas.length - 1; i >= 0; i--){
      String audioName = datas[i]["audioName"];
      if(audioName.compareTo(key) == -1) {
        var f3 = File(audioName);
        if (f3.existsSync()) {
          f3.deleteSync();
        }
        datas.removeAt(i);
        b = true;
      }
    }

    List<String> archives = await Archive.getFiles(home);
    for(var i = archives.length - 1; i >= 0; i--){
      var archive = '$home${archives[i]}';
      if(archives[i].startsWith("yt-") && archive.compareTo(key) == -1) {
        var f3 = File(archive);
        if (f3.existsSync()) {
          f3.deleteSync();
        }
      } else {
        var f3 = File(archive);
        if( f3.lengthSync() == 0){
          f3.deleteSync();
        }
      }
    }
    if(b == true){
      Archive.writeText("${home}playlist.txt", jsonEncode(datas));
    }
    await Storage.setString("trim-date", today1);
  }
}