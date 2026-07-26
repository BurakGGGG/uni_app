import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/generated/app_localizations.dart';

/// Grafik köprüsü, Pro özet ve notların toplandığı tek satır.
///
/// Bu üç blok sayfanın son üçte birini kaplıyordu ve ikisi (Pro özeti,
/// notlar) ücretsiz kullanıcıda yalnız satış kartı olarak duruyordu.
/// Kapalıyken tek satır; isteyen açıyor.
class CompareMoreSection extends StatefulWidget {
  final List<Widget> children;

  const CompareMoreSection({super.key, required this.children});

  @override
  State<CompareMoreSection> createState() => _CompareMoreSectionState();
}

class _CompareMoreSectionState extends State<CompareMoreSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderLightFor(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.cmpMoreTitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: AppColors.textTertiaryFor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final child in widget.children) ...[
                      const SizedBox(height: 12),
                      child,
                    ],
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
