import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Rozet tanımları — id'ler server tarafındaki award_badges.ts ile birebir.
class BadgeDefinition {
  final String id;
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations) label;
  final String Function(AppLocalizations) description;

  const BadgeDefinition({
    required this.id,
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
  });
}

final List<BadgeDefinition> badgeDefinitions = [
  BadgeDefinition(
    id: 'first_review',
    icon: Icons.rate_review_rounded,
    color: const Color(0xFF6C63FF),
    label: (loc) => loc.badgeFirstReview,
    description: (loc) => loc.badgeFirstReviewDesc,
  ),
  BadgeDefinition(
    id: 'detailed_reviewer',
    icon: Icons.workspace_premium_rounded,
    color: const Color(0xFFF59E0B),
    label: (loc) => loc.badgeDetailedReviewer,
    description: (loc) => loc.badgeDetailedReviewerDesc,
  ),
  BadgeDefinition(
    id: 'helpful',
    icon: Icons.thumb_up_alt_rounded,
    color: const Color(0xFF10B981),
    label: (loc) => loc.badgeHelpful,
    description: (loc) => loc.badgeHelpfulDesc,
  ),
];
