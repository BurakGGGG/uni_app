import '../../university/domain/models/department_model.dart';
import '../../university/domain/models/university_model.dart';
import 'models/preference_list_model.dart';

/// Bir üniversite + bölümden tercih listesi öğesi (`PreferenceItem`) üretir.
///
/// Hem `DepartmentPickerSheet` hem de Tercih Robotu kartları bu yardımcıyı
/// kullanır — denormalize alanlar (logo, marka rengi, taban/sıralama) tek
/// yerden doldurulur. `order` ekleme anında repository tarafından atanır.
PreferenceItem buildPreferenceItem(
  UniversityModel uni,
  DepartmentModel dept, {
  int order = 0,
}) {
  final score = dept.scoreData;
  return PreferenceItem(
    deptId: dept.id,
    uniId: uni.id,
    order: order,
    deptName: dept.name,
    uniName: uni.name,
    uniLogoUrl: uni.logoAssetPath,
    faculty: dept.faculty,
    deptType: dept.type,
    language: dept.language,
    scoreType: score?.scoreType ?? dept.scoreType,
    baseScore: score?.baseScore ?? dept.baseScore,
    ranking: score?.ranking ?? dept.ranking,
    quota: score?.quota ?? dept.quota,
    placedCount: score?.placedCount,
    uniBrandHex: uni.brandPrimaryHex,
  );
}
