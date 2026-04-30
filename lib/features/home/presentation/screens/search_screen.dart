import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../university/presentation/providers/university_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

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
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchController,
                      autofocus: true,
                      hintText: 'Üniversite ara...',
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          ref.read(searchQueryProvider.notifier).state = value;
                        });
                      },
                      trailing: query.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Hata: $e')),
                data: (results) {
                  if (results.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'Sonuç bulunamadı',
                      description: '"$query" aramasına uygun üniversite yok.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    cacheExtent: 1000,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final uni = results[index];
                      return UniCard(
                        title: uni.name,
                        subtitle: '${uni.type} • Kuruluş: ${uni.establishedYear}',
                        rating: uni.avgRating,
                        reviewCount: uni.reviewCount,
                        tags: [
                          if (uni.hasCampus) 'Kampüslü',
                          uni.type,
                        ],
                        onTap: () => context.push('/university/${uni.id}'),
                        badge: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            uni.type,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: uni.type == 'Devlet' ? AppColors.stateUni : AppColors.foundationUni,
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
