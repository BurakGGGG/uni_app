/// Öğrencinin opsiyonel tercih sinyalleri — şehirler, üniversite tipi ve ilgi
/// alanları (bölüm aileleri).
///
/// SERT filtre DEĞİLDİR: eşleşen programlar kategori içi sıralamada öne
/// çekilir, hiçbir program elenmez (sert filtreler Plus'taki filtre
/// sheet'inde). `shared_preferences`'ta profilden ayrı anahtarda saklanır.
class WizardPrefs {
  final Set<String> cityIds; // university.cityId
  final Set<String> uniTypes; // 'Devlet' / 'Vakıf'
  final Set<String> interestKeys; // InterestArea.key değerleri

  /// 'Türkçe' / 'İngilizce'. Yumuşak tutulur çünkü öğretim dili bir tercih
  /// sebebidir, eleme sebebi değil: "İngilizce isterim" diyen biri de
  /// Türkçe bir programı görebilmeli. (Sert dil filtresi [WizardFilter]'da.)
  final Set<String> languages;

  const WizardPrefs({
    this.cityIds = const {},
    this.uniTypes = const {},
    this.interestKeys = const {},
    this.languages = const {},
  });

  bool get isEmpty =>
      cityIds.isEmpty &&
      uniTypes.isEmpty &&
      interestKeys.isEmpty &&
      languages.isEmpty;

  int get activeCount =>
      cityIds.length +
      uniTypes.length +
      interestKeys.length +
      languages.length;

  WizardPrefs copyWith({
    Set<String>? cityIds,
    Set<String>? uniTypes,
    Set<String>? interestKeys,
    Set<String>? languages,
  }) {
    return WizardPrefs(
      cityIds: cityIds ?? this.cityIds,
      uniTypes: uniTypes ?? this.uniTypes,
      interestKeys: interestKeys ?? this.interestKeys,
      languages: languages ?? this.languages,
    );
  }

  Map<String, dynamic> toJson() => {
        'cityIds': cityIds.toList(),
        'uniTypes': uniTypes.toList(),
        'interestKeys': interestKeys.toList(),
        'languages': languages.toList(),
      };

  factory WizardPrefs.fromJson(Map<String, dynamic> json) {
    Set<String> readSet(String key) =>
        ((json[key] as List?) ?? const []).cast<String>().toSet();
    return WizardPrefs(
      cityIds: readSet('cityIds'),
      uniTypes: readSet('uniTypes'),
      interestKeys: readSet('interestKeys'),
      languages: readSet('languages'),
    );
  }
}
