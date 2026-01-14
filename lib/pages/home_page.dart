import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void addListener() {
    EMClient.getInstance.chatRoomManager.addEventHandler(
      'identifier',
      EMChatRoomEventHandler(
        onMemberJoinedFromChatRoom: (roomId, participant, ext) {
          debugPrint('member joined: $participant');
        },
        onMemberExitedFromChatRoom: (roomId, roomName, participant) {
          debugPrint('member exited: $participant');
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    addListener();
  }

  String roomId = '302384032055299';
  String userId = 'du002';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QA Flutter')),
      body: ListView(
        children: [
          TextButton(
            onPressed: () async {
              await EMClient.getInstance.loginWithPassword(userId, '1');
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () async {
              await EMClient.getInstance.chatRoomManager.joinChatRoom(roomId);
            },
            child: const Text('Join Chat Room'),
          ),
          TextButton(
            onPressed: () async {
              final mes = EMMessage.createTxtSendMessage(
                targetId: roomId,
                content: 'hello',
                chatType: ChatType.ChatRoom,
              );
              await EMClient.getInstance.chatManager.sendMessage(mes);
            },
            child: const Text('Send Message'),
          ),
          TextButton(
            onPressed: () async {
              await EMClient.getInstance.chatRoomManager.leaveChatRoom(roomId);
            },
            child: const Text('Leave Chat Room'),
          ),
          TextButton(
            onPressed: () async {
              await EMClient.getInstance.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
