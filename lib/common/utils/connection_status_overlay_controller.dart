import 'dart:async';

import 'package:flutter/foundation.dart';

class ConnectionStatusOverlayController extends ChangeNotifier {
  static const Duration defaultDuration = Duration(seconds: 3);

  String? _message;
  Timer? _hideTimer;
  bool? _isConnected;

  String? get message => _message;
  bool get isVisible => _message != null && _message!.isNotEmpty;
  bool? get isConnected => _isConnected;

  void showMessage(String message, {Duration duration = defaultDuration}) {
    _hideTimer?.cancel();
    _message = message;
    notifyListeners();
    _hideTimer = Timer(duration, hide);
  }

  Future<void> refreshConnectionLight(
    Future<bool> Function() readConnection,
  ) async {
    final nextValue = await readConnection();
    if (_isConnected == nextValue) {
      return;
    }
    _isConnected = nextValue;
    notifyListeners();
  }

  void hide() {
    if (_message == null) {
      return;
    }
    _hideTimer?.cancel();
    _hideTimer = null;
    _message = null;
    notifyListeners();
  }

  void reset() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_message == null && _isConnected == null) {
      return;
    }
    _message = null;
    _isConnected = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
