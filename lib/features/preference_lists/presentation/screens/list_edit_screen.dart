import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../assistant/domain/robot_brain.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../preference_wizard/domain/list_health.dart';
import '../../../preference_wizard/domain/models/student_score_profile.dart';
import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../../../score_calculator/domain/models/match_result.dart';
import '../../domain/list_overview.dart';
import '../../domain/models/preference_list_model.dart';
import '../providers/preference_list_providers.dart';
import '../widgets/dashed_box.dart';
import '../widgets/department_picker_sheet.dart';
import '../widgets/list_actions_sheet.dart';
import '../widgets/list_balance_bar.dart';

/// Tek bir tercih listesi: özet + sıralanabilir tercihler.
///
/// **Kaydet butonu YOK** (kullanıcı kararı): her değişiklik anında yazılır,
/// altta birkaç saniye "GERİ AL" durur. Eski hâlde sürükleyip kaydetmeden
/// çıkan öğrenci emeğini kaybediyordu — bir sıralama ekranında en kolay
/// yapılan hata buydu.
class ListEditScreen extends ConsumerStatefulWidget {
  final String listId;
  const ListEditScreen({super.key, required this.listId});

  @override
  ConsumerState<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends ConsumerState<ListEditScreen> {
  /// Ekrandaki sıra. Firestore'dan gelenle senkron tutulur ama kullanıcı
  /// sürüklerken ondan önde gider (iyimser güncelleme).
  List<PreferenceItem>? _items;

  /// En son yazılan hâl — gelen stream'in bizim yazımımız mı yoksa başka bir
  /// cihazdan gelen değişiklik mi olduğunu ayırt etmek için.
  List<PreferenceItem>? _saved;

  /// Sunucudan en son GÖRÜLEN hâl. Aynı anlık görüntüyle tekrar çizilmek
  /// (ör. "yazılıyor" göstergesi açılıp kapanırken) uzaktan gelen bir
  /// değişiklik sayılmamalı — yoksa daha yeni yerel silme geri gelir.
  List<PreferenceItem>? _remote;

  Timer? _saveTimer;
  bool _saving = false;

  /// Sürüklerken her kare yazmamak için: birkaç hızlı hareket tek yazıma
  /// toplanır.
  static const Duration _kSaveDebounce = Duration(milliseconds: 600);

  /// `dispose` içinde `ref` kullanılamaz; depoyu önden tutuyoruz ki ekrandan
  /// çıkarken bekleyen yazım yine de gitsin.
  late final _repo = ref.read(preferenceListRepositoryProvider);

  @override
  void dispose() {
    _saveTimer?.cancel();
    final pending = _items;
    // Kaydedilmemiş bir sıra kaldıysa ekran kapanırken son bir kez yaz.
    if (pending != null && !_sameOrder(pending, _saved)) {
      unawaited(_repo.reorderItems(widget.listId, pending).catchError((_) {}));
    }
    super.dispose();
  }

  // ─── Durum senkronu ──────────────────────────────────────────

  void _syncFromRemote(PreferenceListModel list) {
    final incoming = _normalized(list.items);
    if (_items == null) {
      _items = incoming;
      _saved = incoming;
      _remote = incoming;
      return;
    }
    // Aynı anlık görüntü yeniden çizildi: uzaktan haber yok, karışma.
    if (_sameOrder(_remote, incoming)) return;
    _remote = incoming;

    // Gerçekten yeni bir uzak hâl geldi. Bekleyen yerel değişiklik varsa
    // (kullanıcı hâlâ sürüklüyor) ona dokunmuyoruz; yoksa ekranı tazele.
    if (_sameOrder(_items, _saved)) {
      _items = incoming;
      _saved = incoming;
    }
  }

  List<PreferenceItem> get _current => _items ?? const [];

  /// Yeni sırayı ekrana basar ve yazımı planlar.
  ///
  /// [undoTo] verilirse altta "GERİ AL" çıkar — sürükleme, silme ve
  /// sıralama hepsi bu tek yoldan geçer, geri alma davranışı tek yerde.
  void _apply(
    List<PreferenceItem> next, {
    List<PreferenceItem>? undoTo,
    String? message,
    bool immediate = false,
  }) {
    final normalized = _normalized(next);
    setState(() => _items = normalized);
    _scheduleSave(immediate: immediate);

    if (undoTo == null || message == null) return;
    final snapshot = _normalized(undoTo);
    showAppSnackBar(
      context,
      message: message,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: AppLocalizations.of(context).prefListUndoAction,
        textColor: Colors.white,
        onPressed: () {
          if (!mounted) return;
          setState(() => _items = snapshot);
          _scheduleSave(immediate: true);
        },
      ),
    );
  }

  void _scheduleSave({bool immediate = false}) {
    _saveTimer?.cancel();
    if (immediate) {
      unawaited(_save());
      return;
    }
    _saveTimer = Timer(_kSaveDebounce, () => unawaited(_save()));
  }

  Future<void> _save() async {
    final items = _items;
    if (items == null || _saving || _sameOrder(items, _saved)) return;
    setState(() => _saving = true);
    try {
      await _repo.reorderItems(widget.listId, items);
      if (!mounted) return;
      setState(() => _saved = _normalized(items));
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: AppLocalizations.of(context).prefListSaveError('$e'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Eylemler ────────────────────────────────────────────────

  Future<void> _addItem() async {
    final loc = AppLocalizations.of(context);
    final current = _current;
    if (current.length >= PreferenceListModel.maxItems) {
      showAppSnackBar(
        context,
        message: loc.prefListMaxItems(PreferenceListModel.maxItems),
      );
      return;
    }

    final newItem = await DepartmentPickerSheet.show(context);
    if (newItem == null || !mounted) return;

    if (current.any((i) => i.deptId == newItem.deptId)) {
      showAppSnackBar(context, message: loc.prefListDuplicateDepartment);
      return;
    }
    _apply([...current, newItem], immediate: true);
  }

  void _removeAt(int index) {
    final current = _current;
    if (index < 0 || index >= current.length) return;
    final removed = current[index];
    _apply(
      [...current]..removeAt(index),
      undoTo: current,
      message: AppLocalizations.of(context).prefListItemRemoved(removed.uniName),
      immediate: true,
    );
  }

  /// Üni'nin sağlıklı sırası: zorlayıcılar üstte, güvenliler altta.
  ///
  /// ÖSYM yerleştirmesi listeyi yukarıdan aşağı tarar — en çok istenen
  /// (ve en zor) program üstte olmazsa öğrenci daha kolay girdiği bir alt
  /// tercihe yerleşip üsttekini kaçırır. Grup içinde taban puanı yüksek
  /// olan önce gelir.
  void _sortByHealth(StudentScoreProfile profile, int? estimatedRank) {
    final current = _current;
    if (current.length < 2) return;

    int rank(PreferenceItem item) => switch (categorizeListItem(
          item,
          profile,
          estimatedStudentRank: estimatedRank,
        )) {
          MatchCategory.dream => 0,
          MatchCategory.target => 1,
          MatchCategory.guaranteed => 2,
          // Değerlendirilemeyenler en sona: sıraları hakkında bir şey
          // söyleyemiyorum, öne almak yanıltıcı olur.
          null => 3,
        };

    final sorted = [...current]
      ..sort((a, b) {
        final byBand = rank(a).compareTo(rank(b));
        if (byBand != 0) return byBand;
        final byScore = (b.baseScore ?? 0).compareTo(a.baseScore ?? 0);
        if (byScore != 0) return byScore;
        return a.order.compareTo(b.order);
      });

    _apply(
      sorted,
      undoTo: current,
      message: AppLocalizations.of(context).prefListSortedByRisk,
      immediate: true,
    );
  }

  // ─── Yardımcılar ─────────────────────────────────────────────

  List<PreferenceItem> _normalized(List<PreferenceItem> items) =>
      List<PreferenceItem>.generate(
        items.length,
        (i) => items[i].copyWith(order: i + 1),
        growable: false,
      );

  bool _sameOrder(List<PreferenceItem>? a, List<PreferenceItem>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].deptId != b[i].deptId) return false;
    }
    return true;
  }

  // ─── Çizim ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final listAsync = ref.watch(preferenceListProvider(widget.listId));

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: listAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(loc.errorGeneral(e.toString()))),
        data: (list) {
          if (list == null) return Center(child: Text(loc.prefListNotFound));
          _syncFromRemote(list);
          return _content(list);
        },
      ),
    );
  }

  Widget _content(PreferenceListModel list) {
    final items = _current;
    final profile = ref.watch(studentScoreProfileProvider);
    final estimator = ref.watch(rankEstimatorProvider).valueOrNull;
    final estimatedRank = profile == null || profile.hasRank || !profile.hasScore
        ? null
        : estimator?.estimateRank(profile.placementScore, profile.scoreType);

    final health = profile == null
        ? null
        : analyzeListHealth(items, profile, estimatedStudentRank: estimatedRank);
    final overview = ListOverview(
      list: list.copyWith(items: items),
      health: health,
      pinned: ref.watch(pinnedListProvider) == list.id,
    );

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _TopBar(
              saving: _saving,
              onBack: () => Navigator.pop(context),
              onMore: () => ListActionsSheet.show(
                context,
                ref,
                overview,
                onDeleted: () {
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: _SummaryCard(
                overview: overview,
                onSort: profile == null
                    ? null
                    : () => _sortByHealth(profile, estimatedRank),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(child: _EmptyItems(onAdd: _addItem))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              sliver: SliverReorderableList(
                itemCount: items.length,
                onReorderItem: (oldIndex, newIndex) {
                  final before = _current;
                  final next = [...before];
                  next.insert(newIndex, next.removeAt(oldIndex));
                  _apply(
                    next,
                    undoTo: before,
                    message: AppLocalizations.of(context).prefListOrderUpdated,
                  );
                },
                itemBuilder: (context, index) => _ItemRow(
                  key: ValueKey(items[index].deptId),
                  item: items[index],
                  index: index,
                  category: profile == null
                      ? null
                      : categorizeListItem(
                          items[index],
                          profile,
                          estimatedStudentRank: estimatedRank,
                        ),
                  onRemove: () => _removeAt(index),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: _AddRow(
                full: items.length >= PreferenceListModel.maxItems,
                onTap: _addItem,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Üst çubuk ─────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _TopBar({
    required this.saving,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          const Spacer(),
          // Kaydet butonu yok; onun yerine "yazılıyor" işareti. Kullanıcı
          // hiçbir zaman kaydetmeyi hatırlamak zorunda değil.
          //
          // Gizliyken tamamen ağaçtan çıkıyor: opacity 0 ile bırakılan
          // dönen gösterge boşuna kare harcar (ve testlerde hiç durmaz).
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !saving
                ? const SizedBox.shrink()
                : Row(
                    key: const ValueKey('saving'),
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).prefListSaving,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiaryFor(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).prefListOptions,
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

// ─── Özet kart ─────────────────────────────────────────────────

/// Başlık + doluluk + denge + Üni'nin yorumu TEK kartta.
///
/// Eskiden burada beş ayrı blok vardı (özet kart, sağlık paneli, sırala
/// çubuğu, ekle butonu, sil+kaydet satırı) ve asıl içerik — tercihler —
/// ekranın çok aşağısında kalıyordu.
class _SummaryCard extends StatelessWidget {
  final ListOverview overview;
  final VoidCallback? onSort;

  const _SummaryCard({required this.overview, required this.onSort});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final list = overview.list;
    final health = overview.health;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightFor(context)),
        boxShadow: AppColors.softShadowFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            list.title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (list.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              list.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${overview.filled}',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                ' ${loc.prefListItemLimit(ListOverview.capacity)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: overview.progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariantFor(context),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          if (health != null && overview.hasBalance) ...[
            const SizedBox(height: 14),
            ListBalanceBar(report: health),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RobotAvatar(size: 24, animated: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    RobotBrain.listHealthComment(health).text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (onSort != null && overview.filled > 1) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onSort,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(loc.prefListSortWithUni),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ] else if (health == null) ...[
            const SizedBox(height: 14),
            ListBalanceInvite(
              onTap: () =>
                  navigateToRoute(context, AppRoutes.scoreCalculator),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tercih satırı ─────────────────────────────────────────────

/// Tek tercih. Sola/sağa kaydırınca listeden çıkar (geri al'lı), uzun
/// basınca sürüklenir.
class _ItemRow extends StatelessWidget {
  final PreferenceItem item;
  final int index;
  final MatchCategory? category;
  final VoidCallback onRemove;

  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.category,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final band = category;
    final color =
        band == null ? AppColors.borderLightFor(context) : listBandColor(band);
    final meta = _meta(AppLocalizations.of(context));

    return Padding(
      key: ValueKey('row_${item.deptId}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('dismiss_${item.deptId}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onRemove(),
        background: const _RemoveBackground(alignEnd: false),
        secondaryBackground: const _RemoveBackground(alignEnd: true),
        child: ReorderableDelayedDragStartListener(
          index: index,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLightFor(context)),
              boxShadow: AppColors.softShadowFor(context),
            ),
            child: Row(
              children: [
                // Kategori şeridi kartın sol kenarında: liste kaydırılırken
                // dengenin dağılımı kendini gösterir.
                Container(
                  width: 5,
                  height: 62,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 22,
                  child: Text(
                    '${item.order}',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textTertiaryFor(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.uniName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.deptName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiaryFor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 20,
                    color: AppColors.textTertiaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "2.400. sıra · SAY 521,4" — geçen yılın verisi satırda kalsın ki
  /// karşılaştırmak için listeden çıkmak gerekmesin.
  String? _meta(AppLocalizations loc) {
    final parts = <String>[];
    final rank = item.ranking;
    if (rank != null && rank > 0) {
      parts.add(loc.rankFormat(AppFormatters.ranking(rank)));
    }
    final base = item.baseScore;
    if (base != null && base > 0) {
      final type = item.scoreType;
      final score = AppFormatters.score(base);
      parts.add(type == null || type.isEmpty ? score : '$type $score');
    }
    return parts.isEmpty ? null : parts.join('  ·  ');
  }
}

class _RemoveBackground extends StatelessWidget {
  final bool alignEnd;
  const _RemoveBackground({required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.error,
      ),
    );
  }
}

// ─── Ekleme ve boş durum ───────────────────────────────────────

class _AddRow extends StatelessWidget {
  final bool full;
  final VoidCallback onTap;

  const _AddRow({required this.full, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (full) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(
          loc.prefListFullLimit(PreferenceListModel.maxItems),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiaryFor(context),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DottedBorderBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                loc.prefListAddDepartment,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyItems({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Column(
        children: [
          const RobotAvatar(size: 64),
          const SizedBox(height: 16),
          Text(
            loc.prefListEmptyItemsTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.prefListEmptyItemsDesc(PreferenceListModel.maxItems),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
