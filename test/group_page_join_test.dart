import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/group/group_page.dart';

void main() {
  void useLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'group message long press opens thread creation with parent message id',
    (tester) async {
      useLargeViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: GroupPage(
            groupId: 'group-001',
            showAppBar: false,
            groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(GroupPage)) as dynamic;
      final message = EMMessage.fromJson({
        'from': 'alice',
        'to': 'group-001',
        'body': {
          'type': MessageType.TXT.index,
          'content': 'thread parent message',
        },
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'msg-thread-parent-001',
        'convId': 'group-001',
        'chatType': ChatType.GroupChat.index,
        'status': MessageStatus.SUCCESS.index,
      });
      state.addReceiveLog(
        'alice: thread parent message',
        attachment: message,
        tag: 'message',
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.textContaining('thread parent message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('创建子区'));
      await tester.pumpAndSettle();

      expect(find.textContaining('当前父级群组 ID: group-001'), findsOneWidget);
      expect(
        find.textContaining('当前父消息 ID: msg-thread-parent-001'),
        findsOneWidget,
      );

      await tester.tap(find.text('创建').last);
      await tester.pumpAndSettle();

      expect(find.text('创建子区'), findsOneWidget);
      expect(find.text('父级群组 ID: group-001'), findsOneWidget);
      expect(find.text('父消息 ID: msg-thread-parent-001'), findsOneWidget);
      expect(find.widgetWithText(TextField, '父消息 ID'), findsNothing);
    },
  );

  testWidgets('creating a group sends configured options to SDK callback', (
    tester,
  ) async {
    String? createdName;
    String? createdDesc;
    List<String>? createdMembers;
    String? createdReason;
    EMGroupOptions? createdOptions;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupCreator:
              ({
                groupName,
                desc,
                inviteMembers,
                inviteReason,
                required options,
              }) async {
                createdName = groupName;
                createdDesc = desc;
                createdMembers = inviteMembers;
                createdReason = inviteReason;
                createdOptions = options;
                return EMGroup(groupId: 'group-created');
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '群组名称'), 'qa group');
    await tester.enterText(find.widgetWithText(TextField, '群组描述'), 'desc');
    await tester.enterText(
      find.widgetWithText(TextField, '邀请成员，英文逗号分隔'),
      'alice,bob',
    );
    await tester.enterText(find.widgetWithText(TextField, '创建/邀请原因'), 'reason');
    await tester.enterText(find.widgetWithText(TextField, '最大人数'), '100');
    await tester.tap(find.text('私有成员可邀请'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('公开自由加入').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('需要确认'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(createdName, 'qa group');
    expect(createdDesc, 'desc');
    expect(createdMembers, ['alice', 'bob']);
    expect(createdReason, 'reason');
    expect(createdOptions?.style, EMGroupStyle.PublicOpenJoin);
    expect(createdOptions?.inviteNeedConfirm, isTrue);
    expect(createdOptions?.maxCount, 100);
    expect(find.text('Leave'), findsOneWidget);
  });

  testWidgets('approval-required group sends join request instead of joining', (
    tester,
  ) async {
    var joined = false;
    var requestedGroupId = '';

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupInfoLoader: (_) async =>
              EMGroup(groupId: 'group-001', isMemberOnly: true),
          publicGroupJoiner: (_) async {
            joined = true;
          },
          publicGroupJoinRequester: (groupId, {reason}) async {
            requestedGroupId = groupId;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'group-001');
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joined, isFalse);
    expect(requestedGroupId, 'group-001');
    expect(find.textContaining('已发送入群申请'), findsOneWidget);
    expect(find.text('group-001(群)'), findsNothing);
  });

  testWidgets('open public group joins directly', (tester) async {
    var joinedGroupId = '';
    var requested = false;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupInfoLoader: (_) async =>
              EMGroup(groupId: 'group-001', isMemberOnly: false),
          publicGroupJoiner: (groupId) async {
            joinedGroupId = groupId;
          },
          publicGroupJoinRequester: (_, {reason}) async {
            requested = true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'group-001');
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joinedGroupId, 'group-001');
    expect(requested, isFalse);
    expect(find.textContaining('加入成功'), findsOneWidget);
  });

  testWidgets('missing approval flag does not guess join path', (tester) async {
    var joined = false;
    var requested = false;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          publicGroupJoiner: (_) async {
            joined = true;
          },
          publicGroupJoinRequester: (_, {reason}) async {
            requested = true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'group-001');
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joined, isFalse);
    expect(requested, isFalse);
    expect(find.textContaining('服务端未返回入群审批信息'), findsOneWidget);
  });

  testWidgets('destroy group action is disabled for non owner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Admin,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final destroyButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('解散'), matching: find.byType(ElevatedButton)),
    );
    expect(destroyButton.onPressed, isNull);
  });

  testWidgets('group owner can destroy group after confirmation', (
    tester,
  ) async {
    useLargeViewport(tester);
    String? destroyedGroupId;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Owner,
          ),
          groupDestroyer: (groupId) async {
            destroyedGroupId = groupId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final destroyButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('解散'), matching: find.byType(ElevatedButton)),
    );
    expect(destroyButton.onPressed, isNotNull);

    await tester.tap(find.text('解散'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定解散'));
    await tester.pumpAndSettle();

    expect(destroyedGroupId, 'group-001');
    expect(find.text('Join'), findsOneWidget);
  });

  testWidgets('regular member can block and unblock group messages', (
    tester,
  ) async {
    useLargeViewport(tester);
    var messageBlocked = false;
    final calls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Member,
            messageBlocked: messageBlocked,
          ),
          groupMessageBlocker: (groupId) async {
            calls.add('block:$groupId');
            messageBlocked = true;
          },
          groupMessageUnblocker: (groupId) async {
            calls.add('unblock:$groupId');
            messageBlocked = false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('屏蔽消息'), findsOneWidget);
    var blockButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('屏蔽消息'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(blockButton.onPressed, isNotNull);

    await tester.tap(find.text('屏蔽消息'));
    await tester.pumpAndSettle();

    expect(calls, ['block:group-001']);
    expect(find.text('解除屏蔽'), findsOneWidget);

    final unblockButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('解除屏蔽'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(unblockButton.onPressed, isNotNull);

    await tester.tap(find.text('解除屏蔽'));
    await tester.pumpAndSettle();

    expect(calls, ['block:group-001', 'unblock:group-001']);
    expect(find.text('屏蔽消息'), findsOneWidget);
  });

  testWidgets('owner and admin cannot block group messages', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Admin,
            messageBlocked: false,
          ),
          groupMessageBlocker: (_) async {
            calls += 1;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final adminBlockButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('屏蔽消息'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(adminBlockButton.onPressed, isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Owner,
            messageBlocked: false,
          ),
          groupMessageBlocker: (_) async {
            calls += 1;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ownerBlockButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('屏蔽消息'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(ownerBlockButton.onPressed, isNull);
    expect(calls, 0);
  });

  testWidgets('group page logs invitation declined callback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    EMClient.getInstance.groupManager
        .getEventHandler('group_test')
        ?.onInvitationDeclinedFromGroup
        ?.call('group-001', 'user-b', 'busy');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('onInvitationDeclinedFromGroup'),
      findsOneWidget,
    );
    expect(find.textContaining('invitee: user-b'), findsOneWidget);
    expect(find.textContaining('reason: busy'), findsOneWidget);
  });

  testWidgets('group page sends targeted message with receiver list', (
    tester,
  ) async {
    EMMessage? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          messageSender: (message) async {
            sentMessage = message;
            return message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '定向接收人，英文逗号分隔，最多 20 个'),
      'alice, bob',
    );
    await tester.enterText(find.widgetWithText(TextField, '输入消息内容'), 'hello');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(sentMessage, isNotNull);
    expect(sentMessage!.receiverList, ['alice', 'bob']);
    expect(find.textContaining('开始发送定向消息: alice, bob'), findsOneWidget);
  });

  testWidgets('group page selects members and fills targeted receiver input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          groupMembersLoader: (_, {cursor = '', pageSize = 50}) async =>
              EMCursorResult<String>('', const ['alice', 'bob', 'charlie']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.tap(find.text('charlie'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final receiverField = tester.widget<TextField>(
      find.widgetWithText(TextField, '定向接收人，英文逗号分隔，最多 20 个'),
    );
    expect(receiverField.controller?.text, 'alice, charlie');
  });

  testWidgets(
    'group page select all fills loaded members up to receiver limit',
    (tester) async {
      final members = List<String>.generate(25, (index) => 'user$index');

      await tester.pumpWidget(
        MaterialApp(
          home: GroupPage(
            groupId: 'group-001',
            showAppBar: false,
            groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
            groupMembersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', members),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('选择'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('全选'));
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      final receiverField = tester.widget<TextField>(
        find.widgetWithText(TextField, '定向接收人，英文逗号分隔，最多 20 个'),
      );
      expect(receiverField.controller?.text, members.take(20).join(', '));
    },
  );

  testWidgets('group page rejects targeted message receiver list over limit', (
    tester,
  ) async {
    EMMessage? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          messageSender: (message) async {
            sentMessage = message;
            return message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final receivers = List.generate(21, (index) => 'u$index').join(',');
    await tester.enterText(
      find.widgetWithText(TextField, '定向接收人，英文逗号分隔，最多 20 个'),
      receivers,
    );
    await tester.enterText(find.widgetWithText(TextField, '输入消息内容'), 'hello');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(sentMessage, isNull);
    expect(find.textContaining('定向消息接收人最多 20 个'), findsOneWidget);
  });

  testWidgets('group message log can send and fetch read acknowledgements', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? ackMsgId;
    String? ackGroupId;
    String? fetchMsgId;
    String? fetchGroupId;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          groupMessageReadAckSender: (msgId, groupId, {content}) async {
            ackMsgId = msgId;
            ackGroupId = groupId;
          },
          groupAcksFetcher:
              (msgId, groupId, {startAckId, pageSize = 20}) async {
                fetchMsgId = msgId;
                fetchGroupId = groupId;
                return EMCursorResult<EMGroupMessageAck>('', [
                  EMGroupMessageAck(
                    messageId: msgId,
                    from: 'alice',
                    content: 'qa_group_read_ack',
                    readCount: 1,
                    timestamp: 1,
                  ),
                ]);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(GroupPage)) as dynamic;
    final message = EMMessage.fromJson({
      'from': 'alice',
      'to': 'group-001',
      'body': {
        'type': MessageType.TXT.index,
        'content': 'received group message',
      },
      'direction': MessageDirection.RECEIVE.index,
      'hasRead': false,
      'hasReadAck': false,
      'hasDeliverAck': false,
      'needGroupAck': true,
      'msgId': 'msg-001',
      'convId': 'group-001',
      'chatType': ChatType.GroupChat.index,
      'status': MessageStatus.SUCCESS.index,
    });
    state.addReceiveLog(
      'alice: received group message',
      attachment: message,
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('received group message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送群回执'));
    await tester.pumpAndSettle();

    expect(ackMsgId, 'msg-001');
    expect(ackGroupId, 'group-001');
    expect(find.textContaining('发送群消息已读回执成功'), findsOneWidget);

    await tester.longPress(find.textContaining('received group message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('回执详情'));
    await tester.pumpAndSettle();

    expect(fetchMsgId, 'msg-001');
    expect(fetchGroupId, 'group-001');
    expect(find.textContaining('from=alice'), findsOneWidget);
  });

  testWidgets(
    'self sent group message can request read ack and fetch ack detail',
    (tester) async {
      EMMessage? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupPage(
            groupId: 'group-001',
            showAppBar: false,
            groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
            messageSender: (message) async {
              sentMessage = message;
              return message;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '输入消息内容'), 'hello');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(sentMessage?.needGroupAck, isTrue);
    },
  );

  testWidgets('group log action forwards one message body and ext', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    EMMessage? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          messageSender: (message) async {
            sentMessage = message;
            return message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(GroupPage)) as dynamic;
    final message = EMMessage.fromJson({
      'from': 'alice',
      'to': 'group-001',
      'body': {
        'type': MessageType.TXT.index,
        'content': 'forward source message',
      },
      'direction': MessageDirection.RECEIVE.index,
      'hasRead': false,
      'hasReadAck': false,
      'hasDeliverAck': false,
      'msgId': 'msg-forward-001',
      'convId': 'group-001',
      'chatType': ChatType.GroupChat.index,
      'status': MessageStatus.SUCCESS.index,
      'attributes': {'qa_ext': 'forward', 'qa_count': 1},
    });
    state.addReceiveLog(
      'alice: forward source message',
      attachment: message,
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('forward source message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('转发'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '目标 ID'),
      'group-002',
    );
    await tester.enterText(find.widgetWithText(TextField, '类型'), 'group');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(sentMessage, isNotNull);
    expect(sentMessage!.to, 'group-002');
    expect(sentMessage!.conversationId, 'group-002');
    expect(sentMessage!.chatType, ChatType.GroupChat);
    expect(sentMessage!.body, same(message.body));
    expect(sentMessage!.attributes, equals(message.attributes));
    expect(sentMessage!.attributes, isNot(same(message.attributes)));
    expect(find.textContaining('转发消息:'), findsOneWidget);
  });

  testWidgets('group combine forward pre-fills matching message ids', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    EMMessage? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          messageSender: (message) async {
            sentMessage = message;
            return message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(GroupPage)) as dynamic;
    state.addReceiveLog(
      'alice: group combine first',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'group-001',
        'body': {'type': MessageType.TXT.index, 'content': 'first'},
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'group-local-a',
        'convId': 'group-001',
        'chatType': ChatType.GroupChat.index,
        'status': MessageStatus.SUCCESS.index,
      }),
      tag: 'message',
    );
    state.addReceiveLog(
      'alice: group combine second',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'group-001',
        'body': {'type': MessageType.TXT.index, 'content': 'second'},
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'group-local-b',
        'convId': 'group-001',
        'chatType': ChatType.GroupChat.index,
        'status': MessageStatus.SUCCESS.index,
      }),
      tag: 'message',
    );
    state.addReceiveLog(
      'alice: group combine failed',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'group-001',
        'body': {'type': MessageType.TXT.index, 'content': 'failed'},
        'direction': MessageDirection.SEND.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'group-local-failed',
        'convId': 'group-001',
        'chatType': ChatType.GroupChat.index,
        'status': MessageStatus.FAIL.index,
      }),
      tag: 'message',
    );
    state.addReceiveLog(
      'alice: wrong type',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'bob',
        'body': {'type': MessageType.TXT.index, 'content': 'single'},
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'single-local-a',
        'convId': 'bob',
        'chatType': ChatType.Chat.index,
        'status': MessageStatus.SUCCESS.index,
      }),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('合并转发'));
    await tester.pumpAndSettle();

    final idsInput = tester.widget<TextField>(
      find.widgetWithText(TextField, '消息 ID 列表'),
    );
    expect(idsInput.controller?.text, 'group-local-b\ngroup-local-a');
    await tester.enterText(find.widgetWithText(TextField, '标题'), '群聊记录');
    await tester.enterText(
      find.widgetWithText(TextField, '摘要'),
      'Alice: group',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(sentMessage, isNotNull);
    expect(sentMessage!.to, 'group-001');
    expect(sentMessage!.conversationId, 'group-001');
    expect(sentMessage!.chatType, ChatType.GroupChat);
    expect(sentMessage!.body, isA<EMCombineMessageBody>());
    expect(sentMessage!.needGroupAck, isTrue);

    final bodyJson = sentMessage!.body.toJson();
    expect(bodyJson['messageList'], ['group-local-b', 'group-local-a']);
    expect(bodyJson['messageList'], isNot(contains('group-local-failed')));
    expect(bodyJson['messageList'], isNot(contains('single-local-a')));
    expect(bodyJson['title'], '群聊记录');
    expect(bodyJson['summary'], 'Alice: group');
    expect(find.textContaining('合并转发消息:'), findsOneWidget);
  });

  testWidgets(
    'group page fetches server announcement and logs returned value',
    (tester) async {
      useLargeViewport(tester);
      String? fetchedGroupId;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupPage(
            groupId: 'group-001',
            showAppBar: false,
            groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
            groupAnnouncementFetcher: (groupId) async {
              fetchedGroupId = groupId;
              return 'server announcement';
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('取公告'));
      await tester.pumpAndSettle();

      expect(fetchedGroupId, 'group-001');
      expect(find.textContaining('群公告: server announcement'), findsOneWidget);
    },
  );

  testWidgets('group page fetches public groups from server', (tester) async {
    useLargeViewport(tester);
    int? capturedPageSize;
    String? capturedCursor;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          publicGroupsFetcher: ({pageSize = 200, cursor}) async {
            capturedPageSize = pageSize;
            capturedCursor = cursor;
            return EMCursorResult<EMGroupInfo>('', [
              EMGroupInfo.fromJson({
                'groupId': 'public-001',
                'name': 'Public QA Group',
              }),
            ]);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('公开群'));
    await tester.pumpAndSettle();

    expect(capturedPageSize, 20);
    expect(capturedCursor, isNull);
    expect(find.textContaining('公开群: groupId=public-001'), findsOneWidget);
    expect(find.textContaining('Public QA Group'), findsOneWidget);
  });

  testWidgets('group page exposes old inviterUser API', (tester) async {
    useLargeViewport(tester);
    String? inviteGroupId;
    List<String>? inviteMembers;
    String? inviteReason;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          oldGroupInviter: (groupId, members, {reason}) async {
            inviteGroupId = groupId;
            inviteMembers = members;
            inviteReason = reason;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('旧邀请'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '成员 ID 列表'),
      'alice,bob',
    );
    await tester.enterText(find.widgetWithText(TextField, '邀请原因'), 'join qa');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(inviteGroupId, 'group-001');
    expect(inviteMembers, ['alice', 'bob']);
    expect(inviteReason, 'join qa');
    expect(find.textContaining('old inviterUser 成功'), findsOneWidget);
  });

  testWidgets('group page queries allow and mute membership from server', (
    tester,
  ) async {
    useLargeViewport(tester);
    String? allowGroupId;
    String? muteGroupId;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          groupAllowListMembershipChecker: (groupId) async {
            allowGroupId = groupId;
            return true;
          },
          groupMuteListMembershipChecker: (groupId) async {
            muteGroupId = groupId;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('查白名单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查禁言'));
    await tester.pumpAndSettle();

    expect(allowGroupId, 'group-001');
    expect(muteGroupId, 'group-001');
    expect(find.textContaining('当前用户在群白名单中: true'), findsOneWidget);
    expect(find.textContaining('当前用户在群禁言列表中: false'), findsOneWidget);
  });

  testWidgets(
    'group page updates avatar with user input and logs server group',
    (tester) async {
      useLargeViewport(tester);
      String? avatarGroupId;
      String? capturedAvatarUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupPage(
            groupId: 'group-001',
            showAppBar: false,
            groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
            groupAvatarUpdater: ({required groupId, required avatarUrl}) async {
              avatarGroupId = groupId;
              capturedAvatarUrl = avatarUrl;
              return EMGroup(
                groupId: groupId,
                groupName: 'server group',
                avatarUrl: avatarUrl,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('头像'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '群头像 URL'),
        'https://example.com/avatar.png',
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(avatarGroupId, 'group-001');
      expect(capturedAvatarUrl, 'https://example.com/avatar.png');
      expect(find.textContaining('修改群头像成功'), findsOneWidget);
      expect(find.textContaining('server group'), findsOneWidget);
    },
  );

  testWidgets('group page updates group extension with raw server API input', (
    tester,
  ) async {
    useLargeViewport(tester);
    String? extensionGroupId;
    String? extensionValue;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          groupExtensionUpdater: (groupId, extension) async {
            extensionGroupId = groupId;
            extensionValue = extension;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('群扩展'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '群扩展字段'),
      '{"qa":"group_ext"}',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(extensionGroupId, 'group-001');
    expect(extensionValue, '{"qa":"group_ext"}');
    expect(find.textContaining('更新群扩展成功'), findsOneWidget);
  });

  testWidgets('group page manages shared files with server callbacks', (
    tester,
  ) async {
    useLargeViewport(tester);
    String? listGroupId;
    String? uploadGroupId;
    String? uploadPath;
    String? downloadGroupId;
    String? downloadFileId;
    String? downloadSavePath;
    String? removeGroupId;
    String? removeFileId;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          groupSharedFileListFetcher:
              (groupId, {pageSize = 200, pageNum = 1}) async {
                listGroupId = groupId;
                return [
                  EMGroupSharedFile.fromJson({
                    'fileId': 'file-001',
                    'name': 'server.txt',
                    'owner': 'alice',
                    'fileSize': 12,
                    'createTime': 1,
                  }),
                ];
              },
          groupSharedFileUploader: (groupId, filePath) async {
            uploadGroupId = groupId;
            uploadPath = filePath;
          },
          groupSharedFileUploadPathProvider: () async => '/tmp/upload.txt',
          groupSharedFileDownloader:
              ({required groupId, required fileId, required savePath}) async {
                downloadGroupId = groupId;
                downloadFileId = fileId;
                downloadSavePath = savePath;
              },
          groupSharedFileRemover: (groupId, fileId) async {
            removeGroupId = groupId;
            removeFileId = fileId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('文件列表'));
    await tester.pumpAndSettle();

    expect(listGroupId, 'group-001');
    expect(find.textContaining('server.txt'), findsOneWidget);
    expect(find.textContaining('file-001'), findsOneWidget);

    await tester.tap(find.text('上传文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(uploadGroupId, 'group-001');
    expect(uploadPath, isNotEmpty);
    expect(find.textContaining('上传群共享文件成功'), findsOneWidget);

    await tester.tap(find.text('下载文件'));
    await tester.pumpAndSettle();
    final fileIdField = tester.widget<TextField>(
      find.widgetWithText(TextField, '共享文件 ID'),
    );
    final savePathField = tester.widget<TextField>(
      find.widgetWithText(TextField, '保存路径'),
    );
    expect(fileIdField.controller?.text, 'file-001');
    expect(savePathField.controller?.text, contains('server.txt'));
    await tester.enterText(
      find.widgetWithText(TextField, '保存路径'),
      '/tmp/file.txt',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(downloadGroupId, 'group-001');
    expect(downloadFileId, 'file-001');
    expect(downloadSavePath, '/tmp/file.txt');
    expect(find.textContaining('下载群共享文件成功'), findsOneWidget);

    await tester.tap(find.text('删文件'));
    await tester.pumpAndSettle();
    final removeFileIdField = tester.widget<TextField>(
      find.widgetWithText(TextField, '共享文件 ID'),
    );
    expect(removeFileIdField.controller?.text, 'file-001');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(removeGroupId, 'group-001');
    expect(removeFileId, 'file-001');
    expect(find.textContaining('删除群共享文件成功'), findsOneWidget);
  });

  testWidgets('group page exposes old group name and desc APIs', (
    tester,
  ) async {
    useLargeViewport(tester);
    String? oldNameGroupId;
    String? oldNameValue;
    String? oldDescGroupId;
    String? oldDescValue;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          oldGroupNameUpdater: (groupId, name) async {
            oldNameGroupId = groupId;
            oldNameValue = name;
          },
          oldGroupDescriptionUpdater: (groupId, desc) async {
            oldDescGroupId = groupId;
            oldDescValue = desc;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('旧名称'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '群组名称(old)'),
      'old name',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(oldNameGroupId, 'group-001');
    expect(oldNameValue, 'old name');
    expect(find.textContaining('old changeGroupName 成功'), findsOneWidget);

    await tester.tap(find.text('旧描述'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '群组描述(old)'),
      'old desc',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(oldDescGroupId, 'group-001');
    expect(oldDescValue, 'old desc');
    expect(
      find.textContaining('old changeGroupDescription 成功'),
      findsOneWidget,
    );
  });

  testWidgets('group page fetches and sets member name card scenario', (
    tester,
  ) async {
    useLargeViewport(tester);
    String? fetchedGroupId;
    int? fetchedLimit;
    String? setGroupId;
    String? setUserId;
    Map<String, String>? setAttributes;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          groupMembersInfoFetcher:
              ({required groupId, cursor, limit = 20}) async {
                fetchedGroupId = groupId;
                fetchedLimit = limit;
                return EMCursorResult<GroupMemberInfo>('', [
                  GroupMemberInfo('alice', 123, EMGroupPermissionType.Member),
                ]);
              },
          groupMemberNameCardSetter:
              ({required groupId, required userId, required nameCard}) async {
                setGroupId = groupId;
                setUserId = userId;
                setAttributes = {'namecard': nameCard};
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('成员名片'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '成员 ID'), 'alice');
    await tester.enterText(find.widgetWithText(TextField, '名片'), 'Alice Card');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(fetchedGroupId, 'group-001');
    expect(fetchedLimit, 20);
    expect(setGroupId, 'group-001');
    expect(setUserId, 'alice');
    expect(setAttributes, {'namecard': 'Alice Card'});
    expect(find.textContaining('群成员信息: userId=alice'), findsOneWidget);
    expect(find.textContaining('设置群成员名片成功'), findsOneWidget);
  });

  testWidgets('group all-member mute logs enable and disable actions', (
    tester,
  ) async {
    useLargeViewport(tester);
    final mutedGroupIds = <String>[];
    final unmutedGroupIds = <String>[];
    var isMuted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async =>
              EMGroup(groupId: 'group-001', isAllMemberMuted: isMuted),
          groupAllMembersMuter: (groupId) async {
            mutedGroupIds.add(groupId);
            isMuted = true;
          },
          groupAllMembersUnmuter: (groupId) async {
            unmutedGroupIds.add(groupId);
            isMuted = false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部禁言'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(mutedGroupIds, ['group-001']);
    expect(find.textContaining('开启群组全部禁言成功: group-001'), findsOneWidget);

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部禁言'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(unmutedGroupIds, ['group-001']);
    expect(find.textContaining('关闭群组全部禁言成功: group-001'), findsOneWidget);
  });
}
