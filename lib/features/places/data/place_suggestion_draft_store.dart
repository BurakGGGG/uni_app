import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaceSuggestionDraft {
  final String name;
  final String type;
  final String description;
  final String address;
  final List<String> photoPaths;
  final double? latitude;
  final double? longitude;
  final String? priceRange;
  final String openHours;
  final String phone;
  final List<String> amenities;
  final DateTime updatedAt;

  const PlaceSuggestionDraft({
    this.name = '',
    this.type = 'cafe',
    this.description = '',
    this.address = '',
    this.photoPaths = const [],
    this.latitude,
    this.longitude,
    this.priceRange,
    this.openHours = '',
    this.phone = '',
    this.amenities = const [],
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'description': description,
    'address': address,
    'photoPaths': photoPaths,
    'latitude': latitude,
    'longitude': longitude,
    'priceRange': priceRange,
    'openHours': openHours,
    'phone': phone,
    'amenities': amenities,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PlaceSuggestionDraft.fromMap(Map<String, dynamic> map) {
    return PlaceSuggestionDraft(
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'cafe',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      photoPaths: List<String>.from(map['photoPaths'] as List? ?? const []),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      priceRange: map['priceRange'] as String?,
      openHours: map['openHours'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      amenities: List<String>.from(map['amenities'] as List? ?? const []),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PlaceSuggestionDraftStore {
  static const _prefix = 'place_suggestion_draft_v1';

  Future<PlaceSuggestionDraft?> load({
    required String userId,
    required String universityId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, universityId));
    if (raw == null) return null;
    try {
      return PlaceSuggestionDraft.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      await prefs.remove(_key(userId, universityId));
      return null;
    }
  }

  Future<void> save({
    required String userId,
    required String universityId,
    required PlaceSuggestionDraft draft,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId, universityId),
      jsonEncode(draft.toMap()),
    );
  }

  Future<void> clear({
    required String userId,
    required String universityId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId, universityId));
  }

  String _key(String userId, String universityId) =>
      '${_prefix}_${userId}_$universityId';
}
