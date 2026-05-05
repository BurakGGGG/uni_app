class RecommendationAnswer {
  final String questionId;
  final List<String> selectedOptionIds;
  final DateTime answeredAt;

  RecommendationAnswer({
    required this.questionId,
    required this.selectedOptionIds,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();
}
