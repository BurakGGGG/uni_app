import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../widgets/review_form_sections/category_ratings_section.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String universityId;

  const WriteReviewScreen({super.key, required this.universityId});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  double _overallRating = 0;
  final Map<String, double> _categoryRatings = {};

  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Tüm zorunlu alanlar dolu mu kontrol et
  bool get _isFormValid {
    final categories = AppConstants.uniRatingCategories;
    final allCategoriesFilled = categories.every(
      (c) => (_categoryRatings[c] ?? 0) > 0,
    );
    return _overallRating > 0 &&
        allCategoriesFilled &&
        _commentController.text.trim().length >= 20;
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen genel bir puan verin')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Kategori kontrolü
    final categories = AppConstants.uniRatingCategories;
    final missingCategories = categories.where(
      (c) => (_categoryRatings[c] ?? 0) == 0,
    ).toList();

    if (missingCategories.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şu kategorilere puan verin: ${missingCategories.join(", ")}'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('Giriş yapılmamış');

      final currentUserData = ref.read(currentUserProvider).value;
      if (currentUserData == null) throw Exception('Kullanıcı profili bulunamadı');

      final review = ReviewModel(
        id: '', // Firestore auto-generates
        type: ReviewType.university,
        targetId: widget.universityId,
        universityId: widget.universityId,
        userId: user.uid,
        userName: _isAnonymous ? 'Anonim Öğrenci' : currentUserData.displayName,
        userPhotoUrl: _isAnonymous ? null : currentUserData.photoUrl,
        userUniversity: currentUserData.university,
        rating: _overallRating,
        categoryRatings: Map<String, double>.from(_categoryRatings),
        comment: _commentController.text.trim(),
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(reviewRepositoryProvider).addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirmeniz başarıyla eklendi!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Değerlendir', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Genel Puan ──────────────────────────────────
              _buildOverallRating()
                  .animate()
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              // ─── Kategori Puanları ───────────────────────────
              CategoryRatingsSection(
                type: ReviewType.university,
                ratings: _categoryRatings,
                onChanged: (category, rating) {
                  setState(() => _categoryRatings[category] = rating);
                },
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              // ─── Yorum Metni ─────────────────────────────────
              _buildCommentField()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ─── Anonim Switch ───────────────────────────────
              _buildAnonymousSwitch()
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // ─── Gönder Butonu ───────────────────────────────
              GradientButton(
                text: 'Değerlendirmeyi Gönder',
                onPressed: _isFormValid ? _submitReview : null,
                isLoading: _isLoading,
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Genel değerlendirme yıldızları
  Widget _buildOverallRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, size: 24, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Genel Değerlendirme', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bu üniversiteyi genel olarak nasıl değerlendirirsiniz?',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= _overallRating;
            return GestureDetector(
              onTap: () => setState(() => _overallRating = starIndex.toDouble()),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled ? AppColors.warning : AppColors.textTertiary,
                  size: 40,
                ),
              ),
            );
          }),
          // Rating metni
        ),
        if (_overallRating > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _getRatingLabel(_overallRating),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Yorum metin alanı
  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Yorumunuz', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Deneyimlerinizi diğer öğrencilerle paylaşın (min. 20 karakter)',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Üniversiteniz hakkında diğer öğrencilere faydalı olabilecek deneyimlerinizi paylaşın...',
            alignLabelWithHint: true,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Lütfen bir yorum yazın';
            }
            if (val.trim().length < 20) {
              return 'Yorumunuz en az 20 karakter olmalıdır';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Anonim paylaşım switch'i
  Widget _buildAnonymousSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: _isAnonymous
            ? AppColors.primary.withAlpha(25)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: _isAnonymous ? AppColors.primary.withAlpha(80) : AppColors.borderLight,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text('Anonim olarak paylaş', style: AppTextStyles.bodyLarge),
        subtitle: Text(
          _isAnonymous
              ? 'Adınız ve fotoğrafınız gizlenecek'
              : 'Adınız ve fotoğrafınız görünür olacak',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        secondary: Icon(
          _isAnonymous ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: _isAnonymous ? AppColors.primary : AppColors.textTertiary,
        ),
        value: _isAnonymous,
        onChanged: (val) => setState(() => _isAnonymous = val),
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  /// Rating değerine göre açıklayıcı etiket
  String _getRatingLabel(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Çok Kötü';
      case 2:
        return 'Kötü';
      case 3:
        return 'Orta';
      case 4:
        return 'İyi';
      case 5:
        return 'Mükemmel';
      default:
        return '';
    }
  }
}
