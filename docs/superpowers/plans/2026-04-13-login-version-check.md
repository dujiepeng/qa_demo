# 登录页版本检测 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在登录页提供自动静默版本检测和手动检查更新能力，并让设置页具备明确的“检查新版本”入口与结果反馈。

**Architecture:** 扩展 `VersionManager` 为可表达检测状态和结果的统一服务，登录页与设置页都复用这一层。登录页只做静默红点提示和手动结果反馈，登录后的首页仍然保留现有主动提醒逻辑，避免职责混乱。

**Tech Stack:** Flutter, Provider, ChangeNotifier, http, flutter_test

---

### Task 1: 为 `VersionManager` 建立可测试的结果模型

**Files:**
- Modify: `lib/common/utils/version_manager.dart`
- Test: `test/version_manager_test.dart`

- [ ] **Step 1: 写出失败测试，覆盖手动检测的三种结果**

```dart
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
          'html_url': 'https://github.com/dujiepeng/qa_demo/releases/tag/v9.9.9+999',
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
          'html_url': 'https://github.com/dujiepeng/qa_demo/releases/tag/v1.0.0+1',
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
}
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `flutter test test/version_manager_test.dart`

Expected: FAIL，提示 `VersionCheckStatus`、`debugParseReleaseResponse` 或 `VersionCheckResult` 未定义。

- [ ] **Step 3: 为 `VersionManager` 增加结果模型和解析入口**

```dart
enum VersionCheckStatus { idle, checking, hasUpdate, upToDate, networkError }

class VersionCheckResult {
  const VersionCheckResult({
    required this.status,
    this.latestVersion = '',
    this.releaseNotes = '',
    this.downloadUrl = '',
    this.message = '',
  });

  final VersionCheckStatus status;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String message;
}

VersionCheckResult debugParseReleaseResponse({
  required int statusCode,
  required String body,
  required String localVersion,
}) {
  return _parseReleaseResponse(
    statusCode: statusCode,
    body: body,
    localVersion: localVersion,
    changelogOverride: null,
  );
}
```

- [ ] **Step 4: 运行测试并确认通过**

Run: `flutter test test/version_manager_test.dart`

Expected: PASS，3 tests passed。

- [ ] **Step 5: 提交**

```bash
git add test/version_manager_test.dart lib/common/utils/version_manager.dart
git commit -m "test: add version manager result model coverage"
```

### Task 2: 实现统一版本检测 API，并兼容首页旧逻辑

**Files:**
- Modify: `lib/common/utils/version_manager.dart`
- Test: `test/version_manager_test.dart`

- [ ] **Step 1: 写出失败测试，覆盖状态更新与缓存行为**

```dart
test('applyCheckResult updates public fields for hasUpdate', () {
  final manager = VersionManager();

  manager.debugApplyResult(
    const VersionCheckResult(
      status: VersionCheckStatus.hasUpdate,
      latestVersion: '2.0.0+2',
      releaseNotes: 'notes',
      downloadUrl: 'https://example.com/app.apk',
    ),
  );

  expect(manager.hasNewVersion, isTrue);
  expect(manager.latestVersion, '2.0.0+2');
  expect(manager.releaseNotes, 'notes');
  expect(manager.downloadUrl, 'https://example.com/app.apk');
  expect(manager.status, VersionCheckStatus.hasUpdate);
});

test('applyCheckResult clears new-version flag for upToDate', () {
  final manager = VersionManager();

  manager.debugApplyResult(
    const VersionCheckResult(status: VersionCheckStatus.upToDate),
  );

  expect(manager.hasNewVersion, isFalse);
  expect(manager.status, VersionCheckStatus.upToDate);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `flutter test test/version_manager_test.dart`

Expected: FAIL，提示 `debugApplyResult` 或 `status` 未定义。

- [ ] **Step 3: 实现统一检测 API**

```dart
VersionCheckStatus _status = VersionCheckStatus.idle;
VersionCheckStatus get status => _status;

Future<void> silentCheck() async {
  await _runCheck(force: false, notifyOnChecking: false);
}

Future<VersionCheckResult> checkWithResult({bool force = true}) async {
  return _runCheck(force: force, notifyOnChecking: true);
}

void debugApplyResult(VersionCheckResult result) {
  _applyResult(result);
}
```

并在 `_applyResult` 中统一维护：

```dart
void _applyResult(VersionCheckResult result) {
  _status = result.status;
  _hasNewVersion = result.status == VersionCheckStatus.hasUpdate;
  _latestVersion = result.latestVersion;
  _releaseNotes = result.releaseNotes;
  _downloadUrl = result.downloadUrl;
  _lastMessage = result.message;
  notifyListeners();
}
```

- [ ] **Step 4: 更新 `main()` 和 `HomePage` 的兼容调用点**

```dart
// lib/main.dart
VersionManager().silentCheck();

// lib/pages/home_page.dart
if (VersionManager().hasNewVersion && !_hasShownUpdateDialog) {
  UpdateDialog.show(
    context,
    version: VersionManager().latestVersion,
    releaseNotes: VersionManager().releaseNotes,
    downloadUrl: VersionManager().downloadUrl,
  );
}
```

- [ ] **Step 5: 运行测试并确认通过**

Run: `flutter test test/version_manager_test.dart`

Expected: PASS，所有 `VersionManager` 单测通过。

- [ ] **Step 6: 提交**

```bash
git add lib/common/utils/version_manager.dart lib/main.dart lib/pages/home_page.dart test/version_manager_test.dart
git commit -m "feat: add structured version check state"
```

### Task 3: 改造更新弹窗，支持显式传参和下载链接回退

**Files:**
- Modify: `lib/common/widgets/update_dialog.dart`
- Test: `test/update_dialog_test.dart`

- [ ] **Step 1: 写出失败测试，覆盖显式传参与按钮行为**

```dart
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
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `flutter test test/update_dialog_test.dart`

Expected: FAIL，如果 `UpdateDialog.show` 仍强依赖 `VersionManager`，相关行为无法独立覆盖。

- [ ] **Step 3: 调整 `UpdateDialog.show` 签名**

```dart
static void show(
  BuildContext context, {
  String? version,
  String? releaseNotes,
  String? downloadUrl,
}) {
  final resolvedVersion = version ?? VersionManager().latestVersion;
  final resolvedNotes = releaseNotes ?? VersionManager().releaseNotes;
  final resolvedDownloadUrl = downloadUrl ?? VersionManager().downloadUrl;

  if (resolvedVersion.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) => UpdateDialog(
      version: resolvedVersion,
      releaseNotes: resolvedNotes,
      downloadUrl: resolvedDownloadUrl,
    ),
  );
}
```

并调整下载逻辑：

```dart
final uri = Uri.parse(
  downloadUrl.isNotEmpty
      ? downloadUrl
      : 'https://github.com/dujiepeng/qa_demo/releases',
);
```

- [ ] **Step 4: 运行测试并确认通过**

Run: `flutter test test/update_dialog_test.dart`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/common/widgets/update_dialog.dart test/update_dialog_test.dart
git commit -m "feat: make update dialog reusable across pages"
```

### Task 4: 给登录页增加表单、更新图标、红点和手动检查

**Files:**
- Modify: `lib/mobile/login_page_mobile.dart`
- Modify: `lib/pad/login_page_pad.dart`
- Modify: `lib/common/mixins/login_logic_mixin.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: 写出失败测试，覆盖登录页更新入口存在**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/mobile/login_page_mobile.dart';

void main() {
  testWidgets('mobile login page shows version check action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPageMobile()));

    expect(find.byIcon(Icons.system_update_alt_outlined), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `flutter test test/widget_test.dart`

Expected: FAIL，找不到新图标。

- [ ] **Step 3: 在登录页引入独立的表单 key 和版本检查 loading 状态**

```dart
final _formKey = GlobalKey<FormState>();
bool _isCheckingVersion = false;

Future<void> _handleCheckVersion() async {
  setState(() => _isCheckingVersion = true);
  final result = await VersionManager().checkWithResult(force: true);
  if (!mounted) return;
  setState(() => _isCheckingVersion = false);

  switch (result.status) {
    case VersionCheckStatus.hasUpdate:
      UpdateDialog.show(
        context,
        version: result.latestVersion,
        releaseNotes: result.releaseNotes,
        downloadUrl: result.downloadUrl,
      );
      break;
    case VersionCheckStatus.upToDate:
      _showMessageDialog('当前已是最新版本');
      break;
    case VersionCheckStatus.networkError:
      _showMessageDialog(result.message.isNotEmpty ? result.message : '网络不可达，请稍后重试');
      break;
    default:
      break;
  }
}
```

- [ ] **Step 4: 在 mobile 和 pad 登录页上增加右上角检查更新图标与红点**

```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    IconButton(
      icon: Icon(
        Icons.system_update_alt_outlined,
        color: AppColors.textPrimary(isDark).withValues(alpha: 0.8),
      ),
      onPressed: _isCheckingVersion ? null : _handleCheckVersion,
    ),
    if (context.watch<VersionManager>().hasNewVersion)
      const Positioned(
        right: 10,
        top: 10,
        child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
      ),
  ],
)
```

并在 `initState()` 中执行静默检查：

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  VersionManager().silentCheck();
});
```

- [ ] **Step 5: 用 `Form` 包裹登录输入区域，并在登录按钮中调用校验**

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        controller: uidController,
        validator: (value) =>
            value == null || value.trim().isEmpty ? '请输入 UID' : null,
      ),
      TextFormField(
        controller: pwdController,
        validator: (value) =>
            value == null || value.trim().isEmpty ? '请输入 Password' : null,
      ),
    ],
  ),
)
```

登录按钮改为：

```dart
onPressed: () {
  if (_formKey.currentState?.validate() != true) return;
  handleLogin();
}
```

- [ ] **Step 6: 运行测试并确认通过**

Run: `flutter test test/widget_test.dart`

Expected: PASS，登录页能渲染检查更新入口。

- [ ] **Step 7: 提交**

```bash
git add lib/mobile/login_page_mobile.dart lib/pad/login_page_pad.dart lib/common/mixins/login_logic_mixin.dart test/widget_test.dart
git commit -m "feat: add login page version check entry"
```

### Task 5: 改造设置页，明确展示“检查新版本”入口

**Files:**
- Modify: `lib/common/widgets/me_page_content.dart`
- Test: `test/me_page_content_test.dart`

- [ ] **Step 1: 写出失败测试，覆盖设置页存在检查新版本文案**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/widgets/me_page_content.dart';
import 'package:qa_flutter/common/utils/version_manager.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  testWidgets('settings page shows check new version action', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: VersionManager()),
        ],
        child: const MaterialApp(home: MePageContent()),
      ),
    );

    expect(find.text('检查新版本'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `flutter test test/me_page_content_test.dart`

Expected: FAIL，当前页面没有“检查新版本”文案。

- [ ] **Step 3: 调整设置页尾部交互区**

```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (vm.hasNewVersion) _buildNewBadge(),
    Text(AppConfig.appVersion),
    const SizedBox(width: 8),
    Text(
      '检查新版本',
      style: TextStyle(
        color: AppColors.primary(isDark),
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
),
onTap: () async {
  final result = await VersionManager().checkWithResult(force: true);
  if (!context.mounted) return;
  // 与登录页一致地弹出结果
}
```

- [ ] **Step 4: 运行测试并确认通过**

Run: `flutter test test/me_page_content_test.dart`

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/common/widgets/me_page_content.dart test/me_page_content_test.dart
git commit -m "feat: add explicit check-new-version action in settings"
```

### Task 6: 端到端验证并清理

**Files:**
- Modify: `docs/superpowers/specs/2026-04-13-login-version-check-design.md`（仅在需要同步实现细节时）

- [ ] **Step 1: 运行针对性测试**

Run: `flutter test test/version_manager_test.dart test/update_dialog_test.dart test/me_page_content_test.dart test/widget_test.dart`

Expected: PASS，所有新增测试通过。

- [ ] **Step 2: 运行静态分析**

Run: `flutter analyze`

Expected: No issues found，或仅保留与本次无关的既有告警。

- [ ] **Step 3: 手工验证登录页和设置页交互**

Run: `flutter run`

Expected:
- 登录页初次进入时，有新版本只显示红点
- 登录页手动检查显示 loading，随后弹出对应结果
- 设置页展示“检查新版本”入口，并对三种结果给出明确反馈
- 登录页检查过程中若已登录离开，不再由登录页弹结果

- [ ] **Step 4: 提交**

```bash
git add .
git commit -m "feat: add login and settings version check flow"
```
