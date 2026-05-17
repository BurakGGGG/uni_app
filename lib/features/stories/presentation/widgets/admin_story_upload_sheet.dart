import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/story_providers.dart';

/// Admin kullanıcıların story paylaşmasını sağlayan bottom sheet.
class AdminStoryUploadSheet extends ConsumerStatefulWidget {
  const AdminStoryUploadSheet({super.key});

  @override
  ConsumerState<AdminStoryUploadSheet> createState() =>
      _AdminStoryUploadSheetState();
}

class _AdminStoryUploadSheetState
    extends ConsumerState<AdminStoryUploadSheet> {
  File? _selectedImage;
  final _titleController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedImage == null) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !user.isAdmin) return;

    setState(() => _isUploading = true);

    final success = await ref
        .read(storyUploadControllerProvider.notifier)
        .uploadStory(
          imageFile: _selectedImage!,
          authorUid: user.uid,
          authorName: user.displayName,
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

            // Görsel Seçme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariantFor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.borderFor(context),
                      width: _selectedImage != null ? 2 : 1,
                    ),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 40,
                              color: AppColors.textTertiaryFor(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Görsel Seçin',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondaryFor(context),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Başlık Metni
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
            const SizedBox(height: 16),

            // Paylaş Butonu
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
                            gradient: _selectedImage != null
                                ? AppColors.heroGradient
                                : null,
                            color: _selectedImage == null
                                ? AppColors.borderFor(context)
                                : null,
                          ),
                          child: InkWell(
                            onTap: _selectedImage != null ? _upload : null,
                            child: Center(
                              child: Text(
                                'Paylaş',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: _selectedImage != null
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
