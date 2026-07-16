import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/redirect_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/auth_providers.dart';

/// Giriş ekranı
class LoginScreen extends ConsumerStatefulWidget {
  final String? from;

  const LoginScreen({super.key, this.from});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  void _onLoginSuccess() {
    if (!mounted) return;
    setState(() => _isLoading = false);

    context.go(localRedirectPathFromParam(widget.from) ?? '/');
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      final state = ref.read(authControllerProvider);
      if (state is AsyncError) {
        _showError(state.error.toString());
        setState(() => _isLoading = false);
      } else {
        _onLoginSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      final state = ref.read(authControllerProvider);
      if (state is AsyncError) {
        _showError(state.error.toString());
        setState(() => _isLoading = false);
      } else {
        _onLoginSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    final loc = AppLocalizations.of(context);
    final resetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.authResetPasswordTitle,
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(loc.authResetPasswordDesc, style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: loc.authEmailLabel,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              text: loc.authResetPasswordSend,
              icon: Icons.send_rounded,
              onPressed: () async {
                if (resetController.text.trim().isNotEmpty) {
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(ctx);
                  await ref
                      .read(authControllerProvider.notifier)
                      .resetPassword(resetController.text.trim());
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(loc.authResetPasswordSent)),
                  );
                }
              },
            ),
          ],
        ),
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
                        const SizedBox(height: 40),

                        // ─── Logo & Başlık ─────────────────────────────
                        Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: Image.asset(
                                        'assets/icons/unisec-icon-ink-512.png',
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const AppWordmark(fontSize: 30),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppConstants.appTagline,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondaryFor(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.1),

                        const SizedBox(height: 40),

                        // ─── Giriş Yap başlığı ─────────────────────────
                        Text(
                          loc.authSignIn,
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.textOnSurfaceFor(context),
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: 6),
                        Text(
                          loc.authContinueWithAccount,
                          style: AppTextStyles.bodySmall,
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                        const SizedBox(height: 28),

                        // ─── Google ile giriş ────────────────────────────
                        _SocialLoginButton(
                          text: loc.authGoogleContinue,
                          svgPath: 'assets/icons/google_logo.svg',
                          onPressed: _isLoading ? null : _loginWithGoogle,
                        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // ─── Ayırıcı ─────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.dividerFor(context),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                loc.authOrDivider,
                                style: AppTextStyles.labelSmall,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.dividerFor(context),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // ─── Email ──────────────────────────────────────
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: loc.authEmailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return loc.authEmailRequired;
                            }
                            if (!value.contains('@')) {
                              return loc.authEmailInvalid;
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                        const SizedBox(height: 16),

                        // ─── Şifre ──────────────────────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loginWithEmail(),
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
                            return null;
                          },
                        ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                        const SizedBox(height: 8),

                        // ─── Şifremi Unuttum ─────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPassword,
                            child: Text(
                              loc.authForgotPassword,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ─── Giriş Yap butonu ────────────────────────────
                        GradientButton(
                          text: loc.authSignIn,
                          onPressed: _isLoading ? null : _loginWithEmail,
                          icon: Icons.login_rounded,
                        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                        const SizedBox(height: 24),

                        // ─── Kayıt Ol linki ─────────────────────────────
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.authNoAccount,
                                style: AppTextStyles.bodySmall,
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.go(
                                    routeWithLocalFrom(
                                      '/register',
                                      widget.from,
                                    ),
                                  );
                                },
                                child: Text(
                                  loc.authSignUp,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 550.ms, duration: 400.ms),

                        const SizedBox(height: 16),

                        // ─── Misafir devam ──────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/'),
                            child: Text(
                              loc.authGuestContinue,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textTertiaryFor(context),
                              ),
                            ),
                          ),
                        ),

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
                        boxShadow: AppColors.cardShadowFor(context),
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
                            loc.authLoggingIn,
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

/// Sosyal giriş butonu
class _SocialLoginButton extends StatelessWidget {
  final String text;
  final String svgPath;
  final VoidCallback? onPressed;

  const _SocialLoginButton({
    required this.text,
    required this.svgPath,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.borderFor(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(svgPath, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textOnSurfaceFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
