import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/features/assistant/data/robot_memory.dart';

void main() {
  late RobotMemory memory;

  Future<void> withPrefs([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    memory = RobotMemory(await SharedPreferences.getInstance());
  }

  group('RobotMemory — onboarding\'de sorulan ad', () {
    test('hiç yazılmadıysa null', () async {
      await withPrefs();
      expect(memory.displayName, isNull);
    });

    test('yazılan ad okunur', () async {
      await withPrefs();
      await memory.setDisplayName('Ada');
      expect(memory.displayName, 'Ada');
    });

    test('baştaki/sondaki boşluk kırpılır', () async {
      await withPrefs();
      await memory.setDisplayName('  Ada  ');
      expect(memory.displayName, 'Ada');
    });

    // Onboarding alanı boş bırakılabilir; boş değer "ad yok" demektir,
    // selamlama isimsiz sürüme döner.
    test('yalnız boşluktan ibaret ad null sayılır', () async {
      await withPrefs();
      await memory.setDisplayName('   ');
      expect(memory.displayName, isNull);
    });

    test('kalıcı — aynı prefs\'ten yeniden okunur', () async {
      await withPrefs({'assistant_display_name': 'Deniz'});
      expect(memory.displayName, 'Deniz');
    });
  });

  group('RobotMemory — mevcut davranış korunuyor', () {
    test('son gösterilen mesaj slot bazlı', () async {
      await withPrefs();
      expect(memory.lastShown('home'), isNull);
      await memory.recordShown('home', 'home.tercih.profile.v1');
      expect(memory.lastShown('home'), 'home.tercih.profile.v1');
      expect(memory.lastShown('results'), isNull);
    });

    test('sihirbaz girişi bayrağı', () async {
      await withPrefs();
      expect(memory.wizardIntroSeen, isFalse);
      await memory.markWizardIntroSeen();
      expect(memory.wizardIntroSeen, isTrue);
    });
  });

  // Hesap değişiminde tüm cihaz-yerel Üni hafızası silinmeli, yoksa bir
  // sonraki hesaba "Merhaba <önceki ad>" olarak sızar.
  group('RobotMemory.clear — oturum değişimi', () {
    test('ad, notlar, plan ve bayraklar temizlenir', () async {
      await withPrefs();
      await memory.setDisplayName('Ada');
      await memory.markWizardIntroSeen();
      await memory.recordShown('home', 'home.msg.v1');
      await memory.dismissInsight('list.noSafe');
      await memory.togglePlanTask('2026-W30', 'task-1');
      expect(memory.isInsightDismissed('list.noSafe'), isTrue);

      await memory.clear();

      expect(memory.displayName, isNull);
      expect(memory.wizardIntroSeen, isFalse);
      expect(memory.lastShown('home'), isNull);
      expect(memory.isInsightDismissed('list.noSafe'), isFalse);
      expect(memory.donePlanTasks('2026-W30'), isEmpty);
    });

    test('alakasız anahtarlara dokunmaz', () async {
      await withPrefs({'theme_mode': 'dark', 'onboarding_completed': true});
      await memory.setDisplayName('Ada');

      await memory.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });
  });
}
