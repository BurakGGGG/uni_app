import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../../../../router/app_router.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../domain/insights/insight_context.dart';
import '../../domain/insights/insight_engine.dart';
import '../../domain/robot_mood.dart';
import '../../domain/robot_scripts.dart';
import '../../domain/tercih_calendar.dart';
import '../providers/uni_panel_providers.dart';
import '../widgets/robot_avatar.dart';
import '../widgets/uni_insight_card.dart';
import '../widgets/uni_path_step.dart';

/// Tercih listesinin dolu sayılması için gereken tercih sayısı — ÖSYM'nin
/// verdiği hak.
const int _kListCapacity = 24;

/// Üni Paneli — tercih yolunun tek yüzeyi.
///
/// Panel bir dönem "koç paneli"ydi: hedefe kaç net, hangi ders düşüşte, bu
/// haftanın planı. Hepsi doğru bilgiydi ama hepsi Denemelerim'in işiydi ve
/// tercih yapmak isteyen öğrenci kendi işini ekranın en altındaki küçük bir
/// butonda arıyordu. Şimdi ekran tek bir soruyu yanıtlıyor: **tercih
/// listemi kurmak için sırada ne var?**
///
/// Dört adım, sabit sıra, her adımda tek eylem. Dolu buton yalnız ilk
/// tamamlanmamış adımda — ekranda her zaman tek bir "şimdi bunu yap" vardır.
class UniPanelScreen extends ConsumerStatefulWidget {
  /// "Tercih yolunu baştan geç" — kapı ([UniHomeGate]) akışı yeniden açar.
  /// Panel doğrudan bir rota olarak açıldığında (test, derin bağlantı) null
  /// gelir ve düğme çizilmez.
  final VoidCallback? onRestartFlow;

  const UniPanelScreen({super.key, this.onRestartFlow});

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
    final now = DateTime.now();
    final en = RobotScripts.isEn;

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
            Text(en ? 'Üni · Your path' : 'Üni · Tercih Yolun'),
          ],
        ),
      ),
      body: contextAsync.when(
        loading: () => const BrandLoader(),
        error: (_, _) => _Error(
          onRetry: () => ref.invalidate(insightContextProvider),
        ),
        data: (ctx) => RefreshIndicator(
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
              ..._steps(ctx),
              if (widget.onRestartFlow != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: widget.onRestartFlow,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    en ? 'Walk the path again' : 'Tercih yolunu baştan geç',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _steps(InsightContext ctx) {
    final en = RobotScripts.isEn;
    final main = ref.watch(mainListProvider);
    final listCount = main?.itemCount ?? 0;

    // Sıradaki iş: ilk tamamlanmamış adım. Puan yoksa 1, liste boşsa 2,
    // liste yarımsa 3; yol tamsa (0) hiçbir adım dolu buton taşımaz.
    final int primaryStep;
    if (!ctx.hasProfile) {
      primaryStep = 1;
    } else if (listCount == 0) {
      primaryStep = 2;
    } else if (listCount < _kListCapacity) {
      primaryStep = 3;
    } else {
      primaryStep = 0; // yol tamam — hiçbir adım dolu buton taşımaz
    }

    return [
      // ── 1 · Puanın ──────────────────────────────────────────────
      UniPathStep(
        number: 1,
        title: en ? 'Your score' : 'Puanın',
        done: ctx.hasProfile,
        primary: primaryStep == 1,
        body: ctx.hasProfile ? _ScoreLine(ctx: ctx) : null,
        actionLabel: ctx.hasProfile
            ? (en ? 'Edit' : 'Düzenle')
            : (en ? 'Calculate my score' : 'Puanımı hesapla'),
        route: AppRoutes.scoreCalculator,
      ),

      // ── 2 · Sana uyan programlar ────────────────────────────────
      UniPathStep(
        number: 2,
        title: en ? 'Programs that suit you' : 'Sana uyan programlar',
        locked: !ctx.hasProfile,
        lockedHint: en
            ? 'Once I know your score I can list the programs within reach.'
            : 'Puanını bilince erişebileceğin programları çıkarabilirim.',
        primary: primaryStep == 2,
        body: ctx.hasProfile ? const _MatchLine() : null,
        actionLabel: en ? 'See my matches' : 'Önerileri gör',
        route: AppRoutes.preferenceWizardResults,
        secondaryLabel:
            en ? 'Tell me what you want' : 'Tercihlerini söyle',
        secondaryRoute: AppRoutes.preferenceWizard,
      ),

      // ── 3 · Tercih listen ───────────────────────────────────────
      UniPathStep(
        number: 3,
        title: en ? 'Your preference list' : 'Tercih listen',
        done: listCount >= _kListCapacity,
        primary: primaryStep == 3,
        body: main == null || listCount == 0
            ? Text(
                en
                    ? "You don't have a preference list yet."
                    : 'Henüz tercih listen yok.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              )
            : _ListLine(snapshot: main),
        actionLabel: listCount == 0
            ? (en ? 'Create a list' : 'Liste oluştur')
            : (en ? 'Open my list' : 'Listeyi aç'),
        route: AppRoutes.myLists,
      ),

      // ── 4 · Listenin sağlığı ────────────────────────────────────
      _HealthStep(hasList: listCount > 0),
    ];
  }
}

/// 1. adımın gövdesi: `SAY 421,6 · ≈85.600. sıra`.
class _ScoreLine extends StatelessWidget {
  final InsightContext ctx;
  const _ScoreLine({required this.ctx});

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    final profile = ctx.profile!;
    final parts = <String>[];

    if (profile.hasScore) {
      final score = profile.placementScore.toStringAsFixed(1);
      parts.add(
        '${profile.scoreType} ${en ? score : score.replaceAll('.', ',')}',
      );
    } else {
      parts.add(profile.scoreType);
    }

    final rank = ctx.displayRank;
    if (rank != null) {
      final formatted = InsightEngine.formatRank(rank);
      final prefix = ctx.rankIsEstimated ? '≈' : '';
      parts.add(en ? 'rank $prefix$formatted' : '$prefix$formatted. sıra');
    }

    return Text(
      parts.join(' · '),
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

/// 2. adımın gövdesi: puana uyan program sayısı.
///
/// Sayı [preferenceMatchResultProvider]'dan gelir — sonuç ekranının motoru.
/// Çözülene kadar satır çizilmez; buton zaten çalışıyor, sayı beklemeye
/// değmez.
class _MatchLine extends ConsumerWidget {
  const _MatchLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(preferenceMatchResultProvider).valueOrNull;
    if (result == null || result.total == 0) return const SizedBox.shrink();
    final en = RobotScripts.isEn;

    return Text(
      en
          ? '${result.total} programs within reach · '
              '${result.guaranteed.length} high-chance'
          : 'Puanınla ${result.total} program · '
              '${result.guaranteed.length} yüksek şanslı',
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondaryFor(context),
      ),
    );
  }
}

/// 3. adımın gövdesi: doluluk çubuğu + kategori dağılımı.
class _ListLine extends StatelessWidget {
  final ListSnapshot snapshot;
  const _ListLine({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    final count = snapshot.itemCount;
    final ratio = (count / _kListCapacity).clamp(0.0, 1.0);

    final breakdown = <String>[
      if (snapshot.guaranteed > 0)
        en
            ? '${snapshot.guaranteed} high-chance'
            : '${snapshot.guaranteed} güvenli',
      if (snapshot.target > 0)
        en ? '${snapshot.target} reachable' : '${snapshot.target} ulaşılabilir',
      if (snapshot.dream > 0)
        en ? '${snapshot.dream} ambitious' : '${snapshot.dream} zorlayıcı',
      if (snapshot.unrated > 0)
        en
            ? '${snapshot.unrated} unrated'
            : '${snapshot.unrated} değerlendirilemedi',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count/$_kListCapacity',
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.borderLightFor(context),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        if (breakdown.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            breakdown.join(' · '),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textTertiaryFor(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// 4. adım: liste ve ÖSYM verisi uyarıları. Kartlar kendi butonlarını
/// taşıdığı için adımın ayrı bir eylemi yok.
class _HealthStep extends ConsumerWidget {
  final bool hasList;
  const _HealthStep({required this.hasList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = RobotScripts.isEn;
    final notes = ref.watch(pathInsightsProvider);

    return UniPathStep(
      number: 4,
      title: en ? "Your list's health" : 'Listenin sağlığı',
      locked: !hasList,
      lockedHint: en
          ? "Once your list is up I'll check it here — safe choices, city "
              'concentration, moving cutoffs.'
          : 'Listen kurulunca burayı ben kontrol ederim — güvenli tercih, '
              'şehir yığılması, oynayan tabanlar.',
      body: !hasList
          ? null
          : notes.isEmpty
              ? const _AllClear()
              : Column(
                  children: [
                    for (final insight in notes)
                      UniInsightCard(insight: insight),
                  ],
                ),
    );
  }
}

/// Liste var, uyarı yok — her şey yolunda ya da hepsi susturulmuş.
class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const RobotAvatar(size: 32, mood: RobotMood.happy, animated: false),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            RobotScripts.isEn
                ? "Your list looks balanced. I'll speak up when something "
                    'changes.'
                : 'Listen dengeli görünüyor. Bir şey değişirse sana ben '
                    'söylerim.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
        ),
      ],
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
