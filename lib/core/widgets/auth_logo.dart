import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo text for auth screens; matches React Logo on MobileLoginPage/MobileSignupPage.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Rloco',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppTheme.foregroundColor(context),
        letterSpacing: -0.5,
      ),
    );
  }
}
