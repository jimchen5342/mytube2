import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:intl/intl.dart';

import 'package:mytube2/system/module.dart';
import 'package:mytube2/system/system.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool permission = false;
  late final WebViewController _controller;
  String url = "";

  @override
  void initState() {
    super.initState();
    EasyLoading.show(status: 'loading...');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

      await initial();
      setState(() {});

      setTimeout(() {
        _controller.loadRequest(Uri.parse("https://m.youtube.com/"));
      }, 300);

      await PlayList.trim(home);

      setTimeout(() {
        EasyLoading.dismiss();
      }, 1000 * 1);


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

  void openPlayer(String href) {
    // href = "/watch?v=UxMABs3NsUc";

    var index = href.indexOf("&t=");
    if(index > -1) {
      href = href.substring(0, index);
    }
    Navigator.pushNamed(context, '/player', arguments: href.trim());
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
        if(href != null && href.indexOf("javascr") == -1) {
          if(index == 2) console.log(href)
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
    // openPlayer("/watch?v=sTjJ1LlviKM");
    // String home = await Archive.home();
    // await  PlayList.trim(home);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
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
    );
  }

  Widget webview() {
    return Container(
      color: Colors.white,
      child: (permission == false) ? null : WebViewWidget(controller: _controller),
    );
  }
}

class PlayList {

  // PlayList() { }

  static trim(String home) async { // 清除 7 天前的檔案
    String today = DateTime.now().formate(pattern: "yyMMdd");
    String today2 = await Storage.getString("trim-date");
    if(today2 == today) {
      return;
    }

    List datas = [];
    bool b = false;
    String s = Archive.readText("${home}playlist.txt");
    if(s.isNotEmpty) {
      datas = jsonDecode(s);
    }
    var days7 = DateTime.now().subtract(const Duration(days: 7)).formate(pattern: "yyMMdd"); 
    String key = '${home}yt-$days7';
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
    if(b == true){
      Archive.writeText("${home}playlist.txt", jsonEncode(datas));
    }
    await Storage.setString("trim-date", today);
  }
}