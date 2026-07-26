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
/// "ekran patlıyor mu" ve "tercih yolu doğru adımda mı duruyor".
void main() {
  /// Ekrandaki dolu (birincil) butonların etiketleri. Yolun sözleşmesi şu:
  /// her zaman EN FAZLA BİR tane olur — "şimdi bunu yap" iki kez söylenemez.
  List<String> filledLabels(WidgetTester tester) => tester
      .widgetList<FilledButton>(find.byType(FilledButton))
      .map((b) => ((b.child as Text?)?.data) ?? '')
      .toList();

  PreferenceListModel listWith(int itemCount) => PreferenceListModel(
        id: 'l1',
        userId: 'u1',
        userName: 'Ada',
        title: 'Tercihlerim',
        shareSlug: 'abcde',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
        items: [
          for (var i = 1; i <= itemCount; i++)
            PreferenceItem(
              deptId: 'd$i',
              uniId: 'u$i',
              order: i,
              deptName: 'Bölüm $i',
              uniName: 'Üniversite $i',
            ),
        ],
      );

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

  testWidgets('dört adım her durumda görünür, patlamaz', (tester) async {
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Puanın'), findsOneWidget);
    expect(find.text('Sana uyan programlar'), findsOneWidget);
    expect(find.text('Tercih listen'), findsOneWidget);
    expect(find.text('Listenin sağlığı'), findsOneWidget);
  });

  testWidgets('panel çalışma koçu değil — deneme/hedef/net sormaz',
      (tester) async {
    await pump(tester);

    // Bu üçü Denemelerim'in işi. Panelde göründükleri sürece Üni tercih
    // asistanı değil, ödev listesi olarak okunuyordu.
    expect(find.textContaining('deneme', findRichText: true), findsNothing);
    expect(find.textContaining('Hedef'), findsNothing);
    expect(find.textContaining('net'), findsNothing);
  });

  testWidgets('puan yokken sıradaki iş 1. adım', (tester) async {
    await pump(tester);

    expect(filledLabels(tester), ['Puanımı hesapla']);
    // 2. ve 4. adım kilitli: sebebi yazılı, butonu yok.
    expect(
      find.textContaining('Puanını bilince erişebileceğin'),
      findsOneWidget,
    );
    expect(find.text('Önerileri gör'), findsNothing);
  });

  testWidgets('puan girilince 1. adım tamamlanır, sıra 2. adıma geçer',
      (tester) async {
    await pump(
      tester,
      profile: StudentScoreProfile(
        scoreType: 'SAY',
        placementScore: 430,
        rank: 85600,
        year: 2026,
        updatedAt: DateTime(2026, 3, 1),
      ),
    );

    expect(tester.takeException(), isNull);
    // Puan satırı: gerçek sıra girilmişse "≈" YOK.
    expect(find.text('SAY 430,0 · 85.600. sıra'), findsOneWidget);
    expect(filledLabels(tester), ['Önerileri gör']);
    // 2. adımın kilidi açıldı, 4. adımınki hâlâ kapalı (liste yok).
    expect(find.textContaining('Puanını bilince erişebileceğin'), findsNothing);
    expect(find.textContaining('Listen kurulunca'), findsOneWidget);
  });

  testWidgets('liste varsa 3. adım doluluğu, 4. adım kilidi açılır',
      (tester) async {
    await pump(
      tester,
      profile: StudentScoreProfile(
        scoreType: 'SAY',
        placementScore: 430,
        rank: 85600,
        year: 2026,
        updatedAt: DateTime(2026, 3, 1),
      ),
      lists: [listWith(12)],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('12/24'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(filledLabels(tester), ['Listeyi aç']);
    expect(find.textContaining('Listen kurulunca'), findsNothing);
  });

  testWidgets('liste 24/24 olunca dolu buton kalmaz', (tester) async {
    await pump(
      tester,
      profile: StudentScoreProfile(
        scoreType: 'SAY',
        placementScore: 430,
        year: 2026,
        updatedAt: DateTime(2026, 3, 1),
      ),
      lists: [listWith(24)],
    );

    expect(find.text('24/24'), findsOneWidget);
    // Yol tamam: ekranda "şimdi bunu yap" diyen bir buton kalmaz.
    expect(filledLabels(tester), isEmpty);
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
