import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/uni_flow.dart';
import 'package:uni_app/features/assistant/presentation/flow/steps/flow_list_steps.dart';
import 'package:uni_app/features/assistant/presentation/flow/uni_flow_controller.dart';
import 'package:uni_app/features/preference_wizard/domain/preference_match_engine.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';

/// Akışın omurgası: hangi yoldan gidilirse hangi ekranlar görülür.
///
/// Adım listesi SABİT DEĞİL — giriş yolundan türer. Sıralamasını bilen
/// öğrenciye üç net ekranı göstermek akışın vaadini bozar.
void main() {
  group('adım listesi', () {
    test('net yolu: karşılama + üç giriş + puan + dört adım + kapanış', () {
      final steps = uniFlowSteps(entryMode: NetEntryMode.correctWrong);

      expect(steps, [
        UniFlowStep.start,
        UniFlowStep.tytNets,
        UniFlowStep.aytNets,
        UniFlowStep.obp,
        UniFlowStep.reveal,
        UniFlowStep.targetDept,
        UniFlowStep.interests,
        UniFlowStep.cities,
        UniFlowStep.buildList,
        UniFlowStep.done,
      ]);
    });

    test('doğrudan net girişi de aynı yolu yürür', () {
      expect(
        uniFlowSteps(entryMode: NetEntryMode.directNet),
        uniFlowSteps(entryMode: NetEntryMode.correctWrong),
      );
    });

    test('sıra yolu net ve OBP ekranlarını atlar', () {
      final steps = uniFlowSteps(entryMode: NetEntryMode.rank);

      expect(steps.contains(UniFlowStep.rank), isTrue);
      expect(steps.contains(UniFlowStep.tytNets), isFalse);
      expect(steps.contains(UniFlowStep.aytNets), isFalse);
      expect(steps.contains(UniFlowStep.obp), isFalse);
      // Üç net ekranı yerine tek sıra ekranı: 10 → 8.
      expect(steps.length, 8);
    });

    test('puan yolu sıra yolunun aynadaki eşi', () {
      final steps = uniFlowSteps(entryMode: NetEntryMode.score);

      expect(steps.contains(UniFlowStep.score), isTrue);
      expect(steps.contains(UniFlowStep.rank), isFalse);
      expect(steps.length, 8);
    });

    test('rotadaki ?step= adıma çevrilir', () {
      expect(uniFlowStepFromQuery('interests'), UniFlowStep.interests);
      expect(uniFlowStepFromQuery('cities'), UniFlowStep.cities);
      expect(uniFlowStepFromQuery('list'), UniFlowStep.buildList);
      // Tanınmayan değer akışı baştan başlatır, patlatmaz.
      expect(uniFlowStepFromQuery('saçma'), isNull);
      expect(uniFlowStepFromQuery(null), isNull);
    });

    test('tek adım düzenleme modunda yol tek ekrandır', () {
      final steps = uniFlowSteps(
        entryMode: NetEntryMode.correctWrong,
        mode: UniFlowMode.editOne,
        only: UniFlowStep.cities,
      );

      expect(steps, [UniFlowStep.cities]);
    });
  });

  group('atlanabilirlik', () {
    test('puan adımları atlanamaz — akışın çıktısı onlara bağlı', () {
      for (final step in const [
        UniFlowStep.start,
        UniFlowStep.tytNets,
        UniFlowStep.aytNets,
        UniFlowStep.obp,
        UniFlowStep.rank,
        UniFlowStep.score,
        UniFlowStep.reveal,
      ]) {
        expect(step.skippable, isFalse, reason: '$step atlanabilir olmamalı');
        expect(step.isScorePart, isTrue);
      }
    });

    test('puandan sonraki adımlar atlanabilir', () {
      for (final step in const [
        UniFlowStep.targetDept,
        UniFlowStep.interests,
        UniFlowStep.cities,
        UniFlowStep.buildList,
      ]) {
        expect(step.skippable, isTrue, reason: '$step atlanabilmeli');
      }
    });
  });

  group('gezinme', () {
    UniFlowController controller({
      NetEntryMode entryMode = NetEntryMode.correctWrong,
    }) {
      final c = UniFlowController(entryMode: entryMode);
      addTearDown(c.dispose);
      return c;
    }

    test('ileri geri gider, uçlarda takılmaz', () {
      final c = controller();

      expect(c.state.current, UniFlowStep.start);
      expect(c.state.isFirst, isTrue);

      c.back(); // ilk adımda geri = hiçbir şey
      expect(c.state.index, 0);

      c.next();
      expect(c.state.current, UniFlowStep.tytNets);
      c.back();
      expect(c.state.current, UniFlowStep.start);

      for (var i = 0; i < 20; i++) {
        c.next();
      }
      expect(c.state.current, UniFlowStep.done);
      expect(c.state.isLast, isTrue);
    });

    test('ilerleme oranı adım sayısına göre', () {
      final c = controller();

      expect(c.state.progress, closeTo(0.1, 0.001)); // 1/10
      c.next();
      expect(c.state.progress, closeTo(0.2, 0.001));
    });

    test('yol seçimi değişince kalan adımlar yeniden türer', () {
      final c = controller();
      expect(c.state.steps.length, 10);

      c.syncEntryMode(NetEntryMode.rank);

      expect(c.state.steps.length, 8);
      expect(c.state.current, UniFlowStep.start, reason: 'ilk adımda kalır');
    });

    test('yol ortasında mod değişimi adımları BOZMAZ', () {
      final c = controller();
      c.next(); // tytNets

      c.syncEntryMode(NetEntryMode.rank);

      // Adım listesi değişseydi kullanıcı bulunduğu ekrandan düşerdi.
      expect(c.state.steps.length, 10);
      expect(c.state.current, UniFlowStep.tytNets);
    });

    test('yön bilgisi hareketi izler', () {
      final c = controller();

      c.next();
      expect(c.state.forward, isTrue);
      c.back();
      // Geçiş animasyonu buna bakıyor: geri dönerken ekran soldan gelmeli.
      expect(c.state.forward, isFalse);
      c.jumpTo(UniFlowStep.cities);
      expect(c.state.forward, isTrue);
    });

    test('jumpTo yoldaki adıma gider, yoldaki olmayanı yok sayar', () {
      final c = controller();

      c.jumpTo(UniFlowStep.cities);
      expect(c.state.current, UniFlowStep.cities);

      c.jumpTo(UniFlowStep.rank); // net yolunda böyle bir adım yok
      expect(c.state.current, UniFlowStep.cities);
    });
  });

  // ═════════════════════════════════════════════════════════════
  //  Taslak liste
  //
  //  Akış artık program program "ekle/geç" sormuyor: 24'lük bir taslak
  //  kuruyor, öğrenci beğenmediğini eliyor. Taslağın DENGESİ burada
  //  kilitleniyor — tek renk bir liste (hepsi garanti) sağlıklı bir tercih
  //  listesi değildir.
  // ═════════════════════════════════════════════════════════════
  group('taslak liste', () {
    test('bol veride üç bant da kotasınca temsil edilir', () {
      final draft = buildDraftList(_result(dream: 30, target: 30, safe: 30));

      expect(draft.length, kListCapacity);
      expect(_countOf(draft, MatchCategory.dream), 6);
      expect(_countOf(draft, MatchCategory.target), 10);
      expect(_countOf(draft, MatchCategory.guaranteed), 8);
    });

    test('taslak zorlayıcıdan güvenliye doğru sıralanır', () {
      final draft = buildDraftList(_result(dream: 30, target: 30, safe: 30));

      final bands = draft.map((m) => m.category).toList();
      expect(
        bands,
        [
          ...List.filled(6, MatchCategory.dream),
          ...List.filled(10, MatchCategory.target),
          ...List.filled(8, MatchCategory.guaranteed),
        ],
      );
    });

    test('bir bant yetmezse boşluk diğerlerine dağılır', () {
      // Hiç zorlayıcı program yok: 24 hak yine de dolmalı.
      final draft = buildDraftList(_result(dream: 0, target: 30, safe: 30));

      expect(draft.length, kListCapacity);
      expect(_countOf(draft, MatchCategory.dream), 0);
      expect(_countOf(draft, MatchCategory.target), greaterThan(10));
    });

    test('toplam program kapasitenin altındaysa hepsi girer', () {
      final draft = buildDraftList(_result(dream: 1, target: 2, safe: 3));

      expect(draft.length, 6);
    });

    test('aynı program iki kez girmez', () {
      final draft = buildDraftList(_result(dream: 30, target: 30, safe: 30));

      expect(
        draft.map((m) => m.department.id).toSet().length,
        draft.length,
      );
    });
  });
}

int _countOf(List<UniversityMatch> draft, MatchCategory band) =>
    draft.where((m) => m.category == band).length;

PreferenceMatchResult _result({
  required int dream,
  required int target,
  required int safe,
}) {
  return PreferenceMatchResult(
    guaranteed: _matches(MatchCategory.guaranteed, safe),
    target: _matches(MatchCategory.target, target),
    dream: _matches(MatchCategory.dream, dream),
  );
}

List<UniversityMatch> _matches(MatchCategory band, int count) => [
      for (var i = 0; i < count; i++) _match('${band.name}-$i', band),
    ];

UniversityMatch _match(String id, MatchCategory band) {
  return UniversityMatch(
    department: DepartmentModel(
      id: id,
      universityId: 'u-$id',
      name: 'Bölüm $id',
      faculty: 'Fakülte',
      type: 'Lisans',
      language: 'Türkçe',
    ),
    university: UniversityModel(
      id: 'u-$id',
      cityId: '34',
      name: 'Üniversite $id',
      type: 'Devlet',
      hasCampus: true,
      logoUrl: '',
      photoUrl: '',
      description: '',
      establishedYear: 1990,
      website: '',
    ),
    category: band,
    departmentBaseScore: 450,
    departmentRanking: 45000,
    scoreDifference: 5,
  );
}
