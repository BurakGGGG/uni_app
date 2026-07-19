import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin/data/analytics_service.dart';
import '../../../admin/domain/models/analytics_event.dart';
import '../../../assistant/domain/chat_models.dart';
import '../../../assistant/domain/robot_mood.dart';
import '../../../assistant/domain/robot_scripts.dart';
import '../../../assistant/presentation/providers/chat_wizard_providers.dart';
import '../../../assistant/presentation/widgets/chat_chip_row.dart';
import '../../../assistant/presentation/widgets/chat_input_bar.dart';
import '../../../assistant/presentation/widgets/chat_preview_card.dart';
import '../../../assistant/presentation/widgets/chat_user_bubble.dart';
import '../../../assistant/presentation/widgets/robot_avatar.dart';
import '../../../assistant/presentation/widgets/robot_speech_bubble.dart';

/// Tercih Robotu girişi — Üni ile sohbet. Eski form tamamen sohbete
/// dönüştü (rota aynı: `/preference-wizard`): kullanıcı derdini doğal
/// dille yazar ya da çiplerden ilerler; Üni anlayıp adım adım toplar,
/// onayda motoru çalıştırıp ilk önerileri sohbete düşürür. Karar mantığı
/// ChatFlow'da (saf, headless testli) — bu ekran yalnız çizer.
class PreferenceWizardScreen extends ConsumerStatefulWidget {
  const PreferenceWizardScreen({super.key});

  @override
  ConsumerState<PreferenceWizardScreen> createState() =>
      _PreferenceWizardScreenState();
}

class _PreferenceWizardScreenState
    extends ConsumerState<PreferenceWizardScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance
        .trackEvent(AnalyticsEvent.preferenceWizardOpened);
  }

  Future<void> _onSend(String text) async {
    final effect = await ref
        .read(chatWizardControllerProvider.notifier)
        .sendText(text);
    _handleEffect(effect);
  }

  Future<void> _onChip(ChatChip chip) async {
    final effect =
        await ref.read(chatWizardControllerProvider.notifier).tapChip(chip);
    _handleEffect(effect);
  }

  void _handleEffect(ChatEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case ChatEffect.goResults:
        context.push('/preference-wizard/results');
      case ChatEffect.goCalculator:
        context.push('/score-calculator');
      case ChatEffect.none:
      case ChatEffect.search:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatWizardControllerProvider);
    final heroMood = chat.turns.reversed
            .whereType<UniChatTurn>()
            .firstOrNull
            ?.message
            .mood ??
        RobotMood.happy;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundFor(context),
        elevation: 0,
        title: Row(
          children: [
            // Ekranın tek animasyonlu avatarı — listedekiler statik.
            RobotAvatar(size: 34, mood: heroMood),
            const SizedBox(width: 10),
            Text('$kRobotName ile Sohbet'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: chat.turns.length,
                itemBuilder: (context, i) {
                  final turn = chat.turns[chat.turns.length - 1 - i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TurnView(turn: turn, isNewest: i == 0),
                  );
                },
              ),
            ),
            if (chat.chips.isNotEmpty && !chat.busy)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ChatChipRow(chips: chat.chips, onTap: _onChip),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ChatInputBar(enabled: !chat.busy, onSend: _onSend),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek sohbet satırı. Typewriter yalnız en yeni Üni balonunda (eskiler
/// rebuild'te yeniden yazmasın); animasyonlar kapalıysa hiç kullanılmaz.
class _TurnView extends StatelessWidget {
  final ChatTurn turn;
  final bool isNewest;
  const _TurnView({required this.turn, required this.isNewest});

  @override
  Widget build(BuildContext context) {
    switch (turn) {
      case UniChatTurn(:final message):
        final typewriter =
            isNewest && !MediaQuery.disableAnimationsOf(context);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RobotAvatar(size: 26, mood: message.mood, animated: false),
            const SizedBox(width: 6),
            Expanded(
              child: RobotSpeechBubble(
                message: message,
                typewriter: typewriter,
              ),
            ),
          ],
        );
      case UserChatTurn(:final text):
        return ChatUserBubble(text: text);
      case PreviewChatTurn(:final matches):
        return Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'İlk önerilerin:',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final m in matches) ...[
                ChatPreviewCard(match: m),
                const SizedBox(height: 6),
              ],
            ],
          ),
        );
    }
  }
}
