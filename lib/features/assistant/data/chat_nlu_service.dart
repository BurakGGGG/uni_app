import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../../services/rate_limiter.dart';
import '../domain/chat_nlu_client.dart';

/// `parseWizardUtterance` callable istemcisi (us-central1, App Check'li).
/// Sözleşme: functions/src/assistant/parse.ts — sunucu Pro aboneliği,
/// günlük 20 hakkı ve dakikalık pencereyi denetler; cache yoktur.
///
/// Sohbet hata görmemeli: her başarısızlık null'a düşer, Üni "anlayamadım
/// + çipler" davranışına döner. Buradan asla exception sızmaz.
class ChatNluService implements ChatNluClient {
  final FirebaseFunctions _functions;

  ChatNluService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<RemoteParse?> parse(String utterance) async {
    final trimmed = utterance.trim();
    if (trimmed.isEmpty) return null;
    if (!AppRateLimiters.chatNlu.tryAcquire()) {
      debugPrint('[ChatNlu] Client-side rate limited');
      return null;
    }

    try {
      final callable = _functions.httpsCallable(
        'parseWizardUtterance',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 12), // Function 15s > Groq 8s
        ),
      );
      final response =
          await callable.call<Object?>({'utterance': trimmed});
      return _parse(response.data);
    } on FirebaseFunctionsException catch (e) {
      // Limit/abonelik/ağ hataları operasyonel — sessiz geri düşüş yeter.
      debugPrint('[ChatNlu] ${e.code}: ${e.message}');
      return null;
    } catch (e, st) {
      debugPrint('[ChatNlu] Unknown error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'chat_parseWizardUtterance_unknown_error',
        fatal: false,
      );
      return null;
    }
  }

  RemoteParse? _parse(Object? raw) {
    if (raw is! Map) return null;

    List<String> list(Object? v) => v is List
        ? v.whereType<String>().where((s) => s.trim().isNotEmpty).toList()
        : const [];

    return RemoteParse(
      scoreType: raw['scoreType'] as String?,
      rank: (raw['rank'] as num?)?.toInt(),
      score: (raw['score'] as num?)?.toDouble(),
      cities: list(raw['cities']),
      uniTypes: list(raw['uniTypes']),
      languages: list(raw['languages']),
      programTypes: list(raw['programTypes']),
      onlyScholarship: raw['onlyScholarship'] == true ? true : null,
      depts: list(raw['depts']),
    );
  }
}
