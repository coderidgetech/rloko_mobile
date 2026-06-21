import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_product_variants_usecase.dart';

/// Horizontal color-variant switcher: shows each sibling product (same
/// variant_group_id) as a thumbnail; tapping a different colour opens its PDP.
/// Renders nothing unless there are 2+ variants.
class ProductVariantRow extends StatefulWidget {
  const ProductVariantRow({super.key, required this.productId});

  final String productId;

  @override
  State<ProductVariantRow> createState() => _ProductVariantRowState();
}

class _ProductVariantRowState extends State<ProductVariantRow> {
  List<ProductEntity> _variants = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProductVariantRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      setState(() => _loaded = false);
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final v = await sl<GetProductVariantsUseCase>()(widget.productId);
      if (!mounted) return;
      setState(() {
        _variants = v;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _variants = const [];
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _variants.length < 2) return const SizedBox.shrink();
    final fg = AppTheme.foregroundColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colour',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _variants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final v = _variants[i];
              final selected = v.id == widget.productId;
              final img = v.images.isNotEmpty ? v.images.first : '';
              return GestureDetector(
                onTap: selected ? null : () => context.safePush('/product/${v.id}'),
                child: Container(
                  width: 52,
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? fg : fg.withValues(alpha: 0.2),
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: img.isEmpty
                      ? Container(color: AppTheme.mutedColor(context))
                      : SafeCachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
