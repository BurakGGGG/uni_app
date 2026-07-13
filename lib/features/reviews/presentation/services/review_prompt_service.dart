import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../university/domain/models/university_model.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';
import '../widgets/review_prompt_sheet.dart';

/// Akıllı yorum isteme servisi.
///
/// Uygun kullanıcılara (doğrulanmış öğrenci, o üniversiteye henüz yorum
/// yazmamış) doğru anda — favorileme sonrası veya 3. detay ziyaretinde —
/// "deneyimini paylaş" bottom sheet'i gösterir.
///
/// Durum cihaz-yerel (SharedPreferences): toplam en fazla 2 gösterim,
/// gösterimler arası en az 14 gün, "bir daha gösterme" kalıcı.
class ReviewPromptService {
  ReviewPromptService(this._prefs);

  final SharedPreferences _prefs;

  static const _shownCountKey = 'review_prompt_shown_count_v1';
  static const _lastShownMsKey = 'review_prompt_last_shown_ms_v1';
  static const _neverKey = 'review_prompt_never_v1';
  static String _visitsKey(String uniId) => 'review_prompt_visits_v1_$uniId';

  static const _maxTotalPrompts = 2;
  static const _minDaysBetweenPrompts = 14;
  static const _visitThreshold = 3;

  /// Detay ekranı ziyaretini kaydeder; eşiğe ulaşıldıysa istem dener.
  Future<void> recordVisitAndMaybePrompt(
    BuildContext context,
    WidgetRef ref,
    UniversityModel uni,
  ) async {
    final visits = (_prefs.getInt(_visitsKey(uni.id)) ?? 0) + 1;
    await _prefs.setInt(_visitsKey(uni.id), visits);
    if (visits < _visitThreshold) return;

    if (!context.mounted) return;
    await _maybePrompt(context, ref, uni);
  }

  /// Favoriye ekleme sonrası istem dener.
  Future<void> maybePromptAfterFavorite(
    BuildContext context,
    WidgetRef ref,
    UniversityModel uni,
  ) {
    return _maybePrompt(context, ref, uni);
  }

  Future<void> _maybePrompt(
    BuildContext context,
    WidgetRef ref,
    UniversityModel uni,
  ) async {
    if (!_frequencyAllows()) return;

    final profile = await ref.read(currentUserProvider.future);
    if (profile == null || !profile.isVerifiedStudent) return;

    final alreadyReviewed = await ref
        .read(reviewRepositoryProvider)
        .hasUserReviewed(
          userId: profile.uid,
          targetId: uni.id,
          type: ReviewType.university,
        );
    if (alreadyReviewed) return;

    if (!context.mounted) return;

    await _markShown();
    if (!context.mounted) return;
    await ReviewPromptSheet.show(
      context,
      uni: uni,
      isOwnUniversity: profile.universityId == uni.id,
      onNeverAgain: markNeverAgain,
    );
  }

  bool _frequencyAllows() {
    if (_prefs.getBool(_neverKey) ?? false) return false;
    if ((_prefs.getInt(_shownCountKey) ?? 0) >= _maxTotalPrompts) return false;

    final lastShownMs = _prefs.getInt(_lastShownMsKey) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastShownMs;
    return elapsed > _minDaysBetweenPrompts * 24 * 60 * 60 * 1000;
  }

  Future<void> _markShown() async {
    await _prefs.setInt(
      _shownCountKey,
      (_prefs.getInt(_shownCountKey) ?? 0) + 1,
    );
    await _prefs.setInt(
      _lastShownMsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> markNeverAgain() => _prefs.setBool(_neverKey, true);
}

final reviewPromptServiceProvider = Provider<ReviewPromptService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReviewPromptService(prefs);
});
