import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptic.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/place_suggestion_draft_store.dart';
import '../../domain/models/place_model.dart';
import '../../domain/models/place_suggestion_model.dart';
import '../providers/place_suggestion_providers.dart';
import '../widgets/place_open_hours_picker.dart';
import 'place_location_picker_screen.dart';

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
  final _phoneController = TextEditingController();

  PlaceType _selectedType = PlaceType.cafe;
  final List<File> _selectedPhotos = [];
  final Set<String> _selectedAmenities = {};
  String? _selectedPriceRange;
  String? _openHours;
  double? _latitude;
  double? _longitude;
  Timer? _draftTimer;
  bool _draftRestored = false;
  bool _isSubmitting = false;

  static const _maxPhotos = 5;
  static const _amenityOptions = [
    'Wi-Fi',
    'Priz',
    'Otopark',
    'Engelli erişimi',
    'Çalışma alanı',
    'Açık alan',
    'Klima',
    'Yemek',
    'Güvenlik',
    'Çamaşırhane',
    'Spor alanı',
    '7/24 açık',
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _descController,
      _addressController,
      _phoneController,
    ]) {
      controller.addListener(_scheduleDraftSave);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _draftTimer?.cancel();
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
      _scheduleDraftSave();
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
      _scheduleDraftSave();
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
    _scheduleDraftSave();
  }

  Future<void> _restoreDraft() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.universityId.isEmpty) return;
    final draft = await ref
        .read(placeSuggestionDraftStoreProvider)
        .load(userId: uid, universityId: widget.universityId);
    if (!mounted || draft == null) {
      _draftRestored = true;
      return;
    }

    final restoredPhotos = <File>[];
    for (final path in draft.photoPaths) {
      final file = File(path);
      if (await file.exists()) restoredPhotos.add(file);
    }

    setState(() {
      _nameController.text = draft.name;
      _descController.text = draft.description;
      _addressController.text = draft.address;
      _openHours = draft.openHours.trim().isEmpty ? null : draft.openHours;
      _phoneController.text = _digitsOnly(draft.phone);
      _selectedType = PlaceType.fromString(draft.type);
      _selectedPriceRange = draft.priceRange;
      _latitude = draft.latitude;
      _longitude = draft.longitude;
      _selectedAmenities
        ..clear()
        ..addAll(draft.amenities);
      _selectedPhotos
        ..clear()
        ..addAll(restoredPhotos.take(_maxPhotos));
      _draftRestored = true;
    });
  }

  void _scheduleDraftSave() {
    if (!_draftRestored || _isSubmitting) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 600), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.universityId.isEmpty) return;
    await ref
        .read(placeSuggestionDraftStoreProvider)
        .save(
          userId: uid,
          universityId: widget.universityId,
          draft: PlaceSuggestionDraft(
            name: _nameController.text,
            type: _selectedType.firestoreValue,
            description: _descController.text,
            address: _addressController.text,
            photoPaths: _selectedPhotos.map((file) => file.path).toList(),
            latitude: _latitude,
            longitude: _longitude,
            priceRange: _selectedPriceRange,
            openHours: _openHours ?? '',
            phone: _phoneController.text,
            amenities: _selectedAmenities.toList(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push<PlaceLocationSelection>(
      MaterialPageRoute(
        builder: (_) => PlaceLocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialSearchQuery: [
            _addressController.text.trim(),
            widget.universityName,
          ].where((item) => item.isNotEmpty).join(', '),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
    });
    _scheduleDraftSave();
  }

  Future<bool> _confirmDuplicateCandidates(
    List<PlaceDuplicateCandidate> candidates,
  ) async {
    if (candidates.isEmpty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Benzer mekanlar bulundu'),
            content: SizedBox(
              width: double.maxFinite,
              height: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aşağıdaki kayıtları kontrol et. Aynı mekan değilse devam edebilirsin.',
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: candidates.length,
                      itemBuilder: (_, index) {
                        final candidate = candidates[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            candidate.source == 'place'
                                ? Icons.place_rounded
                                : Icons.pending_actions_rounded,
                            color: AppColors.warning,
                          ),
                          title: Text(candidate.name),
                          subtitle: Text(
                            [
                              if (candidate.address.isNotEmpty)
                                candidate.address,
                              if (candidate.distanceMeters != null)
                                '${candidate.distanceMeters!.round()} m uzakta',
                              candidate.source == 'place'
                                  ? 'Kayıtlı mekan'
                                  : 'İncelemede',
                            ].join(' • '),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Geri dön'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yine de gönder'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(placeSuggestionRepositoryProvider);
      final duplicates = await repository.checkDuplicates(
        universityId: widget.universityId,
        name: _nameController.text.trim(),
        type: _selectedType,
        latitude: _latitude,
        longitude: _longitude,
      );
      if (!mounted) return;
      if (!await _confirmDuplicateCandidates(duplicates)) return;

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
        latitude: _latitude,
        longitude: _longitude,
        priceRange: _selectedPriceRange,
        openHours: _openHours,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        amenities: _selectedAmenities.toList(),
        createdAt: DateTime.now(),
      );

      await repository.submitSuggestion(
        suggestion: suggestion,
        photos: _selectedPhotos,
      );
      await ref
          .read(placeSuggestionDraftStoreProvider)
          .clear(userId: user.uid, universityId: widget.universityId);

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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.formMaxWidth(context),
          ),
          child: Form(
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
                  maxLength: 100,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Mekan adı gerekli';
                    }
                    if (v.trim().length < 2) return 'En az 2 karakter olmalı';
                    if (v.trim().length > 100) {
                      return 'En fazla 100 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ─── Mekan Türü ────────────────────────────────────
                _SectionLabel(label: 'Mekan Türü', required: true),
                const SizedBox(height: 8),
                _PlaceTypeSelector(
                  selected: _selectedType,
                  onChanged: (type) {
                    setState(() => _selectedType = type);
                    _scheduleDraftSave();
                  },
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
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                _SectionLabel(
                  label: 'Harita Konumu',
                  subtitle: 'Admin doğrulaması ve yol tarifi için',
                ),
                const SizedBox(height: 8),
                Material(
                  color: AppColors.surfaceFor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.borderLightFor(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: _selectLocation,
                    leading: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      _latitude == null
                          ? 'Haritadan konum seç'
                          : 'Konum seçildi',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: _latitude == null
                        ? const Text('Haritaya dokunarak pin bırak')
                        : Text(
                            '${_latitude!.toStringAsFixed(6)}, '
                            '${_longitude!.toStringAsFixed(6)}',
                          ),
                    trailing: Icon(
                      _latitude == null
                          ? Icons.chevron_right_rounded
                          : Icons.check_circle_rounded,
                      color: _latitude == null
                          ? AppColors.textTertiaryFor(context)
                          : AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _SectionLabel(label: 'Fiyat Aralığı'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const ['₺', '₺₺', '₺₺₺'].map((price) {
                    return ChoiceChip(
                      label: Text(price),
                      selected: _selectedPriceRange == price,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPriceRange = selected ? price : null;
                        });
                        _scheduleDraftSave();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                _SectionLabel(label: 'Çalışma Saatleri'),
                const SizedBox(height: 8),
                PlaceOpenHoursPicker(
                  value: _openHours,
                  onChanged: (value) {
                    setState(() => _openHours = value);
                    _scheduleDraftSave();
                  },
                ),
                const SizedBox(height: 20),

                _SectionLabel(label: 'Telefon'),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('place_phone_field'),
                  controller: _phoneController,
                  decoration: _inputDecoration(
                    hint: 'Örn: 0346 000 00 00',
                    prefixIcon: Icons.phone_rounded,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 11,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    if (phone.length < 10 || phone.length > 11) {
                      return 'Telefon 10 veya 11 haneli olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _SectionLabel(
                  label: 'Olanaklar',
                  subtitle: 'Mekanda bulunanları seç',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenityOptions.map((amenity) {
                    return FilterChip(
                      label: Text(amenity),
                      selected: _selectedAmenities.contains(amenity),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                        _scheduleDraftSave();
                      },
                    );
                  }).toList(),
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
                _SubmitButton(isSubmitting: _isSubmitting, onTap: _submit),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _digitsOnly(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 11 ? digits : digits.substring(0, 11);
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
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

  const _PlaceTypeSelector({required this.selected, required this.onChanged});

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
          child: Image.file(file, width: 110, height: 110, fit: BoxFit.cover),
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
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
