import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:external_path/external_path.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mytube2/system/youtube.dart';
import 'package:mytube2/system/system.dart';
import 'package:intl/intl.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {

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
              openVideo(obj["href"]);
            }
            print(message.message);
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
        // ..loadRequest(Uri.parse("https://m.youtube.com/"));
      _controller = controller;
      // final String contentBase64 = base64Encode( const Utf8Encoder().convert('''<div style="font-size: 30px;">載入中</div>'''));
      // _controller.loadRequest(
      //   Uri.parse('data:text/html;base64,$contentBase64'),
      // );

      await initial();
      setState(() {});
      Future.delayed(const Duration(milliseconds: 300 * 1), () {
        _controller.loadRequest(Uri.parse("https://m.youtube.com/"));
      });
    });
  }

  onPageFinished(String url) async {
    DateFormat formatter = DateFormat("mm:ss"); // "yyyy/MM/dd HH:mm:ss"

    print("onPageFinished: $url, ${formatter.format(DateTime.now())} ");

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

  void openVideo(String href) {
    Navigator.pushNamed(context, '/video', arguments: href);
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

  writeFile() async { // 測好了，可以用
    var path = await ExternalPath.getExternalStorageDirectories();
    var file = File('${path[0]}/counter.txt');

    file.writeAsString('jim'); 
    /* 測好了，可以用
    var path = await ExternalPath.getExternalStorageDirectories();
    print("path: ${path[0]}");
    var path2 = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_MUSIC);
    print("DIRECTORY_MUSIC: ${path2}");
    */
  }

  @override
  void reassemble() async { // develope mode
    super.reassemble();
    // YouTube youTube = YouTube();
    // // youTube.getData();
    // youTube.getAudioStream();
    Future.delayed(const Duration(milliseconds: 100), () {
      // _controller.loadRequest(Uri.parse("https://api.flutter.dev/flutter/dart-async/Future/timeout.html"));
      openVideo("/watch?v=sTjJ1LlviKM");
    }); 
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
    print("create WebView......................");
    return Container(
      color: Colors.white,
      child: (permission == false) ? null : WebViewWidget(controller: _controller),
    );
  }
}