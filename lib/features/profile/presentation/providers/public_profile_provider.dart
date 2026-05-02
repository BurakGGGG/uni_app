import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Başka bir kullanıcının herkese açık profilini getiren provider.
/// Email gibi özel alanlar maskelenir.
final publicProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) {
  return ref.read(authRepositoryProvider).getPublicProfile(userId);
});
