import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/redirect_utils.dart';
import '../../../../core/utils/responsive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_providers.dart';

/// Kayıt ekranı
class RegisterScreen extends ConsumerStatefulWidget {
  final String? from;

  const RegisterScreen({super.key, this.from});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isEduEmail = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkEduEmail(String email) {
    setState(() {
      _isEduEmail = email.toLowerCase().endsWith('.edu.tr');
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showError('Kayıt olmak için Kullanım Koşulları ve Gizlilik Politikası\'nı kabul etmelisiniz.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .registerWithEmail(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      final state = ref.read(authControllerProvider);
      if (state is AsyncError) {
        _showError(state.error.toString());
        setState(() => _isLoading = false);
      } else {
        if (_isEduEmail) {
          setState(() => _isLoading = false);
          _showEduVerificationDialog();
        } else {
          setState(() => _isLoading = false);
          context.go(localRedirectPathFromParam(widget.from) ?? '/profile');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _showEduVerificationDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success),
            const SizedBox(width: 8),
            Text(loc.authEduVerifyTitle, style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.authEduVerifyLinkSent, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _emailController.text.trim(),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(loc.authEduVerifyAfter, style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(localRedirectPathFromParam(widget.from) ?? '/profile');
            },
            child: Text(loc.authOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: Stack(
        children: [
          // ─── Ana İçerik ────────────────────────────────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.formMaxWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ─── Geri butonu ─────────────────────────────────
                        IconButton(
                          tooltip: loc.authGoBack,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(
                                routeWithLocalFrom('/login', widget.from),
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceFor(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: AppColors.borderLightFor(context),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── Başlık ─────────────────────────────────────
                        Text(
                          loc.authSignUp,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.textOnSurfaceFor(context),
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 6),
                        Text(
                          loc.authRegisterTitle,
                          style: AppTextStyles.bodySmall,
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                        const SizedBox(height: 32),

                        // ─── Ad Soyad ───────────────────────────────────
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: loc.authFullName,
                            prefixIcon: const Icon(Icons.person_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return loc.authFullNameRequired;
                            }
                            if (value.trim().length < 2) {
                              return loc.authFullNameTooShort;
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: 16),

                        // ─── Email ──────────────────────────────────────
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: _checkEduEmail,
                          decoration: InputDecoration(
                            hintText: loc.authEmailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return loc.authEmailRequired;
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return loc.authEmailInvalid;
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                        // ─── edu.tr bilgilendirme ────────────────────────
                        if (_isEduEmail)
                          Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        loc.authEduDetected,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(color: AppColors.success),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: -0.2),

                        const SizedBox(height: 16),

                        // ─── Şifre ──────────────────────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: loc.authPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? loc.authShowPassword
                                  : loc.authHidePassword,
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textTertiaryFor(context),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.authPasswordRequired;
                            }
                            if (value.length < 8) {
                              return loc.authPasswordMin8;
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return loc.authPasswordUppercase;
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return loc.authPasswordDigit;
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                        const SizedBox(height: 16),

                        // ─── Şifre Tekrar ───────────────────────────────
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            hintText: loc.authPasswordConfirm,
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirm
                                  ? loc.authShowPassword
                                  : loc.authHidePassword,
                              onPressed: () {
                                setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                );
                              },
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textTertiaryFor(context),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.authPasswordConfirmRequired;
                            }
                            if (value != _passwordController.text) {
                              return loc.authPasswordMismatch;
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                        const SizedBox(height: 24),
                        
                        // ─── Kullanım Koşulları ve Gizlilik Politikası ───
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _acceptedTerms,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (value) {
                                  setState(() => _acceptedTerms = value ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final url = Uri.parse('https://uni-app-web-sitesi.vercel.app/privacy.html');
                                      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                                    },
                                    child: Text(
                                      'Kullanım Koşulları ve Gizlilik Politikası',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "'nı okudum ve kabul ediyorum.",
                                    style: AppTextStyles.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 380.ms, duration: 400.ms),

                        const SizedBox(height: 28),

                        // ─── Kayıt Ol butonu ─────────────────────────────
                        GradientButton(
                          text: loc.authSignUp,
                          onPressed: _isLoading ? null : _register,
                          icon: Icons.person_add_rounded,
                        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // ─── Giriş Yap linki ─────────────────────────────
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.authHaveAccount,
                                style: AppTextStyles.bodySmall,
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.go(
                                    routeWithLocalFrom('/login', widget.from),
                                  );
                                },
                                child: Text(
                                  loc.authSignIn,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Full-Screen Blur Loading Overlay ──────────────────
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceFor(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            loc.authCreatingAccount,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textOnSurfaceFor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.authPleaseWait,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
