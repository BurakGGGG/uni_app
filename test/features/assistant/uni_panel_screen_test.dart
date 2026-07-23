import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/assistant/presentation/screens/uni_panel_screen.dart';
import 'package:uni_app/features/preference_wizard/data/student_profile_store.dart';
import 'package:uni_app/features/practice_exams/data/practice_exam_repository.dart';
import 'package:uni_app/features/practice_exams/presentation/providers/practice_exam_providers.dart';
import 'package:uni_app/features/preference_lists/domain/models/preference_list_model.dart';
import 'package:uni_app/features/preference_lists/presentation/providers/preference_list_providers.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/score_calculator/presentation/providers/score_calculator_providers.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';

/// Panelin uçtan uca render olduğunu doğrulayan smoke testi — cihaz olmadan
/// yakalanabilecek en değerli şey provider kompozisyonu ve widget kurulumu.
/// Motorun ne ürettiği kendi testinde (`insight_engine_test`); burada sorun
/// "ekran patlıyor mu".
void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    StudentScoreProfile? profile,
    List<PreferenceListModel> lists = const [],
  }) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // PracticeExamRepository yapıcısında FirebaseFirestore.instance'a
      // dokunuyor — cihazda sorun değil, testte Firebase yok. Deneme
      // notifier'ı ilk durumu zaten prefs'ten okuyor, repo yalnız yazmalarda
      // gerekli; boş bir sahte yeter.
      practiceExamRepositoryProvider.overrideWithValue(_FakeExamRepo()),
      // Ağır veri kaynakları boş çözülür — panel bunlar olmadan da çalışmalı.
      allScoredDepartmentsProvider.overrideWith((ref) async => const []),
      allUniversitiesProvider.overrideWith((ref) async => const []),
      citiesProvider.overrideWith((ref) async => const []),
      myPreferenceListsProvider.overrideWith((ref) => Stream.value(lists)),
      if (profile != null)
        studentScoreProfileProvider.overrideWith(
          (ref) => _StubProfile(profile),
        ),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const UniPanelScreen()),
    ]);
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
    // insightContextProvider birkaç future'ı await ediyor (bölümler, üniler,
    // şehirler, liste stream'i) — hepsi çözülene dek pompala.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    return container;
  }

  testWidgets('boş kullanıcıda tek adım görünür, patlamaz', (tester) async {
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Puanını hesaplayalım'), findsOneWidget);
    expect(find.text('Puanımı hesapla'), findsOneWidget);
  });

  testWidgets('kurulum sürerken ekranda tek iş olur', (tester) async {
    await pump(tester);

    // Kart zaten setup notunun kendisi; not listesi de haftalık plan da aynı
    // adımları üretebiliyor. Üçü birden çizilirse kullanıcı aynı şeyi üç kez
    // okur — "ben bile anlamadım" şikâyetinin kaynağı buydu.
    expect(find.text('Puanını hesaplayalım'), findsOneWidget);
    // Ödev listesi görüntüsü veren sayaç/çubuk kalktı.
    expect(find.text('0/2'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    // Sıradaki adım tek: ileriki adımlar henüz görünmez.
    expect(find.text('Deneme ekle'), findsNothing);
    expect(find.text('Hedef belirle'), findsNothing);
  });

  testWidgets('puan girilince kart sıradaki işe döner', (tester) async {
    await pump(
      tester,
      profile: StudentScoreProfile(
        scoreType: 'SAY',
        placementScore: 430,
        year: 2026,
        updatedAt: DateTime(2026, 3, 1),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Şimdi bir deneme ekle'), findsOneWidget);
    expect(find.text('Deneme ekle'), findsOneWidget);
    // Hedef kurulum şartı DEĞİL: deneme gelmeden sorulmaz.
    expect(find.text('Hedefin ne olsun?'), findsNothing);
    expect(find.text('Puanını hesaplayalım'), findsNothing);
  });
}

/// Sabit profil döndüren notifier — gerçek store'a dokunmaz.
class _StubProfile extends StudentScoreProfileNotifier {
  _StubProfile(StudentScoreProfile profile) : super(_NoopStore()) {
    state = profile;
  }
}

/// StudentProfileStore imzasını karşılayan boş store; okuma/yazma no-op.
class _NoopStore implements StudentProfileStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Firebase'e dokunmayan sahte deneme deposu.
class _FakeExamRepo implements PracticeExamRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}
