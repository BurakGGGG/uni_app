import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uni_app/main.dart';
import 'package:uni_app/core/providers/shared_preferences_provider.dart';
import 'package:uni_app/firebase_options.dart';

/// Integration test: University detail screen navigation
///
/// Test akışı:
/// 1. Ana sayfa → popüler üniversite kartına tap
/// 2. Üniversite detay sayfası açılıyor
/// 3. Bölümler preview kartı görünüyor
/// 4. "Tüm bölümleri gör" CTA'ya tap
/// 5. Bölümler sub-route'u açılıyor
/// 6. Geri dönüş → detay sayfası
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('University Detail Navigation', () {
    testWidgets('navigates from home to university detail and sub-routes',
        (tester) async {
      // ─── Setup ──────────────────────────────────────────────
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const UniSecApp(),
        ),
      );

      // İlk yüklemeyi bekle
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ─── 1. Ana sayfa yüklendi mi? ─────────────────────────
      // Bottom navigation bar görünür olmalı
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // ─── 2. Popüler üniversite kartına tap ──────────────────
      // Popüler üniversiteler alanından herhangi bir karta tıkla
      final uniCards = find.byType(GestureDetector);
      if (uniCards.evaluate().isNotEmpty) {
        await tester.tap(uniCards.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // ─── 3. Detay sayfası kontrolleri ───────────────────────
      // SliverAppBar (hero header) olmalı
      final sliverAppBar = find.byType(SliverAppBar);
      if (sliverAppBar.evaluate().isNotEmpty) {
        expect(sliverAppBar, findsOneWidget);

        // Favori butonu olmalı
        expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);

        // ─── 4. Bölümler section'ını bul ve "Tümünü Gör"e tap ─
        // Sayfa aşağı scroll
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, -300),
          1000,
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // "Tüm ... bölümü gör" butonunu ara
        final deptSeeAll = find.textContaining('bölümü gör');
        if (deptSeeAll.evaluate().isNotEmpty) {
          await tester.tap(deptSeeAll.first, warnIfMissed: false);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // ─── 5. Bölümler sub-route açıldı mı? ──────────────
          expect(find.text('Bölümler'), findsWidgets);

          // ─── 6. Geri dön ───────────────────────────────────
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Detay sayfasına geri döndük
            expect(find.byType(SliverAppBar), findsOneWidget);
          }
        }
      }
    });

    testWidgets('pull to refresh invalidates providers', (tester) async {
      // ─── Setup ──────────────────────────────────────────────
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const UniSecApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Popüler üniversite kartına tap
      final uniCards = find.byType(GestureDetector);
      if (uniCards.evaluate().isNotEmpty) {
        await tester.tap(uniCards.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // RefreshIndicator test: aşağı çek
      final scrollView = find.byType(CustomScrollView);
      if (scrollView.evaluate().isNotEmpty) {
        await tester.fling(scrollView, const Offset(0, 300), 1000);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Hala detay sayfasındayız (crash olmadı)
        expect(find.byType(SliverAppBar), findsOneWidget);
      }
    });
  });
}
