/// Uygulama abonelik katmanları.
///
/// Her özelliğin erişim kontrolü bu enum üzerinden yapılır.
enum SubscriptionTier {
  free,
  plus,
  pro;

  /// Firestore / RevenueCat'ten gelen string'i enum'a çevirir.
  static SubscriptionTier fromString(String value) {
    return SubscriptionTier.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionTier.free,
    );
  }

  /// Kullanıcı dostu Türkçe etiket.
  String get label {
    switch (this) {
      case SubscriptionTier.free:
        return 'Ücretsiz';
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  /// Bu tier, parametre olarak verilen tier'ı karşılıyor mu?
  /// Örn: pro.satisfies(plus) → true  (pro, plus'ın üstü)
  bool satisfies(SubscriptionTier required) {
    return index >= required.index;
  }
}

// ─── Feature Gate Yardımcıları ──────────────────────────────

/// Bölüm karşılaştırması için Plus veya Pro gerekli.
bool canCompareDepartments(SubscriptionTier tier) =>
    tier == SubscriptionTier.plus || tier == SubscriptionTier.pro;

/// Şehir karşılaştırması için Plus veya Pro gerekli.
bool canCompareCities(SubscriptionTier tier) =>
    tier == SubscriptionTier.plus || tier == SubscriptionTier.pro;

/// AI karşılaştırma özeti için Pro gerekli.
bool canUseAiComparison(SubscriptionTier tier) =>
    tier == SubscriptionTier.pro;

/// Pro grafik paketi (trend, scatter, ısı haritası) için Pro gerekli.
bool canUseProCharts(SubscriptionTier tier) =>
    tier == SubscriptionTier.pro;

/// AI öneri asistanı için Pro gerekli.
bool canUseAiRecommendation(SubscriptionTier tier) =>
    tier == SubscriptionTier.pro;

/// Karşılaştırma geçmişi için Plus veya Pro gerekli.
/// Free/misafir kullanıcı buton görür ama listenin yerine paywall mesajı gösterilir.
bool canUseComparisonHistory(SubscriptionTier tier) =>
    tier == SubscriptionTier.plus || tier == SubscriptionTier.pro;
/// Karşılaştırma notları için Plus veya Pro gerekli.
bool canUseComparisonNotes(SubscriptionTier tier) =>
    tier == SubscriptionTier.plus || tier == SubscriptionTier.pro;

/// Üçlü karşılaştırma (3 entity yan yana) için Pro gerekli.
/// Plus üyeler buton görür ama tıkladıklarında paywall'a yönlendirilir.
bool canCompareTriple(SubscriptionTier tier) =>
    tier == SubscriptionTier.pro;
