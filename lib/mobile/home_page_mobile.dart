import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'page_mobile.dart';

class HomePageMobile extends StatelessWidget {
  const HomePageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineMessageCount = context.watch<OfflineMessageCounter>().count;
    return PageMobile(offlineMessageCount: offlineMessageCount);
  }
}
