import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_logo.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../domain/usecases/send_login_otp_usecase.dart';
import '../bloc/auth_bloc.dart';

/// Login OTP entry — same API flow as [DesktopOTPVerificationPage] (non-signup).
class LoginOtpVerificationPage extends StatefulWidget {
  const LoginOtpVerificationPage({
    super.key,
    required this.phone,
    required this.returnTo,
  });

  final String phone;
  final String returnTo;

  @override
  State<LoginOtpVerificationPage> createState() => _LoginOtpVerificationPageState();
}

class _LoginOtpVerificationPageState extends State<LoginOtpVerificationPage> {
  List<String> _otp = List.filled(6, '');
  int _resendTimer = 60;
  Timer? _timer;
  bool _resendLoading = false;

  @override
  void initState() {
    super.initState();
    _scheduleResendTimer();
  }

  void _scheduleResendTimer() {
    _timer?.cancel();
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer <= 1) {
          _resendTimer = 0;
          _timer?.cancel();
        } else {
          _resendTimer--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_resendTimer > 0 || _resendLoading) return;
    setState(() => _resendLoading = true);
    try {
      await sl<SendLoginOtpUseCase>()(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully')),
      );
      setState(() => _otp = List.filled(6, ''));
      _scheduleResendTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  void _verify() {
    final code = _otp.join('');
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }
    context.read<AuthBloc>().add(
          AuthCompleteLoginOtpRequested(phone: widget.phone, code: code),
        );
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.foregroundColor(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              final to = widget.returnTo.isEmpty ? '/' : widget.returnTo;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(to);
              });
            }
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back, color: fg.withValues(alpha: 0.7)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: AuthLogo()),
                  const SizedBox(height: 24),
                  Text(
                    'Verify Your Number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the 6-digit code sent to ${widget.phone}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: fg.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 32),
                  OtpInput(
                    otp: _otp,
                    onChanged: (v) => setState(() => _otp = v),
                  ),
                  const SizedBox(height: 24),
                  if (_resendTimer > 0)
                    Text(
                      'Resend code in ${_resendTimer}s',
                      style: TextStyle(fontSize: 14, color: fg.withValues(alpha: 0.55)),
                    )
                  else
                    TextButton(
                      onPressed: _resendLoading ? null : _resend,
                      child: _resendLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend Code'),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading || _otp.join().length != 6 ? null : _verify,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Verify & Continue'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
