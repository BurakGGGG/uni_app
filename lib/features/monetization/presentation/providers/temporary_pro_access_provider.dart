import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

class TemporaryProAccessState {
  final DateTime? expiresAt;

  const TemporaryProAccessState({this.expiresAt});

  bool get hasAccess => expiresAt != null && expiresAt!.isAfter(DateTime.now());

  Duration get timeLeft => expiresAt == null
      ? Duration.zero
      : expiresAt!.difference(DateTime.now());
}

class TemporaryProAccessNotifier extends StateNotifier<TemporaryProAccessState> {
  final Ref _ref;
  Timer? _timer;
  static const _prefKey = 'temp_pro_unlock_expiry';

  TemporaryProAccessNotifier(this._ref) : super(const TemporaryProAccessState()) {
    _init();
  }

  void _init() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final expiryStr = prefs.getString(_prefKey);
    if (expiryStr != null) {
      final expiresAt = DateTime.tryParse(expiryStr);
      if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
        state = TemporaryProAccessState(expiresAt: expiresAt);
        _startTimer(expiresAt);
      }
    }
  }

  Future<void> unlockProForOneHour() async {
    final expiresAt = DateTime.now().add(const Duration(hours: 1));
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefKey, expiresAt.toIso8601String());

    state = TemporaryProAccessState(expiresAt: expiresAt);
    _startTimer(expiresAt);
  }

  void _startTimer(DateTime expiresAt) {
    _timer?.cancel();
    final duration = expiresAt.difference(DateTime.now());
    _timer = Timer(duration, () {
      state = const TemporaryProAccessState();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final temporaryProAccessProvider =
    StateNotifierProvider<TemporaryProAccessNotifier, TemporaryProAccessState>((ref) {
  return TemporaryProAccessNotifier(ref);
});
