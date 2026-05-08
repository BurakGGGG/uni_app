import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../university/domain/models/city_model.dart';
import '../../../university/presentation/providers/university_providers.dart';
import '../../../university/presentation/widgets/city_logo.dart';

class CityPickerBottomSheet {
  static Future<CityModel?> show(BuildContext context) {
    return showModalBottomSheet<CityModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _Shell(),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) =>
              _Body(scrollController: scrollController),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _Body({required this.scrollController});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Şehir Seç',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: AppSearchBar(
            controller: _searchCtrl,
            hintText: 'Şehir ara…',
            onChanged: (v) => setState(() => _query = v),
            trailing: _query.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textTertiary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  )
                : null,
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),
        Expanded(
          child: citiesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (cities) {
              final q = _query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? cities
                  : cities
                      .where((c) =>
                          c.name.toLowerCase().contains(q) ||
                          c.plateCode.toLowerCase().contains(q))
                      .toList();
              if (filtered.isEmpty) {
                return const _Empty(
                  icon: Icons.search_off_rounded,
                  title: 'Sonuç bulunamadı',
                  subtitle: 'Farklı bir arama deneyebilirsin.',
                );
              }
              return ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CityTile(
                  city: filtered[i],
                  onTap: () => Navigator.pop(context, filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CityTile extends StatelessWidget {
  final CityModel city;
  final VoidCallback onTap;
  const _CityTile({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: city.surfaceGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: CityLogo(city: city, size: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plaka: ${city.plateCode} • Üni: ${city.appUniversityCount}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Empty({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

