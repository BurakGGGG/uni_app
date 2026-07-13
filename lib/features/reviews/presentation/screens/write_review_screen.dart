import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/review_repository.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../../../places/presentation/providers/place_providers.dart';
import '../widgets/review_form_sections/category_ratings_section.dart';
import '../widgets/review_form_sections/pros_cons_section.dart';
import '../widgets/review_form_sections/photo_upload_section.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String targetId;
  final ReviewType type;
  final String universityId;
  final String? placeSubType; // 'cafe', 'dorm', 'library', etc.
  final ReviewModel? initialReview;

  const WriteReviewScreen({
    super.key,
    required this.targetId,
    required this.type,
    required this.universityId,
    this.placeSubType,
    this.initialReview,
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
  final List<String> _existingPhotoUrls = [];

  bool _isAnonymous = false;
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _submitted = false; // Validation hatalarını göstermek için
  bool _showSuccess = false; // Başarı animasyonu
  double _uploadProgress = 0; // Fotoğraf upload ilerleme (0.0 - 1.0)

  // Upload listener subscription — dispose'da cancel edilir
  StreamSubscription<TaskSnapshot>? _uploadSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.initialReview != null) {
      final r = widget.initialReview!;
      _overallRating = r.rating;
      _categoryRatings.addAll(r.categoryRatings);
      _selectedPros.addAll(r.pros);
      _selectedCons.addAll(r.cons);
      _commentController.text = r.comment;
      _isAnonymous = r.isAnonymous;
      _existingPhotoUrls.addAll(r.imageUrls);
    }
  }

  @override
  void dispose() {
    _uploadSubscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  /// Type'a göre kategori listesi (cached)
  late final List<String> _categories = switch (widget.type) {
    ReviewType.university => AppConstants.uniRatingCategories,
    ReviewType.department => AppConstants.deptRatingCategories,
    ReviewType.place => AppConstants.placeRatingCategories,
  };

  /// Type'a göre preset pros (cached)
  late final List<String> _presetPros = switch (widget.type) {
    ReviewType.university => AppConstants.commonUniPros,
    ReviewType.department => AppConstants.commonDeptPros,
    ReviewType.place => _placeProsForSubType,
  };

  /// Type'a göre preset cons (cached)
  late final List<String> _presetCons = switch (widget.type) {
    ReviewType.university => AppConstants.commonUniCons,
    ReviewType.department => AppConstants.commonDeptCons,
    ReviewType.place => _placeConsForSubType,
  };

  /// Place alt tipine göre pros listesi
  List<String> get _placeProsForSubType => switch (widget.placeSubType) {
    'cafe' => AppConstants.cafePros,
    'dorm' => AppConstants.dormPros,
    'library' => AppConstants.libraryPros,
    _ => AppConstants.placePros,
  };

  /// Place alt tipine göre cons listesi
  List<String> get _placeConsForSubType => switch (widget.placeSubType) {
    'cafe' => AppConstants.cafeCons,
    'dorm' => AppConstants.dormCons,
    'library' => AppConstants.libraryCons,
    _ => AppConstants.placeCons,
  };

  /// Tüm zorunlu alanlar dolu mu kontrol et
  bool get _isFormValid {
    final allCategoriesFilled = _categories.every(
      (c) => (_categoryRatings[c] ?? 0) > 0,
    );
    final commentLen = _commentController.text.trim().length;
    final minLen = widget.type == ReviewType.place ? 20 : 20;
    return _overallRating > 0 &&
        allCategoriesFilled &&
        commentLen >= minLen &&
        commentLen <= 500;
  }

  /// Submit butonu tooltip mesajı
  String get _submitTooltip {
    if (_isFormValid) return '';
    final errors = _validationErrors;
    if (errors.isEmpty) return '';
    return errors.join(' • ');
  }

  /// Eksik alan sayısı (validation feedback için)
  List<String> get _validationErrors {
    final errors = <String>[];
    if (_overallRating == 0) errors.add('Genel puan');
    final missing = _categories
        .where((c) => (_categoryRatings[c] ?? 0) == 0)
        .toList();
    if (missing.isNotEmpty) errors.add('${missing.length} kategori puanı');
    final commentLen = _commentController.text.trim().length;
    if (commentLen < 20) errors.add('Yorum (min. 20 karakter)');
    if (commentLen > 500) errors.add('Yorum (max. 500 karakter)');
    return errors;
  }

  /// Fotoğrafları Firebase Storage'a yükle (progress göstergesi ile)
  Future<List<String>> _uploadReviewPhotos(
    List<File> photos,
    String userId,
  ) async {
    final urls = <String>[];
    for (int i = 0; i < photos.length; i++) {
      setState(() {
        _loadingMessage = 'Fotoğraf yükleniyor... ${i + 1}/${photos.length}';
        _uploadProgress = i / photos.length;
      });
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child(
        'review_images/$userId/$imageId.jpg',
      );

      // Upload task ile gerçek progress takibi
      final uploadTask = storageRef.putFile(
        photos[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );

      _uploadSubscription?.cancel();
      _uploadSubscription = uploadTask.snapshotEvents.listen((event) {
        if (mounted) {
          final fileProgress = event.bytesTransferred / event.totalBytes;
          setState(() {
            _uploadProgress = (i + fileProgress) / photos.length;
          });
        }
      });

      await uploadTask;
      await _uploadSubscription?.cancel();
      _uploadSubscription = null;
      urls.add(await storageRef.getDownloadURL());
    }
    setState(() => _uploadProgress = 1.0);
    return urls;
  }

  Future<void> _submitReview() async {
    setState(() => _submitted = true);

    if (_overallRating == 0) {
      showAppSnackBar(
        context,
        message: 'Lütfen genel bir puan verin',
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Kategori kontrolü
    final missingCategories = _categories
        .where((c) => (_categoryRatings[c] ?? 0) == 0)
        .toList();

    if (missingCategories.isNotEmpty) {
      showAppSnackBar(
        context,
        message: 'Şu kategorilere puan verin: ${missingCategories.join(", ")}',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Değerlendirme gönderiliyor...';
    });

    try {
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) {
        showAppSnackBar(
          context,
          message: 'Hesap bilgileri yükleniyor, lütfen bekleyin',
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }
      final user = authAsync.value;
      if (user == null) {
        showAppSnackBar(context, message: 'Lütfen giriş yapın', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final currentUserData = await ref.read(currentUserProvider.future);
      if (currentUserData == null) {
        throw Exception('Kullanıcı profili bulunamadı');
      }

      // 1. Önce yeni fotoğrafları yükle
      List<String> imageUrls = List.from(_existingPhotoUrls);
      if (_localPhotos.isNotEmpty) {
        final newUrls = await _uploadReviewPhotos(_localPhotos, user.uid);
        imageUrls.addAll(newUrls);
      }

      setState(() => _loadingMessage = 'Yorum kaydediliyor...');

      // 2. Sonra review document'i oluştur
      final review = ReviewModel(
        id: widget.initialReview?.id ?? '', // Firestore auto-generates if empty
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
        createdAt: widget.initialReview?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initialReview != null) {
        await ref.read(reviewRepositoryProvider).updateReview(review);
        ref.invalidate(reviewDetailProvider(review.id)); // Cache'i temizle
      } else {
        await ref.read(reviewRepositoryProvider).addReview(review);
      }

      if (mounted) {
        // Başarı animasyonu göster
        setState(() {
          _isLoading = false;
          _showSuccess = true;
        });

        // Profile cache'i temizle — reviewCount anında güncellenir
        invalidateUserProfileAfterReviewChange(ref);

        // Place cache'i temizle — üni sayfasında güncel rating göster
        if (widget.type == ReviewType.place) {
          ref.read(placeRepositoryProvider).clearCache();
          ref.invalidate(placesByUniversityProvider(widget.universityId));
        }

        // 1.5 saniye sonra geri dön
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.pop();
      }
    } on ReviewRateLimitedException {
      if (mounted) {
        showAppSnackBar(
          context,
          message:
              'Çok kısa sürede fazla yorum gönderdiniz. Lütfen biraz bekleyin.',
          isError: true,
        );
      }
    } on ReviewSubmissionException catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: 'Bir hata oluştu: $e', isError: true);
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
        backgroundColor: AppColors.backgroundFor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: AppColors.success,
              ).animate().scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 24),
              Text(
                    'Değerlendirmeniz Gönderildi!',
                    style: AppTextStyles.titleLarge,
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Text(
                'Yorumunuz moderasyon sonrası yayınlanacaktır.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialReview != null
                ? 'Düzenle'
                : switch (widget.type) {
                    ReviewType.university => 'Üniversite Değerlendir',
                    ReviewType.department => 'Bölüm Değerlendir',
                    ReviewType.place => 'Mekan Değerlendir',
                  },
          ),
        ),
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.formMaxWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Genel Puan ──────────────────────────────────
                        _buildOverallRating().animate().fadeIn(
                          duration: 400.ms,
                        ),

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
                            if (item.isNotEmpty &&
                                !_selectedPros.contains(item)) {
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
                            if (item.isNotEmpty &&
                                !_selectedCons.contains(item)) {
                              setState(() => _selectedCons.add(item));
                            }
                          },
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        // ─── Yorum Metni ─────────────────────────────────
                        _buildCommentField().animate().fadeIn(
                          delay: 250.ms,
                          duration: 400.ms,
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        // ─── Fotoğraflar ─────────────────────────────────
                        PhotoUploadSection(
                          localPhotos: _localPhotos,
                          uploadedUrls: _existingPhotoUrls,
                          onAdd: (file) =>
                              setState(() => _localPhotos.add(file)),
                          onRemove: (index, isLocal) {
                            setState(() {
                              if (isLocal) {
                                _localPhotos.removeAt(index);
                              } else {
                                _existingPhotoUrls.removeAt(index);
                              }
                            });
                          },
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                        if (widget.initialReview == null) ...[
                          const SizedBox(height: 24),

                          // ─── Anonim Switch ───────────────────────────────
                          _buildAnonymousSwitch().animate().fadeIn(
                            delay: 350.ms,
                            duration: 400.ms,
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ─── Validation Hataları ─────────────────────────
                        if (_submitted && !_isFormValid)
                          _buildValidationErrors()
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .shakeX(hz: 3, amount: 2, duration: 400.ms),

                        const SizedBox(height: 16),

                        // ─── Gönder Butonu ───────────────────────────────
                        Tooltip(
                          message: _submitted && !_isFormValid
                              ? _submitTooltip
                              : '',
                          child: GradientButton(
                            text: widget.initialReview != null
                                ? 'Değişiklikleri Kaydet'
                                : 'Değerlendirmeyi Gönder',
                            onPressed: _submitReview,
                            isLoading: _isLoading,
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Loading Overlay ─────────────────────────────────
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
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
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.31)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.error,
              ),
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
          ...errors.map(
            (e) => Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.error.withValues(alpha: 0.63),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loading overlay — foto upload progress gösterir
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.39),
      child: Center(
        child:
            Container(
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceFor(context),
                    borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
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
                      if (_uploadProgress > 0 && _uploadProgress < 1.0) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: AppColors.borderLightFor(context),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Lütfen bekleyin...',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.9, 0.9)),
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
        border: hasError
            ? Border.all(color: AppColors.error, width: 1.5)
            : null,
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
            switch (widget.type) {
              ReviewType.university =>
                'Bu üniversiteyi genel olarak nasıl değerlendirirsiniz?',
              ReviewType.department =>
                'Bu bölümü genel olarak nasıl değerlendirirsiniz?',
              ReviewType.place =>
                'Bu mekanı genel olarak nasıl değerlendirirsiniz?',
            },
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
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
                    color: isFilled
                        ? AppColors.warning
                        : (hasError
                              ? AppColors.error.withValues(alpha: 0.39)
                              : AppColors.textTertiaryFor(context)),
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
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText:
                'Bu üniversite hakkında diğer öğrencilere faydalı olabilecek deneyimlerinizi paylaşın...',
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
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: _isAnonymous
                  ? AppColors.primary.withValues(alpha: 0.31)
                  : AppColors.borderLightFor(context),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(
                'Anonim olarak paylaş',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                _isAnonymous
                    ? 'Adınız ve fotoğrafınız gizlenecek'
                    : 'Adınız ve fotoğrafınız görünür olacak',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              secondary: Icon(
                _isAnonymous
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _isAnonymous
                    ? AppColors.primary
                    : AppColors.textTertiaryFor(context),
              ),
              value: _isAnonymous,
              onChanged: (val) => setState(() => _isAnonymous = val),
              activeThumbColor: AppColors.primary,
            ),
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
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anonim modda hesap bilgileriniz (ad, fotoğraf, üniversite) diğer kullanıcılardan gizlenir. Yorumunuz "Anonim Öğrenci" olarak görünür.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
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
