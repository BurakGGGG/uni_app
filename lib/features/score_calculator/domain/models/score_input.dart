import 'yks_subject.dart';

/// Net giriş modu: doğru/yanlış çiftleri veya direkt (küsuratlı) net.
enum NetEntryMode { correctWrong, directNet }

/// Kullanıcının girdiği sınav verileri
class ScoreInput {
  final int selectedYear; // 2022, 2023, 2024, 2025, 2026
  final String scoreType; // '' = tüm uygulanabilir türler; 'TYT', 'SAY', ...
  final double obpScore; // 0-100 arası diploma notu ortalaması
  final String selectedDepartment; // Opsiyonel hedef bölüm adı (ör. "Tıp")

  /// directNet modunda netler [directNets]'ten okunur; doğru/yanlış
  /// alanları yok sayılır.
  final NetEntryMode entryMode;
  final Map<YksSubject, double> directNets;

  /// Geçen yıl bir yükseköğretim programına yerleşti → OBP katsayısı yarıya
  /// iner (0.12 → 0.06).
  final bool placedLastYear;

  /// Meslek lisesi mezunu, kendi alanında tercih → ek OBP katkısı.
  final bool meslekOwnField;

  // ── TYT netleri (herkes girer) ────────────────────────────
  final int tytTurkceCorrect;
  final int tytTurkceWrong;
  final int tytSosyalCorrect;
  final int tytSosyalWrong;
  final int tytMatCorrect;
  final int tytMatWrong;
  final int tytFenCorrect;
  final int tytFenWrong;

  // ── AYT netleri (puan türüne göre dolu gelir) ──────────────
  // SAY
  final int aytMatCorrect;
  final int aytMatWrong;
  final int aytFizikCorrect;
  final int aytFizikWrong;
  final int aytKimyaCorrect;
  final int aytKimyaWrong;
  final int aytBiyoCorrect;
  final int aytBiyoWrong;

  // EA (Matematik + Edebiyat + Tarih-1 + Coğrafya-1)
  final int aytEdebiyatCorrect;
  final int aytEdebiyatWrong;
  final int aytTarih1Correct;
  final int aytTarih1Wrong;
  final int aytCografya1Correct;
  final int aytCografya1Wrong;

  // SÖZ (Edebiyat + Tarih-1 + Coğrafya-1 + Tarih-2 + Coğrafya-2 + Felsefe + DKAB)
  final int aytTarih2Correct;
  final int aytTarih2Wrong;
  final int aytCografya2Correct;
  final int aytCografya2Wrong;
  final int aytFelsefeCorrect;
  final int aytFelsefeWrong;
  final int aytDkabCorrect;
  final int aytDkabWrong;

  // DİL (Yabancı Dil)
  final int ydtCorrect;
  final int ydtWrong;

  const ScoreInput({
    this.selectedYear = 2026,
    this.scoreType = '',
    this.obpScore = 0,
    this.selectedDepartment = '',
    this.entryMode = NetEntryMode.correctWrong,
    this.directNets = const {},
    this.placedLastYear = false,
    this.meslekOwnField = false,
    this.tytTurkceCorrect = 0,
    this.tytTurkceWrong = 0,
    this.tytSosyalCorrect = 0,
    this.tytSosyalWrong = 0,
    this.tytMatCorrect = 0,
    this.tytMatWrong = 0,
    this.tytFenCorrect = 0,
    this.tytFenWrong = 0,
    this.aytMatCorrect = 0,
    this.aytMatWrong = 0,
    this.aytFizikCorrect = 0,
    this.aytFizikWrong = 0,
    this.aytKimyaCorrect = 0,
    this.aytKimyaWrong = 0,
    this.aytBiyoCorrect = 0,
    this.aytBiyoWrong = 0,
    this.aytEdebiyatCorrect = 0,
    this.aytEdebiyatWrong = 0,
    this.aytTarih1Correct = 0,
    this.aytTarih1Wrong = 0,
    this.aytCografya1Correct = 0,
    this.aytCografya1Wrong = 0,
    this.aytTarih2Correct = 0,
    this.aytTarih2Wrong = 0,
    this.aytCografya2Correct = 0,
    this.aytCografya2Wrong = 0,
    this.aytFelsefeCorrect = 0,
    this.aytFelsefeWrong = 0,
    this.aytDkabCorrect = 0,
    this.aytDkabWrong = 0,
    this.ydtCorrect = 0,
    this.ydtWrong = 0,
  });

  // ── Net Hesaplama ─────────────────────────────────────────
  /// Net = Doğru - (Yanlış / 4)
  static double _net(int correct, int wrong) => correct - (wrong / 4.0);

  /// Tek doğruluk noktası: aktif moda göre dersin neti.
  double netOf(YksSubject subject) {
    if (entryMode == NetEntryMode.directNet) {
      final raw = directNets[subject] ?? 0;
      return raw.clamp(subject.minNet, subject.maxQuestions.toDouble());
    }
    switch (subject) {
      case YksSubject.tytTurkce:
        return _net(tytTurkceCorrect, tytTurkceWrong);
      case YksSubject.tytSosyal:
        return _net(tytSosyalCorrect, tytSosyalWrong);
      case YksSubject.tytMat:
        return _net(tytMatCorrect, tytMatWrong);
      case YksSubject.tytFen:
        return _net(tytFenCorrect, tytFenWrong);
      case YksSubject.aytMat:
        return _net(aytMatCorrect, aytMatWrong);
      case YksSubject.aytFizik:
        return _net(aytFizikCorrect, aytFizikWrong);
      case YksSubject.aytKimya:
        return _net(aytKimyaCorrect, aytKimyaWrong);
      case YksSubject.aytBiyo:
        return _net(aytBiyoCorrect, aytBiyoWrong);
      case YksSubject.aytEdebiyat:
        return _net(aytEdebiyatCorrect, aytEdebiyatWrong);
      case YksSubject.aytTarih1:
        return _net(aytTarih1Correct, aytTarih1Wrong);
      case YksSubject.aytCografya1:
        return _net(aytCografya1Correct, aytCografya1Wrong);
      case YksSubject.aytTarih2:
        return _net(aytTarih2Correct, aytTarih2Wrong);
      case YksSubject.aytCografya2:
        return _net(aytCografya2Correct, aytCografya2Wrong);
      case YksSubject.aytFelsefe:
        return _net(aytFelsefeCorrect, aytFelsefeWrong);
      case YksSubject.aytDkab:
        return _net(aytDkabCorrect, aytDkabWrong);
      case YksSubject.ydt:
        return _net(ydtCorrect, ydtWrong);
    }
  }

  double get tytTurkceNet => netOf(YksSubject.tytTurkce);
  double get tytSosyalNet => netOf(YksSubject.tytSosyal);
  double get tytMatNet => netOf(YksSubject.tytMat);
  double get tytFenNet => netOf(YksSubject.tytFen);

  double get aytMatNet => netOf(YksSubject.aytMat);
  double get aytFizikNet => netOf(YksSubject.aytFizik);
  double get aytKimyaNet => netOf(YksSubject.aytKimya);
  double get aytBiyoNet => netOf(YksSubject.aytBiyo);

  double get aytEdebiyatNet => netOf(YksSubject.aytEdebiyat);
  double get aytTarih1Net => netOf(YksSubject.aytTarih1);
  double get aytCografya1Net => netOf(YksSubject.aytCografya1);

  double get aytTarih2Net => netOf(YksSubject.aytTarih2);
  double get aytCografya2Net => netOf(YksSubject.aytCografya2);
  double get aytFelsefeNet => netOf(YksSubject.aytFelsefe);
  double get aytDkabNet => netOf(YksSubject.aytDkab);

  double get ydtNet => netOf(YksSubject.ydt);

  /// Tüm derslerin net toplamı (deneme geçmişi ilerleme göstergesi için).
  double get totalNet =>
      YksSubject.values.fold(0, (sum, s) => sum + netOf(s));

  // ── OBP / Ek puan ─────────────────────────────────────────
  /// Ortaöğretim Başarı Puanı = diploma notu × 5 (250–500 aralığı).
  double get obp => obpScore * 5;

  /// OBP katkısı = OBP × 0.12; geçen yıl yerleşenlerde katsayı 0.06.
  /// (Varsayılan durumda diploma notu × 0.6 ile birebir aynı.)
  double get obpContribution => obp * (placedLastYear ? 0.06 : 0.12);

  /// Meslek lisesi kendi alanı ek katkısı (0.06; indirimlide 0.03).
  /// Yalnız kendi alanındaki programların yerleştirme puanına eklenir.
  double get ekPuanContribution =>
      meslekOwnField ? obp * (placedLastYear ? 0.03 : 0.06) : 0;

  // ── Serileştirme (deneme geçmişi kayıtları için) ──────────
  Map<String, dynamic> toJson() => {
        'selectedYear': selectedYear,
        'scoreType': scoreType,
        'obpScore': obpScore,
        'selectedDepartment': selectedDepartment,
        'entryMode': entryMode.name,
        'directNets': {
          for (final e in directNets.entries) e.key.name: e.value,
        },
        'placedLastYear': placedLastYear,
        'meslekOwnField': meslekOwnField,
        'tytTurkceCorrect': tytTurkceCorrect,
        'tytTurkceWrong': tytTurkceWrong,
        'tytSosyalCorrect': tytSosyalCorrect,
        'tytSosyalWrong': tytSosyalWrong,
        'tytMatCorrect': tytMatCorrect,
        'tytMatWrong': tytMatWrong,
        'tytFenCorrect': tytFenCorrect,
        'tytFenWrong': tytFenWrong,
        'aytMatCorrect': aytMatCorrect,
        'aytMatWrong': aytMatWrong,
        'aytFizikCorrect': aytFizikCorrect,
        'aytFizikWrong': aytFizikWrong,
        'aytKimyaCorrect': aytKimyaCorrect,
        'aytKimyaWrong': aytKimyaWrong,
        'aytBiyoCorrect': aytBiyoCorrect,
        'aytBiyoWrong': aytBiyoWrong,
        'aytEdebiyatCorrect': aytEdebiyatCorrect,
        'aytEdebiyatWrong': aytEdebiyatWrong,
        'aytTarih1Correct': aytTarih1Correct,
        'aytTarih1Wrong': aytTarih1Wrong,
        'aytCografya1Correct': aytCografya1Correct,
        'aytCografya1Wrong': aytCografya1Wrong,
        'aytTarih2Correct': aytTarih2Correct,
        'aytTarih2Wrong': aytTarih2Wrong,
        'aytCografya2Correct': aytCografya2Correct,
        'aytCografya2Wrong': aytCografya2Wrong,
        'aytFelsefeCorrect': aytFelsefeCorrect,
        'aytFelsefeWrong': aytFelsefeWrong,
        'aytDkabCorrect': aytDkabCorrect,
        'aytDkabWrong': aytDkabWrong,
        'ydtCorrect': ydtCorrect,
        'ydtWrong': ydtWrong,
      };

  factory ScoreInput.fromJson(Map<String, dynamic> json) {
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    final rawNets = json['directNets'] as Map<String, dynamic>? ?? const {};
    return ScoreInput(
      selectedYear: (json['selectedYear'] as num?)?.toInt() ?? 2026,
      scoreType: json['scoreType'] as String? ?? '',
      obpScore: (json['obpScore'] as num?)?.toDouble() ?? 0,
      selectedDepartment: json['selectedDepartment'] as String? ?? '',
      entryMode: NetEntryMode.values.asNameMap()[json['entryMode']] ??
          NetEntryMode.correctWrong,
      directNets: {
        for (final e in rawNets.entries)
          if (YksSubject.values.asNameMap()[e.key] != null)
            YksSubject.values.asNameMap()[e.key]!:
                (e.value as num).toDouble(),
      },
      placedLastYear: json['placedLastYear'] as bool? ?? false,
      meslekOwnField: json['meslekOwnField'] as bool? ?? false,
      tytTurkceCorrect: i('tytTurkceCorrect'),
      tytTurkceWrong: i('tytTurkceWrong'),
      tytSosyalCorrect: i('tytSosyalCorrect'),
      tytSosyalWrong: i('tytSosyalWrong'),
      tytMatCorrect: i('tytMatCorrect'),
      tytMatWrong: i('tytMatWrong'),
      tytFenCorrect: i('tytFenCorrect'),
      tytFenWrong: i('tytFenWrong'),
      aytMatCorrect: i('aytMatCorrect'),
      aytMatWrong: i('aytMatWrong'),
      aytFizikCorrect: i('aytFizikCorrect'),
      aytFizikWrong: i('aytFizikWrong'),
      aytKimyaCorrect: i('aytKimyaCorrect'),
      aytKimyaWrong: i('aytKimyaWrong'),
      aytBiyoCorrect: i('aytBiyoCorrect'),
      aytBiyoWrong: i('aytBiyoWrong'),
      aytEdebiyatCorrect: i('aytEdebiyatCorrect'),
      aytEdebiyatWrong: i('aytEdebiyatWrong'),
      aytTarih1Correct: i('aytTarih1Correct'),
      aytTarih1Wrong: i('aytTarih1Wrong'),
      aytCografya1Correct: i('aytCografya1Correct'),
      aytCografya1Wrong: i('aytCografya1Wrong'),
      aytTarih2Correct: i('aytTarih2Correct'),
      aytTarih2Wrong: i('aytTarih2Wrong'),
      aytCografya2Correct: i('aytCografya2Correct'),
      aytCografya2Wrong: i('aytCografya2Wrong'),
      aytFelsefeCorrect: i('aytFelsefeCorrect'),
      aytFelsefeWrong: i('aytFelsefeWrong'),
      aytDkabCorrect: i('aytDkabCorrect'),
      aytDkabWrong: i('aytDkabWrong'),
      ydtCorrect: i('ydtCorrect'),
      ydtWrong: i('ydtWrong'),
    );
  }

  ScoreInput copyWith({
    int? selectedYear,
    String? scoreType,
    double? obpScore,
    String? selectedDepartment,
    NetEntryMode? entryMode,
    Map<YksSubject, double>? directNets,
    bool? placedLastYear,
    bool? meslekOwnField,
    int? tytTurkceCorrect,
    int? tytTurkceWrong,
    int? tytSosyalCorrect,
    int? tytSosyalWrong,
    int? tytMatCorrect,
    int? tytMatWrong,
    int? tytFenCorrect,
    int? tytFenWrong,
    int? aytMatCorrect,
    int? aytMatWrong,
    int? aytFizikCorrect,
    int? aytFizikWrong,
    int? aytKimyaCorrect,
    int? aytKimyaWrong,
    int? aytBiyoCorrect,
    int? aytBiyoWrong,
    int? aytEdebiyatCorrect,
    int? aytEdebiyatWrong,
    int? aytTarih1Correct,
    int? aytTarih1Wrong,
    int? aytCografya1Correct,
    int? aytCografya1Wrong,
    int? aytTarih2Correct,
    int? aytTarih2Wrong,
    int? aytCografya2Correct,
    int? aytCografya2Wrong,
    int? aytFelsefeCorrect,
    int? aytFelsefeWrong,
    int? aytDkabCorrect,
    int? aytDkabWrong,
    int? ydtCorrect,
    int? ydtWrong,
  }) {
    return ScoreInput(
      selectedYear: selectedYear ?? this.selectedYear,
      scoreType: scoreType ?? this.scoreType,
      obpScore: obpScore ?? this.obpScore,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      entryMode: entryMode ?? this.entryMode,
      directNets: directNets ?? this.directNets,
      placedLastYear: placedLastYear ?? this.placedLastYear,
      meslekOwnField: meslekOwnField ?? this.meslekOwnField,
      tytTurkceCorrect: tytTurkceCorrect ?? this.tytTurkceCorrect,
      tytTurkceWrong: tytTurkceWrong ?? this.tytTurkceWrong,
      tytSosyalCorrect: tytSosyalCorrect ?? this.tytSosyalCorrect,
      tytSosyalWrong: tytSosyalWrong ?? this.tytSosyalWrong,
      tytMatCorrect: tytMatCorrect ?? this.tytMatCorrect,
      tytMatWrong: tytMatWrong ?? this.tytMatWrong,
      tytFenCorrect: tytFenCorrect ?? this.tytFenCorrect,
      tytFenWrong: tytFenWrong ?? this.tytFenWrong,
      aytMatCorrect: aytMatCorrect ?? this.aytMatCorrect,
      aytMatWrong: aytMatWrong ?? this.aytMatWrong,
      aytFizikCorrect: aytFizikCorrect ?? this.aytFizikCorrect,
      aytFizikWrong: aytFizikWrong ?? this.aytFizikWrong,
      aytKimyaCorrect: aytKimyaCorrect ?? this.aytKimyaCorrect,
      aytKimyaWrong: aytKimyaWrong ?? this.aytKimyaWrong,
      aytBiyoCorrect: aytBiyoCorrect ?? this.aytBiyoCorrect,
      aytBiyoWrong: aytBiyoWrong ?? this.aytBiyoWrong,
      aytEdebiyatCorrect: aytEdebiyatCorrect ?? this.aytEdebiyatCorrect,
      aytEdebiyatWrong: aytEdebiyatWrong ?? this.aytEdebiyatWrong,
      aytTarih1Correct: aytTarih1Correct ?? this.aytTarih1Correct,
      aytTarih1Wrong: aytTarih1Wrong ?? this.aytTarih1Wrong,
      aytCografya1Correct: aytCografya1Correct ?? this.aytCografya1Correct,
      aytCografya1Wrong: aytCografya1Wrong ?? this.aytCografya1Wrong,
      aytTarih2Correct: aytTarih2Correct ?? this.aytTarih2Correct,
      aytTarih2Wrong: aytTarih2Wrong ?? this.aytTarih2Wrong,
      aytCografya2Correct: aytCografya2Correct ?? this.aytCografya2Correct,
      aytCografya2Wrong: aytCografya2Wrong ?? this.aytCografya2Wrong,
      aytFelsefeCorrect: aytFelsefeCorrect ?? this.aytFelsefeCorrect,
      aytFelsefeWrong: aytFelsefeWrong ?? this.aytFelsefeWrong,
      aytDkabCorrect: aytDkabCorrect ?? this.aytDkabCorrect,
      aytDkabWrong: aytDkabWrong ?? this.aytDkabWrong,
      ydtCorrect: ydtCorrect ?? this.ydtCorrect,
      ydtWrong: ydtWrong ?? this.ydtWrong,
    );
  }
}
