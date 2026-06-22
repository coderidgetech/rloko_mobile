import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/usecases/get_my_reviews_usecase.dart';
import '../../domain/usecases/submit_review_usecase.dart';
import '../../domain/usecases/update_review_usecase.dart';
import '../bloc/review_bloc.dart';

class WriteReviewPage extends StatefulWidget {
  const WriteReviewPage({
    super.key,
    required this.productId,
    this.productName,
    this.reviewId,
    this.initialRating,
    this.initialTitle,
    this.initialComment,
  });

  final String productId;
  final String? productName;
  // When set, the page edits an existing review (PUT) instead of creating one.
  final String? reviewId;
  final int? initialRating;
  final String? initialTitle;
  final String? initialComment;

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  late int _rating;
  late final TextEditingController _titleController;
  late final TextEditingController _commentController;
  bool _saving = false;

  bool get _isEditing => (widget.reviewId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 5;
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _commentController = TextEditingController(text: widget.initialComment ?? '');
  }

  Future<void> _updateExisting() async {
    setState(() => _saving = true);
    try {
      await sl<UpdateReviewUseCase>()(
        productId: widget.productId,
        reviewId: widget.reviewId!,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review updated')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewBloc(sl<GetMyReviewsUseCase>(), sl<SubmitReviewUseCase>()),
      child: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submitted!')),
            );
            context.pop();
          }
          if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ReviewLoading || _saving;
          return Scaffold(
            appBar: AppBar(
              title: Text(_isEditing
                  ? 'Edit Review'
                  : widget.productName != null
                      ? 'Review ${widget.productName}'
                      : 'Write a Review'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Rating', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = star),
                        child: Icon(
                          star <= _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your review',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_titleController.text.trim().isEmpty ||
                                  _commentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill in all fields')),
                                );
                                return;
                              }
                              if (_isEditing) {
                                _updateExisting();
                              } else {
                                context.read<ReviewBloc>().add(ReviewSubmitRequested(
                                      productId: widget.productId,
                                      rating: _rating,
                                      title: _titleController.text.trim(),
                                      comment: _commentController.text.trim(),
                                    ));
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Update Review' : 'Submit Review'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
