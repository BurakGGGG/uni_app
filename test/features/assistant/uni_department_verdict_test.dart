import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/assistant/presentation/widgets/uni_department_verdict.dart';
import 'package:uni_app/features/monetization/domain/enums/subscription_tier.dart';
import 'package:uni_app/features/monetization/presentation/providers/subscription_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';

/// Üni'nin bölüm detayındaki kapısı — hangi durumda konuşur, hangisinde
/// susar. Plus geliri ve "Üni satış yapmaz" ilkesi buna bağlı.
void main() {
  tearDown(() => RobotScripts.languageCode = 'tr');

  DepartmentModel dept({String scoreType = 'SAY', int? ranking = 50000}) {
    return DepartmentModel(
      id: 'd1',
      universityId: 'u1',
      name: 'Bilgisayar Mühendisliği',
      faculty: 'Mühendislik Fakültesi',
      type: 'Lisans',
      language: 'Türkçe',
      scoreType: scoreType,
      baseScore: 450,
      ranking: ranking,
    );
  }

  StudentScoreProfile profile({String scoreType = 'SAY', int? rank = 20000}) {
    return StudentScoreProfile(
      scoreType: scoreType,
      placementScore: 470,
      rank: rank,
      year: 2025,
      updatedAt: DateTime(2026, 7, 21),
    );
  }

  // Profil gerçek store üzerinden tohumlanır (sahte notifier yerine) —
  // okuma yolu da böylece sınanmış olur.
  Future<void> pump(
    WidgetTester tester, {
    StudentScoreProfile? studentProfile,
    SubscriptionTier tier = SubscriptionTier.plus,
    DepartmentModel? department,
  }) async {
    SharedPreferences.setMockInitialValues(
      studentProfile == null
          ? {}
          : {
              'student_score_profile_v1':
                  jsonEncode(studentProfile.toJson()),
            },
    );
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          subscriptionTierProvider.overrideWith((ref) => Stream.value(tier)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: UniDepartmentVerdict(department: department ?? dept()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Plus yoksa Üni susar — kilidi çip anlatır, Üni ısrar etmez',
      (tester) async {
    await pump(
      tester,
      studentProfile: profile(),
      tier: SubscriptionTier.free,
    );
    expect(find.byType(SizedBox), findsWidgets);
    expect(find.textContaining('şans'), findsNothing);
    expect(find.textContaining('ulaşılabilir'), findsNothing);
    // Satış dili asla geçmemeli.
    expect(find.textContaining('Plus'), findsNothing);
  });

  testWidgets('profil yoksa sıralama daveti (ücretsiz kullanıcıya da)',
      (tester) async {
    await pump(tester, tier: SubscriptionTier.free);
    expect(find.textContaining('Sıralamanı bilsem'), findsOneWidget);
  });

  testWidgets('farklı puan türünde sessiz — kıyaslanamaz', (tester) async {
    await pump(
      tester,
      studentProfile: profile(scoreType: 'EA'),
      department: dept(scoreType: 'SAY'),
    );
    expect(find.textContaining('Sıralamanı bilsem'), findsNothing);
    expect(find.textContaining('şans'), findsNothing);
  });

  testWidgets('Plus + profil varsa kararını söyler', (tester) async {
    // Öğrenci 20.000, bölüm tabanı 50.000 → rahat geçer.
    await pump(tester, studentProfile: profile());
    expect(find.textContaining('görünüyor'), findsOneWidget);
  });
}
