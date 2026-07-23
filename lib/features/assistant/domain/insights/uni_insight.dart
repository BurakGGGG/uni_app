import '../robot_message.dart';
import '../robot_mood.dart';

/// İçgörünün doğduğu veri kaynağı — panelde gruplama ve analitik için.
enum InsightKind {
  /// Kurulum yolu: profil / hedef / ilk deneme eksik.
  setup,

  /// Hedef programa mesafe.
  target,

  /// Deneme defterinden çıkan gelişim.
  progress,

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
/// [id] şablon kimliğidir (ör. `target.roadmap`): analitik, susturma
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
}

/// Üni'nin konuşabilmesi için gereken asgari iki şey.
///
/// Sıra anlamlıdır: puan olmadan hedefe mesafe, deneme olmadan ders kırılımı
/// hesaplanamaz. Panel bunların yalnız SIRADAKİNİ, tek cümle + tek butonla
/// gösterir — üçü birden listelenince kart "ödev listesi" gibi okunuyordu.
///
/// Hedef program bilerek BURADA DEĞİL: kullanıcı daha tek deneme girmemişken
/// ondan hedef seçmesini istemek hem erken hem de Üni'nin kendi işi — ilk
/// deneme geldikten sonra hazır öneriyle o soruyor (`setup.noTarget`).
class SetupPath {
  final bool hasProfile;
  final bool hasExam;

  const SetupPath({required this.hasProfile, required this.hasExam});

  int get done => (hasProfile ? 1 : 0) + (hasExam ? 1 : 0);

  static const int total = 2;

  bool get complete => done == total;
}
