import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/subscription_gate_widget.dart';
import '../../../university/domain/models/city_model.dart';
import '../../domain/models/city_comparison.dart';
import '../providers/comparison_providers.dart';
import '../widgets/city_compar_pie_chart.dart';
import '../widgets/city_picker_bottom_sheet.dart';

class CityComparisonScreen extends ConsumerStatefulWidget {
  const CityComparisonScreen({super.key});

  @override
  ConsumerState<CityComparisonScreen> createState() => _CityComparisonScreenState();
}

class _CityComparisonScreenState extends ConsumerState<CityComparisonScreen> {
  CityModel? _a;
  CityModel? _b;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pair = (_a != null && _b != null)
        ? ComparisonPair(idA: _a!.id, idB: _b!.id)
        : null;

    final resultAsync = pair == null
        ? const AsyncValue<CityComparisonResult?>.data(null)
        : ref.watch(cityComparisonResultProvider(pair));

    return SubscriptionGateWidget(
      requiredTier: SubscriptionTier.plus,
      showBlurPreview: true,
      onLocked: () => context.push('/compare/paywall'),
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Şehir Karşılaştır',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_a != null || _b != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _a = null;
                _b = null;
              }),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Sıfırla'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İki şehrin üniversite ekosistemini kıyasla',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CityPickCard(
                      title: 'Şehir A',
                      city: _a,
                      accent: AppColors.primary,
                      onTap: () async {
                        final pick = await CityPickerBottomSheet.show(context);
                        if (pick != null) setState(() => _a = pick);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CityPickCard(
                      title: 'Şehir B',
                      city: _b,
                      accent: AppColors.secondary,
                      onTap: () async {
                        final pick = await CityPickerBottomSheet.show(context);
                        if (pick != null) setState(() => _b = pick);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildResultArea(isDark, resultAsync),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildResultArea(
    bool isDark,
    AsyncValue<CityComparisonResult?> resultAsync,
  ) {
    if (_a == null || _b == null) {
      return _HintCard(isDark: isDark);
    }

    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _ErrorCard(message: '$e', isDark: isDark),
      data: (result) {
        if (result == null) {
          return _ErrorCard(message: 'Sonuç bulunamadı.', isDark: isDark);
        }
        return _CityResultView(result: result);
      },
    );
  }
}

class _HintCard extends StatelessWidget {
  final bool isDark;
  const _HintCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'İki şehir seçince karşılaştırma sonuçları burada gözükecek.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityPickCard extends StatelessWidget {
  final String title;
  final CityModel? city;
  final Color accent;
  final VoidCallback onTap;

  const _CityPickCard({
    required this.title,
    required this.city,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: 10),
              if (city == null) ...[
                Text(
                  'Seçmek için dokun',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Şehir Seç',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  city!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MetaPill(
                      icon: Icons.confirmation_number_rounded,
                      label: city!.plateCode,
                    ),
                    const SizedBox(width: 8),
                    _MetaPill(
                      icon: Icons.school_rounded,
                      label: '${city!.appUniversityCount}',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: isDark ? Colors.white70 : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityResultView extends StatelessWidget {
  final CityComparisonResult result;
  const _CityResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxUni = (result.universityCountA > result.universityCountB
            ? result.universityCountA
            : result.universityCountB)
        .clamp(1, 9999);

    return Column(
      children: [
        _GaugeCard(
          isDark: isDark,
          a: result.universityCountA,
          b: result.universityCountB,
          max: maxUni,
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Devlet / Vakıf Dağılımı',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Şehir A', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    CityComparPieChart(
                      stateCount: result.stateUniversityCountA,
                      foundationCount: result.foundationUniversityCountA,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Text('Şehir B', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    CityComparPieChart(
                      stateCount: result.stateUniversityCountB,
                      foundationCount: result.foundationUniversityCountB,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Top 3 Güçlü Bölüm',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Chip(label: 'Yakında'),
                  _Chip(label: 'Veri'),
                  _Chip(label: 'Eklenecek'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Not: Bu bölüm CityComparisonRepository genişletilince gerçek veriye bağlanacak.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Şehir Özellikleri',
          child: Column(
            children: [
              _InfoRow(
                label: 'Plaka',
                a: result.cityA.plateCode,
                b: result.cityB.plateCode,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Toplam Üni (DB)',
                a: result.cityA.totalUniversityCount.toString(),
                b: result.cityB.totalUniversityCount.toString(),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Üni (Uygulama)',
                a: result.cityA.appUniversityCount.toString(),
                b: result.cityB.appUniversityCount.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugeCard extends StatelessWidget {
  final bool isDark;
  final int a;
  final int b;
  final int max;
  const _GaugeCard({
    required this.isDark,
    required this.a,
    required this.b,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Üniversite Sayısı',
      child: Row(
        children: [
          Expanded(child: _MiniGauge(label: 'Şehir A', value: a, max: max, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _MiniGauge(label: 'Şehir B', value: b, max: max, color: AppColors.secondary)),
        ],
      ),
    );
  }
}

class _MiniGauge extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _MiniGauge({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final v = (value / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: v,
                  strokeWidth: 10,
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      'üni',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String a;
  final String b;
  const _InfoRow({required this.label, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            a,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            b,
            textAlign: TextAlign.left,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

