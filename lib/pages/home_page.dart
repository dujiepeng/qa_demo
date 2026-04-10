import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/mixins/login_logic_mixin.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/update_dialog.dart';
import '../common/widgets/responsive_layout.dart';
import '../mobile/home_page_mobile.dart';
import '../pad/home_page_pad.dart';
import '../theme/app_settings.dart';

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
    // 冷启动时，已登录状态会直接跳到 /home，跳过登录页的 SDK 初始化流程。
    // 此处补一次 ensureSdkInit，确保 SDK 在任何情况下都被正确初始化。
    // 若 isInit 已为 true（正常登录流程进入），则此调用为空操作，不影响性能。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final settings = context.read<AppSettings>();
      await ensureSdkInit(settings);
    });
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
