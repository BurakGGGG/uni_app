import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/insights/insight_context.dart';
import 'package:uni_app/features/assistant/domain/insights/insight_engine.dart';
import 'package:uni_app/features/assistant/domain/insights/uni_insight.dart';
import 'package:uni_app/features/assistant/domain/robot_message.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/assistant/domain/tercih_calendar.dart';
import 'package:uni_app/features/practice_exams/domain/models/exam_target.dart';
import 'package:uni_app/features/practice_exams/domain/models/practice_exam.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/domain/models/yks_subject.dart';

// ── Kurucu yardımcılar ────────────────────────────────────────────

StudentScoreProfile _profile({String type = 'SAY', double score = 430}) =>
    StudentScoreProfile(
      scoreType: type,
      placementScore: score,
      year: 2026,
      updatedAt: DateTime(2026, 3, 1),
    );

/// Netleri doğrudan verilen bir SAY denemesi. Sıra motorda ÖSYM dağılımıyla
/// yeniden hesaplandığı için (`trendFor(year:)`) snapshot'a değil netlere
/// bakılır — testler de öyle kurar.
PracticeExam _exam({
  required String id,
  required DateTime takenAt,
  Map<YksSubject, double> nets = const {},
  bool deleted = false,
}) {
  final input = ScoreInput(
    selectedYear: 2026,
    scoreType: 'SAY',
    obpScore: 80,
    selectedDepartment: '',
    entryMode: NetEntryMode.directNet,
    directNets: nets,
  );
  return PracticeExam(
    id: id,
    takenAt: takenAt,
    createdAt: takenAt,
    updatedAt: takenAt,
    name: 'Deneme $id',
    kind: PracticeExamKind.genel,
    year: 2026,
    input: input,
    results: const [
      TypeScoreSnapshot(
        scoreType: 'SAY',
        rawScore: 300,
        placementScore: 400,
      ),
    ],
    deleted: deleted,
  );
}

Map<YksSubject, double> _nets({
  double tytMat = 20,
  double tytTurkce = 25,
  double tytFen = 10,
  double tytSosyal = 10,
  double aytMat = 15,
  double aytFizik = 7,
  double aytKimya = 7,
  double aytBiyo = 7,
}) =>
    {
      YksSubject.tytMat: tytMat,
      YksSubject.tytTurkce: tytTurkce,
      YksSubject.tytFen: tytFen,
      YksSubject.tytSosyal: tytSosyal,
      YksSubject.aytMat: aytMat,
      YksSubject.aytFizik: aytFizik,
      YksSubject.aytKimya: aytKimya,
      YksSubject.aytBiyo: aytBiyo,
    };

ExamTarget _target({int rank = 8000, String name = 'Bilgisayar Müh.'}) =>
    ExamTarget(
      departmentId: 'd1',
      departmentName: name,
      universityName: 'Boğaziçi',
      scoreType: 'SAY',
      targetRank: rank,
      targetScore: 480,
      setAt: DateTime(2026, 1, 1),
    );

/// Sezon dışı bir gün — takvim ailesi karışmasın diye çoğu test bunu kullanır.
final _offSeason = DateTime(2026, 2, 10, 15);

Set<String> _ids(List<UniInsight> insights) =>
    insights.map((i) => i.id).toSet();

UniInsight? _find(List<UniInsight> insights, String id) {
  for (final i in insights) {
    if (i.id == id) return i;
  }
  return null;
}

void main() {
  // Dil global bir anahtar; sızmasın.
  tearDown(() => RobotScripts.languageCode = 'tr');

  group('kurulum yolu', () {
    test('boş bağlamda yalnız ilk eksik adım yayılır', () {
      final insights = InsightEngine.analyze(InsightContext(now: _offSeason));
      final setup = insights.where((i) => i.kind == InsightKind.setup);

      expect(setup.length, 1);
      expect(setup.first.id, 'setup.noProfile');
      expect(setup.first.action, RobotAction.openScoreCalculator);
      expect(setup.first.dismissible, isFalse,
          reason: 'eksik adım kapatmakla tamamlanmaz');
    });

    test('profil varsa sıra denemeye geçer', () {
      final withProfile = InsightContext(
        now: _offSeason,
        profile: _profile(),
      );
      final next = InsightEngine.analyze(withProfile);
      expect(_find(next, 'setup.noExam'), isNotNull);
      expect(_find(next, 'setup.noProfile'), isNull);
    });

    // Hedef, kurulum şartı DEĞİL. Puanı ve tek denemesi olmayan kişiden
    // "hedef program seç" istemek ona henüz cevaplayamayacağı bir soru
    // sormaktır; davet ancak ölçebildiğim şey varken anlamlı.
    test('hedef daveti kurulum bitmeden çıkmaz', () {
      final beforeExam = InsightContext(
        now: _offSeason,
        profile: _profile(),
      );
      expect(_find(InsightEngine.analyze(beforeExam), 'setup.noTarget'),
          isNull);

      final afterExam = InsightContext(
        now: _offSeason,
        profile: _profile(),
        exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
      );
      final invite = _find(InsightEngine.analyze(afterExam), 'setup.noTarget');
      expect(invite, isNotNull);
      expect(invite!.action, RobotAction.setTarget);
      expect(InsightEngine.setupPathOf(afterExam).complete, isTrue,
          reason: 'hedef kurulum sayacına girmez');
    });

    test('ikisi tamamlanınca kurulum ailesi tamamen susar', () {
      final ctx = InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
      );
      final insights = InsightEngine.analyze(ctx);

      expect(insights.where((i) => i.kind == InsightKind.setup), isEmpty);
      expect(InsightEngine.setupPathOf(ctx).complete, isTrue);
      expect(InsightEngine.setupPathOf(ctx).done, 2);
    });

    test('silinmiş deneme kurulumu tamamlamaz', () {
      final ctx = InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: _target(),
        exams: [
          _exam(
            id: 'a',
            takenAt: _offSeason,
            nets: _nets(),
            deleted: true,
          ),
        ],
      );
      expect(InsightEngine.setupPathOf(ctx).hasExam, isFalse);
      expect(_find(InsightEngine.analyze(ctx), 'setup.noExam'), isNotNull);
    });
  });

  group('hedef', () {
    test('hedefin üstündeki sıra kutlama üretir, yön notu üretmez', () {
      // Çok yüksek netler → hedef sıranın (400.000) rahatça üstünde.
      final ctx = InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: _target(rank: 400000),
        exams: [
          _exam(
            id: 'a',
            takenAt: DateTime(2026, 2, 1),
            nets: _nets(aytMat: 35, aytFizik: 12, aytKimya: 12, aytBiyo: 12),
          ),
        ],
      );
      final insights = InsightEngine.analyze(ctx);

      expect(_find(insights, 'target.reached'), isNotNull);
      expect(_find(insights, 'target.closing'), isNull);
      expect(_find(insights, 'target.drifting'), isNull);
    });

    test('netler yükselirken "yaklaşıyorsun", düşerken "geriliyor" der', () {
      List<PracticeExam> series(bool improving) => [
            _exam(
              id: 'eski',
              takenAt: DateTime(2026, 1, 10),
              nets: _nets(aytMat: improving ? 8 : 30),
            ),
            _exam(
              id: 'yeni',
              takenAt: DateTime(2026, 2, 8),
              nets: _nets(aytMat: improving ? 30 : 8),
            ),
          ];

      final up = InsightEngine.analyze(InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: _target(rank: 1000),
        exams: series(true),
      ));
      expect(_find(up, 'target.closing'), isNotNull);
      expect(_find(up, 'target.drifting'), isNull);

      final down = InsightEngine.analyze(InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: _target(rank: 1000),
        exams: series(false),
      ));
      expect(_find(down, 'target.drifting'), isNotNull);
      expect(_find(down, 'target.closing'), isNull);
    });

    test('hedef sırası yoksa hedef ailesi hiç çalışmaz', () {
      final noRank = ExamTarget(
        departmentId: 'd1',
        departmentName: 'X',
        universityName: 'Y',
        scoreType: 'SAY',
        setAt: DateTime(2026, 1, 1),
      );
      final insights = InsightEngine.analyze(InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: noRank,
        exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
      ));
      expect(insights.where((i) => i.kind == InsightKind.target), isEmpty);
    });
  });

  group('gelişim', () {
    test('21 günden eski defter "sessiz" sayılır', () {
      final ctx = InsightContext(
        now: DateTime(2026, 3, 1),
        profile: _profile(),
        exams: [
          _exam(id: 'a', takenAt: DateTime(2026, 2, 1), nets: _nets()),
        ],
      );
      final stale = _find(InsightEngine.analyze(ctx), 'progress.stale');
      expect(stale, isNotNull);
      expect(stale!.body, contains('28'));
    });

    test('taze defterde sessizlik notu çıkmaz', () {
      final ctx = InsightContext(
        now: DateTime(2026, 2, 10),
        profile: _profile(),
        exams: [
          _exam(id: 'a', takenAt: DateTime(2026, 2, 8), nets: _nets()),
        ],
      );
      expect(_find(InsightEngine.analyze(ctx), 'progress.stale'), isNull);
    });

    test('ders ortalaması sıçrayınca yükseliş, çökünce düşüş notu', () {
      // subjectStats penceresi 5: son 5 deneme "şimdi", önceki 5 "referans".
      final exams = <PracticeExam>[
        for (var i = 0; i < 5; i++)
          _exam(
            id: 'eski$i',
            takenAt: DateTime(2026, 1, i + 1),
            nets: _nets(aytFizik: 3, aytKimya: 10),
          ),
        for (var i = 0; i < 5; i++)
          _exam(
            id: 'yeni$i',
            takenAt: DateTime(2026, 2, i + 1),
            nets: _nets(aytFizik: 10, aytKimya: 3),
          ),
      ];
      final insights = InsightEngine.analyze(InsightContext(
        now: DateTime(2026, 2, 6),
        profile: _profile(),
        exams: exams,
      ));

      final jump = _find(insights, 'progress.jump');
      final drop = _find(insights, 'progress.drop');
      expect(jump, isNotNull);
      expect(jump!.title, contains('Fizik'));
      expect(drop, isNotNull);
      expect(drop!.title, contains('Kimya'));
    });

    test('haftalık seri 2 haftadan itibaren kutlanır', () {
      final now = DateTime(2026, 2, 12); // Perşembe
      final exams = [
        _exam(id: 'buHafta', takenAt: DateTime(2026, 2, 10), nets: _nets()),
        _exam(id: 'gecenHafta', takenAt: DateTime(2026, 2, 3), nets: _nets()),
      ];
      final streak = _find(
        InsightEngine.analyze(
          InsightContext(now: now, profile: _profile(), exams: exams),
        ),
        'progress.streak',
      );
      expect(streak, isNotNull);
      expect(streak!.body, isNotEmpty);
    });
  });

  group('liste', () {
    ListSnapshot snap({
      int items = 10,
      int guaranteed = 3,
      int target = 4,
      int dream = 3,
      String? city,
      int cityCount = 0,
    }) =>
        ListSnapshot(
          listId: 'l1',
          title: 'Listem',
          itemCount: items,
          guaranteed: guaranteed,
          target: target,
          dream: dream,
          topCityName: city,
          topCityCount: cityCount,
        );

    InsightContext ctxWith(List<ListSnapshot> lists, {DateTime? now}) =>
        InsightContext(
          now: now ?? _offSeason,
          profile: _profile(),
          target: _target(),
          exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
          lists: lists,
        );

    test('liste yoksa boş-liste notu çıkar', () {
      final insights = InsightEngine.analyze(ctxWith(const []));
      expect(_find(insights, 'list.empty'), isNotNull);
    });

    test('güvenli tercih yoksa uyarır', () {
      final insights = InsightEngine.analyze(
        ctxWith([snap(guaranteed: 0, target: 5, dream: 5, items: 10)]),
      );
      final note = _find(insights, 'list.noSafe');
      expect(note, isNotNull);
      expect(note!.body, contains('10'));
      expect(_find(insights, 'list.tooRisky'), isNull,
          reason: 'iki uyarı aynı anda verilmez — biri diğerini kapsar');
    });

    test('yarıdan fazlası zorlayıcıysa iddialı uyarısı', () {
      final insights = InsightEngine.analyze(
        ctxWith([snap(guaranteed: 1, target: 1, dream: 5, items: 7)]),
      );
      expect(_find(insights, 'list.tooRisky'), isNotNull);
    });

    test('tercih dönemi liste uyarılarını öne fırlatır', () {
      final lists = [snap(guaranteed: 0, target: 5, dream: 5, items: 10)];

      final off = _find(
        InsightEngine.analyze(ctxWith(lists)),
        'list.noSafe',
      )!;
      final inSeason = _find(
        InsightEngine.analyze(
          ctxWith(lists, now: DateTime(2026, 7, 20)),
        ),
        'list.noSafe',
      )!;

      expect(inSeason.priority, greaterThan(off.priority));
      expect(inSeason.tone, InsightTone.urgent);
    });

    test('ilk 5 tercihte şehir yığılması uyarılır', () {
      final insights = InsightEngine.analyze(
        ctxWith([snap(city: 'İstanbul', cityCount: 4)]),
      );
      final note = _find(insights, 'list.cityConcentration');
      expect(note, isNotNull);
      expect(note!.body, contains('İstanbul'));
    });

    test('24 tercih dolunca tamamlama notu çıkmaz', () {
      final insights = InsightEngine.analyze(
        ctxWith([snap(items: 24, guaranteed: 8, target: 8, dream: 8)]),
      );
      expect(_find(insights, 'list.incomplete'), isNull);
    });
  });

  group('ÖSYM verisi', () {
    TrackedProgram prog({double? delta, double? fill}) => TrackedProgram(
          departmentId: 'd1',
          departmentName: 'Bilgisayar Müh.',
          universityName: 'ODTÜ',
          baseScoreDelta: delta,
          fillRate: fill,
        );

    test('taban düşüşü olumlu, yükselişi uyarı tonuyla gelir', () {
      final down = _find(
        InsightEngine.analyze(InsightContext(
          now: _offSeason,
          profile: _profile(),
          target: _target(),
          exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
          tracked: [prog(delta: -6)],
        )),
        'data.baseTrendDown',
      );
      expect(down, isNotNull);
      expect(down!.tone, InsightTone.positive);
      expect(down.body, contains('6,0'));

      final up = _find(
        InsightEngine.analyze(InsightContext(
          now: _offSeason,
          profile: _profile(),
          target: _target(),
          exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
          tracked: [prog(delta: 8)],
        )),
        'data.baseTrendUp',
      );
      expect(up, isNotNull);
      expect(up!.tone, InsightTone.warning);
    });

    test('eşiğin altındaki oynama not üretmez', () {
      final insights = InsightEngine.analyze(InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
        tracked: [prog(delta: 1.2, fill: 1.0)],
      ));
      expect(insights.where((i) => i.kind == InsightKind.data), isEmpty);
    });

    test('dolmayan kontenjan not üretir', () {
      final note = _find(
        InsightEngine.analyze(InsightContext(
          now: _offSeason,
          profile: _profile(),
          target: _target(),
          exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
          tracked: [prog(fill: 0.72)],
        )),
        'data.lowFillRate',
      );
      expect(note, isNotNull);
      expect(note!.body, contains('72'));
    });
  });

  group('takvim', () {
    test('tercih döneminde geri sayım en üstte durur', () {
      final insights = InsightEngine.analyze(InsightContext(
        now: DateTime(2026, 8, 3),
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 8, 1), nets: _nets())],
      ));
      final note = _find(insights, 'calendar.tercihCountdown');
      expect(note, isNotNull);
      expect(note!.title, contains('2'), reason: '5 Ağustos - 3 Ağustos');
      expect(note.tone, InsightTone.urgent);
      expect(note.dismissible, isFalse);
    });

    test('sezon dışında takvim ailesi susar', () {
      final insights = InsightEngine.analyze(InsightContext(
        now: _offSeason,
        profile: _profile(),
        target: _target(),
        exams: [_exam(id: 'a', takenAt: _offSeason, nets: _nets())],
      ));
      expect(insights.where((i) => i.kind == InsightKind.calendar), isEmpty);
    });
  });

  group('sıralama ve metin', () {
    test('öncelik azalan, eşitlikte id alfabetik', () {
      final insights = InsightEngine.analyze(InsightContext(
        now: DateTime(2026, 7, 20),
        profile: _profile(),
        exams: [_exam(id: 'a', takenAt: DateTime(2026, 7, 18), nets: _nets())],
        lists: const [
          ListSnapshot(
            listId: 'l1',
            title: 'Listem',
            itemCount: 8,
            guaranteed: 0,
            target: 4,
            dream: 4,
          ),
        ],
      ));

      for (var i = 1; i < insights.length; i++) {
        final prev = insights[i - 1];
        final cur = insights[i];
        expect(prev.priority >= cur.priority, isTrue);
        if (prev.priority == cur.priority) {
          expect(prev.id.compareTo(cur.id) <= 0, isTrue);
        }
      }
    });

    test('hiçbir notta doldurulmamış yer tutucu kalmaz', () {
      for (final lang in ['tr', 'en']) {
        RobotScripts.languageCode = lang;
        final insights = InsightEngine.analyze(InsightContext(
          now: DateTime(2026, 7, 20),
          profile: _profile(),
          target: _target(rank: 1000),
          exams: [
            for (var i = 0; i < 6; i++)
              _exam(
                id: 'e$i',
                takenAt: DateTime(2026, 6, i + 1),
                nets: _nets(aytFizik: i.toDouble()),
              ),
          ],
          lists: const [
            ListSnapshot(
              listId: 'l1',
              title: 'Listem',
              itemCount: 6,
              guaranteed: 0,
              target: 3,
              dream: 3,
              topCityName: 'İzmir',
              topCityCount: 4,
            ),
          ],
          tracked: const [
            TrackedProgram(
              departmentId: 'd1',
              departmentName: 'Tıp',
              universityName: 'Ege',
              baseScoreDelta: -7,
              fillRate: 0.6,
            ),
          ],
        ));

        expect(insights, isNotEmpty, reason: '$lang için not üretilmedi');
        for (final i in insights) {
          expect(i.title, isNot(contains('{')), reason: '${i.id} ($lang)');
          expect(i.body, isNot(contains('{')), reason: '${i.id} ($lang)');
        }
      }
    });

    test('not id\'leri iki dilde birebir aynı', () {
      RobotScripts.languageCode = 'tr';
      final tr = RobotScripts.insightIds.toSet();
      RobotScripts.languageCode = 'en';
      final en = RobotScripts.insightIds.toSet();
      expect(en, tr);
    });

    test('eylemi olan her notun buton etiketi var', () {
      final insights = InsightEngine.analyze(InsightContext(
        now: DateTime(2026, 7, 20),
      ));
      for (final i in insights.where((i) => i.hasAction)) {
        expect(i.actionLabel, isNotNull, reason: i.id);
        expect(i.actionLabel, isNotEmpty, reason: i.id);
      }
    });
  });

  group('takvim yardımcıları', () {
    test('faz bitişine kalan gün', () {
      expect(daysLeftInPhase(DateTime(2026, 8, 5)), 0);
      expect(daysLeftInPhase(DateTime(2026, 7, 30)), 6);
      expect(daysLeftInPhase(DateTime(2026, 2, 1)), isNull);
    });

    test('faz bitiş tarihi fazla eşleşir', () {
      expect(phaseEndFor(DateTime(2026, 7, 20)), DateTime(2026, 8, 5));
      expect(phaseEndFor(DateTime(2026, 5, 20)), DateTime(2026, 6, 13));
      expect(phaseEndFor(DateTime(2026, 12, 1)), isNull);
    });
  });

  test('id kümesi metin tablosuyla örtüşür', () {
    // Motorun ürettiği her id tabloda var mı? (_build zaten fırlatır ama
    // aile bazlı taramada gözden kaçan dal olabilir.)
    final produced = _ids(InsightEngine.analyze(InsightContext(
      now: DateTime(2026, 7, 20),
      profile: _profile(),
      target: _target(rank: 1),
      exams: [_exam(id: 'a', takenAt: DateTime(2026, 7, 18), nets: _nets())],
    )));
    expect(produced.every(RobotScripts.insightIds.contains), isTrue);
  });
}
