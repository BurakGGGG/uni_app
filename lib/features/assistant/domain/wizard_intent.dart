/// Üni sohbetinin doğal dil ayrıştırma çıktısı (saf Dart, ağ yok).
///
/// [TercihNlu] tek kullanıcı mesajından ne anladıysa buraya koyar; ChatFlow
/// bunu sohbet taslağına uygular. Alanların hiçbiri zorunlu değildir —
/// "İstanbul'da devlet psikoloji, sıralamam 80 bin" tek mesajı dört alanı
/// birden doldurabilir, "merhaba" hiçbirini doldurmaz.
library;

/// Kullanıcının andığı somut bölüm/meslek hedefi.
///
/// [query] motorun `deptQuery` filtresiyle birebir uyumludur: motor
/// `dept.name.toLowerCase().contains(query)` yapar, bu yüzden query her zaman
/// küçük harf ve gerçek bölüm adlarında geçen bir parçadır ("psikoloji",
/// "öğretmenliği"). [label] kullanıcıya dönük addır ("Psikoloji").
class DeptIntent {
  final String label;
  final String query;

  const DeptIntent({required this.label, required this.query});

  @override
  bool operator ==(Object other) =>
      other is DeptIntent && other.label == label && other.query == query;

  @override
  int get hashCode => Object.hash(label, query);

  @override
  String toString() => 'DeptIntent($label → "$query")';
}

class WizardIntent {
  /// 'TYT' / 'SAY' / 'EA' / 'SÖZ' / 'DİL' — StudentScoreProfile.scoreType.
  final String? scoreType;

  /// Başarı sıralaması ("80 bin" → 80000).
  final int? rank;

  /// Yerleştirme puanı ("462,5" → 462.5).
  final double? score;

  /// Plaka kodları ('34') — WizardFilter.cityIds / WizardPrefs.cityIds ile
  /// aynı biçim.
  final Set<String> cityIds;

  /// 'Devlet' / 'Vakıf' — filtre etiketleriyle birebir.
  final Set<String> uniTypes;

  /// 'Türkçe' / 'İngilizce'.
  final Set<String> languages;

  /// 'Lisans' / 'Önlisans'.
  final Set<String> programTypes;

  /// Yalnız burslu programlar istendi mi. null = hiç söz edilmedi.
  final bool? onlyScholarship;

  /// Andığı somut bölümler. Motor filtresine TEK query yazılabildiğinden
  /// birden çok girişte seçim ChatFlow'a kalır.
  final List<DeptIntent> depts;

  /// InterestArea.key değerleri — WizardPrefs.interestKeys'e yazılacak
  /// yumuşak ilgi sinyalleri (meslek sözlüğünden türetilir, eleme yapmaz).
  final Set<String> interestKeys;

  /// Tanınan parçalar çıktıktan sonra kalan anlamlı metin (fold edilmiş).
  /// Boş değilse Üni "şunu tam anlayamadım" diyebilir; Faz B'de Pro için
  /// sunucuya gider.
  final String unresolved;

  // ── Çıkarmalar — olumsuz klausellerden ("istanbulu istemiyorum",
  // "vakıf olmasın"). Taslağa eklenmez, taslaktan SİLİNİR.
  final Set<String> removeCityIds;
  final Set<String> removeUniTypes;
  final Set<String> removeLanguages;
  final Set<String> removeProgramTypes;
  final List<DeptIntent> removeDepts;
  final Set<String> removeInterestKeys;

  const WizardIntent({
    this.scoreType,
    this.rank,
    this.score,
    this.cityIds = const {},
    this.uniTypes = const {},
    this.languages = const {},
    this.programTypes = const {},
    this.onlyScholarship,
    this.depts = const [],
    this.interestKeys = const {},
    this.unresolved = '',
    this.removeCityIds = const {},
    this.removeUniTypes = const {},
    this.removeLanguages = const {},
    this.removeProgramTypes = const {},
    this.removeDepts = const [],
    this.removeInterestKeys = const {},
  });

  /// En az bir alan yakalandı mı ([unresolved] sayılmaz; çıkarmalar
  /// sayılır — "istanbulu istemiyorum" anlaşılmış bir girdidir).
  bool get hasAny =>
      scoreType != null ||
      rank != null ||
      score != null ||
      cityIds.isNotEmpty ||
      uniTypes.isNotEmpty ||
      languages.isNotEmpty ||
      programTypes.isNotEmpty ||
      onlyScholarship != null ||
      depts.isNotEmpty ||
      interestKeys.isNotEmpty ||
      hasRemovals;

  bool get hasRemovals =>
      removeCityIds.isNotEmpty ||
      removeUniTypes.isNotEmpty ||
      removeLanguages.isNotEmpty ||
      removeProgramTypes.isNotEmpty ||
      removeDepts.isNotEmpty ||
      removeInterestKeys.isNotEmpty;
}
