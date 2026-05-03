import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/domain/models/review_photo_model.dart';

class FullscreenPhotoViewer extends StatefulWidget {
  final List<ReviewPhotoModel> photos;
  final int initialIndex;

  const FullscreenPhotoViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenPhotoViewer> createState() => _FullscreenPhotoViewerState();
}

class _FullscreenPhotoViewerState extends State<FullscreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;


  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getReviewTypeName(ReviewType type) {
    switch (type) {
      case ReviewType.university:
        return 'Üniversite Yorumu';
      case ReviewType.department:
        return 'Bölüm Yorumu';
      case ReviewType.place:
        return 'Mekan Yorumu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
          PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: 'photo_${photo.imageUrl}',
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error_outline, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Bottom Info Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.push('/user/${widget.photos[_currentIndex].review.userId}');
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          backgroundImage: widget.photos[_currentIndex].review.userPhotoUrl != null
                              ? CachedNetworkImageProvider(widget.photos[_currentIndex].review.userPhotoUrl!)
                              : null,
                          child: widget.photos[_currentIndex].review.userPhotoUrl == null
                              ? Text(
                                  widget.photos[_currentIndex].review.userName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.photos[_currentIndex].review.userName,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getReviewTypeName(widget.photos[_currentIndex].review.type),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.photos[_currentIndex].review.comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.photos[_currentIndex].review.comment,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ).animate(key: ValueKey(_currentIndex)).fadeIn(duration: 200.ms),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
