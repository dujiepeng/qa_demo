import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/widgets/update_dialog.dart';

void main() {
  testWidgets('renders explicit version and release notes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UpdateDialog(
            version: '2.0.0+2',
            releaseNotes: 'line1',
            downloadUrl: 'https://example.com/app.apk',
          ),
        ),
      ),
    );

    expect(find.text('发现新版本 2.0.0+2'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
  });
}
