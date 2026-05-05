import 'package:flutter/material.dart';

enum QuestionType { singleSelect, multiSelect }

class RecommendationQuestion {
  final String id;
  final String question;
  final String? hint;
  final QuestionType type;
  final List<QuestionOption> options;
  final int maxSelections;
  final bool isOptional;

  const RecommendationQuestion({
    required this.id,
    required this.question,
    this.hint,
    required this.type,
    required this.options,
    this.maxSelections = 1,
    this.isOptional = false,
  });
}

class QuestionOption {
  final String id;
  final String label;
  final IconData? icon;
  /// Tag-based scoring: {'alan': 'bio', 'ilgi': 'saglik'}
  final Map<String, String> tags;

  const QuestionOption({
    required this.id,
    required this.label,
    this.icon,
    this.tags = const {},
  });
}
