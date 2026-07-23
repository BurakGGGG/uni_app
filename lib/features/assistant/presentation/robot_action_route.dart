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
    // Sıralama girişi de sihirbazın içinde (sohbet akışı) toplanıyor.
    case RobotAction.openWizard:
    case RobotAction.addRank:
      return AppRoutes.preferenceWizard;
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
