// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

// InAppLocalhostServer localhostServer = InAppLocalhostServer();

// String serverURI = "http://192.168.149.196";
String serverURI = "http://45.142.215.75";

String server1URI = "$serverURI/coupon.html";
String server2URI = "$serverURI/shop.html";

String navigateToHomeJsURI = "$serverURI/mobile_js/login/navigateToHome.js";
String navigateToLoginJsURI = "$serverURI/mobile_js/login/navigateToLogin.js";
String loginJsURI = "$serverURI/mobile_js/login/login.js";
String loginCheckJsURI = "$serverURI/mobile_js/login/loginCheck.js";

String searchJsURI = "$serverURI/mobile_js/job/search.js";
String selectGoodsJsURI = "$serverURI/mobile_js/job/selectGoods.js";
String likeGoodsJsURI = "$serverURI/mobile_js/job/likeGoods.js";

String uriConstantURI = "$serverURI/mobile_js/constant/uri.js";
String selectorConstantURI = "$serverURI/mobile_js/constant/selector.js";

String historySendURI = "$serverURI/history/add";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await localhostServer.start();
  runApp(const MaterialApp(home: WebViewExample()));
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final InAppWebViewController _controller1;

  late final InAppWebViewController _controller2;
  bool _loaded1 = false;
  bool _loaded2 = false;
  bool _isFirstWebViewActive = true;

  bool _isLoading1 = true;
  bool _isLoading2 = true;
  bool injected = false;

  bool isLoggedIn1 = false;

  bool gotLoginInfo = false;
  dynamic backInfo;

  String navigateSearchUri = "";
  // List<String> navigateHistory = [];

  int currentAppState =
      0; //0:before navigate, 1:navigated, 2:logged in 3:navigated to mypage

  int currentJobState =
      0; //0 before navigate, 1 navigated, 2 searched 3 navigated to detail page 4 liked

  int currentJob = 0;

  @override
  void initState() {
    super.initState();
    getLoginData();
    // navigateHistory = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
                child: IgnorePointer(
                    ignoring: !_isFirstWebViewActive,
                    child: Opacity(
                        opacity: _isFirstWebViewActive ? 1.0 : 0.0,
                        child: Stack(
                          children: [
                            InAppWebView(
                              initialUrlRequest: URLRequest(
                                url: Uri.parse(server1URI),
                              ),
                              onWebViewCreated: (controller) {
                                setState(() {
                                  _controller1 = controller;
                                  _controller1.webStorage.localStorage.clear();
                                  // _controller1.clearCache();
                                  _loaded1 = true;
                                });
                              },
                              onLoadStart: (controller, url) {
                                setState(() {
                                  _isLoading1 = true;
                                });
                                injected = false;
                              },
                              onLoadStop: (controller, url) {
                                setState(() {
                                  _isLoading1 = false;
                                });
                              },
                            ),
                            if (_isLoading1 && _loaded1)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )))),
            Positioned.fill(
                child: IgnorePointer(
                    ignoring: _isFirstWebViewActive,
                    child: Opacity(
                        opacity: _isFirstWebViewActive ? 0.0 : 1.0,
                        child: Stack(
                          children: [
                            InAppWebView(
                              initialUrlRequest:
                                  URLRequest(url: Uri.parse(server2URI)),
                              onWebViewCreated: (controller) {
                                setState(() {
                                  _controller2 = controller;
                                  _controller2.webStorage.localStorage.clear();
                                  _controller2.webStorage.sessionStorage
                                      .clear();
                                  _controller2.clearCache();
                                  _loaded2 = true;
                                });
                              },
                              onLoadStart: (controller, url) async {
                                setState(() {
                                  _isLoading2 = true;
                                });
                                // _controller2.evaluateJavascript(
                                //     source:
                                //         '''window.navigator.userAgent="$userAgent"''');
                                // _controller2.webStorage.localStorage.clear();
                                // _controller2.webStorage.sessionStorage.clear();
                                // _controller2.clearCache();
                                injected = false;
                              },
                              onLoadStop: (controller, url) async {
                                setState(() {
                                  _isLoading2 = false;
                                });
                                // _controller2.evaluateJavascript(
                                //     source:
                                //         '''window.navigator.userAgent="$userAgent"''');
                                if (gotLoginInfo) {
                                  if (currentAppState != 4) {
                                    login();
                                  } else {
                                    doJob();
                                  }
                                }
                              },
                              onLoadError: (controller, url, code, message) {
                                // Error occurred
                                if (code == -6) {
                                  // Connection refused error code
                                  // Reload the WebView
                                  _controller2.reload();
                                }
                              },
                            ),
                            if (_isLoading2 && _loaded2)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )))),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [swapButton(), const SizedBox(height: 16.0), reloadButton()],
      ),
    );
  }

  void getLoginData() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isLoading1) {
        LocalStorage localStorage1 = _controller1.webStorage.localStorage;
        final backInfo = await localStorage1.getItem(key: "back_info");
        if (backInfo != Null) {
          if (backInfo != null) {
            // String userName = backInfo['login_info']['user'];
            // String password = backInfo['login_info']['password'];
            gotLoginInfo = true;
            this.backInfo = backInfo;
            login();
            timer.cancel();
          }
        }
      }
    });
  }

  void login() async {
    while (true) {
      if (_isLoading2) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      } else {
        if (!injected) {
          injected = true;
          await Future.delayed(const Duration(seconds: 2));
          dynamic injectJavascriptCode;
          // navigateHistory.add(currentUriStr);
          if (currentAppState == 0) {
            final javascriptFileResponse =
                await http.get(Uri.parse(navigateToHomeJsURI));
            final javascriptCode = javascriptFileResponse.body;
            injectJavascriptCode = javascriptCode;
          } else if (currentAppState == 1) {
            final javascriptFileResponse =
                await http.get(Uri.parse(navigateToLoginJsURI));
            final javascriptCode = javascriptFileResponse.body;
            injectJavascriptCode = javascriptCode;
          } else if (currentAppState == 2) {
            final javascriptFileResponse =
                await http.get(Uri.parse(loginJsURI));
            final javascriptCode = javascriptFileResponse.body;
            injectJavascriptCode = javascriptCode
                .replaceAll(
                    "USERNAMEFORREPLACE", backInfo["login_info"]["user"])
                .replaceAll(
                    "PASSWORDFORREPLACE", backInfo["login_info"]["password"]);
          } else if (currentAppState == 3) {
            final javascriptFileResponse =
                await http.get(Uri.parse(loginCheckJsURI));
            final javascriptCode = javascriptFileResponse.body;
            injectJavascriptCode = javascriptCode;
          } else {
            sendHistoryToServer("Action Stopped.");
            break;
          }
          dynamic result;
          try {
            final uriJSResponse = await http.get(Uri.parse(uriConstantURI));
            final uriJSCode = uriJSResponse.body;
            final selectorJSResponse =
                await http.get(Uri.parse(selectorConstantURI));
            final selectorJSCode = selectorJSResponse.body;
            await _controller2.evaluateJavascript(source: uriJSCode);
            await _controller2.evaluateJavascript(source: selectorJSCode);
            result = await _controller2.evaluateJavascript(
                source: injectJavascriptCode);
          } finally {
            if (currentAppState == 0) {
              if (result == null || result == Null) {
              } else {
                String resultStr = result.toString();
                if (resultStr == "success") {
                  currentAppState = 1;
                }
              }
            } else if (currentAppState == 1) {
              if (result == null || result == Null) {
              } else {
                String resultStr = result.toString();
                if (resultStr == "success") {
                  currentAppState = 2;
                }
              }
            } else if (currentAppState == 2) {
              if (result == null || result == Null) {
              } else {
                String resultStr = result.toString();
                if (resultStr == "success") {
                  currentAppState = 3;
                }
              }
            } else if (currentAppState == 3) {
              if (result == null || result == Null) {
              } else {
                String resultStr = result.toString();
                if (resultStr == "success") {
                  currentAppState = 4;
                  injected = false;
                  sendHistoryToServer("Login Success");
                  doJob();
                }
              }
            }
          }
          break;
        }
        break;
      }
    }
  }

  void doJob() async {
    final good = backInfo["job_info"]["goods"][currentJob];
    final goodLength = backInfo["job_info"]["goods"].length;

    if (currentJob < goodLength) {
      while (true) {
        if (_isLoading2) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          if (!injected) {
            injected = true;
            await Future.delayed(const Duration(seconds: 2));
            dynamic injectJavascriptCode;
            if (currentJobState == 0) {
              final searchStr = good["keyword1"] +
                  " " +
                  good["keyword2"] +
                  " " +
                  good["keyword3"];
              final javascriptFileResponse =
                  await http.get(Uri.parse(searchJsURI));
              final javascriptCode = javascriptFileResponse.body;
              injectJavascriptCode =
                  javascriptCode.replaceAll("SEARCHSTRFORREPLACE", searchStr);
            } else if (currentJobState == 1) {
              final nvid = good["nvid"];
              final javascriptFileResponse =
                  await http.get(Uri.parse(selectGoodsJsURI));
              final javascriptCode = javascriptFileResponse.body;
              injectJavascriptCode =
                  javascriptCode.replaceAll("GOODSIDREPLACE", nvid);
            } else if (currentJobState == 2) {
              final javascriptFileResponse =
                  await http.get(Uri.parse(likeGoodsJsURI));
              final javascriptCode = javascriptFileResponse.body;
              injectJavascriptCode = javascriptCode;
            } else {
              sendHistoryToServer("Action Stopped");
              break;
            }
            final uriJSResponse = await http.get(Uri.parse(uriConstantURI));
            final uriJSCode = uriJSResponse.body;
            final selectorJSResponse =
                await http.get(Uri.parse(selectorConstantURI));
            final selectorJSCode = selectorJSResponse.body;
            await _controller2.evaluateJavascript(source: uriJSCode);
            await _controller2.evaluateJavascript(source: selectorJSCode);
            final result = await _controller2.evaluateJavascript(
                source: injectJavascriptCode);
            if (currentJobState == 0) {
              if (result == "success") {
                currentJobState = 1;
              }
            } else if (currentJobState == 1) {
              if (result == "success") {
                currentJobState = 2;
              }
            } else if (currentJobState == 2) {
              if (result == "success") {
                currentJobState = 3;
                String actionInfo = "Liked ";
                String actionId = good["nvid"].toString();

                sendHistoryToServer(actionInfo + actionId);
                await Future.delayed(const Duration(seconds: 5));
                currentJob = currentJob + 1;
                currentJobState = 0;
                if (currentJob < goodLength) {
                  _controller2.reload();
                } else {
                  sendHistoryToServer("Finished");
                }
              }
            }
            break;
          }
          break;
        }
      }
    }
  }

  void sendHistoryToServer(String action) {
    final url = Uri.parse(historySendURI);
    final headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    final machine = backInfo["machine_info"]["machine_id"];
    // var machine = "qwe@qwe.qwe";
    final json = {
      'machine': machine,
      'action': action,
    };
    final jsonString = jsonEncode(json);
    http.post(url, headers: headers, body: jsonString);
  }

  Widget swapButton() {
    return FloatingActionButton(
      onPressed: () async {
        setState(() {
          _isFirstWebViewActive = !_isFirstWebViewActive;
        });
      },
      child: const Icon(Icons.swap_horiz),
    );
  }

  Widget reloadButton() {
    return FloatingActionButton(
      onPressed: () async {
        setState(() {
          _isFirstWebViewActive ? _controller1.reload() : _controller2.reload();
        });
      },
      child: const Icon(Icons.rotate_left),
    );
  }
}
