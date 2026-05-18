import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/rgpd/rgpd_service.dart';
import '../../domain/entities/export_data_model.dart';

class GdprExportService {
  final RgpdService _rgpdService;

  const GdprExportService(this._rgpdService);

  Future<Either<Failure, ExportDataModel>> exportData() async {
    final result = await _rgpdService.exportData();
    return result.map(
      (raw) => ExportDataModel(
        raw: raw,
        exportedAt: DateTime.now().toUtc(),
      ),
    );
  }
}
