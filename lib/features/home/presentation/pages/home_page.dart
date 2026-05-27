import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../config/domain/entities/site_config.dart';
import '../../../config/presentation/bloc/config_bloc.dart';
import '../../../config/utils/config_category_utils.dart';
import '../../../product/domain/entities/category_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/presentation/bloc/category_list_bloc.dart';
import '../../../product/presentation/bloc/product_list_bloc.dart';
import '../../../video/domain/entities/inspiration_video_entity.dart';
import '../../../video/presentation/bloc/inspiration_videos_bloc.dart';
import '../../../product/presentation/widgets/product_grid_skeleton.dart';
import '../../../product/presentation/widgets/product_grid_tile.dart';
import '../../../../core/widgets/delivery_location_strip.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductListBloc>().add(const ProductListLoadHomeSections(limit: 10));
    context.read<CategoryListBloc>().add(const CategoryListLoadRequested());
    context.read<ConfigBloc>().add(const ConfigLoadRequested());
    context.read<InspirationVideosBloc>().add(const InspirationVideosLoadRequested(limit: 20));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery address bar matching React MobileHomeHeader row 2
            const DeliveryLocationStrip(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ProductListBloc>().add(const ProductListLoadHomeSections(limit: 10));
                  context.read<CategoryListBloc>().add(const CategoryListLoadRequested());
                  context.read<ConfigBloc>().add(const ConfigLoadRequested());
                  context.read<InspirationVideosBloc>().add(const InspirationVideosLoadRequested(limit: 20));
                },
                child: BlocBuilder<ConfigBloc, ConfigState>(
                  buildWhen: (a, b) => b is ConfigLoaded,
                  builder: (context, configState) {
                    final config = configState is ConfigLoaded ? configState.config : SiteConfig.defaultConfig;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (config.homepage.hero.enabled) const _HeroSection(),
                          if (config.homepage.sections.shopByCategory) const _StoryCirclesSection(),
                          if (config.homepage.sections.shopByCategory || config.homepage.sections.editorialFeatures) const SizedBox(height: 24),
                          if (config.homepage.sections.editorialFeatures) const _InspirationVideosSection(),
                          if (config.homepage.sections.editorialFeatures) const SizedBox(height: 24),
                          _QuickStatsBanner(),
                          if (config.homepage.sections.shopByCategory) _ShopByCategorySection(),
                          if (config.homepage.sections.shopByCategory) Container(height: 8, color: AppTheme.foregroundColor(context).withValues(alpha: 0.05)),
                          const _GiftsSection(),
                          Container(height: 8, color: AppTheme.foregroundColor(context).withValues(alpha: 0.05)),
                          _HomeProductSections(config: config),
                          if (config.homepage.sections.promotionalBanner) _PromoBanner(),
                          _TrustBadges(),
                          _HomeFooter(config: config),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({required this.title, required this.subtitle, required this.image, required this.cta, required this.link});
  final String title, subtitle, image, cta, link;
}

List<_HeroSlide> _defaultHeroSlides() => [
  const _HeroSlide(title: 'New Season', subtitle: 'Spring Collection 2026', image: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=1200&q=80', cta: 'Shop Now', link: '/new-arrivals'),
  const _HeroSlide(title: 'Designer Bags', subtitle: 'Luxury Accessories', image: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=1200&q=80', cta: 'Explore', link: '/categories'),
  const _HeroSlide(title: 'Summer Sale', subtitle: 'Up to 50% Off', image: 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=1200&q=80', cta: 'Shop Sale', link: '/sale'),
];

List<_HeroSlide> _heroSlidesFromConfig(SiteConfig config) {
  final hero = config.homepage.hero;
  if (hero.heading.isEmpty) return _defaultHeroSlides();
  return [
    _HeroSlide(
      title: hero.heading,
      subtitle: hero.subheading,
      image: hero.backgroundImage,
      cta: hero.primaryButtonText.isEmpty ? 'Shop' : hero.primaryButtonText,
      link: hero.primaryButtonLink.isEmpty ? '/categories' : hero.primaryButtonLink,
    ),
  ];
}

class _HeroSection extends StatefulWidget {
  const _HeroSection();

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  late final PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int slideCount) {
    _timer?.cancel();
    if (slideCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final page = _pageController.page?.round() ?? 0;
      final next = (page + 1) % slideCount;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigBloc, ConfigState>(
      buildWhen: (a, b) => b is ConfigLoaded,
      builder: (context, state) {
        final config = state is ConfigLoaded ? state.config : SiteConfig.defaultConfig;
        final slides = _heroSlidesFromConfig(config);
        _startTimer(slides.length);
        return _HeroCarousel(slides: slides, pageController: _pageController);
      },
    );
  }
}

class _StoryCirclesSection extends StatelessWidget {
  const _StoryCirclesSection();

  static List<_StoryItem> _itemsFromCategories(List<CategoryEntity> categories) {
    final items = <_StoryItem>[
      _StoryItem(id: 'new', title: 'New', image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=200&q=80', isNew: true, link: '/new-arrivals'),
    ];
    for (final c in categories.take(5)) {
      items.add(_StoryItem(
        id: c.id,
        title: c.name,
        image: c.image.isNotEmpty ? c.image : fallbackImageForCategory(c.gender, c.slug),
        link: '/category/${c.gender}/${c.slug}',
      ));
    }
    items.add(_StoryItem(id: 'sale', title: 'Sale', image: 'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=200&q=80', link: '/sale'));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryListBloc, CategoryListState>(
      builder: (context, state) {
        var categories = state is CategoryListLoaded ? state.categories : <CategoryEntity>[];
        if (categories.isEmpty) {
          final configState = context.watch<ConfigBloc>().state;
          final config = configState is ConfigLoaded ? configState.config : SiteConfig.defaultConfig;
          categories = categoriesFromConfig(config.categories);
        }
        final items = categories.isNotEmpty
            ? _itemsFromCategories(categories)
            : [
                _StoryItem(id: 'new', title: 'New', image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=200&q=80', isNew: true, link: '/new-arrivals'),
                _StoryItem(id: 'sale', title: 'Sale', image: 'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=200&q=80', link: '/sale'),
              ];
        return _StoryCirclesStrip(items: items);
      },
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({required this.slides, required this.pageController});

  final List<_HeroSlide> slides;
  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    // Match React: h-[60vh], content p-6 pb-8, dots bottom-24
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final s = slides[index];
              final bgUrl = safeImageUrl(s.image);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (bgUrl.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.mutedColor(context),
                            AppTheme.primaryColor(context).withValues(alpha: 0.35),
                            AppTheme.foregroundColor(context).withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: bgUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.mutedColor(context)),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.mutedColor(context), child: const Icon(Icons.image)),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.subtitle.toUpperCase(),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.title,
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.push(s.link),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.foregroundColor(context),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: Text(s.cta),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                return ListenableBuilder(
                  listenable: pageController,
                  builder: (context, _) {
                    final page = pageController.hasClients ? (pageController.page ?? 0).round() : 0;
                    final active = page == i;
                    return GestureDetector(
                      onTap: () => pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: active ? 24 : 6,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryItem {
  const _StoryItem({required this.id, required this.title, required this.image, this.isNew = false, required this.link});
  final String id, title, image, link;
  final bool isNew;
}

class _StoryCirclesStrip extends StatelessWidget {
  const _StoryCirclesStrip({required this.items});

  final List<_StoryItem> items;

  @override
  Widget build(BuildContext context) {
    // Match React: py-3 border-b border-border/30, gap-4 px-4, circle w-16 h-16 (64px)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12))),
      ),
      child: SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            Widget storyAvatar() {
              final u = safeImageUrl(item.image);
              if (u.isEmpty) {
                return Container(
                  width: 60,
                  height: 60,
                  color: AppTheme.mutedColor(context),
                  child: Icon(
                    item.isNew ? Icons.fiber_new : Icons.label_outline,
                    size: 28,
                    color: AppTheme.foregroundColor(context).withValues(alpha: 0.45),
                  ),
                );
              }
              return CachedNetworkImage(
                imageUrl: u,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.mutedColor(context)),
                errorWidget: (_, __, ___) => const Icon(Icons.image),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => context.push(item.link),
                borderRadius: BorderRadius.circular(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.isNew ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: ClipOval(
                            child: storyAvatar(),
                          ),
                        ),
                        if (item.isNew)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor(context),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 64,
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.foregroundColor(context).withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InspirationVideosSection extends StatefulWidget {
  const _InspirationVideosSection();

  @override
  State<_InspirationVideosSection> createState() => _InspirationVideosSectionState();
}

class _InspirationVideosSectionState extends State<_InspirationVideosSection> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspirationVideosBloc, InspirationVideosState>(
      builder: (context, state) {
        if (state is InspirationVideosLoading) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Loading videos...', style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context))),
            ),
          );
        }
        if (state is InspirationVideosError) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(state.message, style: const TextStyle(color: AppTheme.destructive, fontSize: 13)),
          );
        }
        if (state is InspirationVideosLoaded && state.videos.isEmpty) {
          return const SizedBox.shrink();
        }
        if (state is InspirationVideosLoaded) {
          return _InspirationVideosContent(videos: state.videos, pageController: _pageController);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _InspirationVideosContent extends StatelessWidget {
  const _InspirationVideosContent({required this.videos, required this.pageController});

  final List<InspirationVideoEntity> videos;
  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    // Match React: my-6 around section
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text('Tik Tok', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppTheme.mutedForegroundColor(context))),
          const SizedBox(height: 4),
          const Text('INSPIRATION', style: TextStyle(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w300)),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () => context.push(
                          '/video/${video.id}',
                          extra: {
                            'videoUrl': video.videoUrl,
                            'title': video.title,
                            'category': video.category,
                            'thumbnailUrl': video.thumbnailUrl,
                          },
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: safeImageUrl(video.thumbnailUrl),
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppTheme.mutedColor(context)),
                                errorWidget: (_, __, ___) => Container(color: AppTheme.mutedColor(context), child: const Icon(Icons.videocam_off)),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.85)],
                                  ),
                                ),
                              ),
                              const Center(
                                child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 52),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(video.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(video.category.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (videos.length > 1) ...[
                  Positioned(
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        if (pageController.hasClients) {
                          final page = (pageController.page ?? 0).round();
                          final prev = page > 0 ? page - 1 : videos.length - 1;
                          pageController.animateToPage(prev, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        if (pageController.hasClients) {
                          final page = (pageController.page ?? 0).round();
                          final next = (page + 1) % videos.length;
                          pageController.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (videos.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(videos.length, (i) {
                return ListenableBuilder(
                  listenable: pageController,
                  builder: (context, _) {
                    final page = pageController.hasClients ? (pageController.page ?? 0).round() : 0;
                    final active = page == i;
                    return GestureDetector(
                      onTap: () => pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        width: active ? 24 : 6,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primaryColor(context) : AppTheme.borderColor(context),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Discover the latest trends and styling inspiration from our community. Get inspired by real fashion moments and elevate your style.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Match React: bg-primary/5 py-4 px-4 mt-4
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickStat(icon: Icons.storefront_outlined, label: 'Shop all', onTap: () => context.push('/all-products')),
          _QuickStat(icon: Icons.bolt, label: 'New In', onTap: () => context.push('/new-arrivals')),
          _QuickStat(icon: Icons.local_offer, label: 'Sale', onTap: () => context.push('/sale')),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Match React: w-10 h-10 rounded-full bg-primary/10, mb-1.5, text-xs font-medium
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor(context)),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Shop by Category: data from API (CategoryListBloc)
class _ShopByCategorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryListBloc, CategoryListState>(
      builder: (context, state) {
        if (state is CategoryListLoading) {
          return Container(
            color: AppTheme.backgroundColor(context),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shop by Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore our collections',
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  padding: EdgeInsets.zero,
                  itemCount: 6,
                  itemBuilder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: AppTheme.mutedColor(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is CategoryListError) {
          return Container(
            color: AppTheme.backgroundColor(context),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shop by Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                ),
              ],
            ),
          );
        }
        var categories = state is CategoryListLoaded ? state.categories : <CategoryEntity>[];
        if (categories.isEmpty) {
          final configState = context.watch<ConfigBloc>().state;
          final config = configState is ConfigLoaded ? configState.config : SiteConfig.defaultConfig;
          categories = categoriesFromConfig(config.categories);
        }
        return Container(
          color: AppTheme.backgroundColor(context),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore our collections',
                style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _ShopCategoryCard(category: categories[index], index: index);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShopCategoryCard extends StatelessWidget {
  const _ShopCategoryCard({required this.category, required this.index});

  final CategoryEntity category;
  final int index;

  @override
  Widget build(BuildContext context) {
    final link = '/category/${category.gender}/${category.slug}';
    final imageUrl = category.image.isNotEmpty ? category.image : fallbackImageForCategory(category.gender, category.slug);
    final networkUrl = safeImageUrl(imageUrl);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(link),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (networkUrl.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.mutedColor(context),
                        AppTheme.primaryColor(context).withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.checkroom,
                      size: 48,
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                    ),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: networkUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.mutedColor(context)),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppTheme.mutedColor(context), child: const Icon(Icons.image)),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Perfect Gifts section: Gift For Her / Gift For Him cards linking to category.
class _GiftsSection extends StatelessWidget {
  const _GiftsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor(context),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 2,
            child: Container(
              color: AppTheme.primaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Perfect Gifts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: AppTheme.foregroundColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Handpicked for every special moment',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // Ref: full-width stacked cards (grid-cols-1), each h-[280px], image h-[160px]
          _GiftCard(
            title: 'Gift For Her',
            subtitle: 'Thoughtful presents she\'ll treasure',
            imageUrl: '',
            link: '/gift-for-her',
            accentColor: Colors.pink,
            icon: Icons.favorite,
            itemsLabel: null,
          ),
          const SizedBox(height: 16),
          _GiftCard(
            title: 'Gift For Him',
            subtitle: 'Perfect gifts for every gentleman',
            imageUrl: '',
            link: '/gift-for-him',
            accentColor: AppTheme.primaryColor(context),
            icon: Icons.card_giftcard_outlined,
            itemsLabel: null,
          ),
        ],
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.link,
    required this.accentColor,
    required this.icon,
    required this.itemsLabel,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final String link;
  final Color accentColor;
  final IconData icon;
  final String? itemsLabel;

  /// Ref mobile: h-[280px] total, image h-[160px], content flex-1; rounded-2xl, icon w-14 h-14 (56), top-4
  static const double _cardHeight = 280;
  static const double _imageHeight = 160;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(link),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: _cardHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (safeImageUrl(imageUrl).isEmpty)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withValues(alpha: 0.35),
                                AppTheme.mutedColor(context),
                              ],
                            ),
                          ),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: safeImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppTheme.mutedColor(context)),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.mutedColor(context),
                            child: Icon(Icons.image, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 26, color: accentColor),
                        ),
                      ),
                      if (itemsLabel != null && itemsLabel!.isNotEmpty)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              itemsLabel!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.foregroundColor(context),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    color: accentColor.withValues(alpha: 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: AppTheme.foregroundColor(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Explore Now',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foregroundColor(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: AppTheme.foregroundColor(context),
                            ),
                          ],
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
    );
  }
}

class _HomeProductSections extends StatefulWidget {
  const _HomeProductSections({required this.config});
  final SiteConfig config;

  @override
  State<_HomeProductSections> createState() => _HomeProductSectionsState();
}

class _HomeProductSectionsState extends State<_HomeProductSections> {
  bool _requestedHomeReload = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.config.homepage.sections;
    return BlocBuilder<ProductListBloc, ProductListState>(
      builder: (context, state) {
        // State was overwritten by ProductListLoadRequested (e.g. from product detail or search).
        // Re-request home sections only when Home is the visible route (not when user is on category/search).
        final isHomeCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
        if (state is ProductListLoaded && !_requestedHomeReload && isHomeCurrentRoute) {
          _requestedHomeReload = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<ProductListBloc>().add(const ProductListLoadHomeSections(limit: 10));
            }
          });
          return _buildLoadingSections(context, s);
        }
        if (state is ProductListHomeLoaded) {
          _requestedHomeReload = false;
        }
        if (state is ProductListHomeLoading) {
          return _buildLoadingSections(context, s);
        }
        if (state is ProductListError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(state.message, style: const TextStyle(color: AppTheme.destructive)),
          );
        }
        if (state is ProductListHomeLoaded) {
          final children = <Widget>[];
          if (s.featuredProducts && state.featured.isNotEmpty) {
            children.addAll([
              _SectionTitle(title: '✨ Featured', onSeeAll: () => context.push('/all-products')),
              _ProductGrid(products: state.featured),
              const SizedBox(height: 16),
              Divider(height: 2, color: AppTheme.foregroundColor(context).withValues(alpha: 0.05)),
              const SizedBox(height: 16),
            ]);
          }
          if (s.newArrivals && state.newArrivals.isNotEmpty) {
            children.addAll([
              _SectionTitle(title: '🆕 New Arrivals', onSeeAll: () => context.push('/new-arrivals')),
              _ProductGrid(products: state.newArrivals),
              const SizedBox(height: 16),
              Divider(height: 2, color: AppTheme.foregroundColor(context).withValues(alpha: 0.05)),
              const SizedBox(height: 16),
            ]);
          }
          if (s.bestSellers && state.sale.isNotEmpty) {
            children.addAll([
              _SectionTitle(title: '🔥 On Sale', onSeeAll: () => context.push('/sale')),
              _ProductGrid(products: state.sale),
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
        }
        if (state is ProductListInitial || state is ProductListLoading) {
          return _buildLoadingSections(context, s);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingSections(BuildContext context, dynamic s) {
    final children = <Widget>[];
    if (s.featuredProducts) {
      children.addAll([const _SectionTitle(title: '✨ Featured'), const ProductGridSkeleton(itemCount: 4), const SizedBox(height: 24)]);
    }
    if (s.newArrivals) {
      children.addAll([const _SectionTitle(title: '🆕 New Arrivals'), const ProductGridSkeleton(itemCount: 4), const SizedBox(height: 24)]);
    }
    if (s.bestSellers) {
      children.addAll([const _SectionTitle(title: '🔥 On Sale'), const ProductGridSkeleton(itemCount: 4)]);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.52,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductGridTile(product: products[index]),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Match React: mx-4 my-6 gradient rounded-2xl p-6 text-center
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.primaryColor(context).withValues(alpha: 0.1),
            AppTheme.primaryColor(context).withValues(alpha: 0.05),
            AppTheme.primaryColor(context).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Download Our App',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Get exclusive deals and early access to sales',
            style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("You're already using the Rloco app")),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.foregroundColor(context),
              foregroundColor: AppTheme.backgroundColor(context),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Download Now'),
          ),
        ],
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Match React: grid-cols-3 gap-4 px-4 py-6 border-t border-border/30
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TrustBadge(emoji: '🚚', title: 'Shipping', subtitle: 'Rates at checkout'),
          _TrustBadge(emoji: '↩️', title: 'Returns', subtitle: 'See return policy'),
          _TrustBadge(emoji: '🔒', title: 'Payments', subtitle: 'Processed securely'),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.emoji, required this.title, required this.subtitle});

  final String emoji, title, subtitle;

  @override
  Widget build(BuildContext context) {
    // Match React: text-2xl mb-1, text-xs font-medium, text-[10px] text-foreground/50
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(subtitle, style: TextStyle(fontSize: 10, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
      ],
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter({required this.config});
  final SiteConfig config;

  @override
  Widget build(BuildContext context) {
    final copyright = config.navigation.footer.copyrightText.isNotEmpty
        ? config.navigation.footer.copyrightText
        : '© ${DateTime.now().year} ${config.general.siteName}. All rights reserved.';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12))),
      ),
      child: Column(
        children: [
          Text(
            copyright,
            style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => context.push('/privacy'),
                child: Text('Privacy', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
              ),
              Text(' • ', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
              TextButton(
                onPressed: () => context.push('/terms'),
                child: Text('Terms', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
              ),
              Text(' • ', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
              TextButton(
                onPressed: () => context.push('/help'),
                child: Text('Help', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
