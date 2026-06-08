import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/admin_report_model.dart';
import '../../../reviews/domain/models/review_model.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../providers/admin_reports_providers.dart';

/// Rapor detay bottom sheet — bir rapor seçildiğinde açılır.
class ReportDetailSheet extends ConsumerStatefulWidget {
  final AdminReportModel report;
  const ReportDetailSheet({super.key, required this.report});

  static Future<void> show(BuildContext context, AdminReportModel report) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDetailSheet(report: report),
    );
  }

  @override
  ConsumerState<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends ConsumerState<ReportDetailSheet> {
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.report.adminNote != null) _noteCtrl.text = widget.report.adminNote!;
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(reviewDetailProvider(widget.report.reviewId));
    final reportsAsync = ref.watch(reportsForReviewProvider(widget.report.reviewId));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.textTertiaryFor(context).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Başlık
                Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.flag_rounded, color: AppColors.error, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Şikayet Detayı', style: AppTextStyles.titleLarge)),
                  GestureDetector(onTap: () => Navigator.pop(context),
                    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.backgroundFor(context), shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondaryFor(context)))),
                ]),
                const SizedBox(height: 20),

                // Şikayet bilgileri
                _buildInfoCard(context, reportsAsync),
                const SizedBox(height: 16),

                // Yorum önizleme
                Text('Şikayet Edilen Yorum', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _buildReviewPreview(reviewAsync),
                const SizedBox(height: 16),

                // Admin notu
                Text('Admin Notu', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(controller: _noteCtrl, maxLines: 3, maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'İsteğe bağlı admin notu...', hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context)),
                    filled: true, fillColor: AppColors.backgroundFor(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd), borderSide: BorderSide(color: AppColors.borderLightFor(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd), borderSide: BorderSide(color: AppColors.borderLightFor(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  )),

                // Aksiyonlar
                if (widget.report.status == ReportStatus.pending) ...[
                  const SizedBox(height: 20),
                  Text('Aksiyonlar', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _ActionBtn(icon: Icons.visibility_off_rounded, label: 'Yorumu Gizle', sub: 'Yorum kullanıcılardan gizlenir', color: AppColors.warning, onTap: () => _doHide(context)),
                  const SizedBox(height: 8),
                  _ActionBtn(icon: Icons.delete_forever_rounded, label: 'Yorumu Sil', sub: 'Kalıcı olarak silinir', color: AppColors.error, onTap: () => _doDelete(context)),
                  const SizedBox(height: 8),
                  _ActionBtn(icon: Icons.close_rounded, label: 'Şikayeti Reddet', sub: 'Yorum korunur', color: const Color(0xFF6B7280), onTap: () => _doDismiss(context)),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20), const SizedBox(width: 10),
                      Expanded(child: Text('İncelenmiş: ${widget.report.status.label}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))),
                    ])),
                ],
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AsyncValue<List<AdminReportModel>> reportsAsync) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.backgroundFor(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLightFor(context))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Şikayet Bilgileri', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _infoRow(Icons.category_rounded, 'Neden', widget.report.reason.label),
        _infoRow(Icons.access_time_rounded, 'Tarih', timeago.format(widget.report.createdAt, locale: 'tr')),
        GestureDetector(
          onTap: () { Navigator.pop(context); context.push('/user/${widget.report.userId}'); },
          child: _infoRow(Icons.person_outline_rounded, 'Şikayet Eden', widget.report.userId.length > 12 ? '${widget.report.userId.substring(0, 12)}...' : widget.report.userId, linkStyle: true),
        ),
        if (widget.report.explanation?.isNotEmpty == true)
          _infoRow(Icons.notes_rounded, 'Açıklama', widget.report.explanation!),
        reportsAsync.when(
          data: (r) => _infoRow(Icons.stacked_bar_chart_rounded, 'Toplam Şikayet', '${r.length} kişi'),
          loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink()),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool linkStyle = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textTertiaryFor(context)),
      const SizedBox(width: 8),
      SizedBox(width: 100, child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryFor(context)))),
      Expanded(child: Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: linkStyle ? AppColors.primary : null), maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]));
  }

  Widget _buildReviewPreview(AsyncValue<ReviewModel?> reviewAsync) {
    return reviewAsync.when(
      data: (review) {
        if (review == null) return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.backgroundFor(context), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [Icon(Icons.delete_outline_rounded, color: AppColors.textTertiaryFor(context)), const SizedBox(width: 12), Text('Bu yorum silinmiş.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryFor(context)))]));
        return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.backgroundFor(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLightFor(context))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: review.userPhotoUrl != null ? NetworkImage(review.userPhotoUrl!) : null,
                child: review.userPhotoUrl == null ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 10)) : null),
              const SizedBox(width: 8),
              Expanded(child: Text(review.isAnonymous ? 'Anonim' : review.userName, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
              const Icon(Icons.star_rounded, size: 14, color: AppColors.warning), const SizedBox(width: 2),
              Text(review.rating.toStringAsFixed(1), style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Text(review.comment, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryFor(context)), maxLines: 4, overflow: TextOverflow.ellipsis),
          ]));
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => Text('Yorum yüklenemedi.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
    );
  }

  String? get _note => _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null;

  Future<void> _doHide(BuildContext ctx) async {
    final review = await ref.read(reviewRepositoryProvider).getReview(widget.report.reviewId);
    if (!mounted) return;
    final ok = await _confirm(ctx, 'Yorumu Gizle', 'Yorum kullanıcılardan gizlenecek.', 'Gizle', AppColors.warning);
    if (ok != true || !mounted) return;
    await ref.read(reportActionControllerProvider.notifier).hideReview(reportId: widget.report.id, reviewId: widget.report.reviewId, reviewOwnerId: review?.userId ?? '', adminNote: _note);
    if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Yorum gizlendi'), behavior: SnackBarBehavior.floating)); }
  }

  Future<void> _doDelete(BuildContext ctx) async {
    final review = await ref.read(reviewRepositoryProvider).getReview(widget.report.reviewId);
    if (!mounted) return;
    final ok = await _confirm(ctx, 'Yorumu Kalıcı Sil', 'Bu işlem geri alınamaz!', 'Sil', AppColors.error);
    if (ok != true || !mounted) return;
    await ref.read(reportActionControllerProvider.notifier).deleteReview(reportId: widget.report.id, reviewId: widget.report.reviewId, reviewOwnerId: review?.userId ?? '', photoUrls: review?.imageUrls ?? [], adminNote: _note);
    if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Yorum silindi'), behavior: SnackBarBehavior.floating)); }
  }

  Future<void> _doDismiss(BuildContext ctx) async {
    final ok = await _confirm(ctx, 'Şikayeti Reddet', 'Yorum korunacak.', 'Reddet', const Color(0xFF6B7280));
    if (ok != true || !mounted) return;
    await ref.read(reportActionControllerProvider.notifier).dismissReport(reportId: widget.report.id, adminNote: _note);
    if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Şikayet reddedildi'), behavior: SnackBarBehavior.floating)); }
  }

  Future<bool?> _confirm(BuildContext ctx, String title, String content, String action, Color color) {
    return showDialog<bool>(context: ctx, builder: (c) => AlertDialog(title: Text(title), content: Text(content), actions: [
      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
      FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: color), child: Text(action)),
    ]));
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final String sub; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: color)),
            Text(sub, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryFor(context))),
          ])),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]))));
  }
}
