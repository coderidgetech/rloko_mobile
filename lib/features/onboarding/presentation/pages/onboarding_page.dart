import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/region/region_repository.dart';
import '../../../../core/region/resolve/domain/usecases/resolve_region_usecase.dart';
import '../../../../core/region/resolve/presentation/location_gate_cubit.dart';
import '../../../../core/region/resolve/presentation/widgets/location_gate_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';

const String _kHasSeenOnboarding = 'hasSeenOnboarding';

Future<void> setOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kHasSeenOnboarding, true);
}

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kHasSeenOnboarding) ?? false;
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
  final String title;
  final String description;
  final String image;
  final IconData icon;
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    title: 'Discover Luxury Fashion',
    description:
        'Explore curated collections of premium clothing, accessories, and jewelry from top designers',
    image:
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600&q=80',
    icon: Icons.auto_awesome,
  ),
  _OnboardingSlide(
    title: 'Personalized Shopping',
    description:
        'Get tailored recommendations, exclusive deals, and early access to new arrivals just for you',
    image:
        'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80',
    icon: Icons.shopping_bag_outlined,
  ),
  _OnboardingSlide(
    title: 'Secure & Easy Checkout',
    description:
        'Shop with confidence using secure payments, multiple payment options, and buyer protection',
    image:
        'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=600&q=80',
    icon: Icons.lock_outline,
  ),
  _OnboardingSlide(
    title: 'Delivery & Returns',
    description:
        'Fast shipping to India and USA with easy 30-day returns — hassle-free from start to finish',
    image:
        'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=600&q=80',
    icon: Icons.local_shipping_outlined,
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  /// Owned here (not created inside `itemBuilder`) so the cubit isn't recreated
  /// and reset on every PageView rebuild. Closed manually in [dispose].
  final LocationGateCubit _locationGateCubit = LocationGateCubit(
    sl<ResolveRegionUseCase>(),
  );

  /// The location step is appended after the informational slides; it cannot be
  /// skipped, so onboarding completes only once a location is chosen.
  int get _locationStepIndex => _slides.length;

  bool get _isLocationStep => _currentSlide == _locationStepIndex;

  @override
  void dispose() {
    _locationGateCubit.close();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeWithLocation() async {
    // Best-effort writes — never block leaving onboarding on a prefs failure.
    try {
      await setOnboardingComplete();
      await sl<RegionRepository>().markLocationChosen();
    } catch (_) {
      /* ignore */
    }
    if (mounted) context.go('/');
  }

  void _goToLocationStep() {
    _pageController.animateToPage(
      _locationStepIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentSlide = _locationStepIndex);
  }

  void _next() {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentSlide++);
    } else {
      // Last info slide → advance to the (mandatory) location step.
      _goToLocationStep();
    }
  }

  void _goToLogin() async {
    await setOnboardingComplete();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLocationStep)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _goToLocationStep,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foregroundColor(
                          context,
                        ).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length + 1,
                // The location step is mandatory — block swipe navigation while on it.
                physics: _isLocationStep
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentSlide = i),
                itemBuilder: (context, index) {
                  if (index == _locationStepIndex) {
                    return BlocProvider.value(
                      value: _locationGateCubit,
                      child: LocationGateView(onChosen: _completeWithLocation),
                    );
                  }
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    // Center when there's room; scroll instead of overflowing on
                    // shorter viewports.
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  // Cap by available height so the title + full
                                  // description always fit without scrolling.
                                  maxWidth: math.min(
                                    MediaQuery.of(context).size.width * 0.85,
                                    constraints.maxHeight * 0.46,
                                  ),
                                  maxHeight: math.min(
                                    MediaQuery.of(context).size.width * 0.85,
                                    constraints.maxHeight * 0.46,
                                  ),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (safeImageUrl(slide.image).isEmpty)
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppTheme.mutedColor(context),
                                                  AppTheme.primaryColor(
                                                    context,
                                                  ).withValues(alpha: 0.35),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          CachedNetworkImage(
                                            imageUrl: safeImageUrl(slide.image),
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppTheme.mutedColor(
                                                context,
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                  color: AppTheme.mutedColor(
                                                    context,
                                                  ),
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 48,
                                                  ),
                                                ),
                                          ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor(
                                    context,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 40,
                                  color: AppTheme.primaryColor(context),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                slide.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppTheme.mutedForegroundColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 32,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length + 1, (i) {
                      final active = _currentSlide == i;
                      return GestureDetector(
                        // Don't allow tap-navigating away from the mandatory
                        // location step.
                        onTap: _isLocationStep
                            ? null
                            : () {
                                _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setState(() => _currentSlide = i);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: active ? 32 : 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primaryColor(context)
                                : const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // The location step supplies its own "Continue" CTA.
                  if (!_isLocationStep)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Next'),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ),
                  if (_currentSlide == _slides.length - 1) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _goToLogin,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.mutedForegroundColor(context),
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppTheme.primaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
