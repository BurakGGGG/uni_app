import 'package:flutter/material.dart';

import '../../domain/robot_mood.dart';

/// Bir adımın kabuğa söyledikleri.
///
/// Adımlar kendi başlığını, butonunu ya da ilerleme çubuğunu ÇİZMEZ; onları
/// kabuk ([UniFlowScreen]) tek yerden çizer. Böylece on ekran boyunca başlık
/// yeri, buton yeri ve geçiş animasyonu birebir aynı kalır — akış hissi
/// buradan doğuyor.
class UniFlowStepSpec {
  /// Üni'nin o ekrandaki sorusu.
  final String title;

  /// Bir cümlelik açıklama; gerekmiyorsa null.
  final String? subtitle;

  /// Sorunun gövdesi — giriş alanları, çipler, kartlar.
  ///
  /// Tek widget değil LİSTE: kabuk parçaları sırayla içeri alıyor. Gövde tek
  /// bir `Column` olsaydı ekran tek blok hâlinde "yapışarak" belirirdi.
  final List<Widget> body;

  /// Devam butonu etkin mi? Zorunlu bir cevap eksikse false.
  final bool canAdvance;

  /// Devam butonunun yazısı; null → kabuğun varsayılanı ("Devam").
  final String? ctaLabel;

  /// Devam edilirken çalışır (kaydetme). Hata atarsa ilerleme durur.
  final Future<void> Function()? onAdvance;

  /// Üni'nin o adımdaki yüzü.
  final RobotMood mood;

  const UniFlowStepSpec({
    required this.title,
    required this.body,
    this.subtitle,
    this.canAdvance = true,
    this.ctaLabel,
    this.onAdvance,
    this.mood = RobotMood.happy,
  });
}
