import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

import '../providers/score_calculator_providers.dart';
import '../widgets/department_picker_sheet.dart';
import '../widgets/obp_section.dart';
import '../widgets/rank_input_section.dart';
import '../widgets/subject_net_input.dart';
import '../widgets/subject_score_input.dart';
import '../../domain/models/score_input.dart';
import '../../domain/models/yks_subject.dart';
import '../../domain/score_calculator_engine.dart';

/// Puan hesaplama girişi v2: netleri bir kez gir, uygulanabilir tüm puan
/// türleri (TYT/SAY/EA/SÖZ/DİL) birden hesaplanır. Bölüm seçimi opsiyonel,
/// yıl seçimi sonuç ekranındaki karşılaştırmaya taşındı.
class ScoreCalculatorScreen extends ConsumerStatefulWidget {
  const ScoreCalculatorScreen({super.key});

  @override
  ConsumerState<ScoreCalculatorScreen> createState() =>
      _ScoreCalculatorScreenState();
}

class _ScoreCalculatorScreenState extends ConsumerState<ScoreCalculatorScreen> {
  late final TextEditingController _obpController;
  late final TextEditingController _rankController;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(scoreInputProvider);
    final obp = saved.obpScore;
    _rankController = TextEditingController(
        text: saved.enteredRank == null ? '' : '${saved.enteredRank}');
    _obpController =
        TextEditingController(text: obp == 0 ? '80' : _trimZero(obp));
    // Controller ile state'i eşitle (ilk açılışta default 80).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final input = ref.read(scoreInputProvider);
      final parsed = double.tryParse(_obpController.text) ?? 80;
      if (input.obpScore != parsed) {
        _update(input.copyWith(obpScore: parsed));
      }
    });
  }

  static String _trimZero(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _obpController.dispose();
    _rankController.dispose();
    super.dispose();
  }

  void _update(ScoreInput newInput) {
    ref.read(scoreInputProvider.notifier).state = newInput;
  }

  void _calculate() {
    context.push('/score-result');
  }

  Future<void> _switchMode(NetEntryMode mode) async {
    final input = ref.read(scoreInputProvider);
    if (mode == input.entryMode) return;

    // Sıra moduna geçiş: netler saklanır (geri dönülebilsin), yalnız mod
    // değişir. Puan türü çipten seçilir, burada dokunulmaz.
    if (mode == NetEntryMode.rank) {
      _update(input.copyWith(entryMode: mode));
      return;
    }

    // Sıra modundan çıkış: girilen sıra netlere çevrilemez, temizlenir.
    if (input.isRankMode) {
      if (input.enteredRank != null) {
        final confirmed = await _confirmDiscard(
          title: 'Net girişine dön',
          message: 'Girdiğin başarı sırası netlere çevrilemez ve silinecek. '
              'Önceki net girişlerin geri gelir. Devam edilsin mi?',
        );
        if (confirmed != true) return;
      }
      _rankController.clear();
      _update(ref
          .read(scoreInputProvider)
          .copyWith(entryMode: mode, scoreType: '', clearRank: true));
      return;
    }

    if (mode == NetEntryMode.directNet) {
      // Doğru/yanlıştan hesaplanan netler direkt alanlara taşınır.
      final nets = <YksSubject, double>{
        for (final s in YksSubject.values)
          if (input.netOf(s) > 0) s: input.netOf(s),
      };
      _update(input.copyWith(entryMode: mode, directNets: nets));
      return;
    }

    // Net → doğru/yanlış: net modundaki değerler geri dönüştürülemez.
    if (input.directNets.isNotEmpty) {
      final confirmed = await _confirmDiscard(
        title: 'Doğru/yanlış moduna dön',
        message: 'Net modunda girdiğin değerler doğru/yanlış sayısına '
            'çevrilemez; önceki doğru/yanlış girişlerin geri gelir. '
            'Devam edilsin mi?',
      );
      if (confirmed != true) return;
    }
    _update(ref
        .read(scoreInputProvider)
        .copyWith(entryMode: mode, directNets: const {}));
  }

  Future<bool?> _confirmDiscard({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  Widget _subjectRow(ScoreInput input, YksSubject subject) {
    if (input.entryMode == NetEntryMode.directNet) {
      return SubjectNetInput(
        key: ValueKey('net_${subject.name}'),
        title: subject.labelTr,
        maxQuestions: subject.maxQuestions,
        value: input.directNets[subject] ?? 0,
        onChanged: (v) =>
            _update(ref.read(scoreInputProvider).withDirectNet(subject, v)),
      );
    }
    return SubjectScoreInput(
      key: ValueKey('dy_${subject.name}'),
      title: subject.labelTr,
      maxQuestions: subject.maxQuestions,
      correct: input.correctOf(subject),
      wrong: input.wrongOf(subject),
      onCorrectChanged: (v) =>
          _update(ref.read(scoreInputProvider).withCorrect(subject, v)),
      onWrongChanged: (v) =>
          _update(ref.read(scoreInputProvider).withWrong(subject, v)),
    );
  }

  bool _sectionHasNets(ScoreInput input, List<YksSubject> subjects) =>
      subjects.any((s) => input.netOf(s) != 0);

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(scoreInputProvider);
    final applicableTypes = ScoreCalculatorEngine.applicableScoreTypes(input);

    final aytSubjects = [
      ...YksSubject.bySection(YksSection.aytSay),
      ...YksSubject.bySection(YksSection.aytEaSoz),
      ...YksSubject.bySection(YksSection.aytSoz2),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: CustomScrollView(
        slivers: [
          // ─── Gradient Header ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Puan Hesapla',
                style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.calculate_rounded,
                          size: 160,
                          color: Colors.white.withValues(alpha: 0.07)),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              tooltip: 'Geri',
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Deneme geçmişi',
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                onPressed: () => context.push('/score-calculator/history'),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Giriş modu ─────────────────────────────────
                Center(
                  child: SegmentedButton<NetEntryMode>(
                    segments: const [
                      ButtonSegment(
                        value: NetEntryMode.correctWrong,
                        label: Text('Doğru / Yanlış'),
                        icon: Icon(Icons.rule_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: NetEntryMode.directNet,
                        label: Text('Net Gir'),
                        icon: Icon(Icons.speed_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: NetEntryMode.rank,
                        label: Text('Sıralama'),
                        icon: Icon(Icons.leaderboard_rounded, size: 18),
                      ),
                    ],
                    selected: {input.entryMode},
                    onSelectionChanged: (selection) =>
                        _switchMode(selection.first),
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Sıra modu: netlerin ve OBP'nin yerini alır ──
                if (input.isRankMode) ...[
                  _SectionCard(
                    icon: Icons.leaderboard_rounded,
                    iconColor: AppColors.primary,
                    title: 'Başarı Sıralaman',
                    child: RankInputSection(
                      controller: _rankController,
                      input: input,
                      // Tür değişince seçili hedef bölüm artık o türde
                      // olmayabilir — sessizce tutmak yanıltıcı olurdu.
                      onScoreTypeChanged: (type) => _update(ref
                          .read(scoreInputProvider)
                          .copyWith(scoreType: type, selectedDepartment: '')),
                      onRankChanged: (rank) => _update(rank == null
                          ? ref
                              .read(scoreInputProvider)
                              .copyWith(clearRank: true)
                          : ref
                              .read(scoreInputProvider)
                              .copyWith(enteredRank: rank)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Netler + OBP (sıra modunda gizli) ──────────
                if (!input.isRankMode) ...[
                  // ─── TYT (herkes girer, hep açık) ─────────────
                  _buildSectionHeader('TYT Testleri'),
                  Text(
                    'Puan hesaplanması için Türkçe veya Temel Matematik '
                    'netin en az 0.5 olmalı.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryFor(context)),
                  ),
                  const SizedBox(height: 12),
                  for (final s in YksSubject.bySection(YksSection.tyt))
                    _subjectRow(input, s),

                  // ─── AYT (açılır) ───────────────────────────────
                  _CollapsibleSection(
                    title: 'AYT Testleri',
                    subtitle: 'SAY, EA ve SÖZ puanları için',
                    icon: Icons.science_rounded,
                    initiallyExpanded: _sectionHasNets(input, aytSubjects),
                    children: [
                      _buildGroupHeader(context, 'Sayısal'),
                      for (final s in YksSubject.bySection(YksSection.aytSay))
                        _subjectRow(input, s),
                      _buildGroupHeader(context, 'Sözel-1 / Eşit Ağırlık'),
                      for (final s in YksSubject.bySection(YksSection.aytEaSoz))
                        _subjectRow(input, s),
                      _buildGroupHeader(context, 'Sözel-2'),
                      for (final s in YksSubject.bySection(YksSection.aytSoz2))
                        _subjectRow(input, s),
                    ],
                  ),

                  // ─── YDT (açılır) ───────────────────────────────
                  _CollapsibleSection(
                    title: 'YDT (Yabancı Dil)',
                    subtitle: 'DİL puanı için',
                    icon: Icons.language_rounded,
                    initiallyExpanded: _sectionHasNets(
                        input, YksSubject.bySection(YksSection.ydt)),
                    children: [
                      for (final s in YksSubject.bySection(YksSection.ydt))
                        _subjectRow(input, s),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── OBP ────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: AppColors.gold,
                    title: 'Diploma Notu (OBP)',
                    child: ObpSection(
                      controller: _obpController,
                      input: input,
                      onObpChanged: (v) => _update(
                          ref.read(scoreInputProvider).copyWith(obpScore: v)),
                      onPlacedLastYearChanged: (v) => _update(ref
                          .read(scoreInputProvider)
                          .copyWith(placedLastYear: v)),
                      onMeslekOwnFieldChanged: (v) => _update(ref
                          .read(scoreInputProvider)
                          .copyWith(meslekOwnField: v)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Hedef bölüm (opsiyonel) ────────────────────
                _SectionCard(
                  icon: Icons.school_rounded,
                  iconColor: AppColors.primary,
                  title: 'Hedef Bölüm (opsiyonel)',
                  child: _TargetDepartmentTile(
                    selected: input.selectedDepartment,
                    onPick: () async {
                      // Sıra modunda tür belli: yalnız o türün bölümleri.
                      final dept = await DepartmentPickerSheet.show(
                        context,
                        scoreType: input.isRankMode ? input.scoreType : '',
                      );
                      if (dept != null) {
                        _update(ref
                            .read(scoreInputProvider)
                            .copyWith(selectedDepartment: dept));
                      }
                    },
                    onClear: () => _update(ref
                        .read(scoreInputProvider)
                        .copyWith(selectedDepartment: '')),
                  ),
                ),

                // Hesaplanacak türlerin önizlemesi. Sıra modunda türü zaten
                // kullanıcı seçiyor — aynı bilgiyi tekrar basmak gereksiz.
                if (!input.isRankMode && applicableTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in applicableTypes)
                        Chip(
                          avatar: const Icon(Icons.check_rounded,
                              size: 16, color: AppColors.primary),
                          label: Text(type,
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          side: BorderSide(
                              color:
                                  AppColors.primary.withValues(alpha: 0.25)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (applicableTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    input.isRankMode
                        ? 'Hesaplama için puan türünü seç ve sıranı gir'
                        : 'Hesaplama için TYT Türkçe veya Temel Matematik '
                            'neti gir',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryFor(context)),
                    textAlign: TextAlign.center,
                  ),
                ),
              GradientButton(
                text: applicableTypes.isEmpty
                    ? 'Hesapla'
                    : 'Hesapla (${applicableTypes.join(" · ")})',
                icon: Icons.calculate_rounded,
                onPressed: applicableTypes.isEmpty ? null : _calculate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSecondaryFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Hedef bölüm tile ───────────────────────────────────────────

class _TargetDepartmentTile extends StatelessWidget {
  final String selected;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _TargetDepartmentTile({
    required this.selected,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hasSelection = selected.isNotEmpty;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelection
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.borderLightFor(context),
            width: hasSelection ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasSelection ? Icons.check_circle_rounded : Icons.search_rounded,
              color: hasSelection
                  ? AppColors.primary
                  : AppColors.textTertiaryFor(context),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSelection
                    ? selected
                    : 'Hedefindeki bölümü seç, sonuçta öne çıkaralım…',
                style: hasSelection
                    ? AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)
                    : AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textTertiaryFor(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasSelection)
              IconButton(
                tooltip: 'Kaldır',
                icon: Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textTertiaryFor(context)),
                onPressed: onClear,
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiaryFor(context)),
          ],
        ),
      ),
    );
  }
}

// ─── Açılır bölüm ───────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.initiallyExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      // ListTile mürekkep efektleri için dekorun üstünde şeffaf Material.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
            title: Text(title,
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondaryFor(context))),
            children: children,
          ),
        ),
      ),
    );
  }
}

// ─── Section Card ───────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
