import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/preference_lists/domain/list_overview.dart';
import 'package:uni_app/features/preference_lists/domain/models/preference_list_model.dart';

/// Hub'ın hangi listeyi "ANA LİSTEN" diye öne çıkardığı.
///
/// Kural iki katmanlı: sabitlenen varsa o, yoksa **en dolu** liste. İkinci
/// kural Üni Paneli'nin `mainListProvider`'ıyla bilinçli olarak aynı — iki
/// yüzey farklı listeden konuşursa kullanıcı hangisinin asıl olduğunu
/// anlayamaz.
void main() {
  group('hubOrder', () {
    test('boş girdide boş döner', () {
      expect(hubOrder(const []), isEmpty);
    });

    test('sabitleme yokken en dolu liste başa geçer', () {
      final order = hubOrder([
        _overview('a', items: 3),
        _overview('b', items: 12),
        _overview('c', items: 7),
      ]);

      expect(order.first.id, 'b');
    });

    test('sabitlenen liste daha boş olsa da başa geçer', () {
      final order = hubOrder([
        _overview('a', items: 20),
        _overview('b', items: 2, pinned: true),
      ]);

      expect(order.first.id, 'b');
    });

    test('kalanlar en son güncellenen önce sıralanır', () {
      final order = hubOrder([
        _overview('eski', items: 1, updatedAt: DateTime(2026, 7, 1)),
        _overview('ana', items: 15, updatedAt: DateTime(2026, 7, 2)),
        _overview('yeni', items: 2, updatedAt: DateTime(2026, 7, 20)),
      ]);

      expect(order.map((o) => o.id), ['ana', 'yeni', 'eski']);
    });

    test('hiçbir liste düşmez ve tekrarlamaz', () {
      final order = hubOrder([
        _overview('a', items: 5),
        _overview('b', items: 5),
        _overview('c', items: 5),
      ]);

      expect(order.length, 3);
      expect(order.map((o) => o.id).toSet().length, 3);
    });
  });

  group('ListOverview', () {
    test('doluluk ve kalan hak', () {
      final o = _overview('a', items: 9);

      expect(o.filled, 9);
      expect(o.remaining, 15);
      expect(o.progress, closeTo(9 / 24, 0.001));
      expect(o.isEmpty, isFalse);
    });

    test('puan profili yokken denge çizilmez', () {
      // `health` null: puansız kullanıcıya uydurma bir dağılım gösterilemez.
      expect(_overview('a', items: 5).hasBalance, isFalse);
    });

    test('ilk tercihler sıra numarasına göre gelir', () {
      final o = ListOverview(
        list: _list('a', [
          _item('x', order: 3),
          _item('y', order: 1),
          _item('z', order: 2),
        ]),
      );

      expect(o.topItems().map((i) => i.deptId), ['y', 'z', 'x']);
    });
  });
}

ListOverview _overview(
  String id, {
  int items = 0,
  bool pinned = false,
  DateTime? updatedAt,
}) {
  return ListOverview(
    list: _list(
      id,
      [for (var i = 0; i < items; i++) _item('$id-$i', order: i + 1)],
      updatedAt: updatedAt,
    ),
    pinned: pinned,
  );
}

PreferenceListModel _list(
  String id,
  List<PreferenceItem> items, {
  DateTime? updatedAt,
}) {
  return PreferenceListModel(
    id: id,
    userId: 'u1',
    userName: 'Test',
    title: 'Liste $id',
    shareSlug: id,
    items: items,
    createdAt: DateTime(2026),
    updatedAt: updatedAt ?? DateTime(2026),
  );
}

PreferenceItem _item(String deptId, {required int order}) => PreferenceItem(
      deptId: deptId,
      uniId: 'u-$deptId',
      order: order,
      deptName: 'Bölüm $deptId',
      uniName: 'Üniversite $deptId',
    );
