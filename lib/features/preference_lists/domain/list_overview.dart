import '../../preference_wizard/domain/list_health.dart';
import 'models/preference_list_model.dart';

/// Hub'ın tek bir liste hakkında bildiği her şey: model + hesaplanmış denge.
///
/// Ekran bu tipe bakar, ham modele değil — "kaç tercih dolu", "dengesi ne",
/// "sabitlenmiş mi" soruları üç ayrı yerde tekrar hesaplanmasın.
class ListOverview {
  final PreferenceListModel list;

  /// Puan profili yoksa null — denge kullanıcının puanına göre hesaplanıyor,
  /// puansız kullanıcıya uydurma bir dağılım gösterilemez.
  final ListHealthReport? health;

  final bool pinned;

  const ListOverview({required this.list, this.health, this.pinned = false});

  static const int capacity = PreferenceListModel.maxItems;

  String get id => list.id;
  int get filled => list.items.length;
  int get remaining => capacity - filled;
  double get progress => (filled / capacity).clamp(0.0, 1.0);
  bool get isEmpty => filled == 0;

  /// Denge şeridi çizilebilir mi? Puan olsa bile hiçbir tercih
  /// değerlendirilememiş olabilir (puan türü tutmuyor, taban verisi yok).
  bool get hasBalance => (health?.rated ?? 0) > 0;

  /// Sıra numarasına göre ilk [count] tercih.
  List<PreferenceItem> topItems([int count = 3]) {
    final sorted = [...list.items]..sort((a, b) => a.order.compareTo(b.order));
    return sorted.take(count).toList();
  }
}

/// Hub sırası: ana liste başta, kalanlar en son güncellenen önce.
///
/// Ana liste = sabitlenen; sabitlenen yoksa **en dolu** liste. İkinci kural
/// bilinçli olarak Üni Paneli'nin `mainListProvider`'ıyla aynı — iki yüzey
/// farklı listeden konuşursa kullanıcı hangisinin "asıl" olduğunu anlamaz.
List<ListOverview> hubOrder(List<ListOverview> all) {
  if (all.isEmpty) return const [];

  final rest = [...all]
    ..sort((a, b) => b.list.updatedAt.compareTo(a.list.updatedAt));

  final main = all.where((o) => o.pinned).firstOrNull ??
      all.reduce((a, b) => b.filled > a.filled ? b : a);

  return [main, ...rest.where((o) => o.id != main.id)];
}
