import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../router/app_router.dart';
import '../../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../domain/compare_view.dart';
import '../../providers/compare_personal_providers.dart';
import 'compare_add_to_list_sheet.dart';
import 'compare_theme.dart';

/// "Senin için" — karşılaştırmayı kullanıcının kendi puanına bağlayan blok.
///
/// Karşılaştırmanın en zayıf yanı buydu: iki üniversiteyi okuyup çıkıyordun,
/// kendi durumunla ilgisi kurulmuyordu. Burada kaç bölümün uyduğu ve
/// listene ekleme köprüsü var.
///
/// Dil bilinçli: "girebilirsin" DEĞİL "puanına uyuyor" — uygulama hiçbir
/// yerde yerleşme garantisi vermiyor.
class ComparePersonalCard extends ConsumerWidget {
  final List<CompareSide> sides;

  const ComparePersonalCard({super.key, required this.sides});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final match = ref.watch(compareMatchProvider);

    // Profil yoksa davet — karşılaştırma yine okunur, blok satış yapmaz.
    if (match.valueOrNull == null && !match.isLoading) {
      return _Shell(
        child: _Invite(
          text: loc.cmpPersonalNoProfile,
          cta: loc.cmpPersonalCta,
          onTap: () => navigateToRoute(context, AppRoutes.scoreCalculator),
        ),
      );
    }

    final eligibilities = [
      for (final side in sides)
        ref.watch(compareEligibilityProvider(side.id)).valueOrNull,
    ];
    if (eligibilities.any((e) => e == null)) {
      return const _Shell(child: _Loading());
    }

    final counts = eligibilities.map((e) => e!.count).toList();
    if (counts.every((c) => c == 0)) {
      return _Shell(child: _Line(text: loc.cmpPersonalNone));
    }

    // En çok uyan tarafın en zor programı — somut tek örnek.
    var bestIndex = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[bestIndex]) bestIndex = i;
    }
    final hardest = eligibilities[bestIndex]!.hardest;

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RobotAvatar(size: 26, animated: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _body(loc, counts),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        height: 1.4,
                      ),
                    ),
                    if (hardest != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        loc.cmpPersonalTop(
                          _short(sides[bestIndex].title),
                          hardest.department.name,
                        ),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: compareSideColor(bestIndex),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => CompareAddToListSheet.show(
                context,
                sides: sides,
                eligibilities: eligibilities.map((e) => e!).toList(),
              ),
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: Text(loc.cmpAddToList),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _body(AppLocalizations loc, List<int> counts) {
    if (counts.length < 2) return '';
    // Üçlü karşılaştırmada ilk iki taraf cümleye giriyor; üçünü tek
    // cümleye sığdırmak satırı okunmaz yapıyor.
    return loc.cmpPersonalBody(
      _short(sides[0].title),
      '${counts[0]}',
      _short(sides[1].title),
      '${counts[1]}',
    );
  }

  static String _short(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    return parts.length <= 2 ? name : parts.take(2).join(' ');
  }
}

class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).cmpPersonalTitle.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String text;
  const _Line({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RobotAvatar(size: 26, animated: false),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Invite extends StatelessWidget {
  final String text;
  final String cta;
  final VoidCallback onTap;

  const _Invite({required this.text, required this.cta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(text: text),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.calculate_rounded, size: 16),
            label: Text(cta),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
