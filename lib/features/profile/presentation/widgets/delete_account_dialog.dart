import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';

class DeleteAccountConfirmation {
  final String? password;

  const DeleteAccountConfirmation({this.password});
}

class DeleteAccountDialog extends StatefulWidget {
  final bool requiresPassword;

  const DeleteAccountDialog({super.key, required this.requiresPassword});

  static Future<DeleteAccountConfirmation?> show(
    BuildContext context, {
    required bool requiresPassword,
  }) {
    return showDialog<DeleteAccountConfirmation>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteAccountDialog(requiresPassword: requiresPassword),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      DeleteAccountConfirmation(
        password: widget.requiresPassword ? _passwordController.text : null,
      ),
    );
  }

  String _normalizeConfirmation(String value) {
    return value.trim().toUpperCase().replaceAll('İ', 'I').replaceAll('ı', 'I');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.deleteAccountTitle,
              style: AppTextStyles.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.deleteAccountDescription,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.deleteAccountWarning,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.requiresPassword
                      ? loc.deleteAccountPasswordNote
                      : loc.deleteAccountGoogleNote,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                if (widget.requiresPassword) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: loc.deleteAccountPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? loc.deleteAccountPasswordRequired
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmationController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: loc.deleteAccountConfirmationLabel(
                      loc.deleteAccountConfirmationWord,
                    ),
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                  validator: (value) =>
                      _normalizeConfirmation(value ?? '') !=
                          _normalizeConfirmation(
                            loc.deleteAccountConfirmationWord,
                          )
                      ? loc.deleteAccountConfirmationMismatch(
                          loc.deleteAccountConfirmationWord,
                        )
                      : null,
                  onFieldSubmitted: (_) => _confirm(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.commonCancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: _confirm,
          icon: const Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(loc.deleteAccountConfirmButton),
        ),
      ],
    );
  }
}
