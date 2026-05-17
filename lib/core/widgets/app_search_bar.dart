import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_constants.dart';

/// Arama çubuğu widget'ı — Keşfet ve Ana Sayfa'da kullanılır
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final Widget? leading;
  final Widget? trailing;
  final bool autofocus;
  final FocusNode? focusNode;

  const AppSearchBar({
    super.key,
    this.hintText = 'Üniversite, bölüm veya şehir ara...',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.leading,
    this.trailing,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(context),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          onTap: readOnly ? onTap : null,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Row(
            children: [
              const SizedBox(width: 16),
              leading ??
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiaryFor(context),
                    size: 22,
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: readOnly
                    ? Text(
                        hintText,
                        style: AppTextStyles.searchHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : TextField(
                        controller: controller,
                        onChanged: onChanged,
                        autofocus: autofocus,
                        focusNode: focusNode,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: AppTextStyles.searchHint,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: true,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 12),
              ] else ...[
                const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
