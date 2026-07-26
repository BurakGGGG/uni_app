import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/assistant/domain/uni_flow.dart';
import 'package:uni_app/features/assistant/presentation/flow/uni_flow_screen.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_repository.dart';
import 'package:uni_app/features/practice_exams/presentation/providers/practice_exam_providers.dart';
import 'package:uni_app/features/preference_wizard/domain/rank_estimator.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/features/score_calculator/domain/models/score_input.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/university/domain/models/city_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';

/// Akış kabuğu: on ekranlık kurulum yolunun gerçekten ekran ekran aktığı.
///
/// Buradaki testler yolun İSKELETİNİ kilitler — hangi soru hangi sırada
/// geliyor, zorunlu cevap verilmeden ilerlenebiliyor mu, seçimler doğru
/// katmana yazılıyor mu. Puan matematiği kendi testlerinde.
void main() {
  late ProviderContainer container;

  /// [settle] false: sayaç gibi SÜREN bir animasyonun ortası yakalanacaksa
  /// kabuk yerleşmeden bırakılır.
  Future<void> pump(
    WidgetTester tester, {
    UniFlowStep? only,
    ScoreInput? input,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // Deneme defteri Firebase'e bakıyor; akışın "son denemenden devam et"
      // kısayolu için yalnız listesi okunuyor.
      practiceExamRepositoryProvider.overrideWithValue(_FakeExamRepo()),
      // Sıra eğrisi normalde tüm bölüm verisinden kuruluyor (Firestore);
      // sıra modunun puanı zaten resmî ÖSYM tablosundan geliyor, eğri
      // yalnız enjekte edilebilsin diye boş kuruluyor.
      multiYearRankEstimatorProvider.overrideWith(
        (ref) async => MultiYearRankEstimator.fromDepartments(const []),
      ),
      citiesProvider.overrideWith((ref) async => const [
            CityModel(
              id: '34',
              name: 'İstanbul',
              plateCode: '34',
              photoUrl: '',
              totalUniversityCount: 0,
              appUniversityCount: 0,
            ),
            CityModel(
              id: '06',
              name: 'Ankara',
              plateCode: '06',
              photoUrl: '',
              totalUniversityCount: 0,
              appUniversityCount: 0,
            ),
          ]),
    ]);
    addTearDown(container.dispose);
    if (input != null) {
      container.read(scoreInputProvider.notifier).state = input;
    }

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => UniFlowScreen(only: only)),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
    // Adım girişleri kademeli (flutter_animate): kaydırma dönüşümü bitmeden
    // dokunulursa tap widget'ı ıskalar — sabit süre yerine yerleşmesini bekle.
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Devam'));
    await tester.pumpAndSettle();
  }

  testWidgets('yol karşılamayla başlar, üç giriş yolu sunar', (tester) async {
    await pump(tester);

    expect(find.text('Nasıl başlayalım?'), findsOneWidget);
    expect(find.text('Netlerimi gireyim'), findsOneWidget);
    expect(find.text('Sıralamamı biliyorum'), findsOneWidget);
    expect(find.text('Puanımı biliyorum'), findsOneWidget);
  });

  testWidgets('net yolu TYT ekranına iner', (tester) async {
    await pump(tester);

    await tapContinue(tester);

    expect(find.text('TYT netlerin'), findsOneWidget);
  });

  testWidgets('TYT neti girilmeden devam edilemez', (tester) async {
    await pump(tester);
    await tapContinue(tester);

    // Motorun kuralı: Türkçe ya da Temel Matematik neti olmadan hiçbir puan
    // türü hesaplanamaz — buton kapalı kalmalı.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Devam'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('sıralama yolu net ekranlarını atlar', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Sıralamamı biliyorum'));
    await tester.pump();
    await tapContinue(tester);

    expect(find.text('Başarı sıralaman'), findsOneWidget);
    expect(find.text('TYT netlerin'), findsNothing);
  });

  testWidgets('sıra girilmeden devam edilemez', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Sıralamamı biliyorum'));
    await tester.pump();
    await tapContinue(tester);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Devam'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('puan sayarak yükselir ve gerçek değerine oturur',
      (tester) async {
    await pump(
      tester,
      only: UniFlowStep.reveal,
      input: const ScoreInput(
        entryMode: NetEntryMode.rank,
        scoreType: 'SAY',
        enteredRank: 85600,
      ),
      settle: false,
    );

    // Sonuç asenkron çözülüyor; sayaç sahneye çıkana dek küçük adımlar.
    double? first;
    for (var i = 0; i < 15 && first == null; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      first = _bigNumber(tester);
    }
    expect(first, isNotNull, reason: 'sayan puan hiç görünmedi');

    // Kutlama anı: sayı ekrana basılmıyor, yükseliyor.
    await tester.pump(const Duration(milliseconds: 250));
    final mid = _bigNumber(tester)!;
    await tester.pumpAndSettle();
    final settled = _bigNumber(tester)!;

    expect(first!, lessThan(mid));
    expect(mid, lessThan(settled));
    // Sayaç ara karede değil, kartın gösterdiği gerçek puanda durur.
    expect(find.text(settled.toStringAsFixed(3)), findsNWidgets(2));
  });

  group('tek adım düzenleme', () {
    testWidgets('ilgi alanları adımı tek başına açılır', (tester) async {
      await pump(tester, only: UniFlowStep.interests);

      expect(find.text('Neye ilgin var?'), findsOneWidget);
      // Tek adımlık yolda ilerleme çubuğu anlamsız.
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('seçim ANINDA yumuşak katmana yazılır', (tester) async {
      await pump(tester, only: UniFlowStep.interests);

      await tester.tap(find.text('Hukuk'));
      await tester.pump();

      // Akış yarıda bırakılsa bile cevap kayıtlı olmalı.
      expect(
        container.read(wizardPrefsProvider).interestKeys,
        contains('hukuk'),
      );
      // Form sert filtreye HİÇ dokunmaz — yoksa listeyi eleyerek daraltır.
      expect(container.read(wizardFilterProvider).hasAnyFilter, isFalse);
    });

    testWidgets('şehir adımı da tek başına açılır ve kaydeder',
        (tester) async {
      await pump(tester, only: UniFlowStep.cities);
      await tester.pump(); // citiesProvider çözülsün

      expect(find.text('Hangi şehirler?'), findsOneWidget);

      await tester.tap(find.text('Ankara'));
      await tester.pump();

      expect(container.read(wizardPrefsProvider).cityIds, contains('06'));
      expect(container.read(wizardFilterProvider).cityIds, isEmpty);
    });

    testWidgets('sorulmayan yumuşak sinyaller silinmez', (tester) async {
      await pump(tester, only: UniFlowStep.interests);
      // Akış artık dil sormuyor; daha önce kaydedilmiş değer sıralama bonusu
      // olarak hâlâ okunuyor (`PreferenceMatchEngine._prefBoostFor`).
      await container.read(wizardPrefsProvider.notifier).save(
            container
                .read(wizardPrefsProvider)
                .copyWith(languages: {'İngilizce'}, uniTypes: {'Devlet'}),
          );
      await tester.pump();

      await tester.tap(find.text('Hukuk'));
      await tester.pump();

      final prefs = container.read(wizardPrefsProvider);
      expect(prefs.interestKeys, contains('hukuk'));
      expect(prefs.languages, contains('İngilizce'));
      expect(prefs.uniTypes, contains('Devlet'));
    });
  });
}

/// Sayan puanın o anki değeri; henüz sahnede değilse null. Üç ondalıklı
/// biçim ekranda yalnız kahraman sayıya ait.
double? _bigNumber(WidgetTester tester) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data != null && RegExp(r'^\d+\.\d{3}$').hasMatch(data)) {
      return double.parse(data);
    }
  }
  return null;
}

/// Firebase'e dokunmayan sahte deneme deposu.
class _FakeExamRepo implements PracticeExamRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}
