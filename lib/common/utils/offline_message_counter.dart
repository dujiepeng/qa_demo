import 'package:flutter/foundation.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

class OfflineMessageCounter extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void reset() {
    if (_count == 0) {
      return;
    }
    _count = 0;
    notifyListeners();
  }

  void recordOnlineStates(Iterable<bool?> onlineStates) {
    var added = 0;
    for (final onlineState in onlineStates) {
      if (onlineState == false) {
        added++;
      }
    }
    if (added == 0) {
      return;
    }

    _count += added;
    notifyListeners();
  }

  void recordMessages(Iterable<EMMessage> messages) {
    recordOnlineStates(messages.map((message) => !message.onlineState));
  }
}
