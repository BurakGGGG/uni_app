import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Yorum formunda fotoğraf ekleme bölümü.
///
/// Galeri veya kameradan fotoğraf ekleme, önizleme ve silme işlemleri.
/// Maksimum 3 fotoğraf eklenebilir. Fotoğraflar 1080px ve %75 kalite ile sıkıştırılır.
class PhotoUploadSection extends StatefulWidget {
  final List<File> localPhotos;
  final List<String> uploadedUrls; // Düzenleme modunda mevcut olanlar
  final void Function(File) onAdd;
  final void Function(int index, bool isLocal) onRemove;

  static const int maxPhotos = 3;

  const PhotoUploadSection({
    super.key,
    required this.localPhotos,
    this.uploadedUrls = const [],
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<PhotoUploadSection> createState() => _PhotoUploadSectionState();
}

class _PhotoUploadSectionState extends State<PhotoUploadSection> {
  final _picker = ImagePicker();

  int get _totalPhotos => widget.localPhotos.length + widget.uploadedUrls.length;
  bool get _canAddMore => _totalPhotos < PhotoUploadSection.maxPhotos;

  Future<void> _pickImage(ImageSource source) async {
    if (!_canAddMore) return;

    if (source == ImageSource.gallery) {
      // Çoklu seçim
      final picked = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 75,
      );

      if (picked.isEmpty) return;

      // Kalan slotu hesapla ve sınırla
      final remainingSlots = PhotoUploadSection.maxPhotos - _totalPhotos;
      final toAdd = picked.take(remainingSlots).toList();

      for (final file in toAdd) {
        widget.onAdd(File(file.path));
      }

      // Eğer daha fazla foto seçtiyse uyar
      if (picked.length > remainingSlots && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'En fazla ${PhotoUploadSection.maxPhotos} fotoğraf yüklenebilir. '
              '${toAdd.length} tanesi eklendi.',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      // Kamera — tek foto
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 75,
      );

      if (picked != null) {
        widget.onAdd(File(picked.path));
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.31),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Fotoğraf Ekle', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.info),
                ),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Fotoğraflar', style: AppTextStyles.titleMedium),
            const SizedBox(width: 8),
            Text(
              '($_totalPhotos/${PhotoUploadSection.maxPhotos})',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Üniversitenizle ilgili fotoğraf ekleyin (opsiyonel)',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (_canAddMore ? 1 : 0) + widget.uploadedUrls.length + widget.localPhotos.length,
            itemBuilder: (context, index) {
              if (_canAddMore) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: _showPickerOptions,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            'Ekle',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                index--;
              }

              if (index < widget.uploadedUrls.length) {
                return _buildPhotoTile(
                  child: CachedNetworkImage(
                    imageUrl: widget.uploadedUrls[index],
                    fit: BoxFit.cover,
                    memCacheWidth: 200, // 200px for thumbnail cache
                    placeholder: (_, _) => Container(color: AppColors.surfaceVariantFor(context)),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surfaceVariantFor(context),
                      child: Icon(Icons.error_outline, color: AppColors.textTertiaryFor(context)),
                    ),
                  ),
                  onRemove: () => widget.onRemove(index, false),
                );
              }
              index -= widget.uploadedUrls.length;

              return _buildPhotoTile(
                child: Image.file(widget.localPhotos[index], fit: BoxFit.cover),
                onRemove: () => widget.onRemove(index, true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTile({required Widget child, required VoidCallback onRemove}) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            child: SizedBox(width: 100, height: 100, child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
