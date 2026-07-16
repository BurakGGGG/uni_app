import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/badge_catalog.dart';
import '../providers/badge_providers.dart';
import 'badge_celebration_dialog.dart';

/// userBadgesProvider'ı dinler; yeni kazanılan rozetler için kutlama
/// diyaloğunu tek tek gösterir.
///
/// İlk gözlemde (SharedPreferences anahtarı yoksa) mevcut rozetlerle
/// "görüldü" kümesini tohumlar ve kutlama YAPMAZ — böylece yeniden
/// kurulum ve backfill edilmiş rozetler spam üretmez.
class BadgeCelebrationListener extends ConsumerStatefulWidget {
  final Widget child;

  const BadgeCelebrationListener({super.key, required this.child});

  @override
  ConsumerState<BadgeCelebrationListener> createState() =>
      _BadgeCelebrationListenerState();
}

class _BadgeCelebrationListenerState
    extends ConsumerState<BadgeCelebrationListener> {
  final List<BadgeDefinition> _queue = [];
  bool _showing = false;

  String _prefsKey(String uid) => 'seenBadges_$uid';

  @override
  Widget build(BuildContext context) {
    // Ham AsyncValue dinlenir: yükleme→veri({}) geçişi de tetiklensin ki
    // yeni (rozetsiz) kullanıcıda taban {} olarak tohumlanabilsin — aksi
    // halde ilk kazanılan rozet tohumlamaya denk gelir ve kutlama atlanır.
    ref.listen<AsyncValue<Map<String, DateTime>>>(
      userBadgesProvider,
      (previous, next) {
        final badges = next.valueOrNull;
        if (badges != null) _handleBadges(badges);
      },
    );
    return widget.child;
  }

  void _handleBadges(Map<String, DateTime> badges) {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final key = _prefsKey(uid);
    final seen = prefs.getStringList(key);

    // Katalogda tanımlı ve gerçekten kazanılmış rozet id'leri.
    final earnedKnown = badges.keys
        .where((id) => _known(id))
        .toSet();

    // İlk gözlem: tohumla, kutlama yok.
    if (seen == null) {
      prefs.setStringList(key, earnedKnown.toList());
      return;
    }

    final seenSet = seen.toSet();
    final newlyEarned = earnedKnown.difference(seenSet);
    if (newlyEarned.isEmpty) return;

    // Görüldü kümesini hemen güncelle (tekrar tetiklenmesin).
    prefs.setStringList(key, {...seenSet, ...earnedKnown}.toList());

    for (final id in newlyEarned) {
      final def = _definitionFor(id);
      if (def != null) _queue.add(def);
    }
    _pump();
  }

  bool _known(String id) => badgeCatalog.any((b) => b.id == id);

  BadgeDefinition? _definitionFor(String id) {
    for (final b in badgeCatalog) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> _pump() async {
    if (_showing || _queue.isEmpty || !mounted) return;
    _showing = true;

    while (_queue.isNotEmpty && mounted) {
      final def = _queue.removeAt(0);
      await BadgeCelebrationDialog.show(context, def);
    }

    _showing = false;
  }
}
