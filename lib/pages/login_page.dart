import 'package:flutter/material.dart';
import '../common/widgets/responsive_layout.dart';
import '../mobile/login_page_mobile.dart';
import '../pad/login_page_pad.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: LoginPageMobile(),
      tablet: LoginPagePad(),
    );
  }
}
