/// Kullanıcının girdiği sınav verileri
class ScoreInput {
  final int selectedYear; // 2022, 2023, 2024, 2025
  final String scoreType; // 'TYT', 'SAY', 'EA', 'SÖZ', 'DİL'
  final double obpScore; // 0-100 arası diploma notu ortalaması
  final String selectedDepartment; // Bölüm adı (ör. "Tıp")

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
    this.selectedYear = 2025,
    required this.scoreType,
    required this.obpScore,
    required this.selectedDepartment,
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
  static double _net(int correct, int wrong) =>
      correct - (wrong / 4.0);

  double get tytTurkceNet => _net(tytTurkceCorrect, tytTurkceWrong);
  double get tytSosyalNet => _net(tytSosyalCorrect, tytSosyalWrong);
  double get tytMatNet => _net(tytMatCorrect, tytMatWrong);
  double get tytFenNet => _net(tytFenCorrect, tytFenWrong);

  double get aytMatNet => _net(aytMatCorrect, aytMatWrong);
  double get aytFizikNet => _net(aytFizikCorrect, aytFizikWrong);
  double get aytKimyaNet => _net(aytKimyaCorrect, aytKimyaWrong);
  double get aytBiyoNet => _net(aytBiyoCorrect, aytBiyoWrong);

  double get aytEdebiyatNet => _net(aytEdebiyatCorrect, aytEdebiyatWrong);
  double get aytTarih1Net => _net(aytTarih1Correct, aytTarih1Wrong);
  double get aytCografya1Net => _net(aytCografya1Correct, aytCografya1Wrong);

  double get aytTarih2Net => _net(aytTarih2Correct, aytTarih2Wrong);
  double get aytCografya2Net => _net(aytCografya2Correct, aytCografya2Wrong);
  double get aytFelsefeNet => _net(aytFelsefeCorrect, aytFelsefeWrong);
  double get aytDkabNet => _net(aytDkabCorrect, aytDkabWrong);

  double get ydtNet => _net(ydtCorrect, ydtWrong);

  /// OBP katkısı = diploma notu × 0.6
  double get obpContribution => obpScore * 0.6;

  ScoreInput copyWith({
    int? selectedYear,
    String? scoreType,
    double? obpScore,
    String? selectedDepartment,
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
