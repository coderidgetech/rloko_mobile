import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/domain/entities/site_config.dart';
import '../../../config/presentation/bloc/config_bloc.dart';
import '../../../config/utils/config_category_utils.dart';
import '../../../../core/constants/form_hints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/category_list_bloc.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_grid_skeleton.dart';
import '../widgets/product_grid_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final List<String> _recentSearches = [];
  String _query = '';
  late final VoidCallback _listener;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<CategoryListBloc>().add(const CategoryListLoadRequested());
    // Server-side search: debounce typing and query the backend (?search=) instead
    // of filtering a locally-cached page, so the whole catalogue is searchable.
    _listener = () {
      final q = _searchController.text;
      setState(() => _query = q);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted || q.trim().isEmpty) return;
        context
            .read<ProductListBloc>()
            .add(ProductListLoadRequested(search: q.trim(), limit: 50));
      });
    };
    _searchController.addListener(_listener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_listener);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: false),
      body: Column(
        children: [
          // React: search input rounded-full bg-foreground/5, Search icon left, clear when text, Cancel right
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: FormHints.searchProducts,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.4),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _query = '';
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductListBloc, ProductListState>(
              builder: (context, state) {
                final query = _query.trim();
                final showResults = query.isNotEmpty;

                if (state is ProductListLoading && !showResults) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (state is ProductListError) {
                  return EmptyState(
                    title: 'Something went wrong',
                    subtitle: state.message,
                    icon: Icons.error_outline,
                  );
                }

                if (!showResults) {
                  return _SuggestionsView(
                    recentSearches: _recentSearches,
                    onSearch: (q) {
                      _searchController.text = q;
                      _query = q;
                      _onSearch(q);
                      setState(() {});
                    },
                    onClearRecent: () => setState(() => _recentSearches.clear()),
                  );
                }

                if (state is! ProductListLoaded) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: ProductGridSkeleton(itemCount: 6),
                  );
                }
                // Backend already filtered by ?search=; render results directly.
                final filtered = state.products;
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No results',
                    subtitle: 'Try different keywords for "$query"',
                    icon: Icons.search,
                  );
                }
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filtered.length} Results for "$query"',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filtered.length} items',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              ProductGridTile(product: filtered[index]),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsView extends StatelessWidget {
  const _SuggestionsView({
    required this.recentSearches,
    required this.onSearch,
    required this.onClearRecent,
  });
  final List<String> recentSearches;
  final void Function(String) onSearch;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryListBloc, CategoryListState>(
      builder: (context, catState) {
        final configState = context.watch<ConfigBloc>().state;
        final config = configState is ConfigLoaded ? configState.config : SiteConfig.defaultConfig;
        var categories = catState is CategoryListLoaded ? catState.categories : <CategoryEntity>[];
        if (categories.isEmpty) {
          categories = categoriesFromConfig(config.categories);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recentSearches.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                    ),
                    TextButton(
                      onPressed: onClearRecent,
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.primaryColor(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentSearches.map((s) => ListTile(
                      leading: Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.4),
                      ),
                      title: Text(s, style: const TextStyle(fontSize: 14)),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                      ),
                      onTap: () => onSearch(s),
                    )),
                const SizedBox(height: 24),
              ],
              if (categories.isNotEmpty) ...[
                Text(
                  'From your catalog',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                ...categories.take(6).map((c) {
                  return ListTile(
                    leading: Icon(
                      Icons.label_outline,
                      size: 18,
                      color: AppTheme.primaryColor(context),
                    ),
                    title: Text(c.name, style: const TextStyle(fontSize: 14)),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                    ),
                    onTap: () => onSearch(c.name),
                  );
                }),
                const SizedBox(height: 24),
              ],
              Text(
                'Browse categories',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: categories
                    .map(
                      (c) => Material(
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => context.go('/category/${c.gender}/${c.slug}'),
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
