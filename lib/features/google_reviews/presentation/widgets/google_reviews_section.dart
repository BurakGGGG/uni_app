import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../university/domain/models/university_model.dart';
import '../../domain/models/google_reviews_result.dart';
import '../providers/google_reviews_providers.dart';

/// Üniversite detayında kapalı gelen "Google Yorumları" bölümü.
///
/// CF çağrısı yalnızca kullanıcı bölümü açınca yapılır (kota koruması).
/// Places politikası: veri saklanmaz, atıflar (yazar adı/foto/profil linki +
/// Google) eksiksiz gösterilir. Kota/hata durumunda bölüm sessizce gizlenir.
class GoogleReviewsSection extends ConsumerStatefulWidget {
  final UniversityModel uni;
  const GoogleReviewsSection({super.key, required this.uni});

  @override
  ConsumerState<GoogleReviewsSection> createState() =>
      _GoogleReviewsSectionState();
}

class _GoogleReviewsSectionState extends ConsumerState<GoogleReviewsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final disabled = ref.watch(googleReviewsDisabledProvider);

    if (widget.uni.googlePlaceId == null || disabled) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLightFor(context)),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/google_logo.svg',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.googleReviewsTitle,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.googleReviewsTileSubtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) _ExpandedContent(uni: widget.uni),
          ],
        ),
      ),
    );
  }
}

class _ExpandedContent extends ConsumerWidget {
  final UniversityModel uni;
  const _ExpandedContent({required this.uni});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final resultAsync = ref.watch(googleReviewsProvider(uni.id));

    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      // Hata: sessiz gizlenme — kota durumunda disabled provider zaten
      // servis katmanında set edildi, tüm bölüm bir sonraki frame'de kaybolur.
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        if (!result.hasContent) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, color: AppColors.borderLightFor(context)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 20, color: AppColors.ratingStar),
                  const SizedBox(width: 4),
                  Text(
                    result.rating.toStringAsFixed(1),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.googleReviewsCount(result.userRatingCount),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...result.reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GoogleReviewCard(review: review),
                ),
              ),
              // Places politikası gereği zorunlu atıf.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/google_logo.svg',
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.googleReviewsAttribution,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoogleReviewCard extends StatefulWidget {
  final GoogleReview review;
  const _GoogleReviewCard({required this.review});

  @override
  State<_GoogleReviewCard> createState() => _GoogleReviewCardState();
}

class _GoogleReviewCardState extends State<_GoogleReviewCard> {
  bool _showFull = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final photoUri = review.authorPhotoUri;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Yazar foto/ad/link: Places atıf zorunluluğu.
              GestureDetector(
                onTap: () => _openAuthorProfile(review.authorUri),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  // NetworkImage bilinçli: disk cache'e yazan
                  // CachedNetworkImage yerine yalnızca bellek — Places
                  // içeriği cihazda kalıcı olmasın.
                  foregroundImage:
                      photoUri != null ? NetworkImage(photoUri) : null,
                  onForegroundImageError:
                      photoUri != null ? (_, _) {} : null,
                  child: const Icon(Icons.person_rounded,
                      size: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openAuthorProfile(review.authorUri),
                      child: Text(
                        review.authorName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StarRow(rating: review.rating),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            review.relativeTime,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryFor(context),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showFull = !_showFull),
              child: Text(
                review.text,
                style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                maxLines: _showFull ? null : 4,
                overflow: _showFull ? null : TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAuthorProfile(String? uri) async {
    if (uri == null || uri.isEmpty) return;
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return;
    await launchUrl(parsed, mode: LaunchMode.externalApplication);
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 0.75;
        final half = !filled && rating >= i + 0.25;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: 13,
          color: AppColors.ratingStar,
        );
      }),
    );
  }
}
