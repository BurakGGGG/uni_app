import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../comparison_picker_slot.dart';

/// Üç karşılaştırma ekranının ortak seçim adımı.
///
/// Üçü de aynı şeyi ayrı ayrı kuruyordu ve üçü de aynı cümleyi üç kez
/// söylüyordu: üst çubuk başlığı ("Üniversite Karşılaştır"), hemen altında
/// birebir aynı metni yazan bir kart başlığı, iki kutunun içinde "Seçmek
/// için dokun" ve en altta "iki tane seçince sonuçlar burada gözükecek"
/// diyen bir kart daha. Ekranın alt yarısı bomboştu.
///
/// Şimdi: tek cümlelik giriş → iki slot → hangi tarafın eksik olduğunu
/// gösteren adım satırı → dokunulabilir öneriler. Başlık üst çubukta bir
/// kez yazıyor.
class ComparePickStage extends StatelessWidget {
  /// Ne yapıldığını anlatan tek cümle (üst çubuk başlığını tekrar etmez).
  final String lead;

  final Widget slotA;
  final Widget slotB;

  final bool filledA;
  final bool filledB;

  /// Eksik tarafın adı ("Üniversite B" gibi) — adım satırında geçer.
  final String nextLabel;

  /// Öneriler, ipuçları: seçim yapılmadan önce ekranı dolduran her şey.
  final List<Widget> children;

  const ComparePickStage({
    super.key,
    required this.lead,
    required this.slotA,
    required this.slotB,
    required this.filledA,
    required this.filledB,
    required this.nextLabel,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            lead,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: slotA),
              const SizedBox(width: 10),
              const ComparisonVsBadge(size: 40),
              const SizedBox(width: 10),
              Expanded(child: slotB),
            ],
          ),
          const SizedBox(height: 14),
          _StepRow(
            filledA: filledA,
            filledB: filledB,
            text: filledA || filledB
                ? loc.cmpPickNext(nextLabel)
                : loc.cmpPickStart,
          ),
          ...children,
        ],
      ),
    );
  }
}

/// İki nokta + tek cümle: hangi taraf dolu, sırada ne var.
///
/// "İki tane seç" cümlesinin üç ayrı kopyasının yerini alıyor; buradaki
/// hâli durumu da söylüyor, yalnız kuralı değil.
class _StepRow extends StatelessWidget {
  final bool filledA;
  final bool filledB;
  final String text;

  const _StepRow({
    required this.filledA,
    required this.filledB,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: filledA, color: AppColors.primary),
        const SizedBox(width: 5),
        _Dot(active: filledB, color: AppColors.secondary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final Color color;

  const _Dot({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? color : AppColors.borderFor(context),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Seçim ekranının önerileri.
///
/// Ücretsiz kullanıcıda da çalışır (geçmiş çalışmaz — o hub'da duruyor) ve
/// ilk kez giren birinin ekranda takılıp kalmasını engeller: dokunulan
/// öneri BOŞ olan tarafa yerleşir.
class ComparePickSuggestions extends StatelessWidget {
  final String title;
  final List<ComparePickSuggestion> items;

  const ComparePickSuggestions({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          loc.cmpPickSuggestHint,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryFor(context),
          ),
        ),
        const SizedBox(height: 10),
        // Yatay şerit yerine dikey liste: ekranın altı zaten boştu, uzun
        // bölüm adları 118px'lik kartlara sığmıyordu ve yatay kaydırmayla
        // gizlenen öneri hiç görülmüyordu.
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLightFor(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 58,
                    color: AppColors.borderLightFor(context),
                  ),
                _SuggestionRow(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ComparePickSuggestion {
  final String label;
  final String? sublabel;
  final Widget leading;
  final VoidCallback onTap;

  const ComparePickSuggestion({
    required this.label,
    required this.leading,
    required this.onTap,
    this.sublabel,
  });
}

class _SuggestionRow extends StatelessWidget {
  final ComparePickSuggestion item;
  const _SuggestionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              SizedBox(width: 36, child: Center(child: item.leading)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.sublabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  item.sublabel!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(width: 6),
              Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: AppColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
