import 'package:flutter/foundation.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../../mobile/my_models.dart';

class OtherLoggedInDevicesController extends ChangeNotifier {
  final List<MyDeviceInfo> _devices = [];

  List<MyDeviceInfo> get devices => List.unmodifiable(_devices);
  int get deviceCount => _devices.length;
  String? get latestDeviceName =>
      _devices.isEmpty ? null : _devices.first.deviceName;

  void recordDeviceLogin(String deviceName) {
    final trimmed = deviceName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _devices.removeWhere((device) => device.deviceName == trimmed);
    _devices.insert(
      0,
      MyDeviceInfo(deviceName: trimmed, resource: trimmed, sourceLabel: '事件回调'),
    );
    notifyListeners();
  }

  Future<void> refreshFromServer({
    required Future<List<EMDeviceInfo>> Function() loadDevices,
  }) async {
    final devices = await loadDevices();
    _devices
      ..clear()
      ..addAll(
        devices.map(
          (device) => MyDeviceInfo(
            deviceName: (device.deviceName?.trim().isNotEmpty ?? false)
                ? device.deviceName!.trim()
                : (device.resource?.trim().isNotEmpty ?? false)
                ? device.resource!.trim()
                : '未知设备',
            resource: device.resource?.trim() ?? '',
          ),
        ),
      );
    notifyListeners();
  }
}
