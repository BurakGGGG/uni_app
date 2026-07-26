import '../../../router/app_router.dart';
import '../domain/robot_message.dart';

/// [RobotAction] → rota eşlemesi.
///
/// Domain katmanı go_router'ı tanımaz ([robot_message.dart] bunu şart
/// koşuyor); eşleme burada, presentation'da yaşar. Saf fonksiyon —
/// BuildContext almaz, testi kolaydır.
///
/// [RobotAction.none] için null döner: çağıran yüzey kendi varsayılan
/// davranışına düşer.
/// [arg] yalnız veri taşıyan eylemlerde kullanılır (bkz.
/// [RobotMessage.actionArg]).
String? robotActionRoute(RobotAction action, {String? arg}) {
  switch (action) {
    case RobotAction.none:
      return null;
    case RobotAction.openWizard:
      return AppRoutes.preferenceWizard;
    // Sıralama girişi eskiden sihirbazın sohbet akışında toplanıyordu; o akış
    // kalktı, sıra modu puan hesaplayıcının içinde. Tanışma formu puan/sıra
    // sormadığı için oraya götürmek kullanıcıyı çıkmaza sokuyordu.
    case RobotAction.addRank:
    case RobotAction.openScoreCalculator:
      return AppRoutes.scoreCalculator;
    case RobotAction.openLists:
      return AppRoutes.myLists;
    case RobotAction.openBestPrograms:
      return arg == null || arg.isEmpty
          ? AppRoutes.bestPrograms
          : '${AppRoutes.bestPrograms}?dept=${Uri.encodeComponent(arg)}';
    case RobotAction.openUniPanel:
      return AppRoutes.uniPanel;
    // Hedef kartı deneme defterinin içinde yaşıyor; ayrı rota yok.
    case RobotAction.openPracticeExams:
    case RobotAction.setTarget:
      return AppRoutes.practiceExams;
  }
}

/// Eylem giriş isteyen bir ekrana mı gidiyor?
///
/// Cevabı rota tablosundan türetir, ayrı bir liste tutmaz — yeni bir eylem
/// Denemelerim'e bağlandığında burası kendiliğinden doğru cevabı verir.
/// Misafire böyle bir düğme gösterilmez: dokunduğunda yalnız giriş duvarı
/// görürdü (kapı `app_router.dart`'taki `protectedRoutes`).
bool robotActionNeedsAccount(RobotAction action) {
  final route = robotActionRoute(action);
  return route != null && route.startsWith(AppRoutes.practiceExams);
}
