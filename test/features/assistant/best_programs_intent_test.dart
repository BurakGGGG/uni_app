import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/utils/city_helper.dart';
import 'package:uni_app/features/assistant/domain/best_programs_intent.dart';
import 'package:uni_app/features/assistant/domain/chat_flow.dart';
import 'package:uni_app/features/assistant/domain/chat_models.dart';
import 'package:uni_app/features/assistant/domain/robot_message.dart';
import 'package:uni_app/features/assistant/domain/tercih_nlu.dart';

void main() {
  final nlu = TercihNlu(
    cityMap: CityHelper.cityMap,
    deptNames: {'Psikoloji', 'Hukuk', 'Tıp', 'Bilgisayar Mühendisliği'},
  );
  final flow = ChatFlow(nlu: nlu, cityNames: CityHelper.cityMap);

  BestProgramsIntent? detect(String text) =>
      detectBestProgramsIntent(text, nlu.parse(text));

  group('detectBestProgramsIntent', () {
    test('bölümlü üstünlük sorusu yakalanır', () {
      expect(detect('en iyi tıp bölümleri')?.departmentLabel, 'Tıp');
      expect(detect('En İyi Hukuk Bölümleri')?.departmentLabel, 'Hukuk');
    });

    test('halk dili sözlükten çözülür', () {
      // "mühendis" → deptQuery 'mühendis', etiket "Mühendislik".
      expect(detect('en iyi mühendislik bölümleri')?.departmentLabel,
          isNotNull);
    });

    test('bölümsüz üstünlük sorusu genel listeye gider', () {
      final intent = detect('en iyi bölümler hangileri');
      expect(intent, isNotNull);
      expect(intent!.departmentLabel, isNull);
    });

    test('üstünlük yoksa null', () {
      expect(detect('tıp okumak istiyorum'), isNull);
      expect(detect('psikoloji'), isNull);
    });

    test('puan/sıra/tür varsa sohbet bölünmez', () {
      // Kullanıcı liste kurmaya çalışıyor; ekran değiştirmek akışı bozardı.
      expect(detect('sıralamam 45 bin en iyi tıp'), isNull);
      expect(detect('sayısal en iyi mühendislik'), isNull);
    });
  });

  group('ChatFlow entegrasyonu', () {
    test('taslak ve adım korunur, yönlendirme etkisi döner', () {
      final r = flow.handleText(
        'en iyi tıp bölümleri',
        draft: const ChatDraft(),
        step: ChatStep.scoreInfo,
      );

      expect(r.effect, ChatEffect.goBestPrograms);
      expect(r.step, ChatStep.scoreInfo);
      expect(r.draft.depts, isEmpty, reason: 'taslağa bölüm yazılmamalı');
      expect(r.messages.single.action, RobotAction.openBestPrograms);
      expect(r.messages.single.actionArg, 'Tıp');
      expect(r.messages.single.text, contains('Tıp'));
    });

    test('normal mesaj eski yoldan gider (regresyon)', () {
      final r = flow.handleText(
        'tıp okumak istiyorum',
        draft: const ChatDraft(),
        step: ChatStep.scoreInfo,
      );

      expect(r.effect, isNot(ChatEffect.goBestPrograms));
      expect(r.draft.depts, isNotEmpty);
    });
  });
}
