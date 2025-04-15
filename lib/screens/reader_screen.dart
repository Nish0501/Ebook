import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class ReaderScreen extends StatefulWidget {
  final String bookKey;
  final String? title; // Added title parameter

  const ReaderScreen({
    super.key,
    required this.bookKey,
    this.title,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool isLoading = true;
  String? readUrl;
  late WebViewController webViewController;
  double loadingProgress = 0;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
    fetchReadUrl();
  }

  void _initializeWebViewController() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              hasError = true;
              isLoading = false;
            });
          },
        ),
      );

    webViewController = controller;
  }

  Future<void> fetchReadUrl() async {
    final cleanKey = widget.bookKey.replaceAll('/works/', '').replaceAll('/', '');
    final url = Uri.parse("https://openlibrary.org/works/$cleanKey.json");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? url;

        if (data.containsKey('lending_edition')) {
          url = "https://openlibrary.org/books/${data['lending_edition']}";
        } else if (data.containsKey('ocaid')) {
          url = "https://archive.org/stream/${data['ocaid']}";
        } else if (data.containsKey('key')) {
          url = "https://openlibrary.org${data['key']}";
        }

        setState(() {
          readUrl = url;
          if (url != null) {
            webViewController.loadRequest(Uri.parse(url));
          } else {
            isLoading = false;
          }
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title ?? "Read Book"),
        backgroundColor: Colors.black,
        actions: [
          if (readUrl != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                webViewController.reload();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text(
              "Failed to load book content",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              readUrl != null ? "URL: $readUrl" : "No readable version available",
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchReadUrl,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (isLoading && loadingProgress == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    if (readUrl == null) {
      return const Center(
        child: Text(
          "No readable version available for this book",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: webViewController),
        if (isLoading && loadingProgress < 1)
          LinearProgressIndicator(
            value: loadingProgress,
            backgroundColor: Colors.black,
            color: Colors.blue,
            minHeight: 3,
          ),
      ],
    );
  }
}