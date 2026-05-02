import 'package:uni_app/features/reviews/domain/models/review_model.dart';

/// Yorumlardan çıkarılan fotoğrafları ve o fotoğrafın ait olduğu yorumu tutan veri modeli.
class ReviewPhotoModel {
  final String imageUrl;
  final ReviewModel review;

  ReviewPhotoModel({
    required this.imageUrl,
    required this.review,
  });
}
