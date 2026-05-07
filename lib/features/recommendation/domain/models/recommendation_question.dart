import 'package:flutter/material.dart';

enum QuestionType { singleSelect, multiSelect, slider, rangeSlider }

class RecommendationQuestion {
  final String id;
  final String question;
  final String? hint;
  final QuestionType type;
  final List<QuestionOption> options;
  final int maxSelections;
  final bool isOptional;

  /// Sadece slider tipinde kullanılır.
  final SliderConfig? slider;

  const RecommendationQuestion({
    required this.id,
    required this.question,
    this.hint,
    required this.type,
    this.options = const [],
    this.maxSelections = 1,
    this.isOptional = false,
    this.slider,
  });
}

class QuestionOption {
  final String id;
  final String label;
  final String? subtitle;
  final IconData? icon;

  /// Tag-based scoring: {'alan': 'bio', 'ilgi': 'saglik'}
  final Map<String, String> tags;

  const QuestionOption({
    required this.id,
    required this.label,
    this.subtitle,
    this.icon,
    this.tags = const {},
  });
}

/// Slider sorularının konfigürasyonu (sıralama için).
class SliderConfig {
  /// UI üzerinde gösterilecek snap noktaları (insanların kafasında olan yuvarlak değerler).
  final List<SliderSnap> snaps;

  /// Hangi tag adını yazacağı (örn. 'siralama').
  final String tagKey;

  const SliderConfig({required this.snaps, required this.tagKey});
}

class SliderSnap {
  /// Slider değeri (kullanıcının seçtiği yer)
  final int value;

  /// Görüntülenen kısa label (örn. "1 - 1.000")
  final String label;

  /// Engine'e gönderilecek tag değeri (örn. "500")
  final String tagValue;

  const SliderSnap({
    required this.value,
    required this.label,
    required this.tagValue,
  });
}
