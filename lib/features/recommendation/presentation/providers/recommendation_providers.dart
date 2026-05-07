import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/recommendation_engine.dart';
import '../../domain/models/recommendation_answer.dart';
import '../../domain/models/recommendation_enrichment.dart';
import '../../domain/models/recommendation_result.dart';
import '../../domain/question_bank.dart';

/// Mevcut soru indeksi
final currentQuestionIndexProvider = StateProvider<int>((_) => 0);

/// Cevaplar
final recommendationAnswersProvider =
    StateProvider<Map<String, RecommendationAnswer>>((_) => {});

/// Mevcut soru
final currentQuestionProvider = Provider((ref) {
  final idx = ref.watch(currentQuestionIndexProvider);
  if (idx >= QuestionBank.questions.length) return null;
  return QuestionBank.questions[idx];
});

/// İlerleme yüzdesi
final recommendationProgressProvider = Provider<double>((ref) {
  final idx = ref.watch(currentQuestionIndexProvider);
  return idx / QuestionBank.questions.length;
});

/// Structured sonuç provider — yerel kural tabanlı öneri motoru.
final recommendationResultProvider = FutureProvider<RecommendationResult>((
  ref,
) async {
  final answers = ref.watch(recommendationAnswersProvider);

  if (answers.isEmpty) {
    return RecommendationResult(recommendations: [], summary: '');
  }

  final engine = RecommendationEngine();
  final results = engine.generateRecommendations(answers);
  final summary = engine.generateSummary(results);

  return RecommendationResult(recommendations: results, summary: summary);
});

/// AI zenginleştirme provider'ı.
///
/// Engine sonucunu girdi alır, Cloud Function'a gönderir.
/// Hata durumunda `null` döner — UI fallback olarak engine'in
/// kendi reasons listesini gösterir.
final recommendationEnrichmentProvider =
    FutureProvider<RecommendationEnrichment?>((ref) async {
  final base = await ref.watch(recommendationResultProvider.future);
  if (base.recommendations.isEmpty) return null;

  final answers = ref.read(recommendationAnswersProvider);
  final tags = RecommendationEngine().extractTagsForLlm(answers);

  // Sadece top 8'i gönder
  final payload = {
    'userTags': tags,
    'recommendations': base.recommendations
        .take(8)
        .map((r) => {
              'departmentId': r.departmentId,
              'departmentName': r.departmentName,
              'universityId': r.universityId,
              'universityName': r.universityName,
              'totalScore': r.totalScore,
              'reasons': r.reasons,
            })
        .toList(),
  };

  try {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable(
      'enrichRecommendations',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 20),
      ),
    );
    final res = await callable.call<Map<String, dynamic>>(payload);
    final data = Map<String, dynamic>.from(res.data);
    return RecommendationEnrichment.fromMap(data);
  } on FirebaseFunctionsException catch (e) {
    debugPrint('AI enrichment failed: ${e.code} ${e.message}');
    return null;
  } catch (e, st) {
    debugPrint('AI enrichment unexpected: $e\n$st');
    return null;
  }
});
