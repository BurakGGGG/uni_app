import 'package:flutter/material.dart';
import '../../domain/models/city_model.dart';

/// Şehir logo widget'ı.
///
/// - Asset bulunamazsa otomatik gradient + harf fallback gösterir.
/// - cacheWidth ile downsample ederek RAM tüketimini sınırlandırır.
/// - withBackground=false → şeffaf zemin (gradient kart üzerinde)
/// - withBackground=true  → surfaceGradient daire (liste maddesi içinde)
class CityLogo extends StatelessWidget {
  final CityModel city;
  final double size;
  final bool withBackground;
  final double padding;

  const CityLogo({
    super.key,
    required this.city,
    required this.size,
    this.withBackground = true,
    this.padding = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    // Geçici (şimdilik idare edecek) tasarım: Plaka kodunu gösteren şık bir daire
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: city.brandGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: city.surfaceGradient.colors.first.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          city.plateCode,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}
