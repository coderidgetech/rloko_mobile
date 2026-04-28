import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/safe_network_image.dart' show SafeCachedNetworkImage;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../review/data/dto/my_review_dto.dart';
import '../../../review/domain/usecases/get_my_reviews_usecase.dart';

/// Lists reviews written by the current user (GET /api/reviews/me).
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<MyReviewDto> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      if (mounted) {
        setState(() {
          _loading = false;
          _reviews = [];
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await sl<GetMyReviewsUseCase>().call();
      if (!mounted) return;
      setState(() {
        _reviews = r.reviews;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[ReviewsPage] $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border, size: 64, color: AppTheme.mutedForegroundColor(context)),
                    const SizedBox(height: 16),
                    const Text('Sign in to see your reviews', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/login', extra: '/reviews'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_loading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          if (_reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border, size: 64, color: AppTheme.mutedForegroundColor(context)),
                    const SizedBox(height: 16),
                    Text('No reviews yet', style: TextStyle(fontSize: 18, color: AppTheme.mutedForegroundColor(context))),
                    const SizedBox(height: 8),
                    Text(
                      'Reviews you write for products will appear here.',
                      style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = _reviews[i];
                return Material(
                  color: AppTheme.backgroundColor(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (r.productId.isNotEmpty) {
                        context.push('/product/${r.productId}');
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (r.productImage != null && r.productImage!.isNotEmpty)
                                ? SafeCachedNetworkImage(
                                    imageUrl: r.productImage!,
                                    width: 64,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 64,
                                    height: 80,
                                    color: AppTheme.mutedColor(context),
                                    child: const Icon(Icons.image_outlined, size: 32),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.productName?.isNotEmpty == true ? r.productName! : 'Product',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(
                                    5,
                                    (j) => Icon(
                                      j < r.rating ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: AppTheme.primaryColor(context),
                                    ),
                                  ),
                                ),
                                if (r.title.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(r.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  r.comment,
                                  style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.8)),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
          );
        },
      ),
    );
  }
}
