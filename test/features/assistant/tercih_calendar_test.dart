import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/assistant/domain/tercih_calendar.dart';

void main() {
  group('tercihPhaseFor', () {
    test('bugünkü tercih dönemi (2026-07-19)', () {
      expect(tercihPhaseFor(DateTime(2026, 7, 19)), TercihPhase.tercihPeriod);
    });

    test('faz sınırları', () {
      expect(tercihPhaseFor(DateTime(2026, 5, 1)), TercihPhase.examCountdown);
      expect(tercihPhaseFor(DateTime(2026, 6, 13)), TercihPhase.examCountdown);
      expect(tercihPhaseFor(DateTime(2026, 6, 14)), TercihPhase.examWeek);
      expect(tercihPhaseFor(DateTime(2026, 6, 20)), TercihPhase.examWeek);
      expect(tercihPhaseFor(DateTime(2026, 6, 23)), TercihPhase.resultsWait);
      expect(tercihPhaseFor(DateTime(2026, 7, 14)), TercihPhase.resultsWait);
      expect(tercihPhaseFor(DateTime(2026, 7, 15)), TercihPhase.tercihPeriod);
      expect(tercihPhaseFor(DateTime(2026, 8, 5)), TercihPhase.tercihPeriod);
      expect(tercihPhaseFor(DateTime(2026, 8, 6)), TercihPhase.placementWait);
      expect(tercihPhaseFor(DateTime(2026, 8, 28)), TercihPhase.placementDone);
      expect(tercihPhaseFor(DateTime(2026, 9, 30)), TercihPhase.placementDone);
      expect(tercihPhaseFor(DateTime(2026, 10, 1)), TercihPhase.offSeason);
      expect(tercihPhaseFor(DateTime(2026, 2, 15)), TercihPhase.offSeason);
    });

    test('yıldan bağımsız', () {
      expect(tercihPhaseFor(DateTime(2031, 7, 20)), TercihPhase.tercihPeriod);
    });
  });

  group('dayPeriodFor', () {
    test('gün dilimleri', () {
      expect(dayPeriodFor(DateTime(2026, 7, 19, 8)), DayPeriod.morning);
      expect(dayPeriodFor(DateTime(2026, 7, 19, 13)), DayPeriod.afternoon);
      expect(dayPeriodFor(DateTime(2026, 7, 19, 20)), DayPeriod.evening);
      expect(dayPeriodFor(DateTime(2026, 7, 19, 23)), DayPeriod.night);
      expect(dayPeriodFor(DateTime(2026, 7, 19, 3)), DayPeriod.night);
    });
  });

  group('phaseChipLabel', () {
    test('tercih dönemi çipi yıl içerir', () {
      expect(
        phaseChipLabel(TercihPhase.tercihPeriod, 2026),
        '2026 TERCİH DÖNEMİ',
      );
    });
  });
}
