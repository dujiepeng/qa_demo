import 'dart:async';

import 'package:flutter/foundation.dart';

class ConnectionStatusOverlayController extends ChangeNotifier {
  static const Duration defaultDuration = Duration(seconds: 3);

  String? _message;
  Timer? _hideTimer;

  String? get message => _message;
  bool get isVisible => _message != null && _message!.isNotEmpty;

  void showMessage(String message, {Duration duration = defaultDuration}) {
    _hideTimer?.cancel();
    _message = message;
    notifyListeners();
    _hideTimer = Timer(duration, hide);
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

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
