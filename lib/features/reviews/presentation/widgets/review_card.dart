import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/review_model.dart';

class ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  final bool showActions;
  final bool showReportMenu;
  final VoidCallback? onTap;
  final bool compact;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;

  const ReviewCard({
    super.key,
    required this.review,
    this.showActions = false,
    this.showReportMenu = true,
    this.onTap,
    this.compact = false,
    this.onDeleted,
    this.onEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Sonraki günlerde doldurulacak
    return Card(
      child: ListTile(
        title: Text(review.userName),
        subtitle: Text(review.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(review.rating.toStringAsFixed(1)),
        onTap: onTap,
      ),
    );
  }
}
