import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_grid_skeleton.dart';
import '../widgets/product_grid_tile.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.gender,
    required this.slug,
  });

  final String gender;
  final String slug;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductListBloc>().add(
          ProductListLoadRequested(
            gender: widget.gender,
            category: widget.slug,
            limit: 50,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final categoryTitle = widget.slug.isEmpty
        ? widget.gender.isNotEmpty
            ? '${widget.gender[0].toUpperCase()}${widget.gender.substring(1)}'
            : 'All'
        : '${widget.gender[0].toUpperCase()}${widget.gender.substring(1)} / ${widget.slug}';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(categoryTitle),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.foreground,
      ),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          if (state is ProductListLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ProductGridSkeleton(itemCount: 6),
            );
          }
          if (state is ProductListError) {
            return EmptyState(
              title: 'Something went wrong',
              subtitle: state.message,
              icon: Icons.error_outline,
            );
          }
          if (state is ProductListLoaded) {
            if (state.products.isEmpty) {
              return const EmptyState(
                title: 'No products in this category',
                icon: Icons.grid_view,
              );
            }
            // Match React MobileCategoryPage: filter bar (title + item count) then grid (MobileProductGrid: 2 cols gap-3 px-4)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    border: Border(
                      bottom: BorderSide(
                          color: AppTheme.foreground.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${state.products.length} items',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.foreground.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) =>
                        ProductGridTile(product: state.products[index]),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
