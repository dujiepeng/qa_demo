import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/version_manager.dart';

void main() {
  group('VersionManager parsing helpers', () {
    test('maps newer remote version to hasUpdate result', () {
      final manager = VersionManager();
      final result = manager.debugParseReleaseResponse(
        statusCode: 200,
        body: jsonEncode({
          'tag_name': 'v9.9.9+999',
          'html_url':
              'https://github.com/dujiepeng/qa_demo/releases/tag/v9.9.9+999',
          'body': 'notes',
          'assets': [
            {
              'name': 'app-arm64-v8a-release.apk',
              'browser_download_url': 'https://example.com/app.apk',
            },
          ],
        }),
        localVersion: '1.0.0+1',
      );

      expect(result.status, VersionCheckStatus.hasUpdate);
      expect(result.latestVersion, '9.9.9+999');
      expect(result.downloadUrl, 'https://example.com/app.apk');
    });

    test('maps same version to upToDate result', () {
      final manager = VersionManager();
      final result = manager.debugParseReleaseResponse(
        statusCode: 200,
        body: jsonEncode({
          'tag_name': 'v1.0.0+1',
          'html_url':
              'https://github.com/dujiepeng/qa_demo/releases/tag/v1.0.0+1',
          'body': 'notes',
          'assets': [],
        }),
        localVersion: '1.0.0+1',
      );

      expect(result.status, VersionCheckStatus.upToDate);
    });

    test('maps non-200 response to networkError result', () {
      final manager = VersionManager();
      final result = manager.debugParseReleaseResponse(
        statusCode: 500,
        body: '{}',
        localVersion: '1.0.0+1',
      );

      expect(result.status, VersionCheckStatus.networkError);
      expect(result.message, isNotEmpty);
    });
  });

  group('VersionManager state updates', () {
    test('applyCheckResult updates public fields for hasUpdate', () {
      final manager = VersionManager();

      manager.debugApplyResult(
        const VersionCheckResult(
          status: VersionCheckStatus.hasUpdate,
          latestVersion: '2.0.0+2',
          releaseNotes: 'notes',
          downloadUrl: 'https://example.com/app.apk',
        ),
        source: VersionCheckSource.manualSettings,
      );

      expect(manager.hasNewVersion, isTrue);
      expect(manager.latestVersion, '2.0.0+2');
      expect(manager.releaseNotes, 'notes');
      expect(manager.downloadUrl, 'https://example.com/app.apk');
      expect(manager.status, VersionCheckStatus.hasUpdate);
      expect(manager.lastCheckSource, VersionCheckSource.manualSettings);
    });

    test('applyCheckResult clears new-version flag for upToDate', () {
      final manager = VersionManager();

      manager.debugApplyResult(
        const VersionCheckResult(status: VersionCheckStatus.upToDate),
        source: VersionCheckSource.loginSilent,
      );

      expect(manager.hasNewVersion, isFalse);
      expect(manager.status, VersionCheckStatus.upToDate);
      expect(manager.lastCheckSource, VersionCheckSource.loginSilent);
    });

    test('login silent check refreshes stale new-version flag', () async {
      final manager = VersionManager();
      manager.debugApplyResult(
        const VersionCheckResult(
          status: VersionCheckStatus.hasUpdate,
          latestVersion: '2.0.0+2',
        ),
        source: VersionCheckSource.startupSilent,
      );
      manager.debugSetLastCheckTime(DateTime.now());

      var calls = 0;
      manager.debugSetCheckRunner(({
        required bool force,
        required bool notifyOnChecking,
        required VersionCheckSource source,
      }) async {
        calls++;
        expect(source, VersionCheckSource.loginSilent);
        return const VersionCheckResult(status: VersionCheckStatus.upToDate);
      });
      addTearDown(() {
        manager.debugSetCheckRunner(null);
        manager.debugSetLastCheckTime(null);
      });

      await manager.silentCheck(source: VersionCheckSource.loginSilent);

      expect(calls, 1);
      expect(manager.hasNewVersion, isFalse);
      expect(manager.status, VersionCheckStatus.upToDate);
    });

    test('non-login silent check still returns cached snapshot', () async {
      final manager = VersionManager();
      manager.debugApplyResult(
        const VersionCheckResult(
          status: VersionCheckStatus.hasUpdate,
          latestVersion: '2.0.0+2',
        ),
        source: VersionCheckSource.manualSettings,
      );
      manager.debugSetLastCheckTime(DateTime.now());

      var calls = 0;
      manager.debugSetCheckRunner(({
        required bool force,
        required bool notifyOnChecking,
        required VersionCheckSource source,
      }) async {
        calls++;
        return const VersionCheckResult(status: VersionCheckStatus.upToDate);
      });
      addTearDown(() {
        manager.debugSetCheckRunner(null);
        manager.debugSetLastCheckTime(null);
      });

      await manager.silentCheck(source: VersionCheckSource.manualSettings);

      expect(calls, 0);
      expect(manager.hasNewVersion, isTrue);
      expect(manager.status, VersionCheckStatus.hasUpdate);
    });
  });
}
