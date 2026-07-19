import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../data/robot_enrichment_service.dart';
import '../../data/robot_memory.dart';
import '../../domain/robot_brain.dart';
import '../../domain/robot_enrichment.dart';
import '../../domain/robot_message.dart';
import '../../domain/robot_message_source.dart';
import '../../domain/tercih_calendar.dart';

final robotMemoryProvider = Provider<RobotMemory>((ref) {
  return RobotMemory(ref.watch(sharedPreferencesProvider));
});

/// Ana ekran selamlaması. Seed varsayılanı gün+ay olduğundan mesaj gün
/// içinde sabittir (rebuild'te değişmez), ertesi gün kendiliğinden döner.
final homeGreetingProvider = Provider.autoDispose<RobotMessage>((ref) {
  final profile = ref.watch(studentScoreProfileProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  final name = user?.displayName.trim();
  final firstName =
      (name == null || name.isEmpty) ? null : name.split(' ').first;
  return RobotBrain.homeGreeting(
    HomeContext(
      now: DateTime.now(),
      hasProfile: profile != null && profile.scoreType.isNotEmpty,
      firstName: firstName,
    ),
  );
});

/// Günün ipucu — gün bazlı döner.
final tipOfDayProvider = Provider.autoDispose<RobotMessage>((ref) {
  return RobotBrain.tipOfDay(tercihPhaseFor(DateTime.now()));
});

final robotEnrichmentClientProvider = Provider<RobotEnrichmentClient>((ref) {
  return RobotEnrichmentService();
});

/// Faz 2: Pro'da balon metni LLM özetiyle zenginleşir; diğer herkes (ve LLM
/// tarafındaki her hata) kural kaynağına düşer. Rewarded geçici Pro erişimi
/// KASITLI olarak uygulanmaz — sunucu gerçek Pro tier'ı denetler (aynı
/// gerekçe: canUseAiComparisonProvider notu).
final robotMessageSourceProvider = Provider<RobotMessageSource>((ref) {
  final tier = ref.watch(subscriptionTierProvider).valueOrNull;
  final isPro = tier != null && tier.satisfies(SubscriptionTier.pro);
  if (!isPro) return const RuleBasedMessageSource();
  return LlmEnrichedMessageSource(ref.watch(robotEnrichmentClientProvider));
});

/// Sonuç ekranı özeti (balon mesajı + kart notları) — motor sonucundan
/// bağlam kurup kaynağa sorar. Profil yoksa null (ekran zaten giriş
/// ekranına yönlendirir).
final robotResultsSummaryProvider =
    FutureProvider.autoDispose<RobotResultsSummary?>((ref) async {
  final result = await ref.watch(preferenceMatchResultProvider.future);
  if (result == null) return null;
  final profile = ref.watch(studentScoreProfileProvider);
  final ctx = ResultsContext(
    guaranteed: result.guaranteed.length,
    target: result.target.length,
    dream: result.dream.length,
    usedEstimatedRank:
        profile != null && profile.hasScore && !profile.hasRank,
    scoreType: profile?.scoreType,
    rank: profile != null && profile.hasRank ? profile.rank : null,
  );
  final top = [...result.guaranteed, ...result.target, ...result.dream];
  return ref
      .watch(robotMessageSourceProvider)
      .resultsSummary(ctx, topMatches: top);
});

/// Balon mesajı — başlık bileşeni yalnız mesajı ister.
final robotResultsMessageProvider =
    FutureProvider.autoDispose<RobotMessage?>((ref) async {
  return (await ref.watch(robotResultsSummaryProvider.future))?.message;
});

/// `universityId_departmentId` → Üni'nin kişisel kart notu.
/// Yalnız Pro + LLM başarılıyken dolu; kural kaynağında hep boş.
final robotCardNotesProvider =
    Provider.autoDispose<Map<String, String>>((ref) {
  return ref.watch(robotResultsSummaryProvider).valueOrNull?.notes ??
      const {};
});
