import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.dart';

/// Tercih yolundaki tek bir adım: numara + başlık + durum + tek eylem.
///
/// Panel dört tane çizer ve hepsi aynı iskelete oturur; adımlar arasındaki
/// tek fark [body]'de duran içerik. Sunum widget'ı — veri okumaz, çağıran
/// verir; böylece testte tek tek kurulabilir.
///
/// Ekranda aynı anda YALNIZ BİR tane [primary] adım olmalı: dolu buton
/// "şimdi bunu yap" demektir, ikisi birden olursa cümle anlamını yitirir.
class UniPathStep extends StatelessWidget {
  /// 1–4. Tamamlanan adımda numara yerine ✓ çizilir.
  final int number;
  final String title;

  /// Adım tamamlandı mı? Yalnız durumu ölçülebilen adımlarda anlamlı
  /// (puan girildi / liste 24'e ulaştı).
  final bool done;

  /// Önceki adım eksik olduğu için henüz sırası gelmedi mi? Kilitli adım
  /// soluk çizilir ve butonu yerine [lockedHint] görünür — buton pasif
  /// bırakmak yerine sebebi yazmak, kullanıcıyı boş dokunuştan kurtarır.
  final bool locked;
  final String? lockedHint;

  /// Durum satırı, ilerleme çubuğu ya da not kartları.
  final Widget? body;

  final String? actionLabel;

  /// `context.push` edilecek rota; null ise buton çizilmez.
  final String? route;

  /// Sıradaki iş bu adım mı? Dolu buton yalnız burada.
  final bool primary;

  /// Ana eylemin altındaki ikincil metin bağlantısı (ör. "Tercihlerini söyle").
  final String? secondaryLabel;
  final String? secondaryRoute;

  const UniPathStep({
    super.key,
    required this.number,
    required this.title,
    this.done = false,
    this.locked = false,
    this.lockedHint,
    this.body,
    this.actionLabel,
    this.route,
    this.primary = false,
    this.secondaryLabel,
    this.secondaryRoute,
  });

  @override
  Widget build(BuildContext context) {
    final showAction = !locked && route != null && actionLabel != null;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.borderLightFor(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(number: number, done: done),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: 12),
              body!,
            ],
            if (locked && lockedHint != null) ...[
              const SizedBox(height: 12),
              Text(
                lockedHint!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiaryFor(context),
                  height: 1.4,
                ),
              ),
            ],
            if (showAction) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: primary ? 48 : 44,
                child: primary
                    ? FilledButton(
                        onPressed: () => navigateToRoute(context, route!),
                        child: Text(actionLabel!),
                      )
                    : OutlinedButton(
                        onPressed: () => navigateToRoute(context, route!),
                        child: Text(actionLabel!),
                      ),
              ),
              if (secondaryLabel != null && secondaryRoute != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                      navigateToRoute(context, secondaryRoute!),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(secondaryLabel!),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Adım numarası — tamamlandıysa dolu daire içinde ✓.
class _Badge extends StatelessWidget {
  final int number;
  final bool done;
  const _Badge({required this.number, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.success : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.success : AppColors.borderLightFor(context),
          width: 1.5,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : Text(
              '$number',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondaryFor(context),
              ),
            ),
    );
  }
}
