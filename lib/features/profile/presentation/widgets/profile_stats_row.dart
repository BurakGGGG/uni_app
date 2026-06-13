import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/user_model.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';

/// Profil sayfasındaki istatistik kartları satırı.
/// Yorum sayısı, favori sayısı ve üyelik süresi gösterir.
class ProfileStatsRow extends ConsumerWidget {
  final UserModel? profile;

  const ProfileStatsRow({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final favoritesCount = ref.watch(favoritesProvider).value?.length ?? 0;
    final memberDays = DateTime.now()
        .difference(profile?.createdAt ?? DateTime.now())
        .inDays;

    return Row(
      children: [
        _StatCard(
          icon: Icons.rate_review_rounded,
          label: loc.profileStatReview,
          value: '${profile?.reviewCount ?? 0}',
          color: AppColors.primary,
          onTap: () => context.push('/my-reviews'),
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.favorite_rounded,
          label: loc.profileStatFavorite,
          value: '$favoritesCount',
          color: AppColors.error,
          onTap: () => context.push('/favorites'),
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.cake_rounded,
          label: loc.profileStatMembership,
          value: loc.profileStatDays(memberDays),
          color: AppColors.warning,
        ),
      ],
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(value, style: AppTextStyles.titleLarge),
                Text(label, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
