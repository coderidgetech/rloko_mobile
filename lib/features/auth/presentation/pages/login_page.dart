import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/dial_countries.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_logo.dart';
import '../../domain/usecases/send_login_otp_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../models/login_otp_route_extra.dart';
import '../widgets/google_g_logo.dart';
import '../widgets/phone_country_row.dart';

/// Matches web [MobileLoginPage]: phone + Send OTP → OR → Google → sign up.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.redirectAfterLogin});

  final String? redirectAfterLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _phoneLocal = '';
  DialCountry _country = kDialCountries[1];
  bool _otpSendLoading = false;
  /// True while the native Google account picker is open (before we hit the API).
  bool _googleFlowActive = false;

  String get _returnTo => widget.redirectAfterLogin ?? '/account';

  void _goSignup() {
    if (_returnTo != '/account') {
      context.push('/signup?redirect=${Uri.encodeComponent(_returnTo)}');
    } else {
      context.push('/signup');
    }
  }

  Future<void> _sendPhoneOtp() async {
    final digits = buildPhoneDigitsForApi(_country.dialCode, _phoneLocal);
    if (digits.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose country and enter your full mobile number')),
      );
      return;
    }
    setState(() => _otpSendLoading = true);
    try {
      await sl<SendLoginOtpUseCase>()(digits);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your phone')),
      );
      context.push(
        '/otp-verification',
        extra: LoginOtpRouteExtra(phone: digits, returnTo: _returnTo),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("We couldn't send the code. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _otpSendLoading = false);
    }
  }

  Future<void> _onGoogle() async {
    setState(() => _googleFlowActive = true);
    try {
      // scopeHint helps some platforms return OIDC id_token together with sign-in.
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['openid', 'email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No Google ID token. Set GOOGLE_WEB_CLIENT_ID in app env (web client) '
              'and on iOS GOOGLE_IOS_CLIENT_ID, then try again. You can also use phone OTP.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthLoginWithGoogleRequested(idToken));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[LoginPage] GoogleSignInException: code=${e.code} description=${e.description}',
        );
      }
      if (!mounted) return;
      final detail = e.description?.trim();
      final message = kDebugMode
          ? 'Google sign-in: ${(detail != null && detail.isNotEmpty) ? detail : e.code}'
          : "Google sign-in didn't work. Check app configuration (client IDs) or use phone sign-in.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[LoginPage] Google: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in error. $e")),
      );
    } finally {
      if (mounted) setState(() => _googleFlowActive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromCheckout = widget.redirectAfterLogin == '/checkout';
    final fg = AppTheme.foregroundColor(context);
    final primary = AppTheme.primaryColor(context);
    final borderSoft = fg.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              final redirect = widget.redirectAfterLogin ?? '/';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(redirect);
              });
            }
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final googleLoading = _googleFlowActive || state is AuthLoading;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: IconButton(
                      onPressed: () => context.go(fromCheckout ? '/cart' : '/'),
                      icon: Icon(Icons.close, size: 24, color: fg.withValues(alpha: 0.7)),
                      style: IconButton.styleFrom(
                        backgroundColor: fg.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (fromCheckout) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 20, color: primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sign in to place your order. You\'ll return to checkout after.',
                                    style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        const Center(child: AuthLogo()),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: fg),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your mobile number — we'll send you a code to sign in (no password)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.35, color: fg.withValues(alpha: 0.62)),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: fg.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PhoneCountryRow(
                          localPhone: _phoneLocal,
                          onLocalPhoneChanged: (v) => setState(() => _phoneLocal = v),
                          selectedCountry: _country,
                          onSelectCountry: (c) => setState(() => _country = c),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _otpSendLoading ? null : _sendPhoneOtp,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(color: borderSoft),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ).copyWith(
                            overlayColor: WidgetStateProperty.resolveWith(
                              (s) => s.contains(WidgetState.pressed)
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : null,
                            ),
                          ),
                          child: _otpSendLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Send OTP',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider(color: fg.withValues(alpha: 0.12))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(fontSize: 14, color: fg.withValues(alpha: 0.4)),
                              ),
                            ),
                            Expanded(child: Divider(color: fg.withValues(alpha: 0.12))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: googleLoading ? null : _onGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: fg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: fg.withValues(alpha: 0.12), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                          child: googleLoading
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const GoogleGLogo(size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: fg,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(fontSize: 14, color: fg.withValues(alpha: 0.6)),
                            ),
                            TextButton(
                              onPressed: _goSignup,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
