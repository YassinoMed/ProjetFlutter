import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/rgpd/rgpd_service.dart';
import '../../data/services/gdpr_export_service.dart';
import '../../domain/entities/export_data_model.dart';

final gdprExportServiceProvider = Provider<GdprExportService>((ref) {
  return GdprExportService(ref.watch(rgpdServiceProvider));
});

class GdprExportController extends AsyncNotifier<ExportDataModel?> {
  @override
  Future<ExportDataModel?> build() async => null;

  Future<void> runExport() async {
    state = const AsyncLoading();
    final service = ref.read(gdprExportServiceProvider);
    final result = await service.exportData();
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      AsyncData.new,
    );
  }
}

final gdprExportControllerProvider =
    AsyncNotifierProvider<GdprExportController, ExportDataModel?>(
  GdprExportController.new,
);

final gdprExportHistoryProvider =
    StateProvider<List<ExportDataModel>>((ref) => const []);
