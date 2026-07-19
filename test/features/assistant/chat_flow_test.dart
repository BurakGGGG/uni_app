import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/utils/city_helper.dart';
import 'package:uni_app/features/assistant/domain/chat_flow.dart';
import 'package:uni_app/features/assistant/domain/chat_models.dart';
import 'package:uni_app/features/assistant/domain/tercih_nlu.dart';
import 'package:uni_app/features/assistant/domain/wizard_intent.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/domain/models/wizard_prefs.dart';

void main() {
  final nlu = TercihNlu(
    cityMap: CityHelper.cityMap,
    deptNames: {'Psikoloji', 'Hukuk', 'Tıp', 'Bilgisayar Mühendisliği'},
  );
  final flow = ChatFlow(nlu: nlu, cityNames: CityHelper.cityMap);

  final profile = StudentScoreProfile(
    scoreType: 'SAY',
    placementScore: 0,
    rank: 45000,
    year: 2026,
    updatedAt: DateTime(2026, 7, 19),
  );

  ChatChip chipLabeled(List<ChatChip> chips, String label) =>
      chips.firstWhere((c) => c.label == label);

  group('yeni kullanıcı akışı', () {
    test('açılış: selamlama + puan türü sorusu + çipler', () {
      final r = flow.start();
      expect(r.step, ChatStep.scoreInfo);
      expect(r.messages.map((m) => m.id),
          ['chat.hello.new', 'chat.ask.type']);
      expect(r.chips.map((c) => c.label), contains('SAY'));
    });

    test('SAY çipi tepki + sıralama sorusuna geçirir', () {
      final r = flow.handleChip(
        chipLabeled(ChatFlow.scoreTypeChips, 'SAY'),
        draft: const ChatDraft(),
        step: ChatStep.scoreInfo,
      );
      expect(r.draft.scoreType, 'SAY');
      expect(r.messages.map((m) => m.id), contains('wizard.type.SAY'));
      expect(r.messages.last.id, 'chat.ask.rank');
      // Sıralama serbest yazılır; tek çip hesaplayıcı köprüsüdür.
      expect(r.chips.single.command, ChatCommand.calcScore);
    });

    test('"sıralamam 80 bin" → sıra tepkisi + ilgi sorusu', () {
      final r = flow.handleText(
        'sıralamam 80 bin',
        draft: const ChatDraft(scoreType: 'SAY'),
        step: ChatStep.scoreInfo,
      );
      expect(r.draft.rank, 80000);
      expect(r.messages.first.id, startsWith('wizard.rank'));
      expect(r.step, ChatStep.interests);
      expect(r.chips.map((c) => c.label), contains('Farketmez'));
    });

    test('tek mesaj üç adımı birden bitirir → onay balonu', () {
      final r = flow.handleText(
        'sayısal 80 bin istanbulda devlet psikoloji',
        draft: const ChatDraft(),
        step: ChatStep.scoreInfo,
      );
      expect(r.step, ChatStep.confirm);
      expect(r.draft.cityIds, {'34'});
      expect(r.draft.uniTypes, {'Devlet'});
      final confirm = r.messages.last;
      expect(confirm.id, 'chat.confirm');
      expect(confirm.text, contains('Psikoloji'));
      expect(confirm.text, contains('80.000'));
      // Dürüstlük: özet balonu tahmin dili taşır, garanti vermez.
      expect(confirm.text, contains('tahmin'));
      expect(confirm.text.toLowerCase(), isNot(contains('garanti eder')));
    });

    test('ilgide Farketmez → kısıt sorusu; kısıtta yanıt → onay', () {
      const afterScore = ChatDraft(scoreType: 'SAY', rank: 80000);
      final skipped = flow.handleChip(
        chipLabeled(ChatFlow.interestChips, 'Farketmez'),
        draft: afterScore,
        step: ChatStep.interests,
      );
      expect(skipped.step, ChatStep.constraints);

      final done = flow.handleText(
        'istanbul devlet',
        draft: skipped.draft,
        step: skipped.step,
      );
      expect(done.step, ChatStep.confirm);
      expect(done.draft.cityIds, {'34'});
    });

    test('geçersiz puan reddedilir ve yeniden sorulur', () {
      final r = flow.handleText(
        'puanım 90',
        draft: const ChatDraft(scoreType: 'SAY'),
        step: ChatStep.scoreInfo,
      );
      expect(r.draft.score, isNull);
      expect(r.messages.map((m) => m.id), contains('chat.score.invalid'));
      expect(r.messages.last.id, 'chat.ask.rank');
    });

    test('anlaşılmayan girdi: şaşkınlık + bekleyen sorunun çipleri', () {
      final r = flow.handleText(
        'asdfg hjkl',
        draft: const ChatDraft(),
        step: ChatStep.scoreInfo,
      );
      expect(r.messages.single.id, 'chat.confused');
      expect(r.step, ChatStep.scoreInfo);
      expect(r.chips.map((c) => c.label), contains('SAY'));
    });
  });

  group('onay ve arama', () {
    const ready = ChatDraft(
      scoreType: 'SAY',
      rank: 80000,
      interestsDone: true,
      constraintsDone: true,
    );

    test('Ara → search etkisi + done adımı + Tümünü gör', () {
      final r = flow.handleChip(
        chipLabeled(ChatFlow.confirmChips, 'Ara 🔍'),
        draft: ready,
        step: ChatStep.confirm,
      );
      expect(r.effect, ChatEffect.search);
      expect(r.step, ChatStep.done);
      expect(r.chips.map((c) => c.label), contains('Tümünü gör'));
    });

    test('eksik bilgiyle Ara → uyarı + eksik soruya dönüş', () {
      final r = flow.handleChip(
        chipLabeled(ChatFlow.confirmChips, 'Ara 🔍'),
        draft: const ChatDraft(scoreType: 'SAY'),
        step: ChatStep.confirm,
      );
      expect(r.effect, ChatEffect.none);
      expect(r.messages.first.id, 'chat.search.missing');
      expect(r.messages.last.id, 'chat.ask.rank');
    });

    test('sonuçlardan sonra düzeltme aramayı tazeler', () {
      final r = flow.handleText(
        'sadece izmir olsun',
        draft: ready,
        step: ChatStep.done,
      );
      expect(r.effect, ChatEffect.search);
      expect(r.draft.cityIds, {'35'});
      expect(r.step, ChatStep.done);
    });
  });

  group('çoklu bölüm odağı', () {
    const base = ChatDraft(
      scoreType: 'SAY',
      rank: 80000,
      constraintsDone: true,
    );

    test('iki bölüm → odak sorusu çipleri', () {
      final r = flow.handleText(
        'psikoloji ve hukuk düşünüyorum',
        draft: base,
        step: ChatStep.interests,
      );
      expect(r.step, ChatStep.confirm);
      expect(r.messages.last.id, 'chat.focus');
      expect(r.chips.map((c) => c.label),
          containsAll(['Psikoloji', 'Hukuk', 'Hepsi']));
    });

    test('odak seçimi tek bölüme indirir', () {
      final asked = flow.handleText(
        'psikoloji ve hukuk',
        draft: base,
        step: ChatStep.interests,
      );
      final focusChip =
          asked.chips.firstWhere((c) => c.label == 'Psikoloji');
      final r = flow.handleChip(focusChip,
          draft: asked.draft, step: asked.step);
      expect(r.draft.depts.single.label, 'Psikoloji');
      expect(r.draft.filterDeptQuery, 'psikoloji');
      expect(r.messages.last.id, 'chat.confirm');
    });

    test('Hepsi → filtre sorgusu boş kalır (kategoriler tümünü gösterir)',
        () {
      final asked = flow.handleText(
        'psikoloji ve hukuk',
        draft: base,
        step: ChatStep.interests,
      );
      final r = flow.handleChip(
        asked.chips.firstWhere((c) => c.label == 'Hepsi'),
        draft: asked.draft,
        step: asked.step,
      );
      expect(r.draft.filterDeptQuery, isEmpty);
      expect(r.messages.last.id, 'chat.confirm');
    });
  });

  group('dönen kullanıcı', () {
    test('profil özeti + hızlı yol çipleri', () {
      final r = flow.start(profile: profile, prefs: const WizardPrefs());
      expect(r.step, ChatStep.greeting);
      expect(r.messages.single.id, 'chat.hello.back');
      expect(r.messages.single.text, contains('SAY'));
      expect(r.messages.single.text, contains('45.000'));
      expect(r.chips.map((c) => c.label),
          ['Sonuçlara geç', 'Bilgilerimi güncelle', 'Baştan başla']);
    });

    test('Sonuçlara geç → goResults etkisi', () {
      final start = flow.start(profile: profile);
      final r = flow.handleChip(
        chipLabeled(start.chips, 'Sonuçlara geç'),
        draft: start.draft,
        step: start.step,
      );
      expect(r.effect, ChatEffect.goResults);
    });

    test('Bilgilerimi güncelle → dolu taslakla onay özeti', () {
      final start = flow.start(profile: profile);
      final r = flow.handleChip(
        chipLabeled(start.chips, 'Bilgilerimi güncelle'),
        draft: start.draft,
        step: start.step,
      );
      expect(r.messages.first.id, 'chat.update');
      expect(r.messages.last.id, 'chat.confirm');
      expect(r.messages.last.text, contains('45.000'));
    });

    test('Baştan başla taslağı sıfırlar', () {
      final start = flow.start(profile: profile);
      final r = flow.handleChip(
        chipLabeled(start.chips, 'Baştan başla'),
        draft: start.draft,
        step: start.step,
      );
      expect(r.draft.scoreType, isNull);
      expect(r.messages.first.id, 'chat.restart');
      expect(r.messages.last.id, 'chat.ask.type');
    });

    test('serbest güncelleme onaya taşır ("sıralamam 90 bin oldu")', () {
      final start = flow.start(profile: profile);
      final r = flow.handleText(
        'sıralamam 90 bin oldu',
        draft: start.draft,
        step: start.step,
      );
      expect(r.draft.rank, 90000);
      expect(r.messages.last.id, 'chat.confirm');
    });
  });

  group('kalıcı modellere köprüler', () {
    const draft = ChatDraft(
      scoreType: 'SAY',
      rank: 80000,
      cityIds: {'34'},
      uniTypes: {'Devlet'},
      languages: {'İngilizce'},
      onlyScholarship: true,
      depts: [],
      interestKeys: {'psikoloji'},
      interestsDone: true,
      constraintsDone: true,
    );

    test('profil: yalnız sıralamayla girişte puan 0 (mevcut davranış)', () {
      final p = draft.buildProfile(DateTime(2026, 7, 19));
      expect(p.scoreType, 'SAY');
      expect(p.rank, 80000);
      expect(p.placementScore, 0);
      expect(p.year, 2026);
    });

    test('prefs: şehir + tür + ilgi anahtarları (yumuşak sinyal)', () {
      final prefs = draft.buildPrefs();
      expect(prefs.cityIds, {'34'});
      expect(prefs.uniTypes, {'Devlet'});
      expect(prefs.interestKeys, {'psikoloji'});
    });

    test('filtre: ücretsizde yalnız deptQuery, Plus\'ta tümü', () {
      const withDept = ChatDraft(
        scoreType: 'SAY',
        rank: 80000,
        cityIds: {'34'},
        languages: {'İngilizce'},
        depts: [DeptIntent(label: 'Psikoloji', query: 'psikoloji')],
      );
      final free = withDept.buildFilter(hasPlus: false);
      expect(free.deptQuery, 'psikoloji');
      expect(free.cityIds, isEmpty);
      expect(free.languages, isEmpty);

      final plus = withDept.buildFilter(hasPlus: true);
      expect(plus.deptQuery, 'psikoloji');
      expect(plus.cityIds, {'34'});
      expect(plus.languages, {'İngilizce'});
    });
  });
}
