import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_logo.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _barWidth;
  late Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _barWidth = Tween<double>(begin: 0, end: 120).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _bottomOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.64, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      await _waitForAuthResolved();
      if (!mounted) return;
      final seen = await hasSeenOnboarding();
      if (!mounted) return;
      if (seen) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    });
  }

  /// Waits for auth check to complete (so token from cache restores session) before navigating.
  Future<void> _waitForAuthResolved() async {
    final authBloc = context.read<AuthBloc>();
    final state = authBloc.state;
    if (state is! AuthInitial && state is! AuthLoading) return;
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = authBloc.stream.listen((s) {
      if (s is AuthAuthenticated || s is AuthUnauthenticated || s is AuthError) {
        if (!completer.isCompleted) completer.complete();
      }
    });
    try {
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => sub.cancel(),
      );
    } finally {
      await sub.cancel();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor(context).withOpacity(0.03),
                      Colors.transparent,
                      AppTheme.primaryColor(context).withOpacity(0.03),
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: const AuthLogo(height: 64),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _taglineOpacity.value,
                        child: Text(
                          'LUXURY FASHION REDEFINED',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 3,
                            color: AppTheme.mutedForegroundColor(context),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        height: 4,
                        width: _barWidth.value,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _bottomOpacity.value,
                  child: Text(
                    'EST. 2024',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 4,
                      color: AppTheme.mutedForegroundColor(context).withOpacity(0.6),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
