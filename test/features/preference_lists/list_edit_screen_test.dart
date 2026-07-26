import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/preference_lists/data/preference_list_repository.dart';
import 'package:uni_app/features/preference_lists/domain/models/preference_list_model.dart';
import 'package:uni_app/features/preference_lists/presentation/providers/preference_list_providers.dart';
import 'package:uni_app/features/preference_lists/presentation/screens/list_edit_screen.dart';
import 'package:uni_app/features/preference_wizard/data/student_profile_store.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/l10n/generated/app_localizations.dart';

/// Liste detayı.
///
/// Kilitlenen sözleşme — hepsi "kullanıcı emeğini kaybetmesin" kuralları:
/// **Kaydet butonu yoktur**, her değişiklik kendiliğinden yazılır, yanlışlıkla
/// yapılan her şey GERİ AL'lıdır ve "Üni sıraya dizsin" zorlayıcıları üste
/// alır (ÖSYM listeyi yukarıdan tarar).
void main() {
  late _FakeRepo repo;

  Future<ProviderContainer> containerWith(
    PreferenceListModel list, {
    bool withProfile = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = _FakeRepo();

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      preferenceListRepositoryProvider.overrideWithValue(repo),
      preferenceListProvider(list.id).overrideWith((ref) => Stream.value(list)),
      myPreferenceListsProvider.overrideWith((ref) => Stream.value([list])),
      if (withProfile)
        studentScoreProfileProvider.overrideWith(
          (ref) => StudentScoreProfileNotifier(StudentProfileStore(prefs))
            ..save(
              StudentScoreProfile(
                scoreType: 'SAY',
                placementScore: 430,
                rank: 42000,
                year: 2026,
                updatedAt: DateTime(2026, 7, 20),
              ),
            ),
        ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container,
    String listId,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => ListEditScreen(listId: listId)),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('kaydet butonu yoktur', (tester) async {
    final container = await containerWith(_list(5));
    await pump(tester, container, 'a');

    // Eski ekranın en büyük tuzağı: sürükleyip kaydetmeden çıkmak.
    expect(find.widgetWithText(FilledButton, 'Kaydet'), findsNothing);
    expect(find.text('Kaydet'), findsNothing);
  });

  testWidgets('silme ANINDA yazılır', (tester) async {
    final container = await containerWith(_list(4));
    await pump(tester, container, 'a');

    await tester.drag(find.text('Üniversite 1'), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(repo.saved, isNotEmpty, reason: 'kaydet düğmesi beklenmiyor');
    expect(repo.saved.last.map((i) => i.deptId), isNot(contains('d1')));
    expect(repo.saved.last.length, 3);
  });

  testWidgets('silinen tercih GERİ AL ile döner', (tester) async {
    final container = await containerWith(_list(4));
    await pump(tester, container, 'a');

    await tester.drag(find.text('Üniversite 1'), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Üniversite 1'), findsNothing);

    await tester.tap(find.text('GERİ AL'));
    await tester.pumpAndSettle();

    expect(find.text('Üniversite 1'), findsOneWidget);
    expect(repo.saved.last.length, 4);
  });

  testWidgets('sıra numaraları silme sonrası yeniden numaralanır',
      (tester) async {
    final container = await containerWith(_list(3));
    await pump(tester, container, 'a');

    await tester.drag(find.text('Üniversite 0'), const Offset(600, 0));
    await tester.pumpAndSettle();

    // 1-2-3 sırası boşluksuz kalmalı; ÖSYM listesinde sıra numarası anlam
    // taşıyor.
    expect(repo.saved.last.map((i) => i.order), [1, 2]);
  });

  testWidgets('Üni sıraya dizsin: zorlayıcılar üste çıkar', (tester) async {
    final container = await containerWith(_list(4));
    await pump(tester, container, 'a');

    await tester.tap(find.text('Üni sıraya dizsin'));
    await tester.pumpAndSettle();

    // Sıra 42.000; küçük sıralı (zor) programlar başa gelmeli.
    final ranks = repo.saved.last.map((i) => i.ranking!).toList();
    expect(ranks.first, lessThan(42000));
    expect(ranks.last, greaterThan(42000));
    expect(find.text('GERİ AL'), findsOneWidget, reason: 'geri alınabilmeli');
  });

  testWidgets('GERİ AL şeridi kendiliğinden kaybolur', (tester) async {
    final container = await containerWith(_list(4));
    await pump(tester, container, 'a');

    await tester.tap(find.text('Üni sıraya dizsin'));
    await tester.pumpAndSettle();
    expect(find.text('GERİ AL'), findsOneWidget);

    // Ekranda kalıcı bir şerit bırakmak kabul edilemez: kullanıcı listeyi
    // onun altından okumaya çalışıyor.
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.text('GERİ AL'), findsNothing);
  });

  testWidgets('puan yoksa Üni sıralaması sunulmaz', (tester) async {
    final container = await containerWith(_list(4), withProfile: false);
    await pump(tester, container, 'a');

    // Kategori bilinmeden "sağlıklı sıra" diye bir şey söylenemez.
    expect(find.text('Üni sıraya dizsin'), findsNothing);
    expect(find.textContaining('Puanını hesapla'), findsOneWidget);
  });
}

PreferenceListModel _list(int count) {
  return PreferenceListModel(
    id: 'a',
    userId: 'u1',
    userName: 'Test',
    title: 'Sayısal Planım',
    shareSlug: 'a',
    items: [
      for (var i = 0; i < count; i++)
        PreferenceItem(
          deptId: 'd$i',
          uniId: 'u$i',
          order: i + 1,
          deptName: 'Bölüm $i',
          uniName: 'Üniversite $i',
          scoreType: 'SAY',
          // Kasten TERS: en güvenli tercih başta duruyor. "Üni sıraya
          // dizsin" bir şeyi gerçekten kımıldatmalı.
          ranking: 10000 + (count - 1 - i) * 25000,
          baseScore: 500 - (count - 1 - i) * 10,
        ),
    ],
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 20),
  );
}

/// Firestore'a dokunmayan depo — yazılan sıraları biriktirir.
class _FakeRepo implements PreferenceListRepository {
  final List<List<PreferenceItem>> saved = [];

  @override
  Future<void> reorderItems(String listId, List<PreferenceItem> items) async {
    saved.add(List.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}
