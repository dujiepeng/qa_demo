import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/theme/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists log overlay minimized state and bubble placement', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();

    await settings.setLogOverlayMinimized(true);
    await settings.updateLogBubblePlacement(
      onRightSide: false,
      verticalRatio: 0.35,
    );

    await settings.setLogOverlayMinimized(false);
    await settings.updateLogBubblePlacement(
      onRightSide: true,
      verticalRatio: 0.8,
    );

    await settings.loadSettings();

    expect(settings.isLogOverlayMinimized, isFalse);
    expect(settings.logBubbleOnRightSide, isTrue);
    expect(settings.logBubbleVerticalRatio, 0.8);
  });
}
