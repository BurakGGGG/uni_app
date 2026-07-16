import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/features/reviews/data/review_repository.dart';
import 'package:uni_app/features/reviews/domain/models/review_model.dart';

ReviewModel _review({
  required String id,
  required int likes,
  required DateTime createdAt,
}) {
  return ReviewModel(
    id: id,
    type: ReviewType.university,
    targetId: 'uni1',
    universityId: 'uni1',
    userId: 'u_$id',
    userName: 'Test',
    rating: 4.0,
    comment: 'yorum',
    likes: likes,
    isApproved: true,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  group('sortTopReviews', () {
    test('önce beğeniye göre azalan sıralar', () {
      final result = sortTopReviews([
        _review(id: 'a', likes: 2, createdAt: DateTime(2026, 1, 1)),
        _review(id: 'b', likes: 9, createdAt: DateTime(2026, 1, 1)),
        _review(id: 'c', likes: 5, createdAt: DateTime(2026, 1, 1)),
      ]);
      expect(result.map((r) => r.id).toList(), ['b', 'c', 'a']);
    });

    test('beğeni eşitse en yeni öne gelir', () {
      final result = sortTopReviews([
        _review(id: 'old', likes: 3, createdAt: DateTime(2026, 1, 1)),
        _review(id: 'new', likes: 3, createdAt: DateTime(2026, 6, 1)),
        _review(id: 'mid', likes: 3, createdAt: DateTime(2026, 3, 1)),
      ]);
      expect(result.map((r) => r.id).toList(), ['new', 'mid', 'old']);
    });

    test('tüm beğeniler 0 iken en tazeye düşer (zarif bozulma)', () {
      final result = sortTopReviews([
        _review(id: 'x', likes: 0, createdAt: DateTime(2026, 1, 1)),
        _review(id: 'y', likes: 0, createdAt: DateTime(2026, 2, 1)),
      ]);
      expect(result.first.id, 'y');
    });

    test('limit uygulanır', () {
      final reviews = List.generate(
        10,
        (i) => _review(
          id: '$i',
          likes: 10 - i,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      expect(sortTopReviews(reviews, limit: 3).length, 3);
    });

    test('girdi listesini mutasyona uğratmaz', () {
      final input = [
        _review(id: 'a', likes: 1, createdAt: DateTime(2026, 1, 1)),
        _review(id: 'b', likes: 9, createdAt: DateTime(2026, 1, 1)),
      ];
      sortTopReviews(input);
      expect(input.first.id, 'a');
    });
  });
}
