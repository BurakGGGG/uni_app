import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/robot_brain.dart';
import 'package:uni_app/features/assistant/domain/robot_enrichment.dart';
import 'package:uni_app/features/assistant/domain/robot_message_source.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';

/// Sahte istemci — çağrı sayısını ve son girdileri kaydeder.
class _FakeClient implements RobotEnrichmentClient {
  final RobotEnrichment? result;
  final bool throws;
  int calls = 0;
  Map<String, String>? lastTags;
  List<RobotEnrichCandidate>? lastCandidates;

  _FakeClient({this.result, this.throws = false});

  @override
  Future<RobotEnrichment?> enrich({
    required Map<String, String> userTags,
    required List<RobotEnrichCandidate> candidates,
  }) async {
    calls++;
    lastTags = userTags;
    lastCandidates = candidates;
    if (throws) throw Exception('ağ hatası');
    return result;
  }
}

UniversityMatch _match({
  String deptId = 'd1',
  String uniId = 'u1',
  MatchCategory category = MatchCategory.guaranteed,
}) {
  return UniversityMatch(
    department: DepartmentModel(
      id: deptId,
      universityId: uniId,
      name: 'Bilgisayar Mühendisliği',
      faculty: 'Mühendislik Fakültesi',
      type: 'Lisans',
      language: 'Türkçe',
    ),
    university: UniversityModel(
      id: uniId,
      cityId: 'ist',
      name: 'Test Üniversitesi',
      type: 'Devlet',
      hasCampus: true,
      logoUrl: '',
      photoUrl: '',
      description: '',
      establishedYear: 1990,
      website: '',
    ),
    category: category,
    departmentBaseScore: 450,
    departmentRanking: 45000,
    scoreDifference: 10,
    fitScore: 80,
  );
}

void main() {
  const balancedCtx = ResultsContext(
    guaranteed: 3,
    target: 4,
    dream: 2,
    scoreType: 'SAY',
    rank: 45000,
  );
  const riskyCtx = ResultsContext(guaranteed: 0, target: 1, dream: 4);

  group('RuleBasedMessageSource', () {
    test('kural mesajını boş notlarla döner', () async {
      const source = RuleBasedMessageSource();
      final summary = await source.resultsSummary(balancedCtx);
      expect(summary.message.text,
          RobotBrain.resultsSummary(balancedCtx).text);
      expect(summary.notes, isEmpty);
    });
  });

  group('LlmEnrichedMessageSource', () {
    test('LLM özeti balon metni olur, mood kuraldan gelir', () async {
      final client = _FakeClient(
        result: const RobotEnrichment(
          summary: 'Sıralaman mühendislik için gayet uygun görünüyor.',
          notes: {'u1_d1': 'Sayısal profilinle güçlü bir eşleşme.'},
        ),
      );
      final source = LlmEnrichedMessageSource(client);
      final summary = await source
          .resultsSummary(riskyCtx, topMatches: [_match()]);

      expect(summary.message.id, 'results.llm');
      expect(summary.message.text,
          'Sıralaman mühendislik için gayet uygun görünüyor.');
      // Riskli bağlamda mood kuraldan (concerned) gelir — LLM mood seçemez.
      expect(summary.message.mood,
          RobotBrain.resultsSummary(riskyCtx).mood);
      expect(summary.notes['u1_d1'],
          'Sayısal profilinle güçlü bir eşleşme.');
    });

    test('istemci hata fırlatırsa sessizce kural metnine düşer', () async {
      final client = _FakeClient(throws: true);
      final source = LlmEnrichedMessageSource(client);
      final summary = await source
          .resultsSummary(balancedCtx, topMatches: [_match()]);

      expect(summary.message.text,
          RobotBrain.resultsSummary(balancedCtx).text);
      // Varyant güne göre döner (RobotBrain.pick) — büyük/küçük harf değişir.
      expect(summary.message.text.toLowerCase(), contains('tahmin'));
      expect(summary.notes, isEmpty);
    });

    test('istemci null dönerse kural metnine düşer', () async {
      final client = _FakeClient(result: null);
      final source = LlmEnrichedMessageSource(client);
      final summary = await source
          .resultsSummary(balancedCtx, topMatches: [_match()]);

      expect(client.calls, 1);
      expect(summary.message.text,
          RobotBrain.resultsSummary(balancedCtx).text);
    });

    test('boş özet geçersizdir — kural metnine düşer', () async {
      final client =
          _FakeClient(result: const RobotEnrichment(summary: '   '));
      final source = LlmEnrichedMessageSource(client);
      final summary = await source
          .resultsSummary(balancedCtx, topMatches: [_match()]);

      expect(summary.message.text,
          RobotBrain.resultsSummary(balancedCtx).text);
    });

    test('sonuç yokken veya eşleşme listesi boşken istemci hiç çağrılmaz',
        () async {
      final client = _FakeClient(
          result: const RobotEnrichment(summary: 'kullanılmamalı'));
      final source = LlmEnrichedMessageSource(client);

      const emptyCtx = ResultsContext(guaranteed: 0, target: 0, dream: 0);
      await source.resultsSummary(emptyCtx, topMatches: [_match()]);
      await source.resultsSummary(balancedCtx);
      expect(client.calls, 0);
    });

    test('etiketler ve adaylar sunucu sözleşmesine göre kurulur', () async {
      final client =
          _FakeClient(result: const RobotEnrichment(summary: 'özet'));
      final source = LlmEnrichedMessageSource(client);
      const ctx = ResultsContext(
        guaranteed: 2,
        target: 3,
        dream: 1,
        usedEstimatedRank: true,
        scoreType: 'EA',
        rank: 120000,
      );
      final matches = [
        for (var i = 0; i < 10; i++)
          _match(deptId: 'd$i', category: MatchCategory.target),
      ];
      await source.resultsSummary(ctx, topMatches: matches);

      final tags = client.lastTags!;
      // Anahtarlar sunucu filtresinden (a-zA-Z0-9_) geçmeli.
      for (final key in tags.keys) {
        expect(RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(key), isTrue,
            reason: key);
      }
      expect(tags['puan_turu'], 'EA');
      expect(tags['siralama'], '120.000');
      expect(tags['siralama_notu'], isNotNull);

      // Sunucu en fazla 8 aday kabul eder (MAX_INPUT_DEPTS).
      final candidates = client.lastCandidates!;
      expect(candidates, hasLength(8));
      expect(candidates.first.departmentId, 'd0');
      expect(candidates.first.universityId, 'u1');
      expect(candidates.first.totalScore, 80);
      expect(candidates.first.reasons, contains('ulaşılabilir'));
    });
  });
}
