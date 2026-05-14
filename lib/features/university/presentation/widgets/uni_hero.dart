import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/university_model.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class UniHero extends ConsumerWidget {
  final UniversityModel uni;
  
  const UniHero({super.key, required this.uni});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.value?.contains(uni.id) ?? false;
    final user = ref.watch(authStateProvider).value;

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
          child: _frostedIconButton(
            icon: isFavorite 
              ? Icons.favorite_rounded 
              : Icons.favorite_border_rounded,
            iconColor: Colors.white,
            onTap: () {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Önce giriş yap')),
                );
                return;
              }
              ref.read(favoritesControllerProvider.notifier)
                 .toggleFavorite(user.uid, uni.id, isFavorite);
            },
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
