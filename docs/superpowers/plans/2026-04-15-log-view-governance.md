# LogView Governance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `LogView` into a reusable, better-performing log list with declarative long-press actions and persistent per-item overlay labels.

**Architecture:** Keep the existing `LogController` ownership model in each page, but extend `LogEntry` with overlay UI state and replace page-owned popup menu wiring with a shared `LogAction` / `LogActionResult` contract in `LogView`. Split rendering into a focused log item widget so menu styling, overlay presentation, and per-entry updates stay centralized while single chat, group, and chatroom pages only declare actions.

**Tech Stack:** Flutter, ChangeNotifier, widget tests, unit tests

---

### Task 1: Extend Log Models for Overlay State

**Files:**
- Modify: `lib/common/widgets/log_view.dart`
- Test: `test/log_view_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('updates overlay label and clears it for a specific entry', () {
  final controller = LogController();
  final entry = controller.addLog('hello');

  controller.updateEntry(entry, overlayLabel: '已复制');
  expect(controller.entities.single.overlayLabel, '已复制');

  controller.updateEntry(entry, clearOverlay: true);
  expect(controller.entities.single.overlayLabel, isNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/log_view_controller_test.dart`
Expected: FAIL because `overlayLabel` / `clearOverlay` are not defined yet.

- [ ] **Step 3: Write minimal implementation**

```dart
class LogEntry {
  String? overlayLabel;
  LogOverlayStyle overlayStyle;
}

void updateEntry(
  LogEntry entry, {
  String? overlayLabel,
  LogOverlayStyle? overlayStyle,
  bool clearOverlay = false,
}) {
  if (clearOverlay) {
    entry.overlayLabel = null;
  } else if (overlayLabel != null) {
    entry.overlayLabel = overlayLabel;
    entry.overlayStyle = overlayStyle ?? entry.overlayStyle;
  }
  notifyListeners();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/log_view_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/common/widgets/log_view.dart test/log_view_controller_test.dart
git commit -m "refactor: add overlay state to log entries"
```

### Task 2: Introduce Declarative Log Actions

**Files:**
- Modify: `lib/common/widgets/log_view.dart`
- Test: `test/log_view_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('shows only visible log actions on long press', (tester) async {
  final controller = LogController()..addLog('hello', tag: 'message');

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 240,
          child: LogView(
            controller: controller,
            isDark: true,
            actionsBuilder: (entry) => [
              LogAction(
                id: 'copy',
                title: '复制',
                onSelected: (_) async => null,
              ),
              LogAction(
                id: 'hidden',
                title: '隐藏',
                isVisible: (_) => false,
                onSelected: (_) async => null,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  await tester.longPress(find.textContaining('hello'));
  await tester.pumpAndSettle();

  expect(find.text('复制'), findsOneWidget);
  expect(find.text('隐藏'), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/log_view_test.dart`
Expected: FAIL because `LogAction` and `actionsBuilder` do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
typedef LogActionsBuilder = List<LogAction> Function(LogEntry entry);

class LogAction {
  final String id;
  final String title;
  final IconData? icon;
  final Color? foregroundColor;
  final bool isDestructive;
  final bool Function(LogEntry entry)? isVisible;
  final Future<LogActionResult?> Function(LogEntry entry) onSelected;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/log_view_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/common/widgets/log_view.dart test/log_view_test.dart
git commit -m "refactor: add declarative log actions"
```

### Task 3: Render Persistent Overlay Labels Per Item

**Files:**
- Modify: `lib/common/widgets/log_view.dart`
- Test: `test/log_view_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('renders centered overlay label without replacing log text', (
  tester,
) async {
  final controller = LogController();
  controller.addLog('hello');
  controller.updateEntry(
    controller.entities.single,
    overlayLabel: '已复制',
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 240,
          child: LogView(controller: controller, isDark: true),
        ),
      ),
    ),
  );

  expect(find.textContaining('hello'), findsOneWidget);
  expect(find.text('已复制'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/log_view_test.dart`
Expected: FAIL because overlay label is not rendered.

- [ ] **Step 3: Write minimal implementation**

```dart
class _LogViewItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildLogText(entry),
        if (entry.overlayLabel != null && entry.overlayLabel!.isNotEmpty)
          IgnorePointer(child: _buildOverlayChip(entry)),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/log_view_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/common/widgets/log_view.dart test/log_view_test.dart
git commit -m "feat: add persistent overlay labels to log items"
```

### Task 4: Apply Action Results to Entries in LogView

**Files:**
- Modify: `lib/common/widgets/log_view.dart`
- Test: `test/log_view_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('applies action result overlay to the selected entry', (tester) async {
  final controller = LogController()..addLog('hello');

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 240,
          child: LogView(
            controller: controller,
            isDark: true,
            actionsBuilder: (entry) => [
              LogAction(
                id: 'copy',
                title: '复制',
                onSelected: (_) async => const LogActionResult(
                  overlayLabel: '已复制',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  await tester.longPress(find.textContaining('hello'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('复制'));
  await tester.pumpAndSettle();

  expect(find.text('已复制'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/log_view_test.dart`
Expected: FAIL because selected action results are not applied back to the entry.

- [ ] **Step 3: Write minimal implementation**

```dart
Future<void> _handleActionSelected(LogEntry entry, LogAction action) async {
  final result = await action.onSelected(entry);
  if (result == null) return;
  controller.updateEntry(
    entry,
    content: result.content,
    color: result.color,
    style: result.style,
    overlayLabel: result.overlayLabel,
    overlayStyle: result.overlayStyle,
    clearOverlay: result.clearOverlay,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/log_view_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/common/widgets/log_view.dart test/log_view_test.dart
git commit -m "feat: apply log action results to entries"
```

### Task 5: Migrate Single Chat, Group, and Room Pages

**Files:**
- Modify: `lib/pages/single/single_chat_page.dart`
- Modify: `lib/pages/group/group_page.dart`
- Modify: `lib/pages/chatroom/room_page.dart`
- Test: `test/log_view_page_actions_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('single chat copy action returns persistent overlay text', (
  tester,
) async {
  // Build a focused harness around the page action factory or helper.
  // Expect returned LogActionResult to contain overlayLabel: '已复制'.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/log_view_page_actions_test.dart`
Expected: FAIL because pages still use old `LogMenuItem` wiring.

- [ ] **Step 3: Write minimal implementation**

```dart
actionsBuilder: (entry) => [
  LogAction(
    id: 'copy',
    title: '复制',
    icon: Icons.copy_outlined,
    onSelected: (_) async {
      await Clipboard.setData(ClipboardData(text: text));
      return const LogActionResult(
        overlayLabel: '已复制',
        overlayStyle: LogOverlayStyle.info,
      );
    },
  ),
]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/log_view_page_actions_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/single/single_chat_page.dart lib/pages/group/group_page.dart lib/pages/chatroom/room_page.dart test/log_view_page_actions_test.dart
git commit -m "refactor: migrate page log menus to log actions"
```

### Task 6: Full Verification

**Files:**
- Modify: `lib/common/widgets/log_view.dart`
- Modify: `lib/pages/single/single_chat_page.dart`
- Modify: `lib/pages/group/group_page.dart`
- Modify: `lib/pages/chatroom/room_page.dart`
- Test: `test/log_view_controller_test.dart`
- Test: `test/log_view_test.dart`
- Test: `test/log_view_page_actions_test.dart`

- [ ] **Step 1: Run focused tests**

Run: `flutter test test/log_view_controller_test.dart test/log_view_test.dart test/log_view_page_actions_test.dart`
Expected: PASS

- [ ] **Step 2: Run project verification**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass

- [ ] **Step 3: Commit final cleanups**

```bash
git add lib/common/widgets/log_view.dart lib/pages/single/single_chat_page.dart lib/pages/group/group_page.dart lib/pages/chatroom/room_page.dart test/log_view_controller_test.dart test/log_view_test.dart test/log_view_page_actions_test.dart
git commit -m "refactor: modernize reusable log view"
```
