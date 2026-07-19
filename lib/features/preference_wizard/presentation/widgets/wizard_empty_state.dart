import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../domain/models/wizard_filter.dart';
import '../providers/preference_wizard_providers.dart';

/// Sonuç ekranı boş durumu — filtre kaynaklıysa temizleme kısayolu sunar.
class WizardEmptyResults extends ConsumerWidget {
  final bool hasFilter;
  const WizardEmptyResults({super.key, required this.hasFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RobotAvatar(size: 72, mood: RobotMood.concerned),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'Filtrelere uyan program yok' : 'Eşleşen program yok',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? kEmptyResultsFilterText
                  : 'Bu profille eşleşme bulamadım — puan türünü ve puanını '
                      'birlikte kontrol edelim mi?',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(wizardFilterProvider.notifier).state =
                    const WizardFilter(),
                child: const Text('Filtreleri temizle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sonuç ekranı hata durumu — ham exception yerine stilli kart + tekrar dene.
class WizardErrorState extends ConsumerWidget {
  const WizardErrorState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Öneriler yüklenemedi',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Bağlantını kontrol edip tekrar dene.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(preferenceMatchResultProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
