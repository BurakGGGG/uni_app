import '../../../l10n/generated/app_localizations.dart';

/// Rozet kategorileri — Rozetlerim ekranındaki bölümler.
enum BadgeCategory {
  reviewer,
  hero,
  collection,
  explorer,
  analyst,
  ambassador,
  streak,
  membership,
  special,
}

/// Rozetin ilerlemesini besleyen sayaç.
enum BadgeMetric {
  reviews,
  likesReceived,
  favorites,
  universitiesViewed,
  citiesViewed,
  comparisons,
  shares,
  streak,
  membershipDays,

  /// Eşiksiz (boolean) kriterler: profil tamamlama, doğrulama, early adopter.
  none,
}

/// Rozet tanımı — id'ler server tarafındaki
/// functions/src/badges/catalog.ts ile birebir aynı tutulmalıdır.
class BadgeDefinition {
  final String id;
  final BadgeCategory category;

  /// 1'den başlayan kademe; özel (tek seviyeli) rozetlerde 0.
  final int tier;
  final BadgeMetric metric;

  /// İlerleme çubuğu hedefi; boolean kriterlerde null.
  final int? target;
  final String Function(AppLocalizations) label;
  final String Function(AppLocalizations) description;

  const BadgeDefinition({
    required this.id,
    required this.category,
    required this.tier,
    required this.metric,
    this.target,
    required this.label,
    required this.description,
  });

  String get assetPath => 'assets/badges/$id.svg';
}

/// Bir rozetin kullanıcı özelindeki durumu.
class BadgeProgress {
  final BadgeDefinition definition;

  /// Kazanıldığı an; kazanılmadıysa null.
  final DateTime? earnedAt;
  final int current;

  const BadgeProgress({
    required this.definition,
    this.earnedAt,
    required this.current,
  });

  bool get earned => earnedAt != null;

  /// 0..1 arası ilerleme; boolean kriterlerde kazanılana dek 0.
  double get fraction {
    final target = definition.target;
    if (earned) return 1;
    if (target == null || target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }
}

String badgeCategoryLabel(AppLocalizations loc, BadgeCategory category) {
  switch (category) {
    case BadgeCategory.reviewer:
      return loc.badgeCategoryReviewer;
    case BadgeCategory.hero:
      return loc.badgeCategoryHero;
    case BadgeCategory.collection:
      return loc.badgeCategoryCollection;
    case BadgeCategory.explorer:
      return loc.badgeCategoryExplorer;
    case BadgeCategory.analyst:
      return loc.badgeCategoryAnalyst;
    case BadgeCategory.ambassador:
      return loc.badgeCategoryAmbassador;
    case BadgeCategory.streak:
      return loc.badgeCategoryStreak;
    case BadgeCategory.membership:
      return loc.badgeCategoryMembership;
    case BadgeCategory.special:
      return loc.badgeCategorySpecial;
  }
}

/// Tüm rozet kataloğu. Sıra: kategori içi kademe sırası.
final List<BadgeDefinition> badgeCatalog = [
  // ─── Yorumcu ───────────────────────────────────────────────────
  BadgeDefinition(
    id: 'first_review',
    category: BadgeCategory.reviewer,
    tier: 1,
    metric: BadgeMetric.reviews,
    target: 1,
    label: (loc) => loc.badgeFirstReview,
    description: (loc) => loc.badgeFirstReviewDesc,
  ),
  BadgeDefinition(
    id: 'detailed_reviewer',
    category: BadgeCategory.reviewer,
    tier: 2,
    metric: BadgeMetric.reviews,
    target: 3,
    label: (loc) => loc.badgeDetailedReviewer,
    description: (loc) => loc.badgeDetailedReviewerDesc,
  ),
  BadgeDefinition(
    id: 'prolific_reviewer',
    category: BadgeCategory.reviewer,
    tier: 3,
    metric: BadgeMetric.reviews,
    target: 10,
    label: (loc) => loc.badgeProlificReviewer,
    description: (loc) => loc.badgeProlificReviewerDesc,
  ),
  BadgeDefinition(
    id: 'review_legend',
    category: BadgeCategory.reviewer,
    tier: 4,
    metric: BadgeMetric.reviews,
    target: 25,
    label: (loc) => loc.badgeReviewLegend,
    description: (loc) => loc.badgeReviewLegendDesc,
  ),
  // ─── Kahraman (beğeni) ─────────────────────────────────────────
  BadgeDefinition(
    id: 'helpful',
    category: BadgeCategory.hero,
    tier: 1,
    metric: BadgeMetric.likesReceived,
    target: 10,
    label: (loc) => loc.badgeHelpful,
    description: (loc) => loc.badgeHelpfulDesc,
  ),
  BadgeDefinition(
    id: 'community_hero',
    category: BadgeCategory.hero,
    tier: 2,
    metric: BadgeMetric.likesReceived,
    target: 50,
    label: (loc) => loc.badgeCommunityHero,
    description: (loc) => loc.badgeCommunityHeroDesc,
  ),
  BadgeDefinition(
    id: 'like_magnet',
    category: BadgeCategory.hero,
    tier: 3,
    metric: BadgeMetric.likesReceived,
    target: 150,
    label: (loc) => loc.badgeLikeMagnet,
    description: (loc) => loc.badgeLikeMagnetDesc,
  ),
  // ─── Koleksiyon (favori) ───────────────────────────────────────
  BadgeDefinition(
    id: 'collector',
    category: BadgeCategory.collection,
    tier: 1,
    metric: BadgeMetric.favorites,
    target: 5,
    label: (loc) => loc.badgeCollector,
    description: (loc) => loc.badgeCollectorDesc,
  ),
  BadgeDefinition(
    id: 'master_collector',
    category: BadgeCategory.collection,
    tier: 2,
    metric: BadgeMetric.favorites,
    target: 15,
    label: (loc) => loc.badgeMasterCollector,
    description: (loc) => loc.badgeMasterCollectorDesc,
  ),
  // ─── Keşif ─────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'explorer',
    category: BadgeCategory.explorer,
    tier: 1,
    metric: BadgeMetric.universitiesViewed,
    target: 10,
    label: (loc) => loc.badgeExplorer,
    description: (loc) => loc.badgeExplorerDesc,
  ),
  BadgeDefinition(
    id: 'wanderer',
    category: BadgeCategory.explorer,
    tier: 2,
    metric: BadgeMetric.universitiesViewed,
    target: 30,
    label: (loc) => loc.badgeWanderer,
    description: (loc) => loc.badgeWandererDesc,
  ),
  BadgeDefinition(
    id: 'cartographer',
    category: BadgeCategory.explorer,
    tier: 3,
    metric: BadgeMetric.universitiesViewed,
    target: 60,
    label: (loc) => loc.badgeCartographer,
    description: (loc) => loc.badgeCartographerDesc,
  ),
  BadgeDefinition(
    id: 'city_traveler',
    category: BadgeCategory.explorer,
    tier: 1,
    metric: BadgeMetric.citiesViewed,
    target: 5,
    label: (loc) => loc.badgeCityTraveler,
    description: (loc) => loc.badgeCityTravelerDesc,
  ),
  // ─── Analiz (karşılaştırma) ────────────────────────────────────
  BadgeDefinition(
    id: 'analyst',
    category: BadgeCategory.analyst,
    tier: 1,
    metric: BadgeMetric.comparisons,
    target: 5,
    label: (loc) => loc.badgeAnalyst,
    description: (loc) => loc.badgeAnalystDesc,
  ),
  BadgeDefinition(
    id: 'strategist',
    category: BadgeCategory.analyst,
    tier: 2,
    metric: BadgeMetric.comparisons,
    target: 20,
    label: (loc) => loc.badgeStrategist,
    description: (loc) => loc.badgeStrategistDesc,
  ),
  // ─── Paylaşım ──────────────────────────────────────────────────
  BadgeDefinition(
    id: 'ambassador',
    category: BadgeCategory.ambassador,
    tier: 1,
    metric: BadgeMetric.shares,
    target: 3,
    label: (loc) => loc.badgeAmbassador,
    description: (loc) => loc.badgeAmbassadorDesc,
  ),
  BadgeDefinition(
    id: 'super_ambassador',
    category: BadgeCategory.ambassador,
    tier: 2,
    metric: BadgeMetric.shares,
    target: 10,
    label: (loc) => loc.badgeSuperAmbassador,
    description: (loc) => loc.badgeSuperAmbassadorDesc,
  ),
  // ─── Seri ──────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'streak_starter',
    category: BadgeCategory.streak,
    tier: 1,
    metric: BadgeMetric.streak,
    target: 3,
    label: (loc) => loc.badgeStreakStarter,
    description: (loc) => loc.badgeStreakStarterDesc,
  ),
  BadgeDefinition(
    id: 'streak_keeper',
    category: BadgeCategory.streak,
    tier: 2,
    metric: BadgeMetric.streak,
    target: 7,
    label: (loc) => loc.badgeStreakKeeper,
    description: (loc) => loc.badgeStreakKeeperDesc,
  ),
  BadgeDefinition(
    id: 'streak_master',
    category: BadgeCategory.streak,
    tier: 3,
    metric: BadgeMetric.streak,
    target: 30,
    label: (loc) => loc.badgeStreakMaster,
    description: (loc) => loc.badgeStreakMasterDesc,
  ),
  // ─── Üyelik ────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'loyal_member',
    category: BadgeCategory.membership,
    tier: 1,
    metric: BadgeMetric.membershipDays,
    target: 30,
    label: (loc) => loc.badgeLoyalMember,
    description: (loc) => loc.badgeLoyalMemberDesc,
  ),
  BadgeDefinition(
    id: 'veteran',
    category: BadgeCategory.membership,
    tier: 2,
    metric: BadgeMetric.membershipDays,
    target: 365,
    label: (loc) => loc.badgeVeteran,
    description: (loc) => loc.badgeVeteranDesc,
  ),
  // ─── Özel ──────────────────────────────────────────────────────
  BadgeDefinition(
    id: 'profile_complete',
    category: BadgeCategory.special,
    tier: 0,
    metric: BadgeMetric.none,
    label: (loc) => loc.badgeProfileComplete,
    description: (loc) => loc.badgeProfileCompleteDesc,
  ),
  BadgeDefinition(
    id: 'verified_scholar',
    category: BadgeCategory.special,
    tier: 0,
    metric: BadgeMetric.none,
    label: (loc) => loc.badgeVerifiedScholar,
    description: (loc) => loc.badgeVerifiedScholarDesc,
  ),
  BadgeDefinition(
    id: 'early_adopter',
    category: BadgeCategory.special,
    tier: 0,
    metric: BadgeMetric.none,
    label: (loc) => loc.badgeEarlyAdopter,
    description: (loc) => loc.badgeEarlyAdopterDesc,
  ),
];
