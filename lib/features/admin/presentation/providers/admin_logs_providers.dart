import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_logs_repository.dart';
import '../../domain/models/admin_log_model.dart';

final adminLogsRepositoryProvider = Provider<AdminLogsRepository>((ref) {
  return AdminLogsRepository();
});

final adminAuditLogsProvider = StreamProvider<List<AdminAuditLogModel>>((ref) {
  ref.keepAlive();
  return ref.watch(adminLogsRepositoryProvider).watchAuditLogs();
});

final suspiciousActivityLogsProvider =
    StreamProvider<List<SuspiciousActivityLogModel>>((ref) {
      ref.keepAlive();
      return ref.watch(adminLogsRepositoryProvider).watchSuspiciousLogs();
    });
