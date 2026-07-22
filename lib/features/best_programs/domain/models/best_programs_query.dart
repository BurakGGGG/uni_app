/// Sıralama ölçütü.
enum BestProgramsSort {
  /// Başarı sıralaması artan (küçük = iyi) — "en iyi" varsayılanı.
  rankAsc,

  /// Taban puanı azalan.
  scoreDesc,
}

/// "En iyi bölümler" listesinin filtre + sıralama durumu.
///
/// [categoryKey] ve [departmentName] birlikte kullanılabilir: alan seçilip
/// içinden bölüm seçildiğinde ikisi de dolu olur. İkisi de boşsa liste,
/// [search] varsa ada göre süzülür; o da boşsa tüm programlar gelir.
class BestProgramsQuery {
  final String? categoryKey;

  /// Normalize edilmemiş, ekranda göründüğü haliyle bölüm adı (tam eşleşme).
  final String? departmentName;

  /// Serbest arama (bölüm adı içinde geçer).
  final String search;

  /// 'Lisans' / 'Önlisans'. Varsayılan yalnız lisans — iki kümenin taban
  /// sıraları karşılaştırılabilir değil, tek listede karıştırılmaz.
  final Set<String> programTypes;

  /// Üniversitenin plaka/şehir kodu.
  final Set<String> cityIds;

  /// 'Devlet' / 'Vakıf'.
  final Set<String> uniTypes;

  /// 'Türkçe' / 'İngilizce' ...
  final Set<String> languages;

  /// Yalnız burslu vakıf programları.
  final bool onlyScholarship;

  /// Açıköğretim / uzaktan öğretim programlarını da göster (varsayılan false).
  final bool includeDistance;

  /// Kayıtlı puan/sıra profiline göre yalnız ulaşılabilir programlar.
  final bool onlyEligible;

  final BestProgramsSort sort;

  const BestProgramsQuery({
    this.categoryKey,
    this.departmentName,
    this.search = '',
    this.programTypes = const {'Lisans'},
    this.cityIds = const {},
    this.uniTypes = const {},
    this.languages = const {},
    this.onlyScholarship = false,
    this.includeDistance = false,
    this.onlyEligible = false,
    this.sort = BestProgramsSort.rankAsc,
  });

  /// Kullanıcının elle açtığı filtre sayısı (rozet için) — kapsam seçimi
  /// (alan/bölüm/arama) ve varsayılanlar sayılmaz.
  int get activeFilterCount =>
      (programTypes.length == 1 && programTypes.contains('Lisans') ? 0 : 1) +
      (cityIds.isEmpty ? 0 : 1) +
      (uniTypes.isEmpty ? 0 : 1) +
      (languages.isEmpty ? 0 : 1) +
      (onlyScholarship ? 1 : 0) +
      (includeDistance ? 1 : 0) +
      (onlyEligible ? 1 : 0);

  BestProgramsQuery copyWith({
    String? categoryKey,
    bool clearCategory = false,
    String? departmentName,
    bool clearDepartment = false,
    String? search,
    Set<String>? programTypes,
    Set<String>? cityIds,
    Set<String>? uniTypes,
    Set<String>? languages,
    bool? onlyScholarship,
    bool? includeDistance,
    bool? onlyEligible,
    BestProgramsSort? sort,
  }) {
    return BestProgramsQuery(
      categoryKey: clearCategory ? null : (categoryKey ?? this.categoryKey),
      departmentName:
          clearDepartment ? null : (departmentName ?? this.departmentName),
      search: search ?? this.search,
      programTypes: programTypes ?? this.programTypes,
      cityIds: cityIds ?? this.cityIds,
      uniTypes: uniTypes ?? this.uniTypes,
      languages: languages ?? this.languages,
      onlyScholarship: onlyScholarship ?? this.onlyScholarship,
      includeDistance: includeDistance ?? this.includeDistance,
      onlyEligible: onlyEligible ?? this.onlyEligible,
      sort: sort ?? this.sort,
    );
  }

  /// Filtreler değişince provider'ın yeniden çalışması için değer eşitliği
  /// şart (family parametresi olarak kullanılıyor).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BestProgramsQuery &&
        other.categoryKey == categoryKey &&
        other.departmentName == departmentName &&
        other.search == search &&
        _setEq(other.programTypes, programTypes) &&
        _setEq(other.cityIds, cityIds) &&
        _setEq(other.uniTypes, uniTypes) &&
        _setEq(other.languages, languages) &&
        other.onlyScholarship == onlyScholarship &&
        other.includeDistance == includeDistance &&
        other.onlyEligible == onlyEligible &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(
        categoryKey,
        departmentName,
        search,
        Object.hashAllUnordered(programTypes),
        Object.hashAllUnordered(cityIds),
        Object.hashAllUnordered(uniTypes),
        Object.hashAllUnordered(languages),
        onlyScholarship,
        includeDistance,
        onlyEligible,
        sort,
      );

  static bool _setEq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
