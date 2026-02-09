import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/form_hints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_logo.dart';
import '../bloc/auth_bloc.dart';

/// Login page aligned with React MobileLoginPage: close X, Welcome Back, form, OR, Google, Sign up link.
/// Keeps email/password auth (React mobile uses phone/OTP).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.redirectAfterLogin});

  final String? redirectAfterLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final fromCheckout = widget.redirectAfterLogin == '/checkout';
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Navigate after state is committed so Account (and other pages) see AuthAuthenticated
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
            final loading = state is AuthLoading;
            return Column(
              children: [
                // React: Header with Close (X) button only
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: IconButton(
                      onPressed: () => context.go(fromCheckout ? '/cart' : '/'),
                      icon: Icon(Icons.close, size: 24, color: AppTheme.foreground.withValues(alpha: 0.7)),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.foreground.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (fromCheckout) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 20, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sign in to place your order. You\'ll return to checkout after.',
                                      style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          // React: Logo & Title - "Welcome Back", "Sign in with your email"
                          const Center(child: AuthLogo()),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in with your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: AppTheme.foreground.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 32),
                          // React: inputs h-[54px] bg-foreground/5 border border-border/30 rounded-xl
                          Text(
                            'Email',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.foreground.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: FormHints.email,
                              filled: true,
                              fillColor: AppTheme.foreground.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Password',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.foreground.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: FormHints.password,
                              filled: true,
                              fillColor: AppTheme.foreground.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: AppTheme.foreground.withValues(alpha: 0.5)),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // React: w-full primary py-4 rounded-full
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Sign in'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // React: Divider OR
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.foreground.withValues(alpha: 0.12))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.4))),
                              ),
                              Expanded(child: Divider(color: AppTheme.foreground.withValues(alpha: 0.12))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // React: Continue with Google - border-2 rounded-full
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Google sign-in can be enabled with Firebase')),
                              );
                            },
                            icon: Icon(Icons.g_mobiledata, size: 24, color: AppTheme.foreground.withValues(alpha: 0.7)),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // React: "Don't have an account? Sign up"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
                              ),
                              TextButton(
                                onPressed: () => context.push('/signup'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Sign up', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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
