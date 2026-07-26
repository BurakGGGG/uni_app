import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preference_wizard/presentation/providers/preference_wizard_providers.dart';
import '../flow/uni_flow_screen.dart';
import 'uni_panel_screen.dart';

/// `/uni`'nin kapısı: kurulum yapılmamışsa akış, yapılmışsa özet.
///
/// Karar **bir kez**, ekran kurulurken verilir. Canlı izleseydi akışın 5.
/// adımında puan kaydedilir kaydedilmez ekran altından özete dönerdi —
/// kullanıcı cümlenin ortasında başka bir sayfada bulurdu kendini.
class UniHomeGate extends ConsumerStatefulWidget {
  const UniHomeGate({super.key});

  @override
  ConsumerState<UniHomeGate> createState() => _UniHomeGateState();
}

class _UniHomeGateState extends ConsumerState<UniHomeGate> {
  late bool _inFlow;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(studentScoreProfileProvider);
    _inFlow = profile == null || profile.scoreType.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_inFlow) {
      return UniFlowScreen(
        onFinished: () => setState(() => _inFlow = false),
      );
    }
    return UniPanelScreen(
      onRestartFlow: () => setState(() => _inFlow = true),
    );
  }
}
