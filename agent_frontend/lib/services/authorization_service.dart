import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';

@JS('window')
external Window get window;

@JS()
@staticInterop
class Window {}

@JS()
@staticInterop
class MessageEvent {}

/// Extension for `Window` to listen for messages and open new windows.
extension WindowExtension on Window {
  external WindowInstance? open(String url, String target, String features);
  external void addEventListener(String type, JSExportedDartFunction listener);
  external void removeEventListener(
      String type, JSExportedDartFunction listener);
}

/// Extension for `MessageEvent` to extract received data and origin.
extension MessageEventExtension on MessageEvent {
  external JSAny get data;
  external String get origin; // ✅ Now correctly exposes `origin`
}

/// Interop class for authentication popup window.
@JS()
@staticInterop
class WindowInstance {}

/// Extension to check if the authentication window is closed and close it.
extension WindowInstanceExtension on WindowInstance {
  external bool? get closed;
  external void close();
}

class AuthorizationService {
  late Completer<Map<String, dynamic>> _completer;
  WindowInstance? authWindow;

  // Keep a reference to our JS listener so we can remove it
  late JSExportedDartFunction _messageListener;

  Future<Map<String, dynamic>> authenticate(String authUrl) {
    _completer = Completer<Map<String, dynamic>>();

    // Open popup
    authWindow = window.open(authUrl, '_blank', 'width=500,height=600');
    if (authWindow == null) {
      return Future.error('Popup blocked or failed to open');
    }

    // Start polling to detect manual window close
    // _pollWindowClosed();

    // Prepare our message listener
    _messageListener = _onAuthResponse.toJS;

    // Listen for postMessage event
    window.addEventListener('message', _messageListener);

    return _completer.future;
  }

  @JSExport()
  void _onAuthResponse(MessageEvent event) {
    final String origin = event.origin;
    if (!origin.contains("api.isomorphiq.net") &&
        !origin.contains("api.isomorphiq.com")) {
      debugPrint("Rejected message from unknown origin: $origin");
      return;
    } else {
      debugPrint("Received message from origin: $origin");
    }

    final dynamic eventData = event.data;
    final dynamic response = jsonDecode(eventData);
    if (response is Map<String, dynamic>) {
      String message = response["message"] ?? "Unknown Response";
      int statusCode = response["statusCode"] ?? 400;

      debugPrint("Received message: $message (code: $statusCode)");
      // Optional delay
      Future.delayed(Duration(seconds: 2), () {
        authWindow?.close();
        _completeAndCleanup({"message": message, "statusCode": statusCode});
      });
    }
  }

  // void _pollWindowClosed() {
  //   Timer.periodic(Duration(milliseconds: 500), (timer) {
  //     if (authWindow?.closed == true) {
  //       timer.cancel();
  //       // Window closed manually
  //       debugPrint("User closed authentication");
  //       _completeAndCleanup(
  //           {"message": "User closed authentication", "statusCode": 400});
  //     }
  //     _routerService.replaceWithSourcesView();
  //   });
  // }

  void _completeAndCleanup(Map<String, dynamic> result) {
    if (!_completer.isCompleted) {
      _completer.complete(result);
    }
    // Remove the event listener to avoid duplicates if user calls authenticate() again
    window.removeEventListener('message', _messageListener);
  }
}
