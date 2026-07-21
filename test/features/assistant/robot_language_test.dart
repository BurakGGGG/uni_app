import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/chat_flow.dart';
import 'package:uni_app/features/assistant/domain/robot_brain.dart';
import 'package:uni_app/features/assistant/domain/robot_mood.dart';
import 'package:uni_app/features/assistant/domain/robot_scripts.dart';
import 'package:uni_app/features/assistant/domain/tercih_calendar.dart';
import 'package:uni_app/features/assistant/domain/tercih_nlu.dart';

/// Üni iki dilli: uygulama dili 'en' ise İngilizce konuşur.
/// Diller arasında SCRIPT ID'LERİ değişmez — analitik ve testler dilden
/// bağımsız kalsın diye; yalnız metin çevrilir.
void main() {
  // Dil global bir anahtar (metin kütüphanesi saf Dart, Riverpod'dan
  // habersiz) — her test sonrası varsayılana dönmezse diğer testlere sızar.
  tearDown(() => RobotScripts.languageCode = 'tr');

  ChatFlow flowFor(String lang) {
    RobotScripts.languageCode = lang;
    return ChatFlow(
      nlu: TercihNlu(
        cityMap: const {'34': 'İstanbul'},
        deptNames: const {'Psikoloji', 'Hukuk'},
      ),
      cityNames: const {'34': 'İstanbul'},
    );
  }

  group('RobotScripts — dil anahtarı', () {
    test('varsayılan Türkçe', () {
      expect(RobotScripts.languageCode, 'tr');
      expect(RobotScripts.isEn, isFalse);
    });

    test("'en' tüm aileleri İngilizce tabloya çevirir", () {
      final trHello = RobotScripts.chatHelloNew.text;
      RobotScripts.languageCode = 'en';
      expect(RobotScripts.isEn, isTrue);
      expect(RobotScripts.chatHelloNew.text, isNot(trHello));
    });

    test("bilinmeyen dil kodu Türkçe'de bırakır", () {
      RobotScripts.languageCode = 'de';
      expect(RobotScripts.isEn, isFalse);
    });

    test('script id\'leri iki dilde birebir aynı', () {
      List<String> idsOf() => [
            for (final f in [
              RobotScripts.homeTercihWithProfile,
              RobotScripts.homeTercihNoProfile,
              RobotScripts.homeExamCountdown,
              RobotScripts.homeExamWeek,
              RobotScripts.homeResultsWait,
              RobotScripts.homePlacementWait,
              RobotScripts.homePlacementDone,
              RobotScripts.homeOffSeason,
              RobotScripts.tips,
              RobotScripts.wizardFirstVisit,
              RobotScripts.wizardWithProfile,
              RobotScripts.wizardNoProfile,
              RobotScripts.resultsBalanced,
              RobotScripts.resultsRisky,
              RobotScripts.resultsSafe,
              RobotScripts.resultsEmpty,
              RobotScripts.healthNoGuaranteed,
              RobotScripts.healthTooRisky,
              RobotScripts.healthTooSafe,
              RobotScripts.healthBalanced,
              RobotScripts.healthUnrated,
              RobotScripts.emptyList,
              RobotScripts.badgeCheer,
            ])
              for (final s in f) s.id,
            for (final s in [
              RobotScripts.wizardValidation,
              RobotScripts.chatHelloNew,
              RobotScripts.chatHelloBack,
              RobotScripts.chatAskScoreType,
              RobotScripts.chatAskRank,
              RobotScripts.chatAskInterests,
              RobotScripts.chatAskConstraints,
              RobotScripts.chatConfirm,
              RobotScripts.chatFocus,
              RobotScripts.chatAck,
              RobotScripts.chatPartial,
              RobotScripts.chatConfused,
              RobotScripts.chatComingSoon,
              RobotScripts.chatScoreInvalid,
              RobotScripts.chatRestart,
              RobotScripts.chatUpdate,
              RobotScripts.chatSearchError,
              RobotScripts.chatSearchMissing,
              RobotScripts.deptVerdictHigh,
              RobotScripts.deptVerdictTarget,
              RobotScripts.deptVerdictDream,
              RobotScripts.deptNeedRank,
              RobotScripts.uniFitSummary,
              RobotScripts.uniFitNone,
              RobotScripts.uniNeedRank,
              RobotScripts.emptySearch,
              RobotScripts.emptyFavorites,
              RobotScripts.emptyCompare,
              RobotScripts.emptyMyReviews,
              RobotScripts.emptyUniReviews,
              RobotScripts.emptyExplore,
              RobotScripts.emptyCity,
            ])
              s.id,
          ];

      final tr = idsOf();
      RobotScripts.languageCode = 'en';
      expect(idsOf(), tr);
    });

    test('şablon yer tutucuları İngilizce tabloda da korunur', () {
      RobotScripts.languageCode = 'en';
      expect(RobotScripts.chatConfirm.text, contains('{summary}'));
      expect(RobotScripts.chatAck.text, contains('{pieces}'));
      expect(RobotScripts.chatPartial.text, contains('{rest}'));
      expect(RobotScripts.chatHelloBack.text, contains('{profile}'));
      expect(RobotScripts.uniFitSummary.text, contains('{count}'));
      expect(RobotScripts.uniFitSummary.text, contains('{high}'));
      for (final s in RobotScripts.resultsBalanced) {
        expect(s.text, contains('{total}'));
      }
    });

    test('onboarding sayfaları: id eşliği, iki dilde dolu metin', () {
      final tr = RobotScripts.onboardingPages;
      expect(tr, hasLength(4));

      RobotScripts.languageCode = 'en';
      final en = RobotScripts.onboardingPages;
      expect(en.map((p) => p.id), tr.map((p) => p.id));
      expect(en.map((p) => p.mood), tr.map((p) => p.mood));

      for (var i = 0; i < tr.length; i++) {
        expect(en[i].title, isNotEmpty);
        expect(en[i].body, isNotEmpty);
        // Çeviri gerçekten yapılmış olmalı — kopyala-yapıştır değil.
        expect(en[i].title, isNot(tr[i].title), reason: tr[i].id);
        expect(en[i].body, isNot(tr[i].body), reason: tr[i].id);
      }
      // Son sayfa isim sorusu; Üni orada kutlama modunda.
      expect(tr.last.mood, RobotMood.celebrating);
    });

    // Türkçe eşi: robot_brain_test.dart 'her özet dürüstlük içerir
    // ("tahmin")'. İngilizce tablo da aynı sözü tutmalı — sonuç özetleri
    // tahmin dili taşır, garanti vermez.
    test('dürüstlük: İngilizce sonuç özetleri de tahmin dili taşır', () {
      RobotScripts.languageCode = 'en';
      for (final s in [
        ...RobotScripts.resultsBalanced,
        ...RobotScripts.resultsRisky,
        ...RobotScripts.resultsSafe,
      ]) {
        expect(s.text.toLowerCase(), contains('estimate'),
            reason: '${s.id} tahmin dili taşımıyor');
      }
    });
  });

  group('RobotBrain — dile göre metin, sabit id', () {
    test('selamlama İngilizce', () {
      RobotScripts.languageCode = 'en';
      final msg = RobotBrain.homeGreeting(
        HomeContext(
          now: DateTime(2026, 7, 21, 9),
          hasProfile: true,
          firstName: 'Ada',
          dayPeriod: DayPeriod.morning,
        ),
        seed: 0,
      );
      expect(msg.text, startsWith('Good morning Ada!'));
    });

    test('puan türü tepkisi: id sabit, metin çevrilir', () {
      final tr = RobotBrain.wizardScoreTypeReaction('SAY')!;
      RobotScripts.languageCode = 'en';
      final en = RobotBrain.wizardScoreTypeReaction('SAY')!;
      expect(en.id, tr.id);
      expect(en.mood, tr.mood);
      expect(en.text, isNot(tr.text));
      expect(en.text, contains('SAY'));
    });

    test('sıralama tepkisi bandı dilden bağımsız', () {
      final tr = RobotBrain.wizardRankReaction(5000, 'SAY')!;
      RobotScripts.languageCode = 'en';
      final en = RobotBrain.wizardRankReaction(5000, 'SAY')!;
      expect(en.id, 'wizard.rank.top');
      expect(en.id, tr.id);
      expect(en.text, isNot(tr.text));
    });
  });

  group('ChatFlow — çipler', () {
    test('etiket çevrilir, sendText Türkçe kalır (NLU Türkçe anlar)', () {
      flowFor('en');
      final chip = ChatFlow.interestChips
          .firstWhere((c) => c.sendText == 'yazılım');
      expect(chip.label, 'Computer / Software');

      final skip = ChatFlow.interestChips.last;
      expect(skip.label, "Doesn't matter");

      final devlet =
          ChatFlow.constraintChips.firstWhere((c) => c.sendText == 'devlet');
      expect(devlet.label, 'Public');
      expect(devlet.sendText, 'devlet');
    });

    test('puan türü çipleri iki dilde de kanonik kısaltma', () {
      flowFor('en');
      expect(ChatFlow.scoreTypeChips.map((c) => c.label),
          containsAll(['SAY', 'EA', 'TYT']));
    });

    test('İngilizce çip etiketiyle akış yine ilerler', () {
      final flow = flowFor('en');
      final start = flow.start();
      expect(start.messages.first.text, isNot(contains('Merhaba')));

      final say =
          ChatFlow.scoreTypeChips.firstWhere((c) => c.label == 'SAY');
      final r = flow.handleChip(say, draft: start.draft, step: start.step);
      expect(r.draft.scoreType, 'SAY');
    });
  });

  group('Gösterim çevirileri', () {
    test('filterLabel kanonik değeri yalnız gösterimde çevirir', () {
      expect(RobotScripts.filterLabel('Devlet'), 'Devlet');
      RobotScripts.languageCode = 'en';
      expect(RobotScripts.filterLabel('Devlet'), 'Public');
      expect(RobotScripts.filterLabel('İngilizce'), 'English');
      // Sözlükte olmayan değer aynen döner — motor sözleşmesi bozulmaz.
      expect(RobotScripts.filterLabel('Açıköğretim'), 'Açıköğretim');
    });

    test('interestLabel bilinmeyen anahtarda Türkçe etikete düşer', () {
      RobotScripts.languageCode = 'en';
      expect(RobotScripts.interestLabel('hukuk', 'Hukuk'), 'Law');
      expect(RobotScripts.interestLabel('yok', 'Bilinmeyen'), 'Bilinmeyen');
    });

    test('olumsuzlama eki dile göre okunur', () {
      expect(RobotScripts.phraseExcluded, 'hariç');
      RobotScripts.languageCode = 'en';
      expect(RobotScripts.phraseExcluded, 'excluded');
    });
  });
}
