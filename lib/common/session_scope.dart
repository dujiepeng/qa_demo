import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:provider/provider.dart';

import '../theme/app_settings.dart';
import 'utils/connection_status_overlay_controller.dart';
import 'utils/log_service.dart';
import 'utils/offline_message_counter.dart';
import 'utils/other_logged_in_devices_controller.dart';

class QaSessionScope extends StatelessWidget {
  const QaSessionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AppSettings>().isLoggedIn;
    if (!isLoggedIn) {
      return child;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LogService()),
        ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
        ChangeNotifierProvider(create: (_) => ConnectionStatusOverlayController()),
        ChangeNotifierProvider(create: (_) => OtherLoggedInDevicesController()),
      ],
      child: child,
    );
  }
}

T? _maybeRead<T>(BuildContext context) {
  try {
    return Provider.of<T>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

T? maybeReadProvider<T>(BuildContext context) {
  return _maybeRead<T>(context);
}

void clearQaSessionState(BuildContext context) {
  _maybeRead<LogService>(context)?.clear();
  _maybeRead<OfflineMessageCounter>(context)?.reset();
  _maybeRead<ConnectionStatusOverlayController>(context)?.reset();
  _maybeRead<OtherLoggedInDevicesController>(context)?.clear();
}

Future<void> resetQaSession(BuildContext context) async {
  clearQaSessionState(context);
  try {
    await EMClient.getInstance.logout();
  } catch (_) {}
}
