// Üni'nin mimik sayfasını ve tek tek şeffaf zeminli PNG'lerini üretir.
// Pazarlama/press-kit aracı — `flutter test` bunu toplamaz (adı `_test.dart`
// değil). Elle çalıştır:
//
//   flutter test test/tools/uni_mimik_sheet.dart --update-goldens
//
// Çıktı: brand/uni/ altına. Avatar koddan çizildiği için sayfa her zaman
// uygulamadaki Üni'nin birebir aynısıdır; elle çizim/asset kopyası yok.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_app/core/theme/app_colors.dart';
import 'package:uni_app/features/assistant/domain/robot_mood.dart';
import 'package:uni_app/features/assistant/presentation/widgets/robot_avatar.dart';

/// Sayfadaki sıra ve etiketler.
const _moods = <(RobotMood, String)>[
  (RobotMood.happy, 'Mutlu'),
  (RobotMood.neutral, 'Sakin'),
  (RobotMood.thinking, 'Düşünüyor'),
  (RobotMood.celebrating, 'Kutluyor'),
  (RobotMood.concerned, 'Endişeli'),
  (RobotMood.sleeping, 'Uyuyor'),
];

const _font = 'UniSheet';

Future<void> _loadFont() async {
  final loader = FontLoader(_font);
  for (final path in const [
    '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
    '/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf',
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      loader.addFont(file.readAsBytes().then((b) => b.buffer.asByteData()));
    }
  }
  await loader.load();
}

/// Golden yakalaması için ekranı istenen ölçüye sabitler.
Future<void> _frame(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      // Animasyonlar kapalı: avatar hiç controller/timer kurmaz.
      data: const MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('sheet'),
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(_loadFont);

  testWidgets('mimik sayfası (1080x1350)', (tester) async {
    await _frame(
      tester,
      const Size(1080, 1350),
      const ColoredBox(
        color: Color(0xFFF6F5FF),
        child: Padding(
          padding: EdgeInsets.fromLTRB(64, 72, 64, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              SizedBox(height: 48),
              Expanded(child: _Grid()),
              SizedBox(height: 24),
              _Footer(),
            ],
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('sheet')),
      matchesGoldenFile('../../brand/uni/uni-mimikler.png'),
    );
  });

  // Reels kurgusunda üst üste bindirmek için: zemin şeffaf, tek mimik.
  for (final (mood, label) in _moods) {
    testWidgets('şeffaf tek mimik — ${mood.name}', (tester) async {
      await _frame(
        tester,
        const Size(512, 512),
        Center(child: RobotAvatar(size: 440, mood: mood, animated: false)),
      );

      await expectLater(
        find.byKey(const ValueKey('sheet')),
        matchesGoldenFile('../../brand/uni/uni-${mood.name}.png'),
      );
      expect(label, isNotEmpty);
    });
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const RobotAvatar(size: 108, animated: false),
        const SizedBox(width: 28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Üni',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 76,
                height: 1.0,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "ÜniSeç'in tercih asistanı",
              style: TextStyle(
                fontFamily: _font,
                fontSize: 28,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      // 2x3: 4:5 sayfada dikey akış boşluk bırakmadan oturuyor.
      crossAxisCount: 2,
      mainAxisSpacing: 28,
      crossAxisSpacing: 28,
      childAspectRatio: 1.45,
      children: [
        for (final (mood, label) in _moods) _MoodCard(mood: mood, label: label),
      ],
    );
  }
}

class _MoodCard extends StatelessWidget {
  final RobotMood mood;
  final String label;

  const _MoodCard({required this.mood, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RobotAvatar(size: 168, mood: mood, animated: false),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'yakında  ·  unisec',
        style: TextStyle(
          fontFamily: _font,
          fontSize: 24,
          letterSpacing: 2,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
