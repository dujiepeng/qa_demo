# Mobile Log Overlay Filter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add keyword filtering to the home-page floating log panel so QA can narrow visible logs in place and copy only the filtered visible content.

**Architecture:** Keep raw SDK log synchronization inside `LogPanelController` and implement filtering entirely inside `LogPanel` as view state. Recompute visible text whenever the raw content or the filter keyword changes so new matching logs appear automatically.

**Tech Stack:** Flutter widget state, existing `LogPanelController`, Flutter widget tests

---

### Task 1: Add failing widget tests for filter behavior

**Files:**
- Modify: `test/mobile_log_overlay_test.dart`
- Modify: `lib/common/widgets/log_panel/log_panel.dart`

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('log panel filters visible lines by keyword', (tester) async {
  // Add a focused LogPanel test harness using injected controller callbacks.
});

testWidgets('log panel updates filtered results when new matching logs arrive', (
  tester,
) async {
  // Rebuild with updated raw content and verify matching lines appear.
});

testWidgets('log panel copies filtered visible content', (tester) async {
  // Enter filter text, trigger copy, then assert clipboard contents.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/mobile_log_overlay_test.dart`
Expected: FAIL because filter UI and filtered-copy behavior do not exist yet.

- [ ] **Step 3: Commit**

```bash
git add test/mobile_log_overlay_test.dart
git commit -m "test: cover mobile log overlay filtering"
```

### Task 2: Implement filter UI and filtered content rendering

**Files:**
- Modify: `lib/common/widgets/log_panel/log_panel.dart`

- [ ] **Step 1: Add local filter state and filtered text computation**

```dart
String _filterKeyword = '';

String get _visibleContent {
  final raw = _controller.content;
  final keyword = _filterKeyword.trim().toLowerCase();
  if (keyword.isEmpty) return raw;
  final lines = raw.split('\n');
  return lines
      .where((line) => line.toLowerCase().contains(keyword))
      .join('\n');
}
```

- [ ] **Step 2: Add filter toggle and input UI**

```dart
bool _showFilterField = false;

IconButton(
  icon: const Icon(Icons.filter_alt_outlined, size: 18),
  onPressed: () {
    setState(() {
      _showFilterField = !_showFilterField;
    });
  },
)
```

- [ ] **Step 3: Render filtered content and empty-result hint**

```dart
final visibleContent = _visibleContent;

child: visibleContent.isEmpty && _filterKeyword.trim().isNotEmpty
    ? const Text('无匹配日志')
    : SelectableText(visibleContent, ...)
```

- [ ] **Step 4: Update copy action to use filtered visible content**

```dart
final visibleContent = _visibleContent;
if (visibleContent.isNotEmpty) {
  await Clipboard.setData(ClipboardData(text: visibleContent));
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/mobile_log_overlay_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/common/widgets/log_panel/log_panel.dart test/mobile_log_overlay_test.dart
git commit -m "feat: add filtering to mobile log overlay"
```

### Task 3: Verify targeted quality gates

**Files:**
- Modify: `lib/common/widgets/log_panel/log_panel.dart`
- Test: `test/mobile_log_overlay_test.dart`

- [ ] **Step 1: Run targeted tests**

Run: `flutter test test/mobile_log_overlay_test.dart`
Expected: PASS

- [ ] **Step 2: Run static analysis on changed files**

Run: `flutter analyze lib/common/widgets/log_panel/log_panel.dart test/mobile_log_overlay_test.dart`
Expected: No issues found

- [ ] **Step 3: Commit if verification required after adjustments**

```bash
git add lib/common/widgets/log_panel/log_panel.dart test/mobile_log_overlay_test.dart
git commit -m "chore: verify mobile log overlay filter"
```
