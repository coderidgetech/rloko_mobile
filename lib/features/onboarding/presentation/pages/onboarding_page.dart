import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    description: 'Explore curated collections of premium clothing, accessories, and jewelry from top designers',
    image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80',
    icon: Icons.auto_awesome,
  ),
  _OnboardingSlide(
    title: 'Personalized Shopping',
    description: 'Get tailored recommendations, exclusive deals, and early access to new arrivals just for you',
    image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
    icon: Icons.shopping_bag_outlined,
  ),
  _OnboardingSlide(
    title: 'Secure & Easy Checkout',
    description: 'Shop with confidence using secure payments, multiple payment options, and buyer protection',
    image: 'https://images.unsplash.com/photo-1556742502-ec7c0e9f34b1?w=800&q=80',
    icon: Icons.lock_outline,
  ),
  _OnboardingSlide(
    title: 'Fast & Free Delivery',
    description: 'Enjoy complimentary shipping on orders over \$100 and easy returns within 30 days',
    image: 'https://images.unsplash.com/photo-1558769132-cb1aea1f1d6c?w=800&q=80',
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await setOnboardingComplete();
    if (mounted) context.go('/');
  }

  void _skip() => _completeOnboarding();

  void _next() {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentSlide++);
    } else {
      _completeOnboarding();
    }
  }

  void _goToLogin() async {
    await setOnboardingComplete();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentSlide < _slides.length - 1)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentSlide = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                            maxHeight: MediaQuery.of(context).size.width * 0.85,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: safeImageUrl(slide.image),
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: AppTheme.muted),
                                    errorWidget: (_, __, ___) => Container(color: AppTheme.muted, child: const Icon(Icons.image, size: 48)),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.2),
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
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 40, color: AppTheme.primary),
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
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
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
                    children: List.generate(_slides.length, (i) {
                      final active = _currentSlide == i;
                      return GestureDetector(
                        onTap: () {
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
                            color: active ? AppTheme.primary : const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_currentSlide < _slides.length - 1 ? 'Next' : 'Get Started'),
                          if (_currentSlide < _slides.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
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
                          style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppTheme.primary,
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
