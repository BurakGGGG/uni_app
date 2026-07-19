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

  const WizardPrefs({
    this.cityIds = const {},
    this.uniTypes = const {},
    this.interestKeys = const {},
  });

  bool get isEmpty =>
      cityIds.isEmpty && uniTypes.isEmpty && interestKeys.isEmpty;

  int get activeCount => cityIds.length + uniTypes.length + interestKeys.length;

  WizardPrefs copyWith({
    Set<String>? cityIds,
    Set<String>? uniTypes,
    Set<String>? interestKeys,
  }) {
    return WizardPrefs(
      cityIds: cityIds ?? this.cityIds,
      uniTypes: uniTypes ?? this.uniTypes,
      interestKeys: interestKeys ?? this.interestKeys,
    );
  }

  Map<String, dynamic> toJson() => {
        'cityIds': cityIds.toList(),
        'uniTypes': uniTypes.toList(),
        'interestKeys': interestKeys.toList(),
      };

  factory WizardPrefs.fromJson(Map<String, dynamic> json) {
    Set<String> readSet(String key) =>
        ((json[key] as List?) ?? const []).cast<String>().toSet();
    return WizardPrefs(
      cityIds: readSet('cityIds'),
      uniTypes: readSet('uniTypes'),
      interestKeys: readSet('interestKeys'),
    );
  }
}
