import 'package:flutter/material.dart';
import '../common/widgets/me_page_content.dart';

class MePageMobile extends StatelessWidget {
  const MePageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return const MePageContent(showAppBar: true);
  }
}
