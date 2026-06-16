import 'package:flutter/services.dart';

class AppHaptic {
  static Future<void> compareSuccess() => HapticFeedback.mediumImpact();
  static Future<void> swap() => HapticFeedback.selectionClick();
  static Future<void> reset() => HapticFeedback.lightImpact();
  static Future<void> limitReached() => HapticFeedback.heavyImpact();
  static Future<void> aiSummaryReceived() => HapticFeedback.lightImpact();
  static Future<void> noteSaved() => HapticFeedback.lightImpact();
  static Future<void> noteDeleted() => HapticFeedback.selectionClick();
  static Future<void> favoriteToggle() => HapticFeedback.lightImpact();
}
