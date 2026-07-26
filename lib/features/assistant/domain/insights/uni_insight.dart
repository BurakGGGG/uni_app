import '../robot_message.dart';
import '../robot_mood.dart';

/// İçgörünün doğduğu veri kaynağı — panelde gruplama ve analitik için.
enum InsightKind {
  /// Tercih yolunun ön koşulu: puan profili eksik.
  setup,

  /// Tercih listesinin sağlığı.
  list,

  /// Takip edilen programların ÖSYM verisi (taban trendi, doluluk).
  data,

  /// Tercih takvimi.
  calendar,
}

/// Kartın görsel ağırlığı — renk ve ikon seçimi buradan türetilir.
enum InsightTone { neutral, positive, warning, urgent }

/// Üni'nin tek bir notu.
///
/// [id] şablon kimliğidir (ör. `list.noSafe`): analitik, susturma
/// ([RobotMemory]) ve testler bunun üzerinden çalışır — dilden bağımsızdır.
/// Metin üretimi [RobotScripts]'te, seçim [InsightEngine]'de yaşar; bu sınıf
/// yalnız taşır.
class UniInsight {
  final String id;
  final InsightKind kind;
  final InsightTone tone;

  /// 0–100; panel ve ana sayfa kartı azalan sıralar. Faz önceliği kaydırır
  /// (ör. `list.noSafe` tercih döneminde 85, dışında 50).
  final int priority;

  /// Kısa, kalın satır — ana sayfa kartında tek başına da okunabilir olmalı.
  final String title;

  /// Bir-iki cümle açıklama; panelde başlığın altında görünür.
  final String body;

  /// Eylem butonunun etiketi; [action] none ise null.
  final String? actionLabel;
  final RobotAction action;
  final String? actionArg;

  final RobotMood mood;

  /// Kullanıcı kapatabilir mi? Kurulum adımları ve takvim geri sayımı
  /// kapatılamaz — eksik olan şey kapatmakla tamamlanmaz.
  final bool dismissible;

  const UniInsight({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.body,
    this.tone = InsightTone.neutral,
    this.actionLabel,
    this.action = RobotAction.none,
    this.actionArg,
    this.mood = RobotMood.happy,
    this.dismissible = true,
  });

  bool get hasAction => action != RobotAction.none;

  /// Düğmesiz kopya.
  ///
  /// Hedefi üyelere özel bir ekran olan notlar misafire böyle gösterilir:
  /// cümle değerli ("YKS'ye 120 gün"), ama düğme onu giriş duvarına
  /// çarptırırdı.
  UniInsight withoutAction() => UniInsight(
        id: id,
        kind: kind,
        priority: priority,
        title: title,
        body: body,
        tone: tone,
        mood: mood,
        dismissible: dismissible,
      );
}
