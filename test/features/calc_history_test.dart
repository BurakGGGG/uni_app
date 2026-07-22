import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/score_calculator/data/calc_history_store.dart';
import 'package:uni_app/features/score_calculator/domain/models/calc_history_entry.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/score_calculator/presentation/screens/calc_history_screen.dart';

CalcHistoryEntry _entry(
  String id, {
  String label = 'Deneme',
  int tytMat = 10,
  double say = 400,
  int? rank = 90000,
}) {
  return CalcHistoryEntry(
    id: id,
    createdAt: DateTime(2026, 7, 20),
    label: label,
    year: 2026,
    input: ScoreInput(tytMatCorrect: tytMat),
    results: [
      TypeScoreSnapshot(
        scoreType: 'SAY',
        rawScore: say - 48,
        placementScore: say,
        estimatedRank: rank,
      ),
    ],
  );
}

void main() {
  group('CalcHistoryStore', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('round-trip: kaydet ve geri oku', () async {
      final store = CalcHistoryStore(prefs);
      await store.save([_entry('1', label: 'İlk Deneme')]);

      final read = CalcHistoryStore(prefs).read();
      expect(read, hasLength(1));
      expect(read.first.label, 'İlk Deneme');
      expect(read.first.input.tytMatCorrect, 10);
      expect(read.first.results.first.estimatedRank, 90000);
    });

    test('bozuk JSON temizlenir ve boş döner', () async {
      SharedPreferences.setMockInitialValues(
          {'calc_history_v1': '{bozuk json'});
      final broken = await SharedPreferences.getInstance();
      final store = CalcHistoryStore(broken);

      expect(store.read(), isEmpty);
      expect(broken.getString('calc_history_v1'), isNull);
    });

    test('50 kayıt tavanı — en eskiler düşer', () async {
      final store = CalcHistoryStore(prefs);
      final entries = [for (var i = 0; i < 60; i++) _entry('$i')];
      await store.save(entries);

      final read = store.read();
      expect(read, hasLength(50));
      expect(read.first.id, '0'); // en yeni başta korunur
      expect(read.last.id, '49');
    });
  });

  group('CalcHistoryNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
    });

    test('add / rename / remove / clear akışı', () async {
      final notifier = container.read(calcHistoryProvider.notifier);

      await notifier.add(_entry('1', tytMat: 10));
      await notifier.add(_entry('2', tytMat: 20));
      expect(container.read(calcHistoryProvider), hasLength(2));
      expect(container.read(calcHistoryProvider).first.id, '2');

      await notifier.rename('1', 'TYT Genel Deneme');
      expect(
        container
            .read(calcHistoryProvider)
            .firstWhere((e) => e.id == '1')
            .label,
        'TYT Genel Deneme',
      );

      await notifier.remove('2');
      expect(container.read(calcHistoryProvider), hasLength(1));

      await notifier.clear();
      expect(container.read(calcHistoryProvider), isEmpty);
    });

    test('aynı girdinin peş peşe kaydı çoğalmaz', () async {
      final notifier = container.read(calcHistoryProvider.notifier);

      await notifier.add(_entry('1', tytMat: 10));
      await notifier.add(_entry('2', tytMat: 10)); // aynı netler
      expect(container.read(calcHistoryProvider), hasLength(1));

      await notifier.add(_entry('3', tytMat: 25)); // farklı netler
      expect(container.read(calcHistoryProvider), hasLength(2));
    });
  });

  group('CalcHistoryScreen', () {
    testWidgets('kayıtları, deltayı gösterir; Netleri Yükle state\'e yazar',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = CalcHistoryStore(prefs);
      // En yeni başta: 30 net (450 puan), önceki 10 net (400 puan).
      await store.save([
        _entry('2', label: 'Deneme 2', tytMat: 30, say: 450, rank: 60000),
        _entry('1', label: 'Deneme 1', tytMat: 10, say: 400, rank: 90000),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: CalcHistoryScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Deneme 2'), findsOneWidget);
      expect(find.text('Deneme 1'), findsOneWidget);
      // Delta: 30 - 10 = +20 net.
      expect(find.textContaining('+20,00 net'), findsOneWidget);
      expect(find.textContaining('SAY +50,0 puan'), findsOneWidget);

      // Netleri Yükle → scoreInputProvider'a geri yazar.
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netleri Yükle'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalcHistoryScreen)),
      );
      expect(container.read(scoreInputProvider).tytMatCorrect, 30);
    });

    testWidgets('boş durum mesajı', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: CalcHistoryScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Henüz kayıtlı deneme yok'), findsOneWidget);
    });
  });
}
