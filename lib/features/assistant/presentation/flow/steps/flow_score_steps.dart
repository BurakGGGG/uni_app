import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../practice_exams/domain/models/practice_exam.dart';
import '../../../../practice_exams/presentation/providers/practice_exam_providers.dart';
import '../../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../../score_calculator/domain/models/multi_score_result.dart';
import '../../../../score_calculator/domain/models/score_input.dart';
import '../../../../score_calculator/domain/models/yks_subject.dart';
import '../../../../score_calculator/domain/score_calculator_engine.dart';
import '../../../../score_calculator/presentation/providers/score_calculator_providers.dart';
import '../../../../score_calculator/presentation/widgets/obp_section.dart';
import '../../../../score_calculator/presentation/widgets/rank_input_section.dart';
import '../../../../score_calculator/presentation/widgets/score_entry_section.dart';
import '../../../../score_calculator/presentation/widgets/score_type_card.dart';
import '../../../../score_calculator/presentation/widgets/subject_net_input.dart';
import '../../../../score_calculator/presentation/widgets/subject_score_input.dart';
import '../../../domain/robot_mood.dart';
import '../../../domain/robot_scripts.dart';
import '../uni_flow_step_spec.dart';

// ═══════════════════════════════════════════════════════════════
//  Puanın kurulduğu adımlar
//
//  Hepsi puan hesaplayıcının KENDİ widget'larını kullanır; katsayı, mod ve
//  doğrulama mantığı tek yerde (score_calculator) kalır. Buradaki tek iş
//  onları "ekranda tek soru" düzenine yerleştirmek.
// ═══════════════════════════════════════════════════════════════

void _update(WidgetRef ref, ScoreInput next) =>
    ref.read(scoreInputProvider.notifier).state = next;

/// ① Nasıl başlayalım?
UniFlowStepSpec startStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final input = ref.watch(scoreInputProvider);
  final lastExam = _lastExam(ref);

  return UniFlowStepSpec(
    title: en ? 'How should we start?' : 'Nasıl başlayalım?',
    subtitle: en
        ? 'I need your score to find the programs within your reach.'
        : 'Erişebileceğin programları çıkarmam için puanın gerek.',
    mood: RobotMood.happy,
    body: [
      if (lastExam != null)
        _PathCard(
          icon: Icons.history_rounded,
          title: en ? 'Use my last mock exam' : 'Son denememi kullan',
          subtitle: '${lastExam.name} · '
              '${lastExam.takenAt.day}.${lastExam.takenAt.month}',
          selected: false,
          // Deneme defterindeki netler olduğu gibi yüklenir; öğrenci aynı
          // sayıları ikinci kez girmesin.
          onTap: () => _update(ref, lastExam.input),
        ),
      _PathCard(
        icon: Icons.edit_note_rounded,
        title: en ? 'Enter my nets' : 'Netlerimi gireyim',
        subtitle: en ? 'TYT and AYT, step by step' : 'TYT ve AYT, adım adım',
        selected: !input.isDirectMode,
        onTap: () => _update(
          ref,
          input.copyWith(entryMode: NetEntryMode.correctWrong),
        ),
      ),
      _PathCard(
        icon: Icons.leaderboard_rounded,
        title: en ? 'I know my rank' : 'Sıralamamı biliyorum',
        subtitle: en
            ? 'The most accurate path'
            : 'En isabetli yol — tahmin devreye girmez',
        selected: input.isRankMode,
        onTap: () =>
            _update(ref, input.copyWith(entryMode: NetEntryMode.rank)),
      ),
      _PathCard(
        icon: Icons.workspace_premium_rounded,
        title: en ? 'I know my score' : 'Puanımı biliyorum',
        subtitle: en
            ? 'Placement score with diploma bonus'
            : 'Diploma notu eklenmiş yerleştirme puanı',
        selected: input.isScoreMode,
        onTap: () =>
            _update(ref, input.copyWith(entryMode: NetEntryMode.score)),
      ),
    ],
  );
}

/// En son çözülen deneme; defter boşsa null.
PracticeExam? _lastExam(WidgetRef ref) {
  final exams = ref.watch(practiceExamsProvider).where((e) => !e.deleted);
  if (exams.isEmpty) return null;
  return exams.reduce((a, b) => b.takenAt.isAfter(a.takenAt) ? b : a);
}

/// ② TYT netlerin
UniFlowStepSpec tytStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final input = ref.watch(scoreInputProvider);

  return UniFlowStepSpec(
    title: en ? 'Your TYT nets' : 'TYT netlerin',
    subtitle: en
        ? 'Everyone takes TYT — leave a test empty if you skipped it.'
        : 'TYT herkesin girdiği oturum; boş bıraktığın testi boş geç.',
    mood: RobotMood.thinking,
    // Motorun kendi kuralı: Türkçe ya da Temel Matematik neti olmadan hiçbir
    // puan türü hesaplanamaz.
    canAdvance: ScoreCalculatorEngine.applicableScoreTypes(input).isNotEmpty,
    body: [
      for (final s in YksSubject.bySection(YksSection.tyt))
        _subjectRow(ref, input, s),
    ],
  );
}

/// ③ AYT netlerin
UniFlowStepSpec aytStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final input = ref.watch(scoreInputProvider);

  return UniFlowStepSpec(
    title: en ? 'Your AYT nets' : 'AYT netlerin',
    subtitle: en
        ? 'Only fill the tests you actually took; the rest stay empty.'
        : 'Yalnız girdiğin testleri doldur, kalanlar boş kalsın.',
    mood: RobotMood.thinking,
    body: [
      _GroupLabel(en ? 'Science' : 'Sayısal'),
      for (final s in YksSubject.bySection(YksSection.aytSay))
        _subjectRow(ref, input, s),
      _GroupLabel(en ? 'Equal weight / verbal' : 'Eşit Ağırlık · Sözel-1'),
      for (final s in YksSubject.bySection(YksSection.aytEaSoz))
        _subjectRow(ref, input, s),
      _GroupLabel(en ? 'Verbal-2' : 'Sözel-2'),
      for (final s in YksSubject.bySection(YksSection.aytSoz2))
        _subjectRow(ref, input, s),
      _GroupLabel(en ? 'Foreign language' : 'Yabancı Dil (YDT)'),
      for (final s in YksSubject.bySection(YksSection.ydt))
        _subjectRow(ref, input, s),
    ],
  );
}

/// ④ Diploma notun
UniFlowStepSpec obpStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  return UniFlowStepSpec(
    title: en ? 'Your diploma grade' : 'Diploma notun',
    subtitle: en
        ? 'It adds up to 60 points on top of your raw score.'
        : 'Ham puanının üstüne 60 puana kadar ekleniyor.',
    mood: RobotMood.thinking,
    body: const [_ObpBody()],
  );
}

/// ④' Sıralaman (net yolunun yerine)
UniFlowStepSpec rankStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final input = ref.watch(scoreInputProvider);
  return UniFlowStepSpec(
    title: en ? 'Your rank' : 'Başarı sıralaman',
    subtitle: en
        ? 'Pick the score type your rank belongs to.'
        : 'Sıranın hangi puan türüne ait olduğunu seç.',
    mood: RobotMood.thinking,
    canAdvance: input.hasValidRank && input.scoreType.isNotEmpty,
    body: const [_RankBody()],
  );
}

/// ④'' Puanın (net yolunun yerine)
UniFlowStepSpec scoreStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final input = ref.watch(scoreInputProvider);
  return UniFlowStepSpec(
    title: en ? 'Your placement score' : 'Yerleştirme puanın',
    subtitle: en
        ? 'The score with the diploma bonus already included.'
        : 'Diploma notu eklenmiş hâli — sıranı ben hesaplarım.',
    mood: RobotMood.thinking,
    canAdvance: input.hasValidScore && input.scoreType.isNotEmpty,
    body: const [_ScoreBody()],
  );
}

/// ⑤ İşte puanın — profil BURADA kaydedilir.
UniFlowStepSpec revealStepSpec(BuildContext context, WidgetRef ref) {
  final en = RobotScripts.isEn;
  final outcome = ref.watch(multiScoreOutcomeProvider).valueOrNull;
  final best = outcome?.best;
  final selectedType = ref.watch(resultSelectedTypeProvider) ??
      best?.score.scoreType ??
      outcome?.outcomes.first.score.scoreType;
  final selected =
      selectedType == null ? null : outcome?.byType(selectedType);

  return UniFlowStepSpec(
    title: en ? 'Here is your score' : 'İşte puanın',
    subtitle: outcome != null && outcome.outcomes.length > 1
        ? (en
            ? 'Tap a type to continue with it.'
            : 'Hangi türle devam edeceğini seçebilirsin.')
        : null,
    mood: RobotMood.celebrating,
    canAdvance: selected != null,
    ctaLabel: en ? 'Continue' : 'Devam',
    onAdvance: selected == null
        ? null
        : () => ref
            .read(studentScoreProfileProvider.notifier)
            .save(profileFromOutcome(selectedType!, selected)),
    body: outcome == null
        ? const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ]
        : [
            if (selected != null) _ScoreReveal(outcome: selected),
            // Kartlar sayacın sonucunu baştan gösteriyordu — kutlama
            // bitmeden sahneye çıkmasınlar.
            Column(
              children: [
                for (final o in outcome.outcomes)
                  ScoreTypeCard(
                    outcome: o,
                    isBest: outcome.outcomes.length > 1 && o == best,
                    onTap: () => ref
                        .read(resultSelectedTypeProvider.notifier)
                        .state = o.score.scoreType,
                    selected: outcome.outcomes.length > 1 &&
                        o.score.scoreType == selectedType,
                  ),
              ],
            )
                .animate()
                .fadeIn(delay: 850.ms, duration: 320.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
          ],
  );
}

/// ⑤'in ödül anı: puan sıfırdan sayarak yükselir.
///
/// Sonucu bir anda basmak akışın en iyi anını harcıyordu — sayaç öğrenciye
/// sayının "kurulduğunu" hissettiriyor. Tür değişince sayaç sıfırdan değil
/// EKRANDAKİ değerden yeni puana kayar; seçim yapmak kutlamayı baştan
/// başlatmamalı ([TweenAnimationBuilder] `end` değiştiğinde bulunduğu
/// yerden devam eder).
class _ScoreReveal extends StatelessWidget {
  final ScoreTypeOutcome outcome;

  const _ScoreReveal({required this.outcome});

  static const Duration _count = Duration(milliseconds: 1100);

  @override
  Widget build(BuildContext context) {
    final en = RobotScripts.isEn;
    final color = scoreTypeColor(outcome.score.scoreType);
    final rank = outcome.estimatedRank;
    // Kullanıcı sırasını kendi girdiyse tahmin değil, veri.
    final prefix = outcome.rankIsUserEntered ? '' : '~';
    final tail = outcome.percentile == null
        ? ''
        : ' · ${formatPercentile(outcome.percentile!)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              en
                  ? '${outcome.score.scoreType} placement score'
                  : '${outcome.score.scoreType} yerleştirme puanın',
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: outcome.score.placementScore),
            duration: _count,
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => Text(
              value.toStringAsFixed(3),
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 44,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: color,
                // Sayarken rakam genişlikleri eşit olmazsa sayı titriyor.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (rank != null) ...[
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: rank.toDouble()),
              duration: _count,
              curve: Curves.easeOutCubic,
              builder: (_, value, _) {
                final shown = formatRank(value.round());
                return Text(
                  en ? 'Rank $prefix$shown$tail' : '$prefix$shown. sıra$tail',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryFor(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Ortak parçalar ────────────────────────────────────────────

Widget _subjectRow(WidgetRef ref, ScoreInput input, YksSubject subject) {
  if (input.entryMode == NetEntryMode.directNet) {
    return SubjectNetInput(
      key: ValueKey('flow_net_${subject.name}'),
      title: subject.labelTr,
      maxQuestions: subject.maxQuestions,
      value: input.directNets[subject] ?? 0,
      onChanged: (v) =>
          _update(ref, ref.read(scoreInputProvider).withDirectNet(subject, v)),
    );
  }
  return SubjectScoreInput(
    key: ValueKey('flow_dy_${subject.name}'),
    title: subject.labelTr,
    maxQuestions: subject.maxQuestions,
    correct: input.correctOf(subject),
    wrong: input.wrongOf(subject),
    onCorrectChanged: (v) =>
        _update(ref, ref.read(scoreInputProvider).withCorrect(subject, v)),
    onWrongChanged: (v) =>
        _update(ref, ref.read(scoreInputProvider).withWrong(subject, v)),
  );
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Yol seçimi kartı — dokununca seçilir, "Devam" ile ilerlenir.
class _PathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PathCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.borderLightFor(context),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textTertiaryFor(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: selected ? AppColors.primary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// OBP / sıra / puan girişleri kendi controller'ını tutar — kabuk her adım
/// değişiminde yeniden çizildiği için controller'lar gövdenin içinde yaşamalı.
class _ObpBody extends ConsumerStatefulWidget {
  const _ObpBody();

  @override
  ConsumerState<_ObpBody> createState() => _ObpBodyState();
}

class _ObpBodyState extends ConsumerState<_ObpBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final obp = ref.read(scoreInputProvider).obpScore;
    _controller = TextEditingController(
      text: obp == 0 ? '80' : (obp == obp.roundToDouble()
          ? obp.toInt().toString()
          : obp.toString()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(scoreInputProvider);
    return ObpSection(
      controller: _controller,
      input: input,
      onObpChanged: (v) =>
          _update(ref, ref.read(scoreInputProvider).copyWith(obpScore: v)),
      onPlacedLastYearChanged: (v) =>
          _update(ref, ref.read(scoreInputProvider).copyWith(placedLastYear: v)),
      onMeslekOwnFieldChanged: (v) => _update(
          ref, ref.read(scoreInputProvider).copyWith(meslekOwnField: v)),
    );
  }
}

class _RankBody extends ConsumerStatefulWidget {
  const _RankBody();

  @override
  ConsumerState<_RankBody> createState() => _RankBodyState();
}

class _RankBodyState extends ConsumerState<_RankBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final rank = ref.read(scoreInputProvider).enteredRank;
    _controller = TextEditingController(text: rank?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RankInputSection(
      controller: _controller,
      input: ref.watch(scoreInputProvider),
      // Tür değişince seçili hedef bölüm artık o türde olmayabilir.
      onScoreTypeChanged: (type) => _update(
        ref,
        ref
            .read(scoreInputProvider)
            .copyWith(scoreType: type, selectedDepartment: ''),
      ),
      onRankChanged: (rank) => _update(
        ref,
        rank == null
            ? ref.read(scoreInputProvider).copyWith(clearRank: true)
            : ref.read(scoreInputProvider).copyWith(enteredRank: rank),
      ),
      onYearChanged: (year) =>
          _update(ref, ref.read(scoreInputProvider).copyWith(selectedYear: year)),
    );
  }
}

class _ScoreBody extends ConsumerStatefulWidget {
  const _ScoreBody();

  @override
  ConsumerState<_ScoreBody> createState() => _ScoreBodyState();
}

class _ScoreBodyState extends ConsumerState<_ScoreBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final score = ref.read(scoreInputProvider).enteredScore;
    _controller = TextEditingController(
      text: score == null ? '' : score.toString().replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScoreEntrySection(
      controller: _controller,
      input: ref.watch(scoreInputProvider),
      onScoreTypeChanged: (type) => _update(
        ref,
        ref
            .read(scoreInputProvider)
            .copyWith(scoreType: type, selectedDepartment: ''),
      ),
      onScoreChanged: (score) => _update(
        ref,
        score == null
            ? ref.read(scoreInputProvider).copyWith(clearScore: true)
            : ref.read(scoreInputProvider).copyWith(enteredScore: score),
      ),
      onYearChanged: (year) =>
          _update(ref, ref.read(scoreInputProvider).copyWith(selectedYear: year)),
    );
  }
}
