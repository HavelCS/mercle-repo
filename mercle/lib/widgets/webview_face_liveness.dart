import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mercle/constants/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';

// Face Liveness Result Model
class FaceLivenessResult {
  final bool success;
  final bool isLive;
  final double confidence;
  final String message;
  final String? sessionId;
  final Map<String, dynamic>? fullResult;

  FaceLivenessResult({
    required this.success,
    required this.isLive,
    required this.confidence,
    required this.message,
    this.sessionId,
    this.fullResult,
  });

  factory FaceLivenessResult.fromJson(Map<String, dynamic> json) {
    return FaceLivenessResult(
      success: json['success'] ?? false,
      isLive: json['isLive'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      message: json['message'] ?? 'Unknown result',
      sessionId: json['sessionId'],
      fullResult: json['fullResult'],
    );
  }
}

class WebViewFaceLiveness extends StatefulWidget {
  final Function(FaceLivenessResult result)? onResult;
  final Function(String error)? onError;
  final VoidCallback? onCancel;
  final String? sessionId;

  const WebViewFaceLiveness({
    super.key,
    this.onResult,
    this.onError,
    this.onCancel,
    this.sessionId,
  });

  @override
  State<WebViewFaceLiveness> createState() => _WebViewFaceLivenessState();
}

class _WebViewFaceLivenessState extends State<WebViewFaceLiveness> {
  late final WebViewController controller;
  bool isLoading = true;
  String? error;

  // Your deployed React Face Liveness app URL
  static const String _faceLivenessUrl =
      'https://face-liveness-react-io419t8ng.vercel.app';
  
  String _faceLivenessUrlWithToken = '';
  bool _urlInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _initializeUrlWithToken();
  }

  /// Initialize URL with authentication token
  Future<void> _initializeUrlWithToken() async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        _faceLivenessUrlWithToken = '$_faceLivenessUrl?token=${Uri.encodeComponent(token)}';
        print('🔑 Face liveness URL with token initialized');
      } else {
        _faceLivenessUrlWithToken = _faceLivenessUrl;
        print('⚠️ No auth token available, using URL without token');
      }
      _urlInitialized = true;
      _initializeWebView();
    } catch (e) {
      print('❌ Error initializing URL with token: $e');
      _faceLivenessUrlWithToken = _faceLivenessUrl;
      _urlInitialized = true;
      _initializeWebView();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera permission is required for face liveness detection',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeWebView() {
    if (!_urlInitialized) return; // Wait for URL to be initialized
    
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFF1a1a1a))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // Update loading progress if needed
              },
              onPageStarted: (String url) {
                if (mounted) {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                }
              },
              onPageFinished: (String url) {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
                // Set up result listener with JavaScript
                _setupResultListener();
              },
              onHttpError: (HttpResponseError error) {
                if (mounted) {
                  setState(() {
                    this.error = 'HTTP Error: ${error.response?.statusCode}';
                    isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) {
                  setState(() {
                    this.error = 'Connection Error: ${error.description}';
                    isLoading = false;
                  });
                }
              },
            ),
          )
          ..addJavaScriptChannel(
            'flutterFaceLiveness',
            onMessageReceived: (JavaScriptMessage message) {
              _handleMessageFromReact(message.message);
            },
          )
          ..loadRequest(Uri.parse(_urlInitialized ? _faceLivenessUrlWithToken : _faceLivenessUrl));
  }

  /// Set up JavaScript listener for Face Liveness results
  void _setupResultListener() {
    // Inject JavaScript to set up a listener for results
    controller.runJavaScript('''
      window.addEventListener('message', function(event) {
        if (event.data && typeof event.data === 'string') {
          try {
            const data = JSON.parse(event.data);
            if (data.type === 'FACE_LIVENESS_RESULT') {
              // Forward the result to Flutter
              window.flutterFaceLiveness.postMessage(JSON.stringify(data));
            }
          } catch (e) {
            console.error('Error parsing message:', e);
          }
        }
      });
      
      // Set up a global variable to receive results from React component
      window.sendResultToFlutter = function(result) {
        window.flutterFaceLiveness.postMessage(JSON.stringify({
          type: 'FACE_LIVENESS_RESULT',
          ...result
        }));
      };
      
      console.log('Flutter result listener initialized');
    ''');
  }

  /// Handle messages from React app
  void _handleMessageFromReact(String message) {
    try {
      final Map<String, dynamic> data = json.decode(message);

      if (data['type'] == 'FACE_LIVENESS_RESULT') {
        // Convert to FaceLivenessResult and notify
        final result = FaceLivenessResult.fromJson(data);

        if (widget.onResult != null) {
          widget.onResult!(result);
        }

        // Close WebView after result
        if (mounted && result.success) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(context).pop();
          });
        }
      } else if (data['type'] == 'FACE_LIVENESS_ERROR') {
        if (widget.onError != null) {
          widget.onError!(data['message'] ?? 'Unknown error');
        }
      } else if (data['type'] == 'FACE_LIVENESS_CANCEL') {
        if (widget.onCancel != null) {
          widget.onCancel!();
        }
      }
    } catch (e) {
      print('Error handling message from React: $e');
      if (widget.onError != null) {
        widget.onError!('Failed to process face liveness result');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // WebView fills entire body
          WebViewWidget(controller: controller),
          if (!isLoading && error == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading Face Liveness...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (error != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connection Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              error = null;
                            });
                            _initializeWebView();
                          },
                          child: const Text('Try Again'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
