import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/temporary_pro_access_provider.dart';

/// Rewarded reklamla alınan geçici Pro erişimi aktifken kalan süreyi
/// gösteren küçük rozet. Erişim yoksa hiçbir şey çizmez.
///
/// Kalan dakika metni 30 saniyede bir tazelenir; erişim sona erince
/// [temporaryProAccessProvider] state'i sıfırlandığı için rozet kendiliğinden
/// kaybolur.
class TemporaryProBadge extends ConsumerStatefulWidget {
  const TemporaryProBadge({super.key});

  @override
  ConsumerState<TemporaryProBadge> createState() => _TemporaryProBadgeState();
}

class _TemporaryProBadgeState extends ConsumerState<TemporaryProBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tempAccess = ref.watch(temporaryProAccessProvider);
    if (!tempAccess.hasAccess) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final minutes = (tempAccess.timeLeft.inSeconds / 60).ceil().clamp(1, 60);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tierPro.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.tierPro.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.tierPro),
          const SizedBox(width: 4),
          Text(
            loc.tempProBadge(minutes),
            style: const TextStyle(
              color: AppColors.tierPro,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
