import 'package:flutter/material.dart';
import '../../domain/models/city_model.dart';

class CityLogo extends StatelessWidget {
  final CityModel city;
  final double size;
  final bool withBackground;

  const CityLogo({
    super.key,
    required this.city,
    required this.size,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    // cacheWidth = size * MediaQuery.devicePixelRatio, max 1024
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * dpr).ceil().clamp(64, 1024);

    final logo = Image.asset(
      city.logoAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: cacheSize,
      filterQuality: FilterQuality.high,
      errorBuilder: (ctx, err, stack) => _fallback(size),
    );

    if (!withBackground) return logo;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: city.surfaceGradient,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: logo,
    );
  }

  Widget _fallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: city.brandGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          city.name.isNotEmpty ? city.name[0] : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
