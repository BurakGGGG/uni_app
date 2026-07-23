import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../../../../router/app_router.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../domain/robot_mood.dart';
import '../../domain/robot_scripts.dart';
import '../../domain/tercih_calendar.dart';
import '../providers/uni_panel_providers.dart';
import '../widgets/robot_avatar.dart';
import '../widgets/uni_insight_card.dart';
import '../widgets/uni_setup_path.dart';

/// Üni Paneli — robotun kendi evi.
///
/// Üni uzun süre "kapı"ydı: her yüzeyde misafir, hiçbirinde ev sahibi. Puan
/// hesaplama v2 kapıların hepsini başka yerden açınca elinde iş kalmadı. Bu
/// ekran o işi geri veriyor: uygulamadaki tüm veriyi tek yerde okuyup
/// "senin için ne anlama geliyor" diyen tek yüzey.
class UniPanelScreen extends ConsumerStatefulWidget {
  const UniPanelScreen({super.key});

  @override
  ConsumerState<UniPanelScreen> createState() => _UniPanelScreenState();
}

class _UniPanelScreenState extends ConsumerState<UniPanelScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackEvent(AnalyticsEvent.uniPanelOpened);
  }

  @override
  Widget build(BuildContext context) {
    final contextAsync = ref.watch(insightContextProvider);
    final insights = ref.watch(uniInsightsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundFor(context),
        elevation: 0,
        title: Row(
          children: [
            // Ekranın tek animasyonlu avatarı; kartlardakiler statik.
            const RobotAvatar(size: 32, mood: RobotMood.happy),
            const SizedBox(width: 10),
            Text(RobotScripts.isEn ? 'Üni · Your coach' : 'Üni · Koçun'),
          ],
        ),
      ),
      body: contextAsync.when(
        loading: () => const BrandLoader(),
        error: (_, _) => _Error(
          onRetry: () => ref.invalidate(insightContextProvider),
        ),
        data: (_) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(insightContextProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                phaseChipLabel(tercihPhaseFor(now), now.year),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              const UniSetupPath(),
              const SizedBox(height: 16),

              // ─── Üni'nin Notları ────────────────────────────
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    RobotScripts.isEn ? "Üni's notes" : "Üni'nin Notları",
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (insights.isEmpty)
                _AllClear()
              else
                for (final insight in insights)
                  UniInsightCard(insight: insight),

              const SizedBox(height: 24),
              _MatchesEntry(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hiç not kalmadığında — her şey yolunda ya da hepsi susturulmuş.
class _AllClear extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          const RobotAvatar(
              size: 32, mood: RobotMood.happy, animated: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              RobotScripts.isEn
                  ? "Nothing needs your attention right now. I'll speak up "
                      'when something changes.'
                  : 'Şu an dikkat isteyen bir şey yok. Bir şey değişirse '
                      'sana ben söylerim.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panelin altındaki tek çıkış: puanına göre program önerileri.
class _MatchesEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => context.push(AppRoutes.preferenceWizardResults),
        icon: const Icon(Icons.school_rounded, size: 18),
        label: Text(
          RobotScripts.isEn
              ? 'Programs that match your score'
              : 'Puanına göre öneriler',
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final VoidCallback onRetry;
  const _Error({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RobotAvatar(size: 64, mood: RobotMood.concerned),
          const SizedBox(height: 14),
          Text(
            RobotScripts.isEn
                ? "I couldn't read your data."
                : 'Verilerini okuyamadım.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(RobotScripts.isEn ? 'Try again' : 'Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
