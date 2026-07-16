import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import 'wizard_recommendation_card.dart';

/// Zorlayıcı bir programın "benzer ama ulaşılabilir" alternatiflerini listeler.
/// [picks] çağıran tarafından `similarReachable` ile hesaplanır (bellek-içi).
Future<void> showSimilarProgramsSheet(
  BuildContext context,
  UniversityMatch source,
  List<UniversityMatch> picks,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLightFor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              children: [
                const Icon(Icons.alt_route_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Benzer ama ulaşılabilir',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${source.department.name} zorlayıcı görünüyor — şansının '
                'daha yüksek olduğu yakın programlar:',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  height: 1.4,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: picks.length,
              itemBuilder: (_, i) =>
                  WizardRecommendationCard(match: picks[i]),
            ),
          ),
        ],
      ),
    ),
  );
}
