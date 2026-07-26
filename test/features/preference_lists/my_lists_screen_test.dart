import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:uni_app/features/preference_lists/domain/models/preference_list_model.dart';
import 'package:uni_app/features/preference_lists/presentation/providers/preference_list_providers.dart';
import 'package:uni_app/features/preference_lists/presentation/screens/my_lists_screen.dart';
import 'package:uni_app/features/preference_wizard/data/student_profile_store.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/l10n/generated/app_localizations.dart';

/// Tercih Listelerim hub'ı.
///
/// Kilitlenen sözleşme: ekranda TEK bir "ana liste" öne çıkar (sabitlenen,
/// yoksa en dolu), kart listenin içinden bir şey gösterir, puanı olmayan
/// kullanıcıya denge yerine davet çıkar ve liste yokken Üni taslak önerir.
void main() {
  late SharedPreferences prefs;

  Future<ProviderContainer> containerWith(
    List<PreferenceListModel> lists, {
    bool withProfile = true,
    String? pinned,
  }) async {
    SharedPreferences.setMockInitialValues(
      pinned == null
          ? <String, Object>{}
          : {PinnedListNotifier.storageKey: pinned},
    );
    prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
      myPreferenceListsProvider.overrideWith((ref) => Stream.value(lists)),
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

  Future<void> pump(WidgetTester tester, ProviderContainer container) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const MyListsScreen()),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          // RobotAvatar bayrağı görünce controller kurmaz; yoksa
          // `pumpAndSettle` sonsuz animasyonda takılır.
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

  testWidgets('ana liste EN DOLU olandır ve tek kahraman kart vardır',
      (tester) async {
    final container = await containerWith([
      _list('a', 'Yedek Plan', 3),
      _list('b', 'Sayısal Planım', 12),
      _list('c', 'Hayallerim', 7),
    ]);
    await pump(tester, container);

    // Rozet tek: ekranda "asıl işim bu" diyen tek bir kart olmalı.
    expect(find.text('ANA LİSTEN'), findsOneWidget);

    final badge = tester.getTopLeft(find.text('ANA LİSTEN'));
    final main = tester.getTopLeft(find.text('Sayısal Planım'));
    final other = tester.getTopLeft(find.text('Yedek Plan'));
    expect((main.dy - badge.dy).abs() < 200, isTrue,
        reason: 'en dolu liste rozetin hemen altında');
    expect(other.dy, greaterThan(main.dy));
  });

  testWidgets('sabitlenen liste daha boş olsa da başa geçer', (tester) async {
    final container = await containerWith(
      [_list('a', 'Sayısal Planım', 12), _list('b', 'Yedek Plan', 2)],
      pinned: 'b',
    );
    await pump(tester, container);

    final badge = tester.getTopLeft(find.text('ANA LİSTEN'));
    expect(tester.getTopLeft(find.text('Yedek Plan')).dy,
        greaterThan(badge.dy - 200));
    expect(
      tester.getTopLeft(find.text('Sayısal Planım')).dy,
      greaterThan(tester.getTopLeft(find.text('Yedek Plan')).dy),
    );
  });

  testWidgets('kahraman kart listenin İÇİNDEN bilgi gösterir', (tester) async {
    final container = await containerWith([_list('a', 'Sayısal Planım', 12)]);
    await pump(tester, container);

    // Eski kart yalnız ad + doluluk gösteriyordu; ilk tercihler ve denge
    // kartın varlık sebebi.
    expect(find.textContaining('Üniversite a-0'), findsWidgets);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('güvenli'), findsOneWidget);
  });

  testWidgets('puanı olmayan kullanıcıya denge yerine davet çıkar',
      (tester) async {
    final container = await containerWith(
      [_list('a', 'Sayısal Planım', 6)],
      withProfile: false,
    );
    await pump(tester, container);

    expect(find.textContaining('Puanını hesapla'), findsOneWidget);
    expect(find.textContaining('güvenli'), findsNothing);
  });

  testWidgets('gizli/açık durumu kartta görünür', (tester) async {
    final container = await containerWith([
      _list('a', 'Sayısal Planım', 6, isPublic: true, viewCount: 42),
    ]);
    await pump(tester, container);

    // Paylaşım sayfasını açmadan da listenin herkese açık olduğu bilinmeli.
    expect(find.textContaining('42'), findsWidgets);
  });

  testWidgets('liste yokken Üni taslak önerir, yüzen buton yoktur',
      (tester) async {
    final container = await containerWith(const []);
    await pump(tester, container);

    expect(find.text('Listeni birlikte kuralım'), findsOneWidget);
    expect(find.text('Üni taslağı hazırlasın'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('yeni liste daveti listenin sonunda satır olarak durur',
      (tester) async {
    final container = await containerWith([_list('a', 'Sayısal Planım', 4)]);
    await pump(tester, container);

    // Yüzen buton kaldırıldı: sağ alt köşe yüzen Üni'nin.
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Yeni Liste'), findsOneWidget);
  });
}

PreferenceListModel _list(
  String id,
  String title,
  int count, {
  bool isPublic = false,
  int viewCount = 0,
}) {
  return PreferenceListModel(
    id: id,
    userId: 'u1',
    userName: 'Test',
    title: title,
    shareSlug: id,
    isPublic: isPublic,
    viewCount: viewCount,
    items: [
      for (var i = 0; i < count; i++)
        PreferenceItem(
          deptId: '$id-$i',
          uniId: 'uni-$id-$i',
          order: i + 1,
          deptName: 'Bölüm $i',
          uniName: 'Üniversite $id-$i',
          scoreType: 'SAY',
          // Sıra 42.000; küçükler zorlayıcı, büyükler güvenli olur.
          ranking: 10000 + i * 12000,
          baseScore: 500 - i * 8,
        ),
    ],
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 20).add(Duration(days: id.codeUnitAt(0) % 5)),
  );
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
