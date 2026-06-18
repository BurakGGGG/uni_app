import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/admin/presentation/widgets/place_suggestion_approval_sheet.dart';
import 'package:uni_app/features/places/domain/models/place_model.dart';
import 'package:uni_app/features/places/domain/models/place_suggestion_model.dart';
import 'package:uni_app/features/places/presentation/widgets/place_open_hours_picker.dart';

void main() {
  testWidgets('approval sheet renders without overflow on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceSuggestionApprovalSheet(
            suggestion: PlaceSuggestionModel(
              id: 'suggestion_1',
              universityId: 'uni_1',
              universityName: 'Test Üniversitesi',
              userId: 'user_1',
              userName: 'Test Kullanıcı',
              name: 'Kampüs Kafe',
              type: PlaceType.cafe,
              description: 'Sessiz çalışma alanı',
              address: 'Merkez Kampüs',
              latitude: 39.7487,
              longitude: 37.015,
              priceRange: '₺₺',
              openHours: '08:00-22:00',
              phone: '0346 000 00 00',
              amenities: const ['Wi-Fi', 'Priz'],
              createdAt: DateTime.utc(2026, 6, 18),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mekanı Düzenle ve Onayla'), findsOneWidget);
    expect(find.text('Kampüs Kafe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone input rejects non-digit characters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceSuggestionApprovalSheet(
            suggestion: _suggestion(phone: ''),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final phoneField = find.byKey(const Key('place_phone_field'));
    await tester.scrollUntilVisible(
      phoneField,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(phoneField, 'abc0555-123 45 67');

    final field = tester.widget<TextFormField>(phoneField);
    expect(field.controller?.text, '05551234567');
  });

  testWidgets('open hours are selected without typing', (tester) async {
    String? selectedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PlaceOpenHoursPicker(
              value: selectedValue,
              onChanged: (value) => setState(() => selectedValue = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Saat seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24 saat açık'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('24 saat açık'), findsOneWidget);
  });
}

PlaceSuggestionModel _suggestion({String? phone = '03460000000'}) {
  return PlaceSuggestionModel(
    id: 'suggestion_1',
    universityId: 'uni_1',
    universityName: 'Test Üniversitesi',
    userId: 'user_1',
    userName: 'Test Kullanıcı',
    name: 'Kampüs Kafe',
    type: PlaceType.cafe,
    description: 'Sessiz çalışma alanı',
    address: 'Merkez Kampüs',
    latitude: 39.7487,
    longitude: 37.015,
    priceRange: '₺₺',
    openHours: '08:00 - 22:00',
    phone: phone,
    amenities: const ['Wi-Fi', 'Priz'],
    createdAt: DateTime.utc(2026, 6, 18),
  );
}
