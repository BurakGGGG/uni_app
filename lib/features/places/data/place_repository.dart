import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/place_model.dart';

class PlaceRepository {
  final FirebaseFirestore _firestore;
  
  // Cache
  final Map<String, List<PlaceModel>> _placesByUniCache = {};
  final Map<String, PlaceModel> _placeByIdCache = {};
  DateTime? _lastFetchTime;

  PlaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5);

  void clearCache() {
    _placesByUniCache.clear();
    _placeByIdCache.clear();
    _lastFetchTime = null;
  }

  CollectionReference<Map<String, dynamic>> get _placesRef =>
      _firestore.collection('places');

  Future<List<PlaceModel>> getPlacesByUniversity(String uniId) async {
    if (_placesByUniCache.containsKey(uniId) && _isCacheValid) {
      return _placesByUniCache[uniId]!;
    }
    
    final snapshot = await _placesRef
        .where('universityId', isEqualTo: uniId)
        .orderBy('promotionPriority', descending: true)
        .orderBy('avgRating', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));
    
    final places = snapshot.docs
        .map((doc) => PlaceModel.fromMap(doc.data(), doc.id))
        .toList();
    
    _placesByUniCache[uniId] = places;
    _lastFetchTime = DateTime.now();
    return places;
  }

  Future<PlaceModel?> getPlace(String placeId) async {
    if (_placeByIdCache.containsKey(placeId) && _isCacheValid) {
      return _placeByIdCache[placeId];
    }
    
    final doc = await _placesRef.doc(placeId).get();
    if (!doc.exists || doc.data() == null) return null;
    
    final place = PlaceModel.fromMap(doc.data()!, doc.id);
    _placeByIdCache[placeId] = place;
    return place;
  }

  Future<List<PlaceModel>> getPlacesByType(String uniId, PlaceType type) async {
    final all = await getPlacesByUniversity(uniId);
    return all.where((p) => p.type == type).toList();
  }

  Stream<PlaceModel?> watchPlace(String placeId) {
    return _placesRef.doc(placeId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PlaceModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<PlaceModel>> watchPlacesByUniversity(String uniId) {
    return _placesRef
        .where('universityId', isEqualTo: uniId)
        .orderBy('promotionPriority', descending: true)
        .orderBy('avgRating', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PlaceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // TODO(sprint5): Şehir bazlı (cross-uni) mekan listesi
}
