import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/subscription_tier.dart';

/// Kullanıcının abonelik durumunu temsil eder.
///
/// Firestore `subscriptions/{uid}` dokümanından okunur.
/// Yazma sadece Cloud Function (RevenueCat webhook) tarafından yapılır.
class SubscriptionModel {
  final String uid;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final String platform; // "android" | "ios"
  final DateTime? expiresAt;
  final String? rcCustomerId; // RevenueCat customer ID
  final bool trialUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.uid,
    required this.tier,
    required this.status,
    required this.platform,
    this.expiresAt,
    this.rcCustomerId,
    this.trialUsed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Free tier varsayılan modeli.
  factory SubscriptionModel.free(String uid) {
    final now = DateTime.now();
    return SubscriptionModel(
      uid: uid,
      tier: SubscriptionTier.free,
      status: SubscriptionStatus.active,
      platform: 'unknown',
      trialUsed: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore dokümanından model oluşturur.
  factory SubscriptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SubscriptionModel(
      uid: doc.id,
      tier: SubscriptionTier.fromString(data['tier'] as String? ?? 'free'),
      status: SubscriptionStatus.fromString(
          data['status'] as String? ?? 'active'),
      platform: data['platform'] as String? ?? 'unknown',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      rcCustomerId: data['rcCustomerId'] as String?,
      trialUsed: data['trialUsed'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore'a yazılacak map.
  Map<String, dynamic> toFirestore() {
    return {
      'tier': tier.name,
      'status': status.name,
      'platform': platform,
      'expiresAt':
          expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'rcCustomerId': rcCustomerId,
      'trialUsed': trialUsed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Abonelik aktif mi? (active veya trial)
  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trial;

  /// Aboneliğin süresi dolmuş mu?
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Efektif tier — süresi dolmuşsa free'ye düşür.
  SubscriptionTier get effectiveTier {
    if (!isActive || isExpired) return SubscriptionTier.free;
    return tier;
  }

  SubscriptionModel copyWith({
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    String? platform,
    DateTime? expiresAt,
    String? rcCustomerId,
    bool? trialUsed,
  }) {
    return SubscriptionModel(
      uid: uid,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      platform: platform ?? this.platform,
      expiresAt: expiresAt ?? this.expiresAt,
      rcCustomerId: rcCustomerId ?? this.rcCustomerId,
      trialUsed: trialUsed ?? this.trialUsed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Abonelik durumu.
enum SubscriptionStatus {
  active,
  expired,
  trial;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionStatus.expired,
    );
  }

  String get label {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Aktif';
      case SubscriptionStatus.expired:
        return 'Süresi Dolmuş';
      case SubscriptionStatus.trial:
        return 'Deneme';
    }
  }
}

/// RevenueCat ürün ID sabitleri.
class RevenueCatProductIds {
  RevenueCatProductIds._();

  static const plusMonthly = 'unisec_plus_monthly';
  static const plusYearly = 'unisec_plus_yearly';
  static const proMonthly = 'unisec_pro_monthly';
  static const proYearly = 'unisec_pro_yearly';

  static const allIds = [plusMonthly, plusYearly, proMonthly, proYearly];
}

/// RevenueCat entitlement sabitleri.
class RevenueCatEntitlements {
  RevenueCatEntitlements._();

  static const plus = 'plus_access';
  static const pro = 'pro_access';
}
