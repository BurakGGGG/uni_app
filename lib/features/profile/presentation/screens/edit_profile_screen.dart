import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/profanity_filter.dart';
import '../../../../core/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/domain/models/university_model.dart';

/// Profil düzenleme ekranı
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedUniversity;
  String? _selectedUniversityId;
  String? _selectedDepartment;
  int? _selectedGrade;
  String? _bio;
  File? _selectedImage;
  String? _currentPhotoUrl;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _bioHasProfanity = false;

  // Geçici üniversite listesi kaldırıldı, Firestore'dan dinamik alınacak

  final _grades = [
    {'value': 0, 'label': 'Hazırlık'},
    {'value': 1, 'label': '1. Sınıf'},
    {'value': 2, 'label': '2. Sınıf'},
    {'value': 3, 'label': '3. Sınıf'},
    {'value': 4, 'label': '4. Sınıf'},
    {'value': 5, 'label': '5. Sınıf+'},
    {'value': 6, 'label': 'Mezun'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final userAsync = ref.read(currentUserProvider);
    userAsync.whenData((profile) {
      if (profile != null) {
        _nameController.text = profile.displayName;
        _selectedUniversity = profile.university;
        _selectedUniversityId = profile.universityId;
        _selectedDepartment = profile.department;
        _selectedGrade = profile.grade;
        _bio = profile.bio;
        _currentPhotoUrl = profile.photoUrl;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _hasChanges = true;
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      // Fotoğraf yükleme
      if (_selectedImage != null) {
        await authRepo.uploadProfilePhoto(user.uid, _selectedImage!);
      }

      // Profil bilgileri güncelle
      await authRepo.updateProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        university: _selectedUniversity,
        universityId: _selectedUniversityId,
        department: _selectedDepartment,
        grade: _selectedGrade,
        bio: _bio,
      );

      // Provider'ı yenile
      ref.invalidate(currentUserProvider);

      if (mounted) {
        showAppSnackBar(context, message: 'Profil başarıyla güncellendi', isSuccess: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: 'Profil güncellenirken hata oluştu', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final universitiesAsync = ref.watch(allUniversitiesProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ─── Profil Fotoğrafı ────────────────────────────
                  GestureDetector(
                    onTap: _showImagePicker,
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _buildAvatar(),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 32),

                  // ─── Ad Soyad ────────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _hasChanges = true),
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ad Soyad gerekli';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ─── Üniversite Seçimi ────────────────────────────
                  universitiesAsync.when(
                    data: (unis) {
                      // Ensure selected university exists in the loaded list, otherwise set to null
                      final selectedUniModel = unis.cast<UniversityModel?>().firstWhere(
                        (u) => u?.id == _selectedUniversityId || u?.name == _selectedUniversity,
                        orElse: () => null,
                      );

                      return DropdownButtonFormField<UniversityModel>(
                        initialValue: selectedUniModel,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Üniversite',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: unis.map((uni) {
                          return DropdownMenuItem(value: uni, child: Text(uni.name, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (uni) {
                          setState(() {
                            _selectedUniversity = uni?.name;
                            _selectedUniversityId = uni?.id;
                            _hasChanges = true;
                          });
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Üniversiteler yüklenemedi: $e'),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ─── Bölüm ────────────────────────────────────────
                  TextFormField(
                    initialValue: _selectedDepartment,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Bölüm',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                      hintText: 'Örn: Bilgisayar Mühendisliği',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                        _hasChanges = true;
                      });
                    },
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ─── Hakkımda (Bio) ──────────────────────────────
                  TextFormField(
                    initialValue: _bio,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: 'Hakkımda (Opsiyonel)',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.info_outline_rounded),
                      ),
                      hintText: 'Kendinden kısaca bahset...',
                      errorText: _bioHasProfanity ? 'Uygunsuz içerik tespit edildi' : null,
                      errorStyle: const TextStyle(color: AppColors.error),
                    ),
                    onChanged: (value) {
                      final hasProfanity = ProfanityFilter.containsProfanity(value);
                      setState(() {
                        _bio = value.trim().isEmpty ? null : value.trim();
                        _bioHasProfanity = hasProfanity;
                        _hasChanges = true;
                      });
                    },
                    validator: (value) {
                      if (value != null && ProfanityFilter.containsProfanity(value)) {
                        return 'Uygunsuz içerik tespit edildi';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ─── Sınıf ────────────────────────────────────────
                  DropdownButtonFormField<int>(
                    initialValue: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Sınıf',
                      prefixIcon: Icon(Icons.grade_outlined),
                    ),
                    items: _grades.map((g) {
                      return DropdownMenuItem(
                        value: g['value'] as int,
                        child: Text(g['label'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGrade = value;
                        _hasChanges = true;
                      });
                    },
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 36),

                  // ─── Kaydet ───────────────────────────────────────
                  GradientButton(
                    text: 'Kaydet',
                    icon: Icons.check_rounded,
                    onPressed: (_hasChanges && !_isLoading && !_bioHasProfanity) ? _saveProfile : null,
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ─── Loading Overlay ──────────────────────────────────
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                          const SizedBox(height: 20),
                          Text('Kaydediliyor...', style: AppTextStyles.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(_selectedImage!, fit: BoxFit.cover, width: 110, height: 110),
      );
    }
    if (_currentPhotoUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _currentPhotoUrl!,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          memCacheWidth: 220,
          memCacheHeight: 220,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => _buildInitials(),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final name = _nameController.text.trim();
    String initials = '?';
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else {
        initials = name[0].toUpperCase();
      }
    }
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
      ),
    );
  }
}
