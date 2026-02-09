import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_grid_skeleton.dart';
import '../widgets/product_grid_tile.dart';

/// Reusable product list page: title + grid. Dispatch event in initState via [loadEvent].
class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    required this.title,
    required this.loadEvent,
  });

  final String title;
  final ProductListEvent loadEvent;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductListBloc>().add(widget.loadEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title),
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
                title: 'No products',
                icon: Icons.grid_view,
              );
            }
            // Match React MobileAllProductsPage: stats bar then grid (2 cols gap-3 px-4)
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
                        'Showing ${state.products.length} products',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.foreground.withValues(alpha: 0.6)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.foreground.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune,
                                size: 14,
                                color: AppTheme.foreground.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'Sort',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.foreground.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
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
