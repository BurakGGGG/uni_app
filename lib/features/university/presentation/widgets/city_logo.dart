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
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * dpr).ceil().clamp(64, 1024);

    final logo = Semantics(
      label: '${city.name} logosu',
      image: true,
      child: ClipOval(
        child: Image.asset(
          city.logoAssetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          filterQuality: FilterQuality.high,
          errorBuilder: (ctx, err, stack) => _fallback(),
        ),
      ),
    );

    if (!withBackground) return logo;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: city.surfaceGradient,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * padding),
      child: logo,
    );
  }

  Widget _fallback() {
    final initial = city.name.isNotEmpty ? city.name[0] : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: city.brandGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
