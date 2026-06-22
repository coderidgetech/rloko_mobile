import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/get_my_reviews_usecase.dart';
import '../../domain/usecases/submit_review_usecase.dart';
import '../../domain/usecases/update_review_usecase.dart';
import '../../domain/usecases/upload_review_image_usecase.dart';
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
  static const int _maxImages = 5;
  late int _rating;
  late final TextEditingController _titleController;
  late final TextEditingController _commentController;
  bool _saving = false;
  final _picker = ImagePicker();
  final List<File> _pickedFiles = [];

  bool get _isEditing => (widget.reviewId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 5;
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _commentController = TextEditingController(text: widget.initialComment ?? '');
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      setState(() {
        for (final x in picked) {
          if (_pickedFiles.length >= _maxImages) break;
          _pickedFiles.add(File(x.path));
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick images')),
      );
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      List<String>? urls;
      if (_pickedFiles.isNotEmpty) {
        urls = [];
        for (final f in _pickedFiles) {
          urls.add(await sl<UploadReviewImageUseCase>()(f));
        }
      }
      if (_isEditing) {
        await sl<UpdateReviewUseCase>()(
          productId: widget.productId,
          reviewId: widget.reviewId!,
          title: _titleController.text.trim(),
          comment: _commentController.text.trim(),
          images: urls,
        );
      } else {
        await sl<SubmitReviewUseCase>()(
          productId: widget.productId,
          rating: _rating,
          title: _titleController.text.trim(),
          comment: _commentController.text.trim(),
          images: urls,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Review updated' : 'Review submitted!')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildImageRow(BuildContext context) {
    final canAdd = _pickedFiles.length < _maxImages;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pickedFiles.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == _pickedFiles.length) {
            return InkWell(
              onTap: _saving ? null : _pickImages,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
              ),
            );
          }
          final f = _pickedFiles[i];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(f, width: 76, height: 76, fit: BoxFit.cover),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _saving ? null : () => setState(() => _pickedFiles.removeAt(i)),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
                  const SizedBox(height: 16),
                  Text('Photos (optional)', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _buildImageRow(context),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
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
