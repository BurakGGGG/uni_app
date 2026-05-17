import 'dart:async';
import 'package:flutter/material.dart';

/// Metni kelime kelime ekrana yazar.
/// Text değişirse animasyon baştan başlar.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration perWord;
  final TextAlign? textAlign;

  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.perWord = const Duration(milliseconds: 55),
    this.textAlign,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late List<String> _words;
  int _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _start();
    }
  }

  void _start() {
    // Boşluk dahil token'lar: hem kelimeler, hem aradaki boşluklar.
    // splitMapJoin sırasıyla onMatch (kelime) ve onNonMatch (boşluk) çağırır.
    final tokens = <String>[];
    widget.text.splitMapJoin(
      RegExp(r'\S+'),
      onMatch: (m) {
        tokens.add(m.group(0)!);
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) tokens.add(s);
        return '';
      },
    );
    _words = tokens;
    _shown = 0;
    _timer = Timer.periodic(widget.perWord, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_shown >= _words.length) {
        t.cancel();
        return;
      }
      // Tek seferde 2 token ilerle: "kelime + sonraki boşluk" beraber
      // gözüksün, animasyon kelime başına olsun (boşluk için ek tick yok).
      setState(() {
        _shown++;
        if (_shown < _words.length &&
            _words[_shown].trim().isEmpty) {
          _shown++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _words.take(_shown).join();
    return Text(
      visible,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
