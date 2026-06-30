import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import '../../../../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../monetization/presentation/providers/subscription_providers.dart';
import '../../../monetization/domain/enums/subscription_tier.dart';
import '../../../monetization/presentation/widgets/native_ad_widget.dart';
import '../providers/recent_searches_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _lastTrackedQuery;

  @override
  void initState() {
    super.initState();
    // Mevcut aramayı sıfırla veya koru, burada sıfırlıyoruz ki her giriş temiz olsun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildRecentSearches(
    BuildContext context,
    List<String> recent,
    AppLocalizations loc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              Text(
                loc.searchRecentTitle,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).clear(),
                child: Text(loc.searchRecentClear),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final term = recent[index];
              return ListTile(
                leading: Icon(
                  Icons.history_rounded,
                  color: AppColors.textTertiaryFor(context),
                ),
                title: Text(term, style: AppTextStyles.bodyMedium),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textTertiaryFor(context),
                  ),
                  onPressed: () =>
                      ref.read(recentSearchesProvider.notifier).remove(term),
                ),
                onTap: () {
                  _searchController.value = TextEditingValue(
                    text: term,
                    selection: TextSelection.collapsed(offset: term.length),
                  );
                  ref.read(searchQueryProvider.notifier).state = term;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header & Arama Çubuğu ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimaryFor(context),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchController,
                      autofocus: true,
                      hintText: loc.searchGlobalHint,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            ref.read(searchQueryProvider.notifier).state =
                                value;
                            if (value.trim().length >= 2 &&
                                value.trim() != _lastTrackedQuery) {
                              _lastTrackedQuery = value.trim();
                              AnalyticsService.instance.trackEvent(
                                AnalyticsEvent.searchPerformed,
                              );
                            }
                          },
                        );
                      },
                      trailing: query.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                              },
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Sonuçlar ────────────────────────────────────────
            Expanded(
              child: searchResultsAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, st) => ErrorState(
                  message: loc.searchError,
                  onRetry: () => ref.invalidate(searchResultsProvider),
                ),
                data: (results) {
                  // Arama kutusu boşken: son aramalar varsa onları göster
                  // (yoksa aşağıdaki tüm-üniversite listesine düşülür).
                  if (query.trim().isEmpty) {
                    final recent = ref.watch(recentSearchesProvider);
                    if (recent.isNotEmpty) {
                      return _buildRecentSearches(context, recent, loc);
                    }
                  }
                  if (results.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: loc.searchNoResults,
                      message: loc.searchNoResultsSub(query),
                    );
                  }

                  final showAds =
                      ref.watch(subscriptionTierProvider).valueOrNull ==
                      SubscriptionTier.free;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    scrollCacheExtent: ScrollCacheExtent.pixels(1000),
                    itemCount: showAds && results.length > 3
                        ? results.length + 1
                        : results.length,
                    itemBuilder: (context, index) {
                      if (showAds && results.length > 3 && index == 3) {
                        return const NativeAdWidget();
                      }

                      final uniIndex =
                          showAds && results.length > 3 && index > 3
                          ? index - 1
                          : index;
                      final uni = results[uniIndex];

                      return UniCard(
                        title: uni.name,
                        subtitle:
                            "${uni.type == 'Devlet' ? loc.exploreTypeState : loc.exploreTypeFoundation} • ${loc.searchEst(uni.establishedYear.toString())}",
                        rating: uni.avgRating,
                        reviewCount: uni.reviewCount,
                        tags: [
                          if (uni.hasCampus) loc.searchCampus,
                          uni.type == 'Devlet'
                              ? loc.exploreTypeState
                              : loc.exploreTypeFoundation,
                        ],
                        brandPrimaryColor: uni.brandColor,
                        logoAssetPath: uni.logoAssetPath,
                        onTap: () {
                          ref
                              .read(recentSearchesProvider.notifier)
                              .add(query);
                          context.push('/university/${uni.id}');
                        },
                        badge: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (uni.type == 'Devlet'
                                        ? AppColors.stateUni
                                        : AppColors.foundationUni)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            uni.type == 'Devlet'
                                ? loc.exploreTypeState
                                : loc.exploreTypeFoundation,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: uni.type == 'Devlet'
                                  ? AppColors.stateUni
                                  : AppColors.foundationUni,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
