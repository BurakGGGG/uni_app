import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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
import '../widgets/review_form_sections/pros_cons_section.dart';
import '../widgets/review_form_sections/photo_upload_section.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String targetId;
  final ReviewType type;
  final String universityId;

  const WriteReviewScreen({
    super.key,
    required this.targetId,
    required this.type,
    required this.universityId,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  double _overallRating = 0;
  final Map<String, double> _categoryRatings = {};
  final List<String> _selectedPros = [];
  final List<String> _selectedCons = [];
  final List<File> _localPhotos = [];

  bool _isAnonymous = false;
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _submitted = false; // Validation hatalarını göstermek için
  bool _showSuccess = false; // Başarı animasyonu

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Type'a göre kategori listesi
  List<String> get _categories {
    return widget.type == ReviewType.university
        ? AppConstants.uniRatingCategories
        : AppConstants.deptRatingCategories;
  }

  /// Type'a göre preset pros
  List<String> get _presetPros {
    return widget.type == ReviewType.university
        ? AppConstants.commonUniPros
        : AppConstants.commonDeptPros;
  }

  /// Type'a göre preset cons
  List<String> get _presetCons {
    return widget.type == ReviewType.university
        ? AppConstants.commonUniCons
        : AppConstants.commonDeptCons;
  }

  /// Tüm zorunlu alanlar dolu mu kontrol et
  bool get _isFormValid {
    final allCategoriesFilled = _categories.every(
      (c) => (_categoryRatings[c] ?? 0) > 0,
    );
    return _overallRating > 0 &&
        allCategoriesFilled &&
        _commentController.text.trim().length >= 20;
  }

  /// Eksik alan sayısı (validation feedback için)
  List<String> get _validationErrors {
    final errors = <String>[];
    if (_overallRating == 0) errors.add('Genel puan');
    final missing = _categories.where((c) => (_categoryRatings[c] ?? 0) == 0).toList();
    if (missing.isNotEmpty) errors.add('${missing.length} kategori puanı');
    if (_commentController.text.trim().length < 20) errors.add('Yorum (min. 20 karakter)');
    return errors;
  }

  /// Fotoğrafları Firebase Storage'a yükle (progress mesajı ile)
  Future<List<String>> _uploadReviewPhotos(List<File> photos, String userId) async {
    final urls = <String>[];
    for (int i = 0; i < photos.length; i++) {
      setState(() {
        _loadingMessage = 'Fotoğraflar yükleniyor... ${i + 1}/${photos.length}';
      });
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('review_images/$userId/$imageId.jpg');
      await ref.putFile(photos[i], SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submitReview() async {
    setState(() => _submitted = true);

    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen genel bir puan verin'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Kategori kontrolü
    final missingCategories = _categories.where(
      (c) => (_categoryRatings[c] ?? 0) == 0,
    ).toList();

    if (missingCategories.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şu kategorilere puan verin: ${missingCategories.join(", ")}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Değerlendirme gönderiliyor...';
    });

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('Giriş yapılmamış');

      final currentUserData = await ref.read(currentUserProvider.future);
      if (currentUserData == null) throw Exception('Kullanıcı profili bulunamadı');

      // 1. Önce fotoğrafları yükle
      List<String> imageUrls = [];
      if (_localPhotos.isNotEmpty) {
        imageUrls = await _uploadReviewPhotos(_localPhotos, user.uid);
      }

      setState(() => _loadingMessage = 'Yorum kaydediliyor...');

      // 2. Sonra review document'i oluştur
      final review = ReviewModel(
        id: '', // Firestore auto-generates
        type: widget.type,
        targetId: widget.targetId,
        universityId: widget.universityId,
        userId: user.uid,
        userName: _isAnonymous ? 'Anonim Öğrenci' : currentUserData.displayName,
        userPhotoUrl: _isAnonymous ? null : currentUserData.photoUrl,
        userUniversity: currentUserData.university,
        rating: _overallRating,
        categoryRatings: Map<String, double>.from(_categoryRatings),
        comment: _commentController.text.trim(),
        pros: List<String>.from(_selectedPros),
        cons: List<String>.from(_selectedCons),
        imageUrls: imageUrls,
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(reviewRepositoryProvider).addReview(review);

      if (mounted) {
        // Başarı animasyonu göster
        setState(() {
          _isLoading = false;
          _showSuccess = true;
        });

        // 1.5 saniye sonra geri dön
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted && !_showSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Başarı animasyonu overlay
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, size: 80, color: AppColors.success)
                  .animate()
                  .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text('Değerlendirmeniz Gönderildi!', style: AppTextStyles.titleLarge)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Text(
                'Yorumunuz moderasyon sonrası yayınlanacaktır.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Değerlendir', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    type: widget.type,
                    ratings: _categoryRatings,
                    onChanged: (category, rating) {
                      setState(() => _categoryRatings[category] = rating);
                    },
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // ─── Artılar (Pros) ──────────────────────────────
                  ProsConsSection(
                    presetItems: _presetPros,
                    selectedItems: _selectedPros,
                    title: 'Artılar',
                    icon: Icons.thumb_up_alt_rounded,
                    color: AppColors.success,
                    onToggle: (item) {
                      setState(() {
                        if (_selectedPros.contains(item)) {
                          _selectedPros.remove(item);
                        } else {
                          _selectedPros.add(item);
                        }
                      });
                    },
                    onAddCustom: (item) {
                      if (item.isNotEmpty && !_selectedPros.contains(item)) {
                        setState(() => _selectedPros.add(item));
                      }
                    },
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // ─── Eksiler (Cons) ──────────────────────────────
                  ProsConsSection(
                    presetItems: _presetCons,
                    selectedItems: _selectedCons,
                    title: 'Eksiler',
                    icon: Icons.thumb_down_alt_rounded,
                    color: AppColors.error,
                    onToggle: (item) {
                      setState(() {
                        if (_selectedCons.contains(item)) {
                          _selectedCons.remove(item);
                        } else {
                          _selectedCons.add(item);
                        }
                      });
                    },
                    onAddCustom: (item) {
                      if (item.isNotEmpty && !_selectedCons.contains(item)) {
                        setState(() => _selectedCons.add(item));
                      }
                    },
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // ─── Yorum Metni ─────────────────────────────────
                  _buildCommentField()
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // ─── Fotoğraflar ─────────────────────────────────
                  PhotoUploadSection(
                    localPhotos: _localPhotos,
                    onAdd: (file) => setState(() => _localPhotos.add(file)),
                    onRemove: (index, isLocal) {
                      if (isLocal) {
                        setState(() => _localPhotos.removeAt(index));
                      }
                    },
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // ─── Anonim Switch ───────────────────────────────
                  _buildAnonymousSwitch()
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  // ─── Validation Hataları ─────────────────────────
                  if (_submitted && !_isFormValid)
                    _buildValidationErrors()
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .shakeX(hz: 3, amount: 2, duration: 400.ms),

                  const SizedBox(height: 16),

                  // ─── Gönder Butonu ───────────────────────────────
                  GradientButton(
                    text: 'Değerlendirmeyi Gönder',
                    onPressed: _submitReview,
                    isLoading: _isLoading,
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ─── Loading Overlay ─────────────────────────────────
          if (_isLoading)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// Validation hata listesi
  Widget _buildValidationErrors() {
    final errors = _validationErrors;
    if (errors.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Eksik alanlar:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map((e) => Padding(
                padding: const EdgeInsets.only(left: 26, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: AppColors.error.withAlpha(160)),
                    const SizedBox(width: 8),
                    Text(e, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Loading overlay — foto upload progress gösterir
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withAlpha(100),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lütfen bekleyin...',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  /// Genel değerlendirme yıldızları
  Widget _buildOverallRating() {
    final hasError = _submitted && _overallRating == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: hasError ? Border.all(color: AppColors.error, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 24, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('Genel Değerlendirme', style: AppTextStyles.titleMedium),
              if (hasError) ...[
                const Spacer(),
                Icon(Icons.error_outline, size: 18, color: AppColors.error),
              ],
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
                onTap: () => setState(() {
                  _overallRating = starIndex.toDouble();
                }),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFilled ? AppColors.warning : (hasError ? AppColors.error.withAlpha(100) : AppColors.textTertiary),
                    size: 40,
                  ),
                ),
              );
            }),
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
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Lütfen bir puan seçin',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
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

  /// Anonim paylaşım switch'i + info banner
  Widget _buildAnonymousSwitch() {
    return Column(
      children: [
        Container(
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
        ),
        // Anonim mod bilgi metni
        if (_isAnonymous)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(20),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                border: Border.all(color: AppColors.info.withAlpha(60)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anonim modda hesap bilgileriniz (ad, fotoğraf, üniversite) diğer kullanıcılardan gizlenir. Yorumunuz "Anonim Öğrenci" olarak görünür.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
          ),
      ],
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
