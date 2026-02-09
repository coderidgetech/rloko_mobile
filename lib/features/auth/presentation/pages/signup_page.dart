import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/form_hints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_logo.dart';
import '../../../../core/widgets/otp_input.dart';
import '../bloc/auth_bloc.dart';

/// Signup page matching React MobileSignupPage: name, email, phone, password, terms → OTP → verify & register.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreeTerms = false;
  bool _otpSent = false;
  bool _loading = false;
  int _countdown = 0;
  List<String> _otp = List.filled(6, '');
  Timer? _timer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_countdown <= 1) {
          _timer?.cancel();
          _countdown = 0;
        } else {
          _countdown--;
        }
      });
    });
  }

  void _sendOtp() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Privacy Policy'),
        ),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpSent = true;
        _otp = List.filled(6, '');
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your phone')),
      );
    });
  }

  /// Accept any 6-digit OTP until SMTP is integrated; no backend verification.
  void _verifyOtp() {
    final otpValue = _otp.join('');
    if (otpValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }
    setState(() => _loading = true);
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          ),
        );
  }

  void _continueWithGoogle() {
    context.pushReplacement('/login');
  }

  void _resendOtp() {
    if (_countdown > 0) return;
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            setState(() => _loading = false);
            context.go('/');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created successfully!')),
            );
          }
          if (state is AuthError) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final authLoading = state is AuthLoading;
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.close, size: 24),
                      style: IconButton.styleFrom(
                        foregroundColor:
                            AppTheme.foreground.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _otpSent
                        ? _buildOtpStep(authLoading)
                        : _buildFormStep(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Center(child: AuthLogo()),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join Rloco today',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.foreground.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 32),
        _label('Full Name'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            hint: FormHints.fullName,
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 16),
        _label('Email'),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hint: 'your@email.com',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label('Phone'),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            hint: FormHints.phone,
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _label('Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: _inputDecoration(
            hint: FormHints.password,
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreeTerms,
                onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.foreground.withValues(alpha: 0.6),
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.push('/terms'),
                          child: const Text(
                            'Terms',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.push('/privacy'),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryForeground,
                    ),
                  )
                : const Text('Send OTP'),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: Divider(color: AppTheme.border.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.foreground.withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(
                child: Divider(color: AppTheme.border.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _loading ? null : _continueWithGoogle,
          icon: const Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.foreground.withValues(alpha: 0.6),
              ),
            ),
            TextButton(
              onPressed: () => context.pushReplacement('/login'),
              child: const Text(
                'Sign in',
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtpStep(bool authLoading) {
    final phone = _phoneController.text.trim();
    final loading = _loading || authLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
            child: const Icon(
              Icons.phone_outlined,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Verify OTP',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to\n$phone',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.foreground.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        OtpInput(
          otp: _otp,
          onChanged: (v) => setState(() => _otp = v),
          enabled: !loading,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: loading || _otp.join().length != 6 ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryForeground,
                    ),
                  )
                : const Text('Verify & Create Account'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              TextButton(
                onPressed: _countdown > 0 ? null : _resendOtp,
                child: Text(
                  _countdown > 0
                      ? 'Resend OTP in ${_countdown}s'
                      : 'Resend OTP',
                  style: TextStyle(
                    fontSize: 14,
                    color: _countdown > 0
                        ? AppTheme.foreground.withValues(alpha: 0.4)
                        : AppTheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _otpSent = false;
                  _otp = List.filled(6, '');
                }),
                child: Text(
                  'Change phone number',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.foreground,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 18,
        color: AppTheme.foreground.withValues(alpha: 0.4),
      ),
      filled: true,
      fillColor: AppTheme.foreground.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
