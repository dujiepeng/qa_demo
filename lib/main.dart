import 'package:flutter/material.dart';

import 'package:im_flutter_sdk/im_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // EMOptions options = EMOptions.withAppKey(
  //   'easemob-demo#dujiepeng',
  //   imServer: 'msync-im-qa-hsb.easemob.com',
  //   imPort: 6717,
  //   restServer: 'https://a1-qa-hsb.easemob.com',
  // );

  EMOptions options = EMOptions.withAppKey(
    'easemob#dutest',
    autoLogin: false,
    debugMode: true,
  );

  await EMClient.getInstance.init(options);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      appBar: AppBar(title: Text('QA Flutter')),
      body: ListView(
        children: [
          TextButton(
            onPressed: () async {
              await EMClient.getInstance.loginWithPassword(userId, '1');
            },
            child: Text('Login'),
          ),

          TextButton(
            onPressed: () async {
              await EMClient.getInstance.chatRoomManager.joinChatRoom(roomId);
            },
            child: Text('Join Chat Room'),
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
            child: Text('Send Message'),
          ),
          TextButton(
            onPressed: () async {
              await EMClient.getInstance.chatRoomManager.leaveChatRoom(roomId);
            },
            child: Text('Leave Chat Room'),
          ),

          TextButton(
            onPressed: () async {
              await EMClient.getInstance.logout();
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
