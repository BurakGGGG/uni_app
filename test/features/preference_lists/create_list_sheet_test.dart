import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/preference_lists/presentation/widgets/create_list_sheet.dart';
import 'package:uni_app/features/preference_wizard/data/student_profile_store.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/presentation/providers/preference_wizard_providers.dart';
import 'package:uni_app/l10n/generated/app_localizations.dart';

/// Yeni liste sheet'i.
///
/// Kilitlenen sözleşme: boş adla oluşturma tetiklenemez (hata kutusuyla
/// azarlamak yerine düğme kapalı durur), hazır adlar tek dokunuşla alana
/// yazar ve puan türü biliniyorsa ilk öneri kişiselleşir.
void main() {
  Future<void> pump(WidgetTester tester, {String? scoreType}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (scoreType != null)
            studentScoreProfileProvider.overrideWith(
              (ref) => StudentScoreProfileNotifier(StudentProfileStore(prefs))
                ..save(
                  StudentScoreProfile(
                    scoreType: scoreType,
                    placementScore: 430,
                    rank: 42000,
                    year: 2026,
                    updatedAt: DateTime(2026, 7, 20),
                  ),
                ),
            ),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Builder(
                builder: (inner) => Center(
                  child: TextButton(
                    onPressed: () => CreateListSheet.show(inner, ref),
                    child: const Text('aç'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  FilledButton createButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('ad boşken oluştur düğmesi kapalı, yazınca açılır',
      (tester) async {
    await pump(tester);

    // Eski hâlde düğme hep açıktı ve boş adda kırmızı hata kutusu çıkıyordu:
    // önce hata ürettirip sonra azarlamak yerine kapı kapalı dursun.
    expect(createButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Sayısal Planım');
    await tester.pump();

    expect(createButton(tester).onPressed, isNotNull);
  });

  testWidgets('yalnız boşluk girmek düğmeyi açmaz', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();

    expect(createButton(tester).onPressed, isNull);
  });

  testWidgets('hazır ad çipi alanı doldurur', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Hayallerim'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, 'Hayallerim');
    expect(createButton(tester).onPressed, isNotNull);
  });

  testWidgets('puan türü biliniyorsa ilk öneri kişiselleşir', (tester) async {
    await pump(tester, scoreType: 'SAY');

    expect(find.text('SAY Planım'), findsOneWidget);
    expect(find.text('Ana Planım'), findsNothing);
  });

  testWidgets('puan türü yoksa genel öneri gösterilir', (tester) async {
    await pump(tester);

    expect(find.text('Ana Planım'), findsOneWidget);
  });
}
