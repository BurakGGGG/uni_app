import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../university/domain/models/university_model.dart';
import '../../domain/models/review_model.dart';
import '../utils/review_submission_guard.dart';

/// "Deneyimini paylaş" bottom sheet'i — ReviewPromptService tarafından
/// doğru anda gösterilir. CTA mevcut yorum yazma akışına (guard dahil) gider.
class ReviewPromptSheet extends ConsumerWidget {
  final UniversityModel uni;
  final bool isOwnUniversity;
  final Future<void> Function() onNeverAgain;

  const ReviewPromptSheet({
    super.key,
    required this.uni,
    required this.isOwnUniversity,
    required this.onNeverAgain,
  });

  static Future<void> show(
    BuildContext context, {
    required UniversityModel uni,
    required bool isOwnUniversity,
    required Future<void> Function() onNeverAgain,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReviewPromptSheet(
        uni: uni,
        isOwnUniversity: isOwnUniversity,
        onNeverAgain: onNeverAgain,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      AppColors.textTertiaryFor(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isOwnUniversity
                    ? loc.reviewPromptTitleOwn
                    : loc.reviewPromptTitleOther,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isOwnUniversity
                    ? loc.reviewPromptBodyOwn(uni.name)
                    : loc.reviewPromptBodyOther(uni.name),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openWriteReviewIfAllowed(
                      context: context,
                      ref: ref,
                      type: ReviewType.university,
                      targetId: uni.id,
                      universityId: uni.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(loc.reviewPromptCta),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  loc.reviewPromptLater,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await onNeverAgain();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(
                  loc.reviewPromptNever,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
