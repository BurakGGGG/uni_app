import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_message.dart';
import 'package:uni_app/features/assistant/presentation/robot_action_route.dart';
import 'package:uni_app/router/app_router.dart';

void main() {
  group('robotActionRoute', () {
    test('none → null (çağıran kendi varsayılanına düşer)', () {
      expect(robotActionRoute(RobotAction.none), isNull);
    });

    test('sihirbaz eylemleri', () {
      expect(robotActionRoute(RobotAction.openWizard),
          AppRoutes.preferenceWizard);
      // Sıralama da sihirbazın sohbet akışında toplanıyor.
      expect(robotActionRoute(RobotAction.addRank), AppRoutes.preferenceWizard);
    });

    test('hesaplayıcı ve listeler', () {
      expect(robotActionRoute(RobotAction.openScoreCalculator),
          AppRoutes.scoreCalculator);
      expect(robotActionRoute(RobotAction.openLists), AppRoutes.myLists);
    });

    test('en iyi bölümler — argümansız ve bölüm adlı', () {
      expect(robotActionRoute(RobotAction.openBestPrograms),
          AppRoutes.bestPrograms);
      expect(robotActionRoute(RobotAction.openBestPrograms, arg: 'Tıp'),
          '${AppRoutes.bestPrograms}?dept=T%C4%B1p');
      // Boş argüman da genel listeye düşer.
      expect(robotActionRoute(RobotAction.openBestPrograms, arg: ''),
          AppRoutes.bestPrograms);
    });

    // Enum büyüdüğünde bu test kırılsın: yeni bir eylem eklenip eşleme
    // unutulursa Üni'nin balonu sessizce hiçbir yere gitmez.
    test('her enum değerinin bir karşılığı var', () {
      for (final action in RobotAction.values) {
        final route = robotActionRoute(action);
        if (action == RobotAction.none) continue;
        expect(route, isNotNull, reason: '$action eşlenmemiş');
        expect(route, startsWith('/'), reason: '$action geçersiz rota');
      }
    });
  });
}
