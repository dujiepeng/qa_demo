# Friend And Blacklist Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add real friend-list and blacklist-list pages backed by SDK data, with mobile and Pad entry points plus long-press actions for add-to-blacklist and remove-from-blacklist.

**Architecture:** Reuse the existing `SingleChatListPage` as the friend page, extend its long-press actions with blacklist support, and introduce a focused `BlackListPage` for blacklist management. Keep route registration centralized in `main.dart`, wire mobile entries through `PageMobile`, and wire Pad entries through both `PagePad` and `HomePagePad` without changing the existing master-detail layout model.

**Tech Stack:** Flutter, im_flutter_sdk, widget tests, ChangeNotifier-free page state

---

### Task 1: Register Friend And Blacklist Routes

**Files:**
- Modify: `lib/main.dart`
- Create: `test/friend_blacklist_routes_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('material app registers friend and blacklist routes', (tester) async {
  await tester.pumpWidget(const MyApp());
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));

  expect(() => navigator.pushNamed('/friend_list'), returnsNormally);
  expect(() => navigator.pushNamed('/black_list'), returnsNormally);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/friend_blacklist_routes_test.dart`
Expected: FAIL because `/friend_list` and `/black_list` are not registered.

- [ ] **Step 3: Write minimal implementation**

```dart
routes: {
  '/friend_list': (context) => const SingleChatListPage(),
  '/black_list': (context) => const BlackListPage(),
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/friend_blacklist_routes_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/friend_blacklist_routes_test.dart
git commit -m "feat: register friend and blacklist routes"
```

### Task 2: Add Mobile Entry Cards

**Files:**
- Modify: `lib/mobile/page_mobile.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('mobile page shows friend and blacklist cards', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: AppSettings(),
      child: const MaterialApp(home: PageMobile()),
    ),
  );

  expect(find.text('好友'), findsOneWidget);
  expect(find.text('黑名单'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the new cards do not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
GridItem(
  title: '好友',
  icon: Icons.people_outline,
  onTap: () => Navigator.pushNamed(context, '/friend_list'),
),
GridItem(
  title: '黑名单',
  icon: Icons.block_outlined,
  onTap: () => Navigator.pushNamed(context, '/black_list'),
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/mobile/page_mobile.dart test/widget_test.dart
git commit -m "feat: add mobile friend and blacklist entries"
```

### Task 3: Add Pad Dashboard And Quick Entries

**Files:**
- Modify: `lib/pad/page_pad.dart`
- Modify: `lib/pad/home_page_pad.dart`
- Create: `test/pad_friend_blacklist_entries_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('pad dashboard exposes friend and blacklist entries', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomePagePad()));

  expect(find.text('好友'), findsWidgets);
  expect(find.text('黑名单'), findsWidgets);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/pad_friend_blacklist_entries_test.dart`
Expected: FAIL because Pad has no friend or blacklist entries yet.

- [ ] **Step 3: Write minimal implementation**

```dart
// PagePad
FriendListPage(onItemTap: ...)
BlackListPage(onItemTap: ...)

// HomePagePad quick actions
TextButton(onPressed: () => _showDetail(const SingleChatListPage(...), '好友'))
TextButton(onPressed: () => _showDetail(const BlackListPage(...), '黑名单'))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/pad_friend_blacklist_entries_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pad/page_pad.dart lib/pad/home_page_pad.dart test/pad_friend_blacklist_entries_test.dart
git commit -m "feat: add pad friend and blacklist entries"
```

### Task 4: Extend Friend Page With Add-To-Blacklist

**Files:**
- Modify: `lib/pages/single/single_chat_list_page.dart`
- Create: `test/friend_page_actions_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('friend page long-press menu includes add to blacklist', (tester) async {
  // Build a focused harness around the menu item builder.
  expect(find.text('加入黑名单'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/friend_page_actions_test.dart`
Expected: FAIL because the long-press menu only has copy and delete.

- [ ] **Step 3: Write minimal implementation**

```dart
const PopupMenuItem(
  value: 'add_to_blacklist',
  child: Text('加入黑名单'),
)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/friend_page_actions_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/single/single_chat_list_page.dart test/friend_page_actions_test.dart
git commit -m "feat: add blacklist action to friend page"
```

### Task 5: Implement Friend Page Blacklist Operation

**Files:**
- Modify: `lib/pages/single/single_chat_list_page.dart`
- Modify: `test/friend_page_actions_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('adding a friend to blacklist refreshes list after success', () async {
  // Fake contact manager add-to-blacklist call.
  // Expect refresh callback to run after success.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/friend_page_actions_test.dart`
Expected: FAIL because there is no blacklist operation implementation yet.

- [ ] **Step 3: Write minimal implementation**

```dart
Future<void> _addToBlackList(String userId) async {
  await EMClient.getInstance.contactManager.addUserToBlackList(userId, false);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已加入黑名单')),
  );
  await _fetchContacts();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/friend_page_actions_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/single/single_chat_list_page.dart test/friend_page_actions_test.dart
git commit -m "feat: support add-to-blacklist from friend page"
```

### Task 6: Create BlackListPage

**Files:**
- Create: `lib/pages/single/black_list_page.dart`
- Create: `test/black_list_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('blacklist page shows empty state when no users exist', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: BlackListPage()));
  expect(find.text('暂无黑名单用户'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/black_list_page_test.dart`
Expected: FAIL because `BlackListPage` does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
class BlackListPage extends StatefulWidget { ... }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/black_list_page_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/single/black_list_page.dart test/black_list_page_test.dart
git commit -m "feat: add blacklist page"
```

### Task 7: Add Remove-From-Blacklist Long-Press Action

**Files:**
- Modify: `lib/pages/single/black_list_page.dart`
- Modify: `test/black_list_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('blacklist page long-press menu includes remove from blacklist', (tester) async {
  // Build page with one blocked user.
  expect(find.text('移出黑名单'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/black_list_page_test.dart`
Expected: FAIL because the long-press menu and action do not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
const PopupMenuItem(
  value: 'remove_from_blacklist',
  child: Text('移出黑名单'),
)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/black_list_page_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/single/black_list_page.dart test/black_list_page_test.dart
git commit -m "feat: add remove-from-blacklist action"
```

### Task 8: Full Verification

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/mobile/page_mobile.dart`
- Modify: `lib/pad/page_pad.dart`
- Modify: `lib/pad/home_page_pad.dart`
- Modify: `lib/pages/single/single_chat_list_page.dart`
- Create: `lib/pages/single/black_list_page.dart`
- Test: `test/friend_blacklist_routes_test.dart`
- Test: `test/pad_friend_blacklist_entries_test.dart`
- Test: `test/friend_page_actions_test.dart`
- Test: `test/black_list_page_test.dart`

- [ ] **Step 1: Run focused tests**

Run: `flutter test test/friend_blacklist_routes_test.dart test/pad_friend_blacklist_entries_test.dart test/friend_page_actions_test.dart test/black_list_page_test.dart`
Expected: PASS

- [ ] **Step 2: Run project verification**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass

- [ ] **Step 3: Commit final cleanups**

```bash
git add lib/main.dart lib/mobile/page_mobile.dart lib/pad/page_pad.dart lib/pad/home_page_pad.dart lib/pages/single/single_chat_list_page.dart lib/pages/single/black_list_page.dart test/friend_blacklist_routes_test.dart test/pad_friend_blacklist_entries_test.dart test/friend_page_actions_test.dart test/black_list_page_test.dart
git commit -m "feat: add friend and blacklist management pages"
```
