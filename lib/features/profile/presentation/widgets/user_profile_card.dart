import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Giriş yapmış kullanıcının profil kartı.
/// Avatar, isim, email, üniversite bilgisi ve doğrulama durumunu gösterir.
class UserProfileCard extends ConsumerWidget {
  final UserModel? profile;
  final dynamic firebaseUser;

  const UserProfileCard({
    super.key,
    required this.profile,
    required this.firebaseUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final displayName =
        profile?.displayName ?? firebaseUser.displayName ?? loc.profileUser;
    final email = profile?.email ?? firebaseUser.email ?? '';
    final photoUrl = profile?.photoUrl ?? firebaseUser.photoURL;
    final isEdu = email.toLowerCase().endsWith('.edu.tr');
    final isVerified =
        isEdu &&
        ((firebaseUser.emailVerified == true) ||
            (profile?.isVerifiedStudent ?? false));
    final university = profile?.university;
    final department = profile?.department;
    final initials =
        profile?.initials ?? (displayName.isNotEmpty ? displayName[0] : '?');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          width: 64,
                          height: 64,
                          memCacheWidth: 128,
                          memCacheHeight: 128,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              initials,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 2),
                    Text(email, style: AppTextStyles.bodySmall),
                    if (university != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        university,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (department != null) ...[
                      Text(
                        department,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                    ],
                    if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        profile!.bio!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // edu.tr rozeti
          if (isVerified)
            _buildVerifiedBadge(loc)
          else if (email.toLowerCase().endsWith('.edu.tr'))
            _buildPendingVerificationBadge(context, ref, loc),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            loc.profileVerifiedStudent,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationBadge(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              loc.profileVerificationPending,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(authRepositoryProvider)
                  .reloadAndCheckVerification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? loc.profileVerified
                          : loc.profileNotVerified,
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                );
                if (success) {
                  // Firestore'daki güncel isVerifiedStudent değerini okutmak için her iki provider'ı yenile
                  ref.invalidate(currentUserProvider);
                  ref.invalidate(authStateProvider);
                }
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              loc.profileRefresh,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
