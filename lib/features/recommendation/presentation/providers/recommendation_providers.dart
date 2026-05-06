import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/recommendation_engine.dart';
import '../../domain/models/recommendation_answer.dart';
import '../../domain/models/recommendation_result.dart';
import '../../domain/question_bank.dart';

/// Mevcut soru indeksi — autoDispose: chat ekranından çıkınca sıfırlanır
final currentQuestionIndexProvider = StateProvider.autoDispose<int>((_) => 0);

/// Cevaplar — autoDispose: ekran kapanınca temizlenir
final recommendationAnswersProvider =
    StateProvider.autoDispose<Map<String, RecommendationAnswer>>((_) => {});

/// Mevcut soru
final currentQuestionProvider = Provider.autoDispose((ref) {
  final idx = ref.watch(currentQuestionIndexProvider);
  if (idx >= QuestionBank.questions.length) return null;
  return QuestionBank.questions[idx];
});

/// İlerleme yüzdesi
final recommendationProgressProvider = Provider.autoDispose<double>((ref) {
  final idx = ref.watch(currentQuestionIndexProvider);
  return idx / QuestionBank.questions.length;
});

/// Sonuç hesaplama — tamamen lokal, autoDispose ile sonuç ekranı kapanınca dispose
final recommendationResultProvider =
    Provider.autoDispose<RecommendationResult>((ref) {
  // keepAlive false (default) — sonuç ekranı kapatıldığında dispose
  final answers = ref.watch(recommendationAnswersProvider);
  final engine = RecommendationEngine();
  final results = engine.generateRecommendations(answers);
  final summary = engine.generateSummary(results);

  return RecommendationResult(
    recommendations: results,
    summary: summary,
  );
});
