import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/recommendation_engine.dart';
import '../../domain/models/recommendation_answer.dart';
import '../../domain/models/recommendation_result.dart';
import '../../domain/question_bank.dart';

/// Mevcut soru indeksi
final currentQuestionIndexProvider = StateProvider<int>((_) => 0);

/// Cevaplar — questionId → answer
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

/// Sonuç hesaplama — artık tamamen lokal, Firestore'a gerek yok
final recommendationResultProvider =
    Provider<RecommendationResult>((ref) {
  final answers = ref.watch(recommendationAnswersProvider);
  final engine = RecommendationEngine();
  final results = engine.generateRecommendations(answers);
  final summary = engine.generateSummary(results);

  return RecommendationResult(
    recommendations: results,
    summary: summary,
  );
});
