import 'package:flutter/material.dart';
import '../common/widgets/me_page_content.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MePageContent(showAppBar: true);
  }
}
