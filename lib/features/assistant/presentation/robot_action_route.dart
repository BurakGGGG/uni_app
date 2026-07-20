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
String? robotActionRoute(RobotAction action) {
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
  }
}
