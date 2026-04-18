import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/review_model.dart';
import '../providers/review_providers.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String universityId;

  const WriteReviewScreen({super.key, required this.universityId});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  double _overallRating = 0;
  double _egitimRating = 0;
  double _kampusRating = 0;
  double _sosyalRating = 0;
  
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen genel bir puan verin')),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('Giriş yapılmamış');

      final currentUserData = ref.read(currentUserProvider).value;
      if (currentUserData == null) throw Exception('Kullanıcı profili bulunamadı');

      final review = ReviewModel(
        id: '', // Firestore auto-generates
        type: ReviewType.university,
        targetId: widget.universityId,
        universityId: widget.universityId,
        userId: user.uid,
        userName: _isAnonymous ? 'Anonim Öğrenci' : currentUserData.displayName,
        userPhotoUrl: _isAnonymous ? null : currentUserData.photoUrl,
        userUniversity: currentUserData.university,
        rating: _overallRating,
        categoryRatings: {
          'Eğitim': _egitimRating,
          'Kampüs': _kampusRating,
          'Sosyal Hayat': _sosyalRating,
        },
        comment: _commentController.text.trim(),
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(reviewRepositoryProvider).addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirmeniz başarıyla eklendi!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStarRating(String title, double rating, ValueChanged<double> onChanged, {bool isOverall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isOverall ? AppTextStyles.titleMedium : AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.warning,
                size: isOverall ? 40 : 30,
              ),
              onPressed: () => onChanged(index + 1.0),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Değerlendir', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStarRating(
                'Genel Değerlendirme',
                _overallRating,
                (val) => setState(() => _overallRating = val),
                isOverall: true,
              ).animate().fadeIn(duration: 400.ms),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              Text('Kategori Puanları', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              
              _buildStarRating('Eğitim Kalitesi', _egitimRating, (val) => setState(() => _egitimRating = val)),
              const SizedBox(height: 16),
              _buildStarRating('Kampüs Olanakları', _kampusRating, (val) => setState(() => _kampusRating = val)),
              const SizedBox(height: 16),
              _buildStarRating('Sosyal Hayat', _sosyalRating, (val) => setState(() => _sosyalRating = val)),

              const SizedBox(height: 32),

              TextFormField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Yorumunuz',
                  hintText: 'Üniversiteniz hakkında diğer öğrencilere faydalı olabilecek deneyimlerinizi paylaşın...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen bir yorum yazın';
                  }
                  if (val.trim().length < 20) {
                    return 'Yorumunuz en az 20 karakter olmalıdır';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Anonim olarak paylaş', style: AppTextStyles.bodyLarge),
                subtitle: Text('Adınız ve fotoğrafınız diğer kullanıcılardan gizlenir', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                value: _isAnonymous,
                onChanged: (val) => setState(() => _isAnonymous = val),
                activeThumbColor: AppColors.primary,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 32),

              GradientButton(
                text: 'Değerlendirmeyi Gönder',
                onPressed: _submitReview,
                isLoading: _isLoading,
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
