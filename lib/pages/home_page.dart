import 'package:flutter/material.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/update_dialog.dart';
import '../common/widgets/responsive_layout.dart';
import '../mobile/home_page_mobile.dart';
import '../pad/home_page_pad.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    VersionManager().addListener(_checkAndShowUpdateDialog);
  }

  @override
  void dispose() {
    VersionManager().removeListener(_checkAndShowUpdateDialog);
    super.dispose();
  }

  bool _hasShownUpdateDialog = false;

  void _checkAndShowUpdateDialog() {
    if (!mounted) return;
    if (VersionManager().hasNewVersion && !_hasShownUpdateDialog) {
      _hasShownUpdateDialog = true;
      UpdateDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: HomePageMobile(),
      tablet: HomePagePad(),
    );
  }
}
