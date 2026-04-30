import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_providers.dart';

/// Kayıt ekranı
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

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

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).registerWithEmail(
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
          final from = GoRouterState.of(context).uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            context.go(Uri.decodeComponent(from));
          } else {
            context.go('/profile');
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _showEduVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success),
            const SizedBox(width: 8),
            Text('edu.tr Doğrulama', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doğrulama linki e-posta adresine gönderildi:',
              style: AppTextStyles.bodyMedium,
            ),
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
            Text(
              'E-postanı doğruladıktan sonra yorum yazabileceksin.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final from = GoRouterState.of(context).uri.queryParameters['from'];
              if (from != null && from.isNotEmpty) {
                context.go(Uri.decodeComponent(from));
              } else {
                context.go('/profile');
              }
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── Ana İçerik ────────────────────────────────────────
          SafeArea(
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
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          final from = GoRouterState.of(context).uri.queryParameters['from'];
                          final loginPath = from != null && from.isNotEmpty 
                              ? '/login?from=${Uri.encodeComponent(from)}' 
                              : '/login';
                          context.go(loginPath);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Başlık ─────────────────────────────────────
                    Text('Kayıt Ol', style: AppTextStyles.displaySmall)
                        .animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Yeni hesap oluştur ve keşfetmeye başla',
                      style: AppTextStyles.bodySmall,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 32),

                    // ─── Ad Soyad ───────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ad Soyad gerekli';
                        }
                        if (value.trim().length < 2) {
                          return 'Ad Soyad en az 2 karakter olmalı';
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
                      decoration: const InputDecoration(
                        hintText: 'E-posta adresi',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'E-posta adresi gerekli';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Geçerli bir e-posta adresi girin';
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
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.2),
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
                                'edu.tr hesabı algılandı! Doğrulama sonrası yorum yazabileceksin.',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),

                    const SizedBox(height: 16),

                    // ─── Şifre ──────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Şifre gerekli';
                        if (value.length < 8) {
                          return 'Şifre en az 8 karakter olmalı';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Şifre en az bir büyük harf içermeli';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Şifre en az bir rakam içermeli';
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
                        hintText: 'Şifre Tekrar',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre tekrarı gerekli';
                        }
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                    const SizedBox(height: 28),

                    // ─── Kayıt Ol butonu ─────────────────────────────
                    GradientButton(
                      text: 'Kayıt Ol',
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
                            'Zaten hesabın var mı? ',
                            style: AppTextStyles.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () {
                              final from = GoRouterState.of(context).uri.queryParameters['from'];
                              final loginPath = from != null && from.isNotEmpty 
                                  ? '/login?from=${Uri.encodeComponent(from)}' 
                                  : '/login';
                              context.go(loginPath);
                            },
                            child: Text(
                              'Giriş Yap',
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
                        color: AppColors.surface,
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
                            'Hesap oluşturuluyor...',
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lütfen bekleyin',
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
