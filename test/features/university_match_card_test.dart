import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/score_calculator/domain/models/match_result.dart';
import 'package:uni_app/features/score_calculator/presentation/widgets/university_match_card.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';
import 'package:uni_app/features/university/domain/models/university_model.dart';

void main() {
  final department = DepartmentModel(
    id: 'd1',
    universityId: 'u1',
    name: 'Bilgisayar Mühendisliği',
    faculty: 'Mühendislik Fakültesi',
    type: 'Lisans',
    language: 'Türkçe',
    scoreData: DepartmentScoreData(
      year: 2025,
      scoreType: 'SAY',
      baseScore: 480.5,
      ranking: 12000,
      quota: 100,
      placedCount: 100,
    ),
  );

  final university = UniversityModel(
    id: 'u1',
    cityId: '06',
    name: 'Test Üniversitesi',
    type: 'Devlet',
    hasCampus: true,
    logoUrl: '',
    photoUrl: '',
    description: '',
    establishedYear: 1990,
    website: '',
  );

  testWidgets('kart üniversiteyi VE bölümü birlikte gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UniversityMatchCard(
            match: UniversityMatch(
              department: department,
              university: university,
              category: MatchCategory.target,
              departmentBaseScore: 480.5,
              departmentRanking: 12000,
              scoreDifference: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Bölüm adı yazmayınca kart "hangi bölüme girebilirim" sorusunu
    // cevapsız bırakıyordu.
    expect(find.text('Test Üniversitesi'), findsOneWidget);
    expect(find.text('Bilgisayar Mühendisliği'), findsOneWidget);
    expect(find.textContaining('Taban Puan: 480.50'), findsOneWidget);
    expect(find.textContaining('Sıralama: 12000'), findsOneWidget);
  });
}
