import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_text_styles.dart';

/// Markalı yükleme göstergesi.
///
/// Generic [CircularProgressIndicator] yerine, marka işareti olan swap glyph'i
/// yumuşakça nabız gibi büyütüp küçülterek yükleme hissini markalar. Ana
/// tam-ekran yükleme noktalarında kullanılır. (İllüstrasyon/Lottie tabanlı
/// boş durumlar ayrı; bu sadece loader.)
class BrandLoader extends StatefulWidget {
  const BrandLoader({super.key, this.size = 48, this.message});

  final double size;
  final String? message;

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.82,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.55,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _opacity,
              child: SvgPicture.asset(
                'assets/icons/compare_icon.svg',
                width: widget.size,
                height: widget.size,
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
