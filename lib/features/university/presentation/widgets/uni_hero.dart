import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptic.dart';
import '../../domain/models/university_model.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class UniHero extends ConsumerStatefulWidget {
  final UniversityModel uni;
  
  const UniHero({super.key, required this.uni});

  @override
  ConsumerState<UniHero> createState() => _UniHeroState();
}

class _UniHeroState extends ConsumerState<UniHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleFavorite(bool isFavorite) {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yap')),
      );
      return;
    }

    AppHaptic.favoriteToggle();
    _heartController.forward(from: 0);
    ref.read(favoritesControllerProvider.notifier)
       .toggleFavorite(user.uid, widget.uni.id, isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final uni = widget.uni;
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.value?.contains(uni.id) ?? false;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: uni.brandColor ?? AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(6.0),
        child: _frostedIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => context.pop(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: _frostedFavoriteButton(
            isFavorite: isFavorite,
            onTap: () => _toggleFavorite(isFavorite),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final isCollapsed = top <= kToolbarHeight + MediaQuery.paddingOf(context).top + 40;
          
          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: const EdgeInsets.only(left: 60, right: 60, bottom: 14),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: Text(
                uni.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(gradient: uni.heroGradient),
              child: Stack(
                children: [
                  if (uni.brandUseDarkOverlay)
                    Container(color: Colors.black.withValues(alpha: 0.35)),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 0.9,
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              uni.logoAssetPath,
                              fit: BoxFit.contain,
                              semanticLabel: 'Üniversite logosu',
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.school_rounded,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            uni.name,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${uni.type} • Kuruluş ${uni.establishedYear}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Favori butonu — scale bounce animasyonlu frosted glass buton.
  Widget _frostedFavoriteButton({
    required bool isFavorite,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: ScaleTransition(
            scale: _heartScale,
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.error : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _frostedIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
