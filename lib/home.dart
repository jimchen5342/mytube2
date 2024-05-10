import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

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
      await Archive.home();
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

      setTimeout(() {
        EasyLoading.dismiss();
      }, 1000 * 3);
      
      // EasyLoading.showToast("吐司");
      // openPlayer("/watch?v=sTjJ1LlviKM");

      
    });
  }

  onPageFinished(String url) async {
    DateFormat formatter = DateFormat("mm:ss"); // "yyyy/MM/dd HH:mm:ss"

    // print("onPageFinished: $url, ${formatter.format(DateTime.now())} ");

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
    Navigator.pushNamed(context, '/player', arguments: href);
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
    var s = await alert2("下載完成");
    print(s);
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