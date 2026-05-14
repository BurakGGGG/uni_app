import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    if (photoUrl == null || photoUrl!.isEmpty) {
      return _fallback(initials);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        placeholder: (_, _) => _fallback(initials),
        errorWidget: (_, _, _) => _fallback(initials),
      ),
    );
  }

  Widget _fallback(String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
