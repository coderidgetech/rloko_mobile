import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../config/presentation/bloc/config_bloc.dart';
import '../../../product/domain/entities/category_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/presentation/bloc/category_list_bloc.dart';
import '../../../product/presentation/bloc/product_list_bloc.dart';
import '../../../video/domain/entities/inspiration_video_entity.dart';
import '../../../video/presentation/bloc/inspiration_videos_bloc.dart';
import '../../../product/presentation/widgets/product_grid_skeleton.dart';
import '../../../product/presentation/widgets/product_grid_tile.dart';

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
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: false),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<ProductListBloc>().add(const ProductListLoadHomeSections(limit: 10));
            context.read<CategoryListBloc>().add(const CategoryListLoadRequested());
            context.read<ConfigBloc>().add(const ConfigLoadRequested());
            context.read<InspirationVideosBloc>().add(const InspirationVideosLoadRequested(limit: 20));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroSection(),
                const _StoryCirclesSection(),
                const SizedBox(height: 24),
                const _InspirationVideosSection(),
                const SizedBox(height: 24),
                _QuickStatsBanner(),
                _ShopByCategorySection(),
                Container(height: 8, color: AppTheme.foreground.withValues(alpha: 0.05)),
                _HomeProductSections(),
                _PromoBanner(),
                _TrustBadges(),
                _HomeFooter(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 0),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({required this.title, required this.subtitle, required this.image, required this.cta, required this.link});
  final String title, subtitle, image, cta, link;
}

const _defaultHeroImages = [
  'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
  'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80',
  'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80',
];

List<_HeroSlide> _defaultHeroSlides() => [
  const _HeroSlide(title: 'New Season', subtitle: 'Spring Collection 2026', image: '', cta: 'Shop Now', link: '/new-arrivals'),
  const _HeroSlide(title: 'Designer Bags', subtitle: 'Luxury Accessories', image: '', cta: 'Explore', link: '/categories'),
  const _HeroSlide(title: 'Summer Sale', subtitle: 'Up to 50% Off', image: '', cta: 'Shop Sale', link: '/sale'),
];

List<_HeroSlide> _buildHeroSlidesWithImages(List<_HeroSlide> slides) {
  return [
    for (var i = 0; i < slides.length; i++)
      _HeroSlide(
        title: slides[i].title,
        subtitle: slides[i].subtitle,
        image: slides[i].image.isNotEmpty ? slides[i].image : _defaultHeroImages[i % _defaultHeroImages.length],
        cta: slides[i].cta,
        link: slides[i].link,
      ),
  ];
}

List<_HeroSlide> _heroSlidesFromConfig(Map<String, dynamic> config) {
  final homepage = config['homepage'];
  if (homepage is! Map) return _defaultHeroSlides();
  final hero = homepage['hero'];
  if (hero is! Map) return _defaultHeroSlides();
  final heading = hero['heading']?.toString();
  final subheading = hero['subheading']?.toString();
  final cta = hero['primaryButtonText']?.toString() ?? 'Shop';
  final link = hero['primaryButtonLink']?.toString() ?? '/categories';
  final image = hero['backgroundImage']?.toString() ?? '';
  if (heading == null || heading.isEmpty) return _defaultHeroSlides();
  return [_HeroSlide(title: heading, subtitle: subheading ?? '', image: image, cta: cta, link: link)];
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
        final raw = state is ConfigLoaded && state.config.isNotEmpty
            ? _heroSlidesFromConfig(state.config)
            : _defaultHeroSlides();
        final slides = _buildHeroSlidesWithImages(raw);
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
      _StoryItem(id: 'new', title: 'New', image: placeholderImageUrl, isNew: true, link: '/new-arrivals'),
    ];
    for (final c in categories.take(5)) {
      items.add(_StoryItem(
        id: c.id,
        title: c.name,
        image: c.image.isNotEmpty ? c.image : placeholderImageUrl,
        link: '/category/${c.gender}/${c.slug}',
      ));
    }
    items.add(_StoryItem(id: 'sale', title: 'Sale', image: placeholderImageUrl, link: '/sale'));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryListBloc, CategoryListState>(
      builder: (context, state) {
        final items = state is CategoryListLoaded && state.categories.isNotEmpty
            ? _itemsFromCategories(state.categories)
            : [
                _StoryItem(id: 'new', title: 'New', image: placeholderImageUrl, isNew: true, link: '/new-arrivals'),
                _StoryItem(id: 'sale', title: 'Sale', image: placeholderImageUrl, link: '/sale'),
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: safeImageUrl(s.image),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.muted),
                    errorWidget: (_, __, ___) => Container(color: AppTheme.muted, child: const Icon(Icons.image)),
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
                              foregroundColor: AppTheme.foreground,
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
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12))),
      ),
      child: SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
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
                              color: item.isNew ? AppTheme.primary : AppTheme.foreground.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: safeImageUrl(item.image),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: AppTheme.muted),
                              errorWidget: (_, __, ___) => const Icon(Icons.image),
                            ),
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
                                color: AppTheme.primary,
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.foreground.withValues(alpha: 0.8)),
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
              child: Text('Loading videos...', style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
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
          Text('Tik Tok', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppTheme.mutedForeground)),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: safeImageUrl(video.thumbnailUrl),
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: AppTheme.muted),
                              errorWidget: (_, __, ___) => Container(color: AppTheme.muted, child: const Icon(Icons.videocam_off)),
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
                          color: active ? AppTheme.primary : AppTheme.border,
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
              style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
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
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickStat(icon: Icons.trending_up, label: 'Trending', onTap: () => context.push('/all-products')),
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
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
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
            color: AppTheme.background,
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
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
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
                      color: AppTheme.muted,
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
            color: AppTheme.background,
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
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                ),
              ],
            ),
          );
        }
        final categories = state is CategoryListLoaded ? state.categories : <CategoryEntity>[];
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          color: AppTheme.background,
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
                style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
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
    final imageUrl = category.image.isNotEmpty ? category.image : placeholderImageUrl;
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
              CachedNetworkImage(
                imageUrl: safeImageUrl(imageUrl),
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.muted),
                errorWidget: (_, __, ___) =>
                    Container(color: AppTheme.muted, child: const Icon(Icons.image)),
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

class _HomeProductSections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListBloc, ProductListState>(
      builder: (context, state) {
        if (state is ProductListHomeLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SectionTitle(title: '✨ Featured'),
                ProductGridSkeleton(itemCount: 4),
                SizedBox(height: 24),
                _SectionTitle(title: '🆕 New Arrivals'),
                ProductGridSkeleton(itemCount: 4),
                SizedBox(height: 24),
                _SectionTitle(title: '🔥 On Sale'),
                ProductGridSkeleton(itemCount: 4),
              ],
            ),
          );
        }
        if (state is ProductListError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(state.message, style: const TextStyle(color: AppTheme.destructive)),
          );
        }
        if (state is ProductListHomeLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.featured.isNotEmpty) ...[
                _SectionTitle(title: '✨ Featured', onSeeAll: () => context.push('/all-products')),
                _ProductGrid(products: state.featured),
                const SizedBox(height: 16),
                Divider(height: 2, color: AppTheme.foreground.withValues(alpha: 0.05)),
                const SizedBox(height: 16),
              ],
              if (state.newArrivals.isNotEmpty) ...[
                _SectionTitle(title: '🆕 New Arrivals', onSeeAll: () => context.push('/new-arrivals')),
                _ProductGrid(products: state.newArrivals),
                const SizedBox(height: 16),
                Divider(height: 2, color: AppTheme.foreground.withValues(alpha: 0.05)),
                const SizedBox(height: 16),
              ],
              if (state.sale.isNotEmpty) ...[
                _SectionTitle(title: '🔥 On Sale', onSeeAll: () => context.push('/sale')),
                _ProductGrid(products: state.sale),
              ],
            ],
          );
        }
        return const SizedBox.shrink();
      },
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
          childAspectRatio: 0.65,
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
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.primary.withValues(alpha: 0.05),
            AppTheme.primary.withValues(alpha: 0.1),
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
            style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.foreground,
              foregroundColor: AppTheme.background,
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
        border: Border(top: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TrustBadge(emoji: '🚚', title: 'Free Shipping', subtitle: 'On orders \$50+'),
          _TrustBadge(emoji: '↩️', title: 'Easy Returns', subtitle: '30-day policy'),
          _TrustBadge(emoji: '🔒', title: 'Secure Pay', subtitle: '100% protected'),
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
        Text(subtitle, style: TextStyle(fontSize: 10, color: AppTheme.foreground.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _HomeFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Match React: px-4 py-8 text-center, text-sm text-foreground/60 mb-2, gap-4 text-xs text-foreground/50
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12))),
      ),
      child: Column(
        children: [
          Text(
            '© ${DateTime.now().year} Rloco. All rights reserved.',
            style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => context.push('/privacy'),
                child: Text('Privacy', style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.5))),
              ),
              Text(' • ', style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.5))),
              TextButton(
                onPressed: () => context.push('/terms'),
                child: Text('Terms', style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.5))),
              ),
              Text(' • ', style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.5))),
              TextButton(
                onPressed: () => context.push('/help'),
                child: Text('Help', style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.5))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.mutedForeground,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Cart'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/categories');
            break;
          case 2:
            context.go('/search');
            break;
          case 3:
            context.go('/account');
            break;
          case 4:
            context.go('/cart');
            break;
        }
      },
    );
  }
}
