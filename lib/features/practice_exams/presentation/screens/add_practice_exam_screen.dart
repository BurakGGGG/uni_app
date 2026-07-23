import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../preference_wizard/domain/rank_estimator.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../score_calculator/domain/models/score_input.dart';
import '../../../score_calculator/domain/models/yks_subject.dart';
import '../../../score_calculator/domain/score_calculator_engine.dart';
import '../../../score_calculator/domain/score_outcome_service.dart';
import '../../../score_calculator/presentation/widgets/obp_section.dart';
import '../../../score_calculator/presentation/widgets/rank_input_section.dart';
import '../../../score_calculator/presentation/widgets/score_entry_section.dart';
import '../../../score_calculator/presentation/widgets/subject_net_input.dart';
import '../../../score_calculator/presentation/widgets/subject_score_input.dart';
import '../../domain/models/practice_exam.dart';
import '../providers/practice_exam_providers.dart';

/// Denemeyi tek ekranda ekleme (ve düzenleme).
///
/// Puan hesaplayıcıya gidip sonucu kaydetmek "hesap yapmak" isteyenin yolu;
/// burası "defterime deneme yazmak" isteyenin yolu. Ad, yayın, tür ve tarih
/// en üstte sorulur, netler/sıra/puan hemen altında girilir — arada sonuç
/// ekranı yok.
///
/// Deneme türü aynı zamanda **kapsamı** belirler: TYT seçiliyse yalnız TYT
/// dersleri açılır ve kapsam dışı dersler kayda hiç girmez ([_scopedInput]).
class AddPracticeExamScreen extends ConsumerStatefulWidget {
  /// Doluysa düzenleme modu — kayıt yenisiyle değiştirilir.
  final PracticeExam? existing;

  const AddPracticeExamScreen({super.key, this.existing});

  @override
  ConsumerState<AddPracticeExamScreen> createState() =>
      _AddPracticeExamScreenState();
}

class _AddPracticeExamScreenState extends ConsumerState<AddPracticeExamScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _publisherController;
  late final TextEditingController _obpController;
  late final TextEditingController _rankController;
  late final TextEditingController _scoreController;

  late ScoreInput _input;
  late PracticeExamKind _kind;
  late DateTime _takenAt;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final saved = existing?.input ?? const ScoreInput();

    _input = saved.obpScore == 0 ? saved.copyWith(obpScore: 80) : saved;
    _kind = existing?.kind ?? PracticeExamKind.tyt;
    _takenAt = existing?.takenAt ?? DateTime.now();

    _nameController = TextEditingController(
      text: existing?.name ?? 'Deneme ${ref.read(practiceExamsProvider).length + 1}',
    );
    _publisherController =
        TextEditingController(text: existing?.publisher ?? '');
    _obpController = TextEditingController(text: _trimZero(_input.obpScore));
    _rankController = TextEditingController(
        text: _input.enteredRank == null ? '' : '${_input.enteredRank}');
    _scoreController = TextEditingController(
        text: _input.enteredScore == null
            ? ''
            : _trimZero(_input.enteredScore!).replaceAll('.', ','));
  }

  static String _trimZero(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _publisherController.dispose();
    _obpController.dispose();
    _rankController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _update(ScoreInput next) => setState(() => _input = next);

  /// Kayda giren girdi: deneme türünün kapsamı dışındaki dersler sıfırlanır.
  ///
  /// Kullanıcı Genel'de AYT netlerini girip sonra TYT'ye dönerse o netler
  /// ekranda görünmez; görünmeyen bir netin puanı beslemesi yanlış olurdu.
  ScoreInput get _scopedInput {
    if (_input.isDirectMode) return _input;
    final allowed = _kind.subjects.toSet();
    var scoped = _input;
    for (final subject in YksSubject.values) {
      if (allowed.contains(subject)) continue;
      scoped = scoped
          .withCorrect(subject, 0)
          .withWrong(subject, 0)
          .withDirectNet(subject, 0);
    }
    return scoped;
  }

  /// Deneme türüne göre açılacak ders blokları.
  List<(String, List<YksSubject>)> get _subjectGroups {
    switch (_kind) {
      case PracticeExamKind.tyt:
        return [('TYT Testleri', YksSubject.bySection(YksSection.tyt))];
      case PracticeExamKind.ayt:
        return [
          ('Sayısal', YksSubject.bySection(YksSection.aytSay)),
          ('Sözel-1 / Eşit Ağırlık',
              YksSubject.bySection(YksSection.aytEaSoz)),
          ('Sözel-2', YksSubject.bySection(YksSection.aytSoz2)),
        ];
      case PracticeExamKind.ydt:
        return [('Yabancı Dil', YksSubject.bySection(YksSection.ydt))];
      case PracticeExamKind.genel:
        return [
          ('TYT Testleri', YksSubject.bySection(YksSection.tyt)),
          ('AYT — Sayısal', YksSubject.bySection(YksSection.aytSay)),
          ('AYT — Sözel-1 / Eşit Ağırlık',
              YksSubject.bySection(YksSection.aytEaSoz)),
          ('AYT — Sözel-2', YksSubject.bySection(YksSection.aytSoz2)),
          ('Yabancı Dil', YksSubject.bySection(YksSection.ydt)),
        ];
    }
  }

  /// TYT neti olmayan denemelerde puan/sıra hesaplanamaz (ÖSYM kuralı:
  /// Türkçe veya Temel Matematik'ten en az 0,5 net). Netler yine de kaydedilir.
  bool get _scoreImpossible =>
      !_input.isDirectMode &&
      (_kind == PracticeExamKind.ayt || _kind == PracticeExamKind.ydt);

  bool get _canSave {
    if (_input.isRankMode) return _input.hasValidRank;
    if (_input.isScoreMode) return _input.hasValidScore;
    final scoped = _scopedInput;
    return _kind.subjects.any((s) => scoped.netOf(s) != 0);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: 'Denemeyi ne zaman çözdün?',
    );
    if (picked != null) setState(() => _takenAt = picked);
  }

  void _switchMode(NetEntryMode mode) {
    if (mode == _input.entryMode) return;

    // Sıra ve puan tek alanlık "gerçekler"; ikisi bir arada tutulursa hangisinin
    // geçerli olduğu belirsizleşir. Netler alanlarda durduğu için kaybolmaz.
    if (mode == NetEntryMode.rank || mode == NetEntryMode.score) {
      _rankController.clear();
      _scoreController.clear();
      _update(_input.copyWith(
        entryMode: mode,
        clearRank: true,
        clearScore: true,
      ));
      return;
    }

    if (_input.isDirectMode) {
      _rankController.clear();
      _scoreController.clear();
      _update(_input.copyWith(
        entryMode: mode,
        scoreType: '',
        clearRank: true,
        clearScore: true,
      ));
      return;
    }

    if (mode == NetEntryMode.directNet) {
      // Doğru/yanlıştan hesaplanan netler direkt alanlara taşınır.
      _update(_input.copyWith(entryMode: mode, directNets: {
        for (final s in YksSubject.values)
          if (_input.netOf(s) > 0) s: _input.netOf(s),
      }));
      return;
    }
    _update(_input.copyWith(entryMode: mode, directNets: const {}));
  }

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final input = _scopedInput;

    // Resmî ÖSYM tabloları beş türü de kapsadığından tahmin motoru yalnız
    // yedektir; veri gelmezse (çevrimdışı) kayıt yine de yapılmalı.
    MultiYearRankEstimator estimator;
    try {
      estimator = await ref.read(multiYearRankEstimatorProvider.future);
    } catch (_) {
      estimator = MultiYearRankEstimator.fromDepartments(const []);
    }
    final outcome = ScoreOutcomeService(estimator: estimator).buildAll(input);

    final rawName = _nameController.text.trim();
    final name = rawName.isEmpty ? 'Deneme' : rawName;
    final publisher = _publisherController.text.trim();
    final notifier = ref.read(practiceExamsProvider.notifier);

    final existing = widget.existing;
    if (existing == null) {
      await notifier.add(PracticeExam.fromOutcome(
        outcome: outcome,
        input: input,
        name: name,
        publisher: publisher,
        kind: _kind,
        takenAt: _takenAt,
      ));
    } else {
      await notifier.update(existing.copyWith(
        name: name,
        publisher: publisher,
        kind: _kind,
        takenAt: _takenAt,
        year: input.selectedYear,
        input: input,
        results: [
          for (final o in outcome.outcomes) TypeScoreSnapshot.fromOutcome(o),
        ],
      ));
    }

    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(_isEdit ? '$name güncellendi' : '$name defterine eklendi'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scoped = _scopedInput;
    final applicableTypes = ScoreCalculatorEngine.applicableScoreTypes(scoped);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        title: Text(_isEdit ? 'Denemeyi Düzenle' : 'Deneme Ekle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _Card(
            icon: Icons.assignment_rounded,
            iconColor: AppColors.primary,
            title: 'Deneme Bilgileri',
            child: _buildInfoFields(context),
          ),
          const SizedBox(height: 16),

          _buildModeSelector(),
          const SizedBox(height: 20),

          if (_input.isRankMode) ...[
            _Card(
              icon: Icons.leaderboard_rounded,
              iconColor: AppColors.primary,
              title: 'Başarı Sıralaman',
              child: RankInputSection(
                controller: _rankController,
                input: _input,
                onScoreTypeChanged: (type) =>
                    _update(_input.copyWith(scoreType: type)),
                onRankChanged: (rank) => _update(rank == null
                    ? _input.copyWith(clearRank: true)
                    : _input.copyWith(enteredRank: rank)),
                onYearChanged: (year) =>
                    _update(_input.copyWith(selectedYear: year)),
              ),
            ),
          ] else if (_input.isScoreMode) ...[
            _Card(
              icon: Icons.workspace_premium_rounded,
              iconColor: AppColors.primary,
              title: 'Yerleştirme Puanın',
              child: ScoreEntrySection(
                controller: _scoreController,
                input: _input,
                onScoreTypeChanged: (type) =>
                    _update(_input.copyWith(scoreType: type)),
                onScoreChanged: (score) => _update(score == null
                    ? _input.copyWith(clearScore: true)
                    : _input.copyWith(enteredScore: score)),
                onYearChanged: (year) =>
                    _update(_input.copyWith(selectedYear: year)),
              ),
            ),
          ] else ...[
            if (_scoreImpossible) _buildNoScoreNote(context),
            for (final (title, subjects) in _subjectGroups) ...[
              _buildGroupHeader(context, title),
              for (final subject in subjects) _subjectRow(subject),
            ],
            const SizedBox(height: 16),
            _Card(
              icon: Icons.workspace_premium_rounded,
              iconColor: AppColors.gold,
              title: 'Diploma Notu (OBP)',
              child: ObpSection(
                controller: _obpController,
                input: _input,
                onObpChanged: (v) => _update(_input.copyWith(obpScore: v)),
                onPlacedLastYearChanged: (v) =>
                    _update(_input.copyWith(placedLastYear: v)),
                onMeslekOwnFieldChanged: (v) =>
                    _update(_input.copyWith(meslekOwnField: v)),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_canSave)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _input.isRankMode
                        ? 'Puan türünü seç ve sıranı gir'
                        : _input.isScoreMode
                            ? 'Puan türünü seç ve puanını gir'
                            : 'En az bir dersin netini gir',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryFor(context)),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (applicableTypes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Hesaplanacak: ${applicableTypes.join(" · ")}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondaryFor(context)),
                    textAlign: TextAlign.center,
                  ),
                ),
              GradientButton(
                text: _isEdit ? 'Değişiklikleri Kaydet' : 'Denemeyi Kaydet',
                icon: Icons.bookmark_added_rounded,
                onPressed: (_canSave && !_saving) ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFields(BuildContext context) {
    final publishers = ref.watch(knownPublishersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          maxLength: PracticeExam.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Deneme adı',
            hintText: 'Ör: TYT Deneme 5',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _publisherController,
          maxLength: PracticeExam.maxPublisherLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Yayın (opsiyonel)',
            hintText: 'Ör: 3D Yayınları',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        if (publishers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in publishers.take(6))
                ActionChip(
                  label: Text(p, style: AppTextStyles.labelSmall),
                  onPressed: () => _publisherController.text = p,
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Deneme türü',
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in PracticeExamKind.values)
              ChoiceChip(
                label: Text(kind.labelTr),
                selected: _kind == kind,
                showCheckmark: false,
                onSelected: (_) => setState(() => _kind = kind),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tür, hangi derslerin sorulacağını belirler.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textTertiaryFor(context)),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Deneme tarihi: ${_formatDate(_takenAt)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiaryFor(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    // Dört segment dar ekranlara sığmıyor; sığdığında ortalanır, sığmadığında
    // yatay kayar.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width - 40,
        ),
        child: Center(
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
              ButtonSegment(
                value: NetEntryMode.score,
                label: Text('Puan Gir'),
                icon: Icon(Icons.workspace_premium_rounded, size: 18),
              ),
            ],
            selected: {_input.entryMode},
            onSelectionChanged: (selection) => _switchMode(selection.first),
          ),
        ),
      ),
    );
  }

  Widget _buildNoScoreNote(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'TYT neti olmadan puan ve sıra hesaplanamaz. Netlerin yine de '
              'kaydedilir ve ders analizine girer.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectRow(YksSubject subject) {
    if (_input.entryMode == NetEntryMode.directNet) {
      return SubjectNetInput(
        key: ValueKey('net_${subject.name}'),
        title: subject.labelTr,
        maxQuestions: subject.maxQuestions,
        value: _input.directNets[subject] ?? 0,
        onChanged: (v) => _update(_input.withDirectNet(subject, v)),
      );
    }
    return SubjectScoreInput(
      key: ValueKey('dy_${subject.name}'),
      title: subject.labelTr,
      maxQuestions: subject.maxQuestions,
      correct: _input.correctOf(subject),
      wrong: _input.wrongOf(subject),
      onCorrectChanged: (v) => _update(_input.withCorrect(subject, v)),
      onWrongChanged: (v) => _update(_input.withWrong(subject, v)),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
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
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _Card({
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
