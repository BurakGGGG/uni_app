import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Uygulama içi geri bildirim (feedback) alt paneli.
///
/// Kullanıcılar profil menüsünden erişerek bug raporu,
/// öneri veya genel geri bildirim gönderebilir.
class FeedbackSheet extends StatefulWidget {
  final String? userId;
  final String? userEmail;

  const FeedbackSheet({super.key, this.userId, this.userEmail});

  /// BottomSheet olarak göster.
  static Future<void> show(
    BuildContext context, {
    String? userId,
    String? userEmail,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedbackSheet(userId: userId, userEmail: userEmail),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  _FeedbackType _selectedType = _FeedbackType.suggestion;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiaryFor(
                      context,
                    ).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Başlık
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.feedback_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.localeName == 'tr' ? 'Geri Bildirim' : 'Feedback',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundFor(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                loc.localeName == 'tr'
                    ? 'Deneyiminizi iyileştirmemize yardımcı olun.'
                    : 'Help us improve your experience.',
                style: AppTextStyles.bodySmall,
              ),

              const SizedBox(height: 20),

              // Tip seçimi
              Text(
                loc.localeName == 'tr' ? 'Tür' : 'Type',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _FeedbackType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type != _FeedbackType.values.last ? 8 : 0,
                      ),
                      child: _TypeChip(
                        type: type,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedType = type),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Mesaj alanı
              Text(
                loc.localeName == 'tr' ? 'Mesajınız' : 'Your Message',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: loc.localeName == 'tr'
                      ? 'Lütfen detaylı bir şekilde açıklayın...'
                      : 'Please describe in detail...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiaryFor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundFor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.borderLightFor(context),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.borderLightFor(context),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return loc.localeName == 'tr'
                        ? 'En az 10 karakter yazın.'
                        : 'Please enter at least 10 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Gönder butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSending ? null : _submit,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSending
                        ? (loc.localeName == 'tr'
                              ? 'Gönderiliyor...'
                              : 'Sending...')
                        : (loc.localeName == 'tr' ? 'Gönder' : 'Send'),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMd,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      await _functions
          .httpsCallable(
            'submitFeedback',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
          )
          .call(<String, dynamic>{
            'type': _selectedType.name,
            'message': _messageController.text.trim(),
            'appVersion': AppConstants.appVersion,
            'platform': defaultTargetPlatform.name,
          });

      if (mounted) {
        Navigator.pop(context);
        final loc = AppLocalizations.of(context);
        showAppSnackBar(
          context,
          message: loc.localeName == 'tr'
              ? 'Geri bildiriminiz alındı. Teşekkürler!'
              : 'Your feedback has been received. Thank you!',
          isSuccess: true,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Feedback] Error: $e');
      if (mounted) {
        setState(() => _isSending = false);
        final loc = AppLocalizations.of(context);
        final isRateLimited = e.code == 'resource-exhausted';
        showAppSnackBar(
          context,
          message: isRateLimited
              ? (loc.localeName == 'tr'
                    ? 'Çok kısa sürede fazla geri bildirim gönderdiniz.'
                    : 'You sent too much feedback in a short time.')
              : (loc.localeName == 'tr'
                    ? 'Gönderilirken bir hata oluştu. Lütfen tekrar deneyin.'
                    : 'An error occurred. Please try again.'),
        );
      }
    } catch (e) {
      debugPrint('[Feedback] Error: $e');
      if (mounted) {
        setState(() => _isSending = false);
        final loc = AppLocalizations.of(context);
        showAppSnackBar(
          context,
          message: loc.localeName == 'tr'
              ? 'Gönderilirken bir hata oluştu. Lütfen tekrar deneyin.'
              : 'An error occurred. Please try again.',
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Feedback türleri
// ═══════════════════════════════════════════════════════════════

enum _FeedbackType {
  bug,
  suggestion,
  other;

  String get labelTr => switch (this) {
    bug => 'Hata',
    suggestion => 'Öneri',
    other => 'Diğer',
  };

  String get labelEn => switch (this) {
    bug => 'Bug',
    suggestion => 'Suggestion',
    other => 'Other',
  };

  IconData get icon => switch (this) {
    bug => Icons.bug_report_rounded,
    suggestion => Icons.lightbulb_rounded,
    other => Icons.chat_bubble_outline_rounded,
  };

  Color get color => switch (this) {
    bug => AppColors.error,
    suggestion => AppColors.warning,
    other => AppColors.info,
  };
}

// ═══════════════════════════════════════════════════════════════
//  Tip seçim chip'i
// ═══════════════════════════════════════════════════════════════

class _TypeChip extends StatelessWidget {
  final _FeedbackType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final label = loc.localeName == 'tr' ? type.labelTr : type.labelEn;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? type.color.withValues(alpha: 0.1)
              : AppColors.backgroundFor(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: isSelected
                ? type.color.withValues(alpha: 0.5)
                : AppColors.borderLightFor(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              type.icon,
              size: 20,
              color: isSelected
                  ? type.color
                  : AppColors.textTertiaryFor(context),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? type.color
                    : AppColors.textSecondaryFor(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
