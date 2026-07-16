/// Tercih robotu sonuç sıralama seçeneği.
enum WizardSort {
  /// Uygunluğa göre (kategori içi: yüksek şanslılar taban desc, diğerleri
  /// puana yakınlık).
  fit,

  /// Taban puanına göre azalan.
  baseDesc,

  /// Başarı sıralamasına göre artan (iyi sıralama önce; sıralaması olmayanlar
  /// sona).
  rankAsc,
}

/// Tercih robotu filtreleri. Tümü opsiyonel; boş küme = filtre yok.
///
/// Not: Puan türü profilden gelir ve motorda zorunlu uygulanır (bir öğrencinin
/// tek bir yerleştirme puanı türü vardır), bu yüzden burada tutulmaz.
class WizardFilter {
  final Set<String> cityIds; // university.cityId
  final Set<String> uniTypes; // 'Devlet' / 'Vakıf'
  final Set<String> languages; // 'Türkçe' / 'İngilizce'
  final Set<String> programTypes; // 'Lisans' / 'Önlisans'
  final String deptQuery; // serbest metin bölüm/fakülte arama
  final WizardSort sort;

  const WizardFilter({
    this.cityIds = const {},
    this.uniTypes = const {},
    this.languages = const {},
    this.programTypes = const {},
    this.deptQuery = '',
    this.sort = WizardSort.fit,
  });

  bool get hasAnyFilter =>
      cityIds.isNotEmpty ||
      uniTypes.isNotEmpty ||
      languages.isNotEmpty ||
      programTypes.isNotEmpty ||
      deptQuery.trim().isNotEmpty;

  int get activeFilterCount =>
      cityIds.length +
      uniTypes.length +
      languages.length +
      programTypes.length +
      (deptQuery.trim().isEmpty ? 0 : 1);

  WizardFilter copyWith({
    Set<String>? cityIds,
    Set<String>? uniTypes,
    Set<String>? languages,
    Set<String>? programTypes,
    String? deptQuery,
    WizardSort? sort,
  }) {
    return WizardFilter(
      cityIds: cityIds ?? this.cityIds,
      uniTypes: uniTypes ?? this.uniTypes,
      languages: languages ?? this.languages,
      programTypes: programTypes ?? this.programTypes,
      deptQuery: deptQuery ?? this.deptQuery,
      sort: sort ?? this.sort,
    );
  }
}
