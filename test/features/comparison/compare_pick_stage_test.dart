import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/theme/app_colors.dart';
import 'package:uni_app/features/comparison/presentation/providers/compare_pick_providers.dart';
import 'package:uni_app/features/comparison/presentation/providers/comparison_providers.dart';
import 'package:uni_app/features/comparison/presentation/widgets/compare/compare_pick_stage.dart';
import 'package:uni_app/features/comparison/presentation/widgets/comparison_picker_slot.dart';
import 'package:uni_app/features/comparison/presentation/widgets/comparison_uni_picker.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';
import 'package:uni_app/features/university/presentation/providers/university_providers.dart';
import 'package:uni_app/l10n/generated/app_localizations.dart';

/// Karşılaştırmanın seçim adımı.
///
/// Kilitlenen sözleşme: "iki tane seç" bir kez söylenir, adım satırı hangi
/// tarafın eksik olduğunu bilir ve öneriye dokunmak BOŞ tarafı doldurur.
void main() {
  UniversityModel uni(String id, String name) => UniversityModel(
        id: id,
        cityId: '34',
        name: name,
        type: 'Devlet',
        hasCampus: true,
        logoUrl: '',
        photoUrl: '',
        description: '',
        establishedYear: 1950,
        website: '',
      );

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget slot(String label, {bool empty = true}) => ComparisonPickerSlot(
        isEmpty: empty,
        emptyLabel: label,
        emptyIcon: Icons.location_city_rounded,
        accentColor: AppColors.primary,
        onTap: () {},
        title: empty ? null : 'İstanbul',
      );

  testWidgets('hiçbir şey seçilmemişken başlangıç yönergesi çıkar',
      (tester) async {
    await pump(
      tester,
      ComparePickStage(
        lead: 'Açıklama',
        slotA: slot('Şehir A'),
        slotB: slot('Şehir B'),
        filledA: false,
        filledB: false,
        nextLabel: 'Şehir A',
      ),
    );

    expect(find.text('Başlamak için birini seç'), findsOneWidget);
    // "Seçmek için dokun" iki slotta; ekranda ÜÇÜNCÜ bir kopya olmamalı —
    // eskiden altta ayrıca robotlu bir boş durum vardı.
    expect(find.text('Seçmek için dokun'), findsNWidgets(2));
  });

  testWidgets('bir taraf doluyken eksik olanı söyler', (tester) async {
    await pump(
      tester,
      ComparePickStage(
        lead: 'Açıklama',
        slotA: slot('Şehir A', empty: false),
        slotB: slot('Şehir B'),
        filledA: true,
        filledB: false,
        nextLabel: 'Şehir B',
      ),
    );

    expect(find.text('Sırada: Şehir B'), findsOneWidget);
    expect(find.text('Başlamak için birini seç'), findsNothing);
  });

  testWidgets('öneri yoksa bölüm hiç çizilmez', (tester) async {
    await pump(
      tester,
      const ComparePickSuggestions(title: 'ÖNERİLER', items: []),
    );

    expect(find.text('ÖNERİLER'), findsNothing);
  });

  testWidgets('öneriye dokunmak önce A sonra B tarafını doldurur',
      (tester) async {
    // Kısaltma tablosundaki yazımlar — `shorten` eşleşmezse ilk iki
    // kelimeye düşüyor, test o yedeğe değil eşleşmeye bakıyor.
    final unis = [
      uni('itu', 'İstanbul Teknik Üniversitesi'),
      uni('odtu', 'Ortadoğu Teknik Üniversitesi'),
    ];
    late WidgetRef capturedRef;

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          comparePickUniversitiesProvider.overrideWith((ref) async => unis),
          for (final u in unis)
            universityDetailProvider(u.id).overrideWith((ref) async => u),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const ComparisonUniPicker();
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('İTÜ'));
    await tester.pumpAndSettle();
    expect(capturedRef.read(comparisonSelectionProvider).uniIdA, 'itu');

    // Seçilen üniversite önerilerden düşer; ikinci dokunuş B'yi doldurur.
    expect(find.text('İTÜ'), findsNothing);
    await tester.tap(find.text('ODTÜ'));
    await tester.pumpAndSettle();
    expect(capturedRef.read(comparisonSelectionProvider).uniIdB, 'odtu');
  });
}
