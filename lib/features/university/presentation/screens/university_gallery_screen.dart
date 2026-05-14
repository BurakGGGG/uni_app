import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/domain/models/review_model.dart';
import 'package:uni_app/features/university/presentation/widgets/fullscreen_photo_viewer.dart';

class UniversityGalleryScreen extends ConsumerStatefulWidget {
  final String universityId;

  const UniversityGalleryScreen({super.key, required this.universityId});

  @override
  ConsumerState<UniversityGalleryScreen> createState() => _UniversityGalleryScreenState();
}

class _UniversityGalleryScreenState extends ConsumerState<UniversityGalleryScreen> {
  ReviewType? _selectedType;

  IconData _getIconForType(ReviewType type) {
    switch (type) {
      case ReviewType.university:
        return Icons.account_balance_rounded;
      case ReviewType.department:
        return Icons.school_rounded;
      case ReviewType.place:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(universityGalleryPhotosProvider(widget.universityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Fotoğraf Galerisi',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Fotoğraflar yüklenemedi: $err',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz fotoğraf eklenmemiş',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk fotoğrafı sen ekleyebilirsin!',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms);
          }

          final filteredPhotos = _selectedType == null
              ? photos
              : photos.where((p) => p.review.type == _selectedType).toList();

          return Column(
            children: [
              // Filtreler
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (context) {
                    final children = [
                      _buildFilterChip('Tümü', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Üniversite', ReviewType.university),
                      const SizedBox(width: 8),
                      _buildFilterChip('Bölüm', ReviewType.department),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mekan', ReviewType.place),
                    ];
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: children.length,
                      itemBuilder: (context, index) => children[index],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              
              // Galeri
              Expanded(
                child: filteredPhotos.isEmpty
                    ? Center(
                        child: Text(
                          'Bu kategoride fotoğraf bulunamadı.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: filteredPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = filteredPhotos[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullscreenPhotoViewer(
                                    photos: filteredPhotos,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'photo_${photo.imageUrl}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: photo.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIconForType(photo.review.type),
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, ReviewType? type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = type;
        });
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
