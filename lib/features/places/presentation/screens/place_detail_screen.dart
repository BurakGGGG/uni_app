import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../reviews/presentation/screens/photo_gallery_screen.dart';
import '../../domain/models/place_model.dart';
import '../providers/place_providers.dart';
import '../widgets/place_type_chip.dart';
import '../widgets/dorm_info_card.dart';
import '../widgets/dorm_room_floor_plan.dart';
import '../widgets/place_amenities_grid.dart';
import '../widgets/place_detail_skeleton.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final placeAsync = ref.watch(placeWatchProvider(widget.placeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: placeAsync.when(
        loading: () => const PlaceDetailSkeleton(),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (place) {
          if (place == null) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Mekan bulunamadı',
                description: 'Bu mekan silinmiş olabilir.',
              ),
            );
          }
          return _buildContent(place);
        },
      ),
    );
  }

  Widget _buildContent(PlaceModel place) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(place),
        SliverToBoxAdapter(child: _buildHeader(place)),
        if (place.type == PlaceType.dorm) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: DormInfoCard(place: place)),
          // Kadı Burhaneddin KYK Yurdu özel oda krokisi
          if (place.name.contains('Kadı Burhaneddin') ||
              place.name.contains('kadı burhaneddin') ||
              place.name.toLowerCase().contains('kadı burhaneddin')) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: DormRoomFloorPlan()),
          ],
        ],
        SliverToBoxAdapter(child: _buildInfoSection(place)),
        if (place.amenities.isNotEmpty)
          SliverToBoxAdapter(child: _buildAmenitiesSection(place)),
        SliverToBoxAdapter(child: _buildActionsBar(place)),
        SliverToBoxAdapter(child: _buildReviewsHeader(place)),
        _buildReviewsList(place),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ─── P1-1 FIX: Foto galerisi + dot indicator + tap-to-fullscreen ─────
  Widget _buildAppBar(PlaceModel place) {
    final hasImages = place.imageUrls.isNotEmpty;
    return SliverAppBar(
      expandedHeight: hasImages ? 240 : 0,
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.white70, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
      flexibleSpace: hasImages
        ? FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: place.imageUrls.length,
                  onPageChanged: (i) =>
                      setState(() => _currentImageIndex = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoGalleryScreen(
                          imageUrls: place.imageUrls,
                          initialIndex: i,
                        ),
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: place.imageUrls[i],
                      fit: BoxFit.cover,
                      placeholder: (_, url) =>
                          Container(color: AppColors.surfaceVariant),
                      errorWidget: (_, url, error) => Container(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(place.type.icon,
                            size: 80, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                // Dot indicator (2+ foto varsa)
                if (place.imageUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        place.imageUrls.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: i == _currentImageIndex ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _currentImageIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Foto sayacı
                if (place.imageUrls.length > 1)
                  Positioned(
                    top: 48,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${place.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        : null,
      title: !hasImages
        ? Text(place.name, style: AppTextStyles.titleMedium)
        : null,
    );
  }

  Widget _buildHeader(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlaceTypeChip(type: place.type),
              if (place.priceRange != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(place.priceRange!,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(place.name, style: AppTextStyles.headlineLarge),
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(place.address,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _buildRatingRow(place),
        ],
      ),
    );
  }

  Widget _buildRatingRow(PlaceModel place) {
    return Row(
      children: [
        if (place.avgRating > 0) ...[
          Icon(Icons.star_rounded, size: 18, color: AppColors.ratingStar),
          const SizedBox(width: 4),
          Text(place.avgRating.toStringAsFixed(1),
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text('(${place.reviewCount} yorum)',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
        ] else
          Text('Henüz değerlendirilmedi',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
        if (place.externalRating != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Google ', style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
              Icon(Icons.star_rounded, size: 12, color: const Color(0xFF1B5E20)),
              const SizedBox(width: 2),
              Text(place.externalRating!.toStringAsFixed(1),
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ],
    );
  }

  // ─── P1-2 / P1-5 FIX: Type'a göre koşullu info section ──────────
  Widget _buildInfoSection(PlaceModel place) {
    // Yurt için openHours gösterme — DormInfoCard zaten üstte
    final showOpenHours = place.type != PlaceType.dorm && place.openHours != null;
    final openHoursLabel = place.type == PlaceType.library
        ? 'Çalışma Saatleri'
        : 'Açılış Saatleri';

    if (place.description.isEmpty && !showOpenHours) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.description.isNotEmpty) ...[
            Text('Hakkında', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(place.description,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
          ],
          if (showOpenHours) ...[
            if (place.description.isNotEmpty) const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('$openHoursLabel: ',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
              Expanded(
                child: Text(place.openHours!,
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Özellikler', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          PlaceAmenitiesGrid(amenities: place.amenities),
        ],
      ),
    );
  }

  Widget _buildActionsBar(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openMap(place),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Haritada Aç'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.push(
                  '/write-review/place/${place.id}?uni=${place.universityId}&pt=${place.type.firestoreValue}');
              },
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Yorum Yaz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── P1-4 FIX: MapLauncher ile platform-aware fallback zinciri ──
  Future<void> _openMap(PlaceModel place) async {
    final ok = await MapLauncher.open(
      mapUrl: place.mapUrl,
      location: place.location,
      name: place.name,
      address: place.address,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Harita uygulaması bulunamadı. Lütfen Google Maps yükleyin.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Yükle',
            textColor: Colors.white,
            onPressed: () => MapLauncher.openPlayStoreMaps(),
          ),
        ),
      );
    }
  }

  Widget _buildReviewsHeader(PlaceModel place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Row(
        children: [
          Text('Yorumlar', style: AppTextStyles.headlineMedium),
          const Spacer(),
          PopupMenuButton<ReviewSort>(
            initialValue: ref.watch(reviewSortProvider),
            onSelected: (s) =>
                ref.read(reviewSortProvider.notifier).state = s,
            itemBuilder: (_) => const [
              PopupMenuItem(value: ReviewSort.newest, child: Text('En yeni')),
              PopupMenuItem(value: ReviewSort.mostLiked, child: Text('En beğenilen')),
            ],
            child: Row(children: [
              Icon(Icons.sort_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                ref.watch(reviewSortProvider) == ReviewSort.newest
                    ? 'En yeni'
                    : 'En beğenilen',
                style: AppTextStyles.labelMedium,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(PlaceModel place) {
    final reviewsAsync = ref.watch(sortedReviewsProvider(
      SortedReviewsParams(targetId: place.id, type: ReviewType.place),
    ));
    return reviewsAsync.when(
      loading: () => const SliverToBoxAdapter(child: ShimmerList(itemCount: 2)),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Yorumlar yüklenemedi: $e'),
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: EmptyStateWidget(
                icon: Icons.rate_review_outlined,
                title: 'Henüz yorum yok',
                description: 'İlk yorum yapan siz olun!',
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ReviewCard(review: reviews[i]),
            childCount: reviews.length,
          ),
        );
      },
    );
  }
}
