import 'package:flutter/material.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'package:qa_flutter/common/session_scope.dart';
import 'page_mobile.dart';

class HomePageMobile extends StatelessWidget {
  const HomePageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = maybeReadProvider<OfflineMessageCounter>(context);
    final offlineMessageCount = counter?.count ?? 0;
    return PageMobile(offlineMessageCount: offlineMessageCount);
  }
}
