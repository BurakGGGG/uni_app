import '../../university/data/university_repository.dart';
import '../../places/data/place_repository.dart';
import '../domain/models/comparison_result.dart';
import '../../university/domain/models/university_model.dart';
import '../../places/domain/models/place_model.dart';

class ComparisonRepository {
  final UniversityRepository _uniRepo;
  final PlaceRepository _placeRepo;
  
  ComparisonRepository({
    UniversityRepository? uniRepo,
    PlaceRepository? placeRepo,
  })  : _uniRepo = uniRepo ?? UniversityRepository(),
        _placeRepo = placeRepo ?? PlaceRepository();
  
  Future<ComparisonResult?> compare(String uniIdA, String uniIdB) async {
    if (uniIdA == uniIdB) {
      throw ArgumentError('İki farklı üniversite seçmelisiniz');
    }
    
    // 1. İki üniversiteyi ve mekanlarını paralel çek
    final results = await Future.wait([
      _uniRepo.getUniversity(uniIdA),
      _uniRepo.getUniversity(uniIdB),
      _placeRepo.getPlacesByUniversity(uniIdA),
      _placeRepo.getPlacesByUniversity(uniIdB),
    ]);
    
    final uniA = results[0] as UniversityModel?;
    final uniB = results[1] as UniversityModel?;
    final placesA = results[2] as List<PlaceModel>;
    final placesB = results[3] as List<PlaceModel>;
    
    if (uniA == null || uniB == null) return null;
    
    // 2. Kategori karşılaştırmaları yap
    final categories = <String, CategoryComparison>{};
    final allCats = <String>{
      ...uniA.categoryRatings.keys,
      ...uniB.categoryRatings.keys,
    };
    
    for (final cat in allCats) {
      final valA = (uniA.categoryRatings[cat] ?? 0).toDouble();
      final valB = (uniB.categoryRatings[cat] ?? 0).toDouble();
      
      String? winnerId;
      if ((valA - valB).abs() < 0.05) {
        winnerId = null;  // tie
      } else {
        winnerId = valA > valB ? uniA.id : uniB.id;
      }
      
      categories[cat] = CategoryComparison(
        categoryName: cat,
        valueA: valA,
        valueB: valB,
        winnerId: winnerId,
      );
    }
    
    // 3. Stats hesapla
    final stats = ComparisonStats(
      reviewCountDelta: uniA.reviewCount - uniB.reviewCount,
      placeCountDelta: placesA.length - placesB.length,
      establishedYearDiff: (uniA.establishedYear - uniB.establishedYear).abs(),
      sameType: uniA.type == uniB.type,
      sameCity: uniA.cityId == uniB.cityId,
      sameCampusLayout: uniA.campusLayout == uniB.campusLayout,
    );
    
    return ComparisonResult(
      uniA: uniA,
      uniB: uniB,
      categoryComparisons: categories,
      stats: stats,
      placeCountA: placesA.length,
      placeCountB: placesB.length,
    );
  }
}
