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
      // Sıra girişi puan hesaplayıcının sıra modunda; tanışma formu puan da
      // sıra da sormuyor, oraya götürmek çıkmaz olurdu.
      expect(robotActionRoute(RobotAction.addRank), AppRoutes.scoreCalculator);
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

  /// Denemelerim üyelere özel (`app_router.dart` → `protectedRoutes`).
  /// Misafire oraya götüren düğme gösterilmez; kural rota tablosundan
  /// türetilir, ayrı liste tutulmaz.
  group('giriş isteyen eylemler', () {
    test('Denemelerim kapıları hesap ister', () {
      expect(robotActionNeedsAccount(RobotAction.openPracticeExams), isTrue);
      expect(robotActionNeedsAccount(RobotAction.setTarget), isTrue);
    });

    test('misafire açık ekranlar hesap istemez', () {
      for (final action in [
        RobotAction.none,
        RobotAction.openScoreCalculator,
        RobotAction.openLists,
        RobotAction.openBestPrograms,
        RobotAction.openWizard,
        RobotAction.openUniPanel,
      ]) {
        expect(robotActionNeedsAccount(action), isFalse, reason: '$action');
      }
    });

    // Kural rotadan türüyor: `/practice-exams`'e çıkan HER eylem hesap
    // ister, listeye elle eklenmesi gerekmez.
    test('kural rota tablosuyla tutarlı', () {
      for (final action in RobotAction.values) {
        final route = robotActionRoute(action);
        expect(
          robotActionNeedsAccount(action),
          route != null && route.startsWith(AppRoutes.practiceExams),
          reason: '$action → $route',
        );
      }
    });
  });
}
