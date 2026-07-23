import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/models/multi_score_result.dart';
import '../../../score_calculator/domain/models/score_input.dart';
import '../../domain/models/practice_exam.dart';
import '../providers/practice_exam_providers.dart';

/// Hesaplama sonucunu deneme defterine yazma sayfası.
///
/// Otomatik kayıt yerine bilinçli kayıt: ad, yayın, tür ve **denemenin
/// çözüldüğü tarih** burada sorulur — gelişim grafiği kaydetme anına değil o
/// tarihe göre çizilir.
class SavePracticeExamSheet extends ConsumerStatefulWidget {
  final MultiScoreOutcome outcome;
  final ScoreInput input;

  const SavePracticeExamSheet({
    super.key,
    required this.outcome,
    required this.input,
  });

  /// Kaydedilen denemeyi döner; vazgeçilirse null.
  static Future<PracticeExam?> show(
    BuildContext context, {
    required MultiScoreOutcome outcome,
    required ScoreInput input,
  }) {
    return showModalBottomSheet<PracticeExam>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavePracticeExamSheet(outcome: outcome, input: input),
    );
  }

  @override
  ConsumerState<SavePracticeExamSheet> createState() =>
      _SavePracticeExamSheetState();
}

class _SavePracticeExamSheetState
    extends ConsumerState<SavePracticeExamSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _publisherController;
  late PracticeExamKind _kind;
  late DateTime _takenAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final count = ref.read(practiceExamsProvider).length;
    _nameController = TextEditingController(text: 'Deneme ${count + 1}');
    _publisherController = TextEditingController();
    _kind = _guessKind();
    _takenAt = DateTime.now();
  }

  /// Girilen verilerden deneme türünü tahmin eder — kullanıcı çoğu zaman
  /// dokunmadan geçebilsin.
  PracticeExamKind _guessKind() {
    final types = widget.outcome.outcomes.map((o) => o.score.scoreType).toSet();
    if (types.length == 1 && types.first == 'TYT') return PracticeExamKind.tyt;
    if (types.length == 1 && types.first == 'DİL') return PracticeExamKind.ydt;
    if (!types.contains('TYT') && types.isNotEmpty) return PracticeExamKind.ayt;
    return PracticeExamKind.genel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Denemeyi ne zaman çözdün?',
    );
    if (picked != null) setState(() => _takenAt = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final exam = PracticeExam.fromOutcome(
      outcome: widget.outcome,
      input: widget.input,
      name: name.isEmpty ? 'Deneme' : name,
      publisher: _publisherController.text.trim(),
      kind: _kind,
      takenAt: _takenAt,
    );
    await ref.read(practiceExamsProvider.notifier).add(exam);
    if (mounted) Navigator.pop(context, exam);
  }

  @override
  Widget build(BuildContext context) {
    final publishers = ref.watch(knownPublishersProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLightFor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Denemelerime Kaydet',
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gelişimini takip edebilmek için denemene bir ad ve tarih ver.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 20),

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
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
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
                const SizedBox(height: 16),

                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.borderLightFor(context)),
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
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                    label: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}
