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
/// Desteklenen medya tipleri:
/// - **Fotoğraf**: Orijinal kalite (sıkıştırma yok)
/// - **Video**: 1080p sıkıştırma, maks 30 saniye
///
/// Her iki tipte de kapak fotoğrafı (circular crop) gereklidir.
class AdminStoryUploadSheet extends ConsumerStatefulWidget {
  const AdminStoryUploadSheet({super.key});

  @override
  ConsumerState<AdminStoryUploadSheet> createState() =>
      _AdminStoryUploadSheetState();
}

class _AdminStoryUploadSheetState extends ConsumerState<AdminStoryUploadSheet> {
  File? _coverImage; // Kapak fotoğrafı (circular cropped)
  File? _storyImage; // Tam ekran story görseli (fotoğraf modu)
  File? _storyVideo; // Video dosyası (video modu)
  final _titleController = TextEditingController();
  bool _isUploading = false;
  bool _isUnisec = true;
  bool _isVideoMode = false; // false=fotoğraf, true=video

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canUpload {
    if (_coverImage == null) return false;
    return _isVideoMode ? _storyVideo != null : _storyImage != null;
  }

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
      setState(() => _coverImage = File(croppedFile.path));
    }
  }

  /// Story görseli seç — orijinal kalite, sıkıştırma yok
  Future<void> _pickStoryImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      // Sıkıştırma yok — orijinal kalite
    );

    if (pickedFile != null) {
      setState(() => _storyImage = File(pickedFile.path));
    }
  }

  /// Video seç — maks 30 saniye
  Future<void> _pickStoryVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );

    if (pickedFile != null) {
      setState(() => _storyVideo = File(pickedFile.path));
    }
  }

  /// Medya modunu değiştir (fotoğraf ↔ video)
  void _toggleMode(bool isVideo) {
    if (_isVideoMode == isVideo) return;
    setState(() {
      _isVideoMode = isVideo;
      // Önceki seçimi temizle
      _storyImage = null;
      _storyVideo = null;
    });
  }

  Future<void> _upload() async {
    if (!_canUpload) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    final isAdmin = ref.read(currentUserAdminProvider).valueOrNull ?? false;
    if (user == null || !isAdmin) return;

    setState(() => _isUploading = true);

    bool success;

    if (_isVideoMode) {
      success = await ref
          .read(storyUploadControllerProvider.notifier)
          .uploadVideoStory(
            videoFile: _storyVideo!,
            thumbnailFile: _coverImage!,
            authorUid: user.uid,
            authorName: _isUnisec ? 'ÜniSeç' : user.displayName,
            authorPhotoUrl: _isUnisec ? null : user.photoUrl,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
          );
    } else {
      success = await ref
          .read(storyUploadControllerProvider.notifier)
          .uploadImageStory(
            imageFile: _storyImage!,
            thumbnailFile: _coverImage!,
            authorUid: user.uid,
            authorName: _isUnisec ? 'ÜniSeç' : user.displayName,
            authorPhotoUrl: _isUnisec ? null : user.photoUrl,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
          );
    }

    if (mounted) {
      setState(() => _isUploading = false);

      if (success) {
        ref.invalidate(storiesStreamProvider);
        ref.invalidate(storiesFallbackProvider);
        ref.invalidate(allStoriesStreamProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isVideoMode
                  ? 'Video story başarıyla paylaşıldı!'
                  : 'Story başarıyla paylaşıldı!',
            ),
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
            const SizedBox(height: 16),

            // ─── Medya Tipi Seçici (Fotoğraf / Video) ─────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildModeTab(
                      icon: Icons.photo_rounded,
                      label: 'Fotoğraf',
                      isSelected: !_isVideoMode,
                      onTap: () => _toggleMode(false),
                    ),
                    _buildModeTab(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      isSelected: _isVideoMode,
                      onTap: () => _toggleMode(true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                                      color: AppColors.textTertiaryFor(context),
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

            // ─── 2. Story Medyası (Fotoğraf veya Video) ───────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isVideoMode
                            ? Icons.videocam_rounded
                            : Icons.fullscreen_rounded,
                        size: 16,
                        color: AppColors.textSecondaryFor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isVideoMode ? 'Video' : 'Story Görseli',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isVideoMode
                            ? '(maks 30sn, 1080p sıkıştırılır)'
                            : '(tam ekran, orijinal kalite)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isUploading
                        ? null
                        : (_isVideoMode ? _pickStoryVideo : _pickStoryImage),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantFor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              (_isVideoMode ? _storyVideo : _storyImage) != null
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.borderFor(context),
                          width:
                              (_isVideoMode ? _storyVideo : _storyImage) != null
                              ? 2
                              : 1,
                        ),
                        image: !_isVideoMode && _storyImage != null
                            ? DecorationImage(
                                image: FileImage(_storyImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _buildMediaPickerContent(),
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
                        _buildAccountTab(
                          icon: Icons.school_rounded,
                          label: 'ÜniSeç',
                          isSelected: _isUnisec,
                          onTap: () => setState(() => _isUnisec = true),
                        ),
                        _buildAccountTab(
                          icon: Icons.person_rounded,
                          label: 'Kişisel',
                          isSelected: !_isUnisec,
                          onTap: () => setState(() => _isUnisec = false),
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
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isVideoMode
                                    ? 'Sıkıştırılıyor & Yükleniyor...'
                                    : 'Yükleniyor...',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
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

  Widget _buildMediaPickerContent() {
    if (_isVideoMode) {
      if (_storyVideo != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 36,
                color: AppColors.primary,
              ),
              const SizedBox(height: 6),
              Text(
                'Video seçildi',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Değiştirmek için dokunun',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                ),
              ),
            ],
          ),
        );
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_rounded,
            size: 36,
            color: AppColors.textTertiaryFor(context),
          ),
          const SizedBox(height: 6),
          Text(
            'Video Seçin',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          Text(
            'Maks 30 saniye',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
            ),
          ),
        ],
      );
    }

    // Fotoğraf modu — image zaten decoration ile gösteriliyor
    if (_storyImage != null) return const SizedBox.shrink();

    return Column(
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
            color: AppColors.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isUploading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondaryFor(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isUploading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondaryFor(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
