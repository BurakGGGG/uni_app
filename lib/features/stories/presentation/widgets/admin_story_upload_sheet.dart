import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/story_providers.dart';

/// Admin kullanıcıların story paylaşmasını sağlayan bottom sheet.
///
/// İki görsel ister:
/// 1. **Kapak Fotoğrafı** — Ana ekrandaki bubble'da yuvarlak gösterilir (circular crop)
/// 2. **Story Görseli** — Tam ekran story viewer'da gösterilir
class AdminStoryUploadSheet extends ConsumerStatefulWidget {
  const AdminStoryUploadSheet({super.key});

  @override
  ConsumerState<AdminStoryUploadSheet> createState() =>
      _AdminStoryUploadSheetState();
}

class _AdminStoryUploadSheetState
    extends ConsumerState<AdminStoryUploadSheet> {
  File? _coverImage; // Kapak fotoğrafı (circular cropped)
  File? _storyImage; // Tam ekran story görseli
  final _titleController = TextEditingController();
  bool _isUploading = false;
  bool _isUnisec = true; // Varsayılan: ÜniSeç olarak paylaş

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canUpload => _coverImage != null && _storyImage != null;

  /// Kapak fotoğrafı seç → Yuvarlak kırpma ekranı aç
  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );

    if (pickedFile == null) return;

    // Yuvarlak kırpma ekranı
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Kapak Fotoğrafını Kırp',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          cropStyle: CropStyle.circle,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Kapak Fotoğrafını Kırp',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      setState(() {
        _coverImage = File(croppedFile.path);
      });
    }
  }

  /// Story görseli seç (tam ekran, kırpma yok)
  Future<void> _pickStoryImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _storyImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _upload() async {
    if (!_canUpload) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !user.isAdmin) return;

    setState(() => _isUploading = true);

    final success = await ref
        .read(storyUploadControllerProvider.notifier)
        .uploadStory(
          imageFile: _storyImage!,
          thumbnailFile: _coverImage!,
          authorUid: user.uid,
          authorName: _isUnisec ? 'ÜniSeç' : user.displayName,
          authorPhotoUrl: _isUnisec ? null : user.photoUrl,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
        );

    if (mounted) {
      setState(() => _isUploading = false);

      if (success) {
        // Provider'ları invalidate et — story listesi güncellensin
        ref.invalidate(storiesStreamProvider);
        ref.invalidate(storiesFallbackProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story başarıyla paylaşıldı! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story yüklenirken bir hata oluştu.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderFor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Yeni Story Paylaş',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── 1. Kapak Fotoğrafı (Yuvarlak) ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle_outlined,
                        size: 16,
                        color: AppColors.textSecondaryFor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kapak Fotoğrafı',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(ana ekranda görünür)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickCoverImage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariantFor(context),
                          border: Border.all(
                            color: _coverImage != null
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : AppColors.borderFor(context),
                            width: _coverImage != null ? 3 : 1.5,
                          ),
                          image: _coverImage != null
                              ? DecorationImage(
                                  image: FileImage(_coverImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _coverImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 28,
                                    color: AppColors.textTertiaryFor(context),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Seç',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color:
                                          AppColors.textTertiaryFor(context),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── 2. Story Görseli (Tam Ekran) ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fullscreen_rounded,
                        size: 16,
                        color: AppColors.textSecondaryFor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Story Görseli',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(tam ekran görünür)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickStoryImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantFor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _storyImage != null
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.borderFor(context),
                          width: _storyImage != null ? 2 : 1,
                        ),
                        image: _storyImage != null
                            ? DecorationImage(
                                image: FileImage(_storyImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _storyImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 36,
                                  color: AppColors.textTertiaryFor(context),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Story Görseli Seçin',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color:
                                        AppColors.textSecondaryFor(context),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Başlık Metni ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _titleController,
                enabled: !_isUploading,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Başlık ekle (opsiyonel)',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariantFor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),

            // ─── Kişisel / ÜniSeç Toggle ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondaryFor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Paylaşım Hesabı',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantFor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isUploading
                                ? null
                                : () => setState(() => _isUnisec = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isUnisec
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 16,
                                    color: _isUnisec
                                        ? Colors.white
                                        : AppColors.textSecondaryFor(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ÜniSeç',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _isUnisec
                                          ? Colors.white
                                          : AppColors.textSecondaryFor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isUploading
                                ? null
                                : () => setState(() => _isUnisec = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isUnisec
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: !_isUnisec
                                        ? Colors.white
                                        : AppColors.textSecondaryFor(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Kişisel',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: !_isUnisec
                                          ? Colors.white
                                          : AppColors.textSecondaryFor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Paylaş Butonu ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: _isUploading
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    : Material(
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _canUpload
                                ? AppColors.heroGradient
                                : null,
                            color: !_canUpload
                                ? AppColors.borderFor(context)
                                : null,
                          ),
                          child: InkWell(
                            onTap: _canUpload ? _upload : null,
                            child: Center(
                              child: Text(
                                'Paylaş',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: _canUpload
                                      ? Colors.white
                                      : AppColors.textTertiaryFor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
