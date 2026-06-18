import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/places/data/place_suggestion_draft_store.dart';
import 'package:uni_app/features/places/domain/models/place_model.dart';
import 'package:uni_app/features/places/domain/models/place_suggestion_model.dart';

void main() {
  group('PlaceSuggestionDraft', () {
    test('map round-trip preserves rich form fields', () {
      final draft = PlaceSuggestionDraft(
        name: 'Kampüs Kafe',
        type: 'cafe',
        description: 'Sessiz çalışma alanı',
        address: 'Merkez Kampüs',
        photoPaths: const ['/tmp/photo.jpg'],
        latitude: 39.7487,
        longitude: 37.015,
        priceRange: '₺₺',
        openHours: '08:00-22:00',
        phone: '0346 000 00 00',
        amenities: const ['Wi-Fi', 'Priz'],
        updatedAt: DateTime.utc(2026, 6, 18, 12),
      );

      final restored = PlaceSuggestionDraft.fromMap(draft.toMap());

      expect(restored.name, draft.name);
      expect(restored.photoPaths, draft.photoPaths);
      expect(restored.latitude, draft.latitude);
      expect(restored.longitude, draft.longitude);
      expect(restored.amenities, draft.amenities);
      expect(restored.updatedAt, draft.updatedAt);
    });
  });

  group('PlaceSuggestionModel quality', () {
    test('complete suggestion receives full completeness score', () {
      final suggestion = _suggestion();

      expect(suggestion.missingQualityFields, isEmpty);
      expect(suggestion.completenessScore, 100);
      expect(suggestion.hasLocation, isTrue);
    });

    test('missing data is reported consistently', () {
      final suggestion = _suggestion(
        description: '',
        address: '',
        photoUrls: const [],
        latitude: null,
        longitude: null,
        openHours: null,
      );

      expect(
        suggestion.missingQualityFields,
        containsAll([
          'Fotoğraf',
          'Adres',
          'Konum',
          'Açıklama',
          'Çalışma saati',
        ]),
      );
      expect(suggestion.completenessScore, 0);
    });
  });
}

PlaceSuggestionModel _suggestion({
  String description = 'Sessiz çalışma alanı',
  String address = 'Merkez Kampüs',
  List<String> photoUrls = const ['https://example.com/photo.jpg'],
  double? latitude = 39.7487,
  double? longitude = 37.015,
  String? openHours = '08:00-22:00',
}) {
  return PlaceSuggestionModel(
    id: 'suggestion_1',
    universityId: 'uni_1',
    universityName: 'Test Üniversitesi',
    userId: 'user_1',
    userName: 'Test User',
    name: 'Kampüs Kafe',
    type: PlaceType.cafe,
    description: description,
    address: address,
    photoUrls: photoUrls,
    latitude: latitude,
    longitude: longitude,
    openHours: openHours,
    createdAt: DateTime.utc(2026, 6, 18),
  );
}
