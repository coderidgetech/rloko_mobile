import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/category_list_bloc.dart';

/// Categories from API (CategoryListBloc); layout matches React MobileCategoriesPage.
String _slugify(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '-');

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryListBloc>().add(const CategoryListLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: false),
      body: BlocBuilder<CategoryListBloc, CategoryListState>(
        builder: (context, state) {
          if (state is CategoryListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoryListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.foreground.withValues(alpha: 0.6)),
                ),
              ),
            );
          }
          final categories = state is CategoryListLoaded ? state.categories : <CategoryEntity>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // React: px-4 mb-8, h1 text-3xl font-medium mb-2, p text-sm text-foreground/60
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Browse',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover our curated collections',
                        style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                ...List.generate(categories.length, (index) {
                  final category = categories[index];
                  final link = '/category/${category.gender}/${category.slug}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryCard(entity: category),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: category.subcategories
                                .map(
                                  (sub) => _SubcategoryRow(
                                    name: sub,
                                    onTap: () => context.push(
                                      '/category/${category.gender}/${_slugify(sub)}',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        if (index < categories.length - 1) ...[
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.border.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // React: p-6 rounded-2xl border border-primary/10, grid-cols-3 gap-6, text-2xl mb-1, text-[11px] text-foreground/60
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${categories.length}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Main\nCategories',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.3,
                                      color: AppTheme.foreground.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 48,
                              color: AppTheme.border.withValues(alpha: 0.3),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${categories.fold<int>(0, (n, c) => n + c.subcategories.length)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sub\nCategories',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.3,
                                      color: AppTheme.foreground.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 48,
                              color: AppTheme.border.withValues(alpha: 0.3),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '—',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total\nProducts',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.3,
                                      color: AppTheme.foreground.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 16),
                  // React: py-8, w-14 h-14 (56) mb-4, font-medium mb-2, text-sm text-foreground/60 mb-5 max-w-[280px], button py-3 px-8 rounded-full
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🔍', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Looking for something specific?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 280,
                          child: Text(
                            'Search our entire catalog to find exactly what you need',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.foreground.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => context.push('/search'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text('Search All Products'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
          },
        ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }
}

/// Category card: full width image, gradient overlay, title, description, item count, arrow.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.entity});

  final CategoryEntity entity;

  @override
  Widget build(BuildContext context) {
    final link = '/category/${entity.gender}/${entity.slug}';
    final imageUrl = entity.image.isNotEmpty
        ? entity.image
        : placeholderImageUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(link),
          child: SizedBox(
            height: 192,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: safeImageUrl(imageUrl),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.muted,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.muted,
                    child: const Icon(Icons.image, size: 48),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // React: absolute bottom-0 px-4 pb-5, text-2xl font-medium, text-xs white/90, text-xs white/80 • X types
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entity.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Explore ${entity.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${entity.subcategories.length} subcategories',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

/// Subcategory row: match React - py-3 border-b border-border/20, dot w-1 h-1 bg-primary/50, gap-3, text-sm font-medium, ChevronRight 16 text-foreground/30
class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.foreground.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.foreground.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
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
      onTap: (i) {
        if (i == 0) context.go('/');
        if (i == 1) context.go('/categories');
        if (i == 2) context.go('/search');
        if (i == 3) context.go('/account');
        if (i == 4) context.go('/cart');
      },
    );
  }
}
