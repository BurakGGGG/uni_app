import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/score_calculator/presentation/screens/score_calculator_screen.dart';
import 'package:uni_app/features/score_calculator/presentation/widgets/rank_input_section.dart';
import 'package:uni_app/features/score_calculator/presentation/widgets/score_entry_section.dart';
import 'package:uni_app/features/score_calculator/presentation/widgets/subject_net_input.dart';
import 'package:uni_app/features/score_calculator/presentation/widgets/subject_score_input.dart';

/// Giriş ekranı v2: mod geçişi, uygulanabilir tür önizlemesi, OBP etiketi.
void main() {
  Future<void> pump(WidgetTester tester) async {
    // Uzun form tek ekrana sığsın diye yüksek yüzey.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ScoreCalculatorScreen()),
      ),
    );
    await tester.pump();
  }

  Finder subjectField(String title, {int index = 0}) => find
      .descendant(
        of: find.widgetWithText(SubjectScoreInput, title),
        matching: find.byType(TextFormField),
      )
      .at(index);

  testWidgets('net yokken Hesapla kapalı ve ipucu görünür', (tester) async {
    await pump(tester);

    expect(
      find.text('Hesaplama için TYT Türkçe veya Temel Matematik neti gir'),
      findsOneWidget,
    );
    expect(find.text('Hesapla'), findsOneWidget);
  });

  testWidgets('TYT neti girilince tür çipleri ve buton etiketi güncellenir',
      (tester) async {
    await pump(tester);

    await tester.enterText(subjectField('Türkçe'), '20');
    await tester.pump();

    expect(find.text('Hesapla (TYT)'), findsOneWidget);
    expect(
      find.text('Hesaplama için TYT Türkçe veya Temel Matematik neti gir'),
      findsNothing,
    );
  });

  testWidgets('AYT Matematik neti SAY ve EA türlerini açar', (tester) async {
    await pump(tester);

    await tester.enterText(subjectField('Türkçe'), '20');
    await tester.pump();

    // AYT bölümünü aç ve Matematik gir ("Temel Matematik" ile karışmaz).
    await tester.tap(find.text('AYT Testleri'));
    await tester.pumpAndSettle();
    await tester.enterText(subjectField('Matematik'), '15');
    await tester.pump();

    expect(find.text('Hesapla (TYT · SAY · EA)'), findsOneWidget);
  });

  testWidgets('mod geçişi netleri taşır, geri dönüş D/Y değerlerini korur',
      (tester) async {
    await pump(tester);

    await tester.enterText(subjectField('Türkçe'), '20');
    await tester.enterText(subjectField('Türkçe', index: 1), '4');
    await tester.pump();

    // Net moduna geç: 20 - 4/4 = 19 taşınmalı.
    await tester.tap(find.text('Net Gir'));
    await tester.pumpAndSettle();

    final netField = find.descendant(
      of: find.widgetWithText(SubjectNetInput, 'Türkçe'),
      matching: find.byType(TextFormField),
    );
    expect(
      tester.widget<TextFormField>(netField).controller!.text,
      '19',
    );

    // Geri dönüş onay ister; D/Y değerleri korunur.
    await tester.tap(find.text('Doğru / Yanlış'));
    await tester.pumpAndSettle();
    expect(find.text('Doğru/yanlış moduna dön'), findsOneWidget);
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(subjectField('Türkçe'))
          .controller!
          .text,
      '20',
    );
  });

  testWidgets('OBP canlı etiketi katsayı indirimini yansıtır', (tester) async {
    await pump(tester);

    // Varsayılan diploma 80 → OBP 400 → +48.0
    expect(find.textContaining('+48.0 puan'), findsOneWidget);

    await tester.tap(
        find.text('Geçen yıl bir yükseköğretim programına yerleştim'));
    await tester.pump();

    expect(find.textContaining('+24.0 puan'), findsOneWidget);
  });

  testWidgets('hedef bölüm opsiyonel — kart ve temizleme akışı', (tester) async {
    await pump(tester);
    expect(find.text('Hedef Bölüm (opsiyonel)'), findsOneWidget);

    // Elle state'e bölüm yaz (picker Firestore'a bağlı, testte açılmaz).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScoreCalculatorScreen)),
    );
    container.read(scoreInputProvider.notifier).state = container
        .read(scoreInputProvider)
        .copyWith(selectedDepartment: 'Bilgisayar Mühendisliği');
    await tester.pump();

    expect(find.text('Bilgisayar Mühendisliği'), findsOneWidget);
    await tester.tap(find.byTooltip('Kaldır'));
    await tester.pump();
    expect(find.text('Bilgisayar Mühendisliği'), findsNothing);
  });

  testWidgets('yıl ve puan türü seçimi artık giriş ekranında yok',
      (tester) async {
    await pump(tester);

    expect(find.text('Yıl Seçimi'), findsNothing);
    expect(find.text('Puan türü otomatik belirlendi'), findsNothing);
    // Varsayılan yıl 2026 kalır (sonuç ekranı karşılaştırması kullanır).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScoreCalculatorScreen)),
    );
    expect(container.read(scoreInputProvider).selectedYear, 2026);
    expect(container.read(scoreInputProvider).entryMode,
        NetEntryMode.correctWrong);
  });

  group('sıralama modu', () {
    Finder rankField() => find.descendant(
          of: find.byType(RankInputSection),
          matching: find.byType(TextFormField),
        );

    testWidgets('net ve OBP bölümleri gizlenir, sıra alanı gelir',
        (tester) async {
      await pump(tester);
      expect(find.text('TYT Testleri'), findsOneWidget);
      expect(find.text('Diploma Notu (OBP)'), findsOneWidget);

      await tester.tap(find.text('Sıralama'));
      await tester.pumpAndSettle();

      expect(find.text('Başarı Sıralaman'), findsOneWidget);
      expect(find.text('TYT Testleri'), findsNothing);
      expect(find.text('AYT Testleri'), findsNothing);
      expect(find.text('Diploma Notu (OBP)'), findsNothing);
      // Hedef bölüm sıra modunda da kalır.
      expect(find.text('Hedef Bölüm (opsiyonel)'), findsOneWidget);
    });

    testWidgets('tür seçilmeden Hesapla kapalı, seçilince açılır',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Sıralama'));
      await tester.pumpAndSettle();

      expect(find.text('Hesaplama için puan türünü seç ve sıranı gir'),
          findsOneWidget);

      // Yalnız tür yetmez.
      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      expect(find.text('Hesapla'), findsOneWidget);

      await tester.enterText(rankField(), '45000');
      await tester.pump();

      expect(find.text('Hesapla (SAY)'), findsOneWidget);
      expect(find.text('Hesaplama için puan türünü seç ve sıranı gir'),
          findsNothing);
    });

    testWidgets('tür çipinde tik yok, altta tür önizlemesi tekrarlanmaz',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Sıralama'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      await tester.enterText(rankField(), '45000');
      await tester.pump();

      // Tik işareti çipi genişletip satır kaydırıyordu.
      expect(
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'SAY'))
            .showCheckmark,
        isFalse,
      );
      // Net modundaki "hesaplanacak türler" şeridi sıra modunda gereksiz.
      expect(find.widgetWithText(Chip, 'SAY'), findsNothing);
    });

    testWidgets('canlı önizleme puanı ve dilimi gösterir', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Sıralama'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      await tester.enterText(rankField(), '45000');
      await tester.pump();

      // 2025 SAY tablosunda 45.000 → ≈451,1 puan; dilim 45.000/1.291.531.
      expect(find.textContaining('≈ 451.1 puan'), findsOneWidget);
      expect(find.textContaining('İlk %3,5'), findsOneWidget);
      expect(find.textContaining('2025 yerleştirme verisine göre'),
          findsOneWidget);
    });

    testWidgets('net moduna dönüş onay ister ve sırayı temizler',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Sıralama'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      await tester.enterText(rankField(), '45000');
      await tester.pump();

      await tester.tap(find.text('Doğru / Yanlış'));
      await tester.pumpAndSettle();
      expect(find.text('Net girişine dön'), findsOneWidget);
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ScoreCalculatorScreen)),
      );
      final input = container.read(scoreInputProvider);
      expect(input.entryMode, NetEntryMode.correctWrong);
      expect(input.enteredRank, isNull);
      expect(input.scoreType, '');
      expect(find.text('TYT Testleri'), findsOneWidget);
    });
  });

  group('puan modu', () {
    Finder scoreField() => find.descendant(
          of: find.byType(ScoreEntrySection),
          matching: find.byType(TextFormField),
        );

    testWidgets('net ve OBP bölümleri gizlenir, puan alanı gelir',
        (tester) async {
      await pump(tester);
      expect(find.text('TYT Testleri'), findsOneWidget);

      await tester.tap(find.text('Puan Gir'));
      await tester.pumpAndSettle();

      expect(find.text('Yerleştirme Puanın'), findsOneWidget);
      expect(find.text('TYT Testleri'), findsNothing);
      expect(find.text('AYT Testleri'), findsNothing);
      expect(find.text('Diploma Notu (OBP)'), findsNothing);
      // Hedef bölüm puan modunda da kalır.
      expect(find.text('Hedef Bölüm (opsiyonel)'), findsOneWidget);
    });

    testWidgets('tür seçilmeden Hesapla kapalı, seçilince açılır',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Puan Gir'));
      await tester.pumpAndSettle();

      expect(find.text('Hesaplama için puan türünü seç ve puanını gir'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      expect(find.text('Hesapla'), findsOneWidget);

      await tester.enterText(scoreField(), '451,1');
      await tester.pump();

      expect(find.text('Hesapla (SAY)'), findsOneWidget);
    });

    testWidgets('canlı önizleme tahmini sırayı ve dilimi gösterir',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Puan Gir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      // Türkçe klavyede ondalık ayracı virgüldür.
      await tester.enterText(scoreField(), '451,1');
      await tester.pump();

      expect(find.textContaining('. sıra'), findsWidgets);
      expect(find.textContaining('İlk %3,5'), findsOneWidget);
      expect(find.textContaining('2025 yerleştirme verisine göre'),
          findsOneWidget);
    });

    testWidgets('sıra modundan puan moduna geçiş sırayı temizler',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Sıralama'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byType(RankInputSection),
          matching: find.byType(TextFormField),
        ),
        '45000',
      );
      await tester.pump();

      await tester.tap(find.text('Puan Gir'));
      await tester.pumpAndSettle();
      expect(find.text('Puan girişine geç'), findsOneWidget);
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ScoreCalculatorScreen)),
      );
      final input = container.read(scoreInputProvider);
      expect(input.entryMode, NetEntryMode.score);
      expect(input.enteredRank, isNull);
      // Puan türü korunur — "hangi türün" sorusu iki modda da aynı.
      expect(input.scoreType, 'SAY');
    });

    testWidgets('net moduna dönüş onay ister ve puanı temizler',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Puan Gir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'SAY'));
      await tester.pump();
      await tester.enterText(scoreField(), '451,1');
      await tester.pump();

      await tester.tap(find.text('Doğru / Yanlış'));
      await tester.pumpAndSettle();
      expect(find.text('Net girişine dön'), findsOneWidget);
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ScoreCalculatorScreen)),
      );
      final input = container.read(scoreInputProvider);
      expect(input.entryMode, NetEntryMode.correctWrong);
      expect(input.enteredScore, isNull);
      expect(input.scoreType, '');
      expect(find.text('TYT Testleri'), findsOneWidget);
    });
  });
}
