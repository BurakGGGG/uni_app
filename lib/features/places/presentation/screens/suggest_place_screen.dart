import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/haptic.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/place_model.dart';
import '../../domain/models/place_suggestion_model.dart';
import '../../data/place_suggestion_repository.dart';
import '../providers/place_suggestion_providers.dart';

/// Mekan Öneri Formu — premium kalitede, fotoğraf destekli.
class SuggestPlaceScreen extends ConsumerStatefulWidget {
  final String universityId;
  final String universityName;

  const SuggestPlaceScreen({
    super.key,
    required this.universityId,
    required this.universityName,
  });

  @override
  ConsumerState<SuggestPlaceScreen> createState() => _SuggestPlaceScreenState();
}

class _SuggestPlaceScreenState extends ConsumerState<SuggestPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  PlaceType _selectedType = PlaceType.cafe;
  final List<File> _selectedPhotos = [];
  bool _isSubmitting = false;

  static const _maxPhotos = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_selectedPhotos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('En fazla $_maxPhotos fotoğraf ekleyebilirsin.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        final remaining = _maxPhotos - _selectedPhotos.length;
        final toAdd = images.take(remaining).map((x) => File(x.path)).toList();
        _selectedPhotos.addAll(toAdd);
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= _maxPhotos) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedPhotos.add(File(image.path));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final suggestion = PlaceSuggestionModel(
        id: '',
        universityId: widget.universityId,
        universityName: widget.universityName,
        userId: user.uid,
        userName: user.displayName,
        name: _nameController.text.trim(),
        type: _selectedType,
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(placeSuggestionRepositoryProvider).submitSuggestion(
            suggestion: suggestion,
            photos: _selectedPhotos,
          );

      AppHaptic.noteSaved();

      if (!mounted) return;

      // Başarı dialog'u göster
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SuccessDialog(
          placeName: _nameController.text.trim(),
          onDone: () {
            Navigator.of(ctx).pop();
            context.pop();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öneri gönderilemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(
          'Mekan Öner',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Üniversite bilgisi ────────────────────────────
            _InfoBanner(universityName: widget.universityName),
            const SizedBox(height: 24),

            // ─── Mekan Adı ─────────────────────────────────────
            _SectionLabel(label: 'Mekan Adı', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                hint: 'Örn: Kampüs Kahve',
                prefixIcon: Icons.store_rounded,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Mekan adı gerekli';
                if (v.trim().length < 2) return 'En az 2 karakter olmalı';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ─── Mekan Türü ────────────────────────────────────
            _SectionLabel(label: 'Mekan Türü', required: true),
            const SizedBox(height: 8),
            _PlaceTypeSelector(
              selected: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 20),

            // ─── Açıklama ──────────────────────────────────────
            _SectionLabel(label: 'Açıklama'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              decoration: _inputDecoration(
                hint: 'Bu mekan hakkında bilgi ver...',
                prefixIcon: Icons.description_rounded,
              ),
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // ─── Adres ─────────────────────────────────────────
            _SectionLabel(label: 'Adres'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration(
                hint: 'Mekanın adresi veya konumu',
                prefixIcon: Icons.location_on_rounded,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // ─── Fotoğraflar ───────────────────────────────────
            _SectionLabel(
              label: 'Fotoğraflar',
              subtitle: 'En fazla $_maxPhotos fotoğraf ekleyebilirsin',
            ),
            const SizedBox(height: 12),
            _PhotoGrid(
              photos: _selectedPhotos,
              maxPhotos: _maxPhotos,
              onPickGallery: _pickPhotos,
              onPickCamera: _takePhoto,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 32),

            // ─── Gönder Butonu ─────────────────────────────────
            _SubmitButton(
              isSubmitting: _isSubmitting,
              onTap: _submit,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textTertiaryFor(context),
      ),
      prefixIcon: Icon(prefixIcon, size: 20),
      filled: true,
      fillColor: AppColors.surfaceFor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderLightFor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderLightFor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─── Alt Widget'lar ──────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String universityName;
  const _InfoBanner({required this.universityName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  universityName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Bu üniversiteye yeni bir mekan öner. Önerilerin admin onayından geçer.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool required;
  final String? subtitle;

  const _SectionLabel({
    required this.label,
    this.required = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryFor(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlaceTypeSelector extends StatelessWidget {
  final PlaceType selected;
  final ValueChanged<PlaceType> onChanged;

  const _PlaceTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlaceType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.borderLightFor(context),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondaryFor(context),
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimaryFor(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<File> photos;
  final int maxPhotos;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final ValueChanged<int> onRemove;

  const _PhotoGrid({
    required this.photos,
    required this.maxPhotos,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Fotoğraf ekleme butonları
          if (photos.length < maxPhotos) ...[
            _AddPhotoButton(
              icon: Icons.photo_library_rounded,
              label: 'Galeri',
              onTap: onPickGallery,
            ),
            const SizedBox(width: 10),
            _AddPhotoButton(
              icon: Icons.camera_alt_rounded,
              label: 'Kamera',
              onTap: onPickCamera,
            ),
            if (photos.isNotEmpty) const SizedBox(width: 10),
          ],

          // Seçilen fotoğraflar
          ...photos.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                right: entry.key < photos.length - 1 ? 10 : 0,
              ),
              child: _PhotoThumbnail(
                file: entry.value,
                onRemove: () => onRemove(entry.key),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddPhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _PhotoThumbnail({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            file,
            width: 110,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),
        // Silme butonu
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onTap;

  const _SubmitButton({required this.isSubmitting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isSubmitting ? null : AppColors.heroGradient,
          color: isSubmitting ? AppColors.textTertiaryFor(context) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSubmitting
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Öneriyi Gönder',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Başarı dialog'u
class _SuccessDialog extends StatelessWidget {
  final String placeName;
  final VoidCallback onDone;

  const _SuccessDialog({required this.placeName, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Önerin Gönderildi!',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$placeName" öneriniz incelenmek üzere adminlere iletildi. Teşekkürler!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
