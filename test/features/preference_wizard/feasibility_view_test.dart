import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/features/monetization/domain/enums/subscription_tier.dart';
import 'package:uni_app/features/monetization/presentation/providers/subscription_providers.dart';
import 'package:uni_app/features/preference_wizard/domain/models/student_score_profile.dart';
import 'package:uni_app/features/preference_wizard/presentation/widgets/feasibility_chip.dart';
import 'package:uni_app/features/university/domain/models/department_model.dart';

/// Uygunluk kapısının SIRASI — çip ve Üni aynı kaynaktan beslendiği için
/// buradaki bir kayma iki yüzeyi birden bozar.
void main() {
  DepartmentModel dept({String scoreType = 'SAY', int? ranking = 50000}) {
    return DepartmentModel(
      id: 'd1',
      universityId: 'u1',
      name: 'Bilgisayar Mühendisliği',
      faculty: 'Mühendislik',
      type: 'Lisans',
      language: 'Türkçe',
      scoreType: scoreType,
      baseScore: 450,
      ranking: ranking,
    );
  }

  Future<void> pumpChip(
    WidgetTester tester, {
    StudentScoreProfile? profile,
    required SubscriptionTier tier,
    required DepartmentModel department,
  }) async {
    SharedPreferences.setMockInitialValues(
      profile == null
          ? {}
          : {'student_score_profile_v1': jsonEncode(profile.toJson())},
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
            body: FeasibilityChip.forDepartment(department),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final sayProfile = StudentScoreProfile(
    scoreType: 'SAY',
    placementScore: 470,
    rank: 20000,
    year: 2025,
    updatedAt: DateTime(2026, 7, 21),
  );

  testWidgets('Plus yoksa ama kıyaslanabiliyorsa kilitli çip çıkar',
      (tester) async {
    await pumpChip(
      tester,
      profile: sayProfile,
      tier: SubscriptionTier.free,
      department: dept(),
    );
    expect(find.text('Uygunluk'), findsOneWidget);
  });

  // Kapı sırası kritik: kıyaslanabilirlik ÖNCE bakılır. Aksi hâlde
  // ücretsiz kullanıcı, hiç kıyaslanamayacak bir programda da kilit
  // görür ve boşuna paywall'a yönlendirilir.
  testWidgets('farklı puan türünde Plus yoksa bile kilit GÖSTERİLMEZ',
      (tester) async {
    await pumpChip(
      tester,
      profile: sayProfile,
      tier: SubscriptionTier.free,
      department: dept(scoreType: 'EA'),
    );
    expect(find.text('Uygunluk'), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('profil yoksa çip hiç çizilmez', (tester) async {
    await pumpChip(
      tester,
      tier: SubscriptionTier.free,
      department: dept(),
    );
    expect(find.text('Uygunluk'), findsNothing);
  });

  testWidgets('Plus + kıyaslanabilir → gerçek kategori çıkar', (tester) async {
    await pumpChip(
      tester,
      profile: sayProfile,
      tier: SubscriptionTier.plus,
      department: dept(),
    );
    // 20.000 sıra, 50.000 taban → rahat.
    expect(find.text('Yüksek şans'), findsOneWidget);
  });
}
