import '../../../university/domain/models/department_model.dart';
import '../../../university/domain/models/university_model.dart';

/// Eşleşme kategorisi
enum MatchCategory {
  guaranteed, // 🟢 Garanti — puanın bölümün taban puanından 2+ yüksek
  target,     // 🟡 Hedef — puanınla gidebileceğin
  dream,      // 🔴 Hayal — henüz yetmiyor ama yakınsın
}

/// Tek bir üniversite-bölüm eşleşmesi
class UniversityMatch {
  final DepartmentModel department;
  final UniversityModel university;
  final MatchCategory category;
  final double departmentBaseScore;
  final int? departmentRanking;
  final double scoreDifference; // pozitif = senin puanın yüksek

  const UniversityMatch({
    required this.department,
    required this.university,
    required this.category,
    required this.departmentBaseScore,
    this.departmentRanking,
    required this.scoreDifference,
  });
}

/// Tüm hesaplama sonucu
class CalculationResult {
  final double calculatedScore;       // Hesaplanan ham + OBP puanı
  final double rawScore;              // Ham puan (OBP hariç)
  final double obpContribution;       // OBP katkısı
  final String scoreType;             // Puan türü
  final String departmentName;        // Seçilen bölüm
  final List<UniversityMatch> guaranteed;  // 🟢 En yakın 2
  final List<UniversityMatch> target;      // 🟡 Gidebileceği 3
  final List<UniversityMatch> dream;       // 🔴 Hedef 2

  const CalculationResult({
    required this.calculatedScore,
    required this.rawScore,
    required this.obpContribution,
    required this.scoreType,
    required this.departmentName,
    required this.guaranteed,
    required this.target,
    required this.dream,
  });

  /// Tüm eşleşmeler
  List<UniversityMatch> get allMatches => [...guaranteed, ...target, ...dream];

  /// Toplam eşleşme sayısı
  int get totalMatches => guaranteed.length + target.length + dream.length;
}
