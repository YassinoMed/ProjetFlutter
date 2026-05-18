/// Détail d'une ordonnance avec aperçu PDF intégré.
///
/// Patient: ouverture en lecture seule + partage.
/// Médecin: idem + bouton « Refaire » pour dupliquer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prescription_entity.dart';
import '../providers/prescription_providers.dart';

class PrescriptionDetailPage extends ConsumerWidget {
  final String prescriptionId;
  const PrescriptionDetailPage({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(prescriptionStoreProvider.notifier);
    final prescription = store.byId(prescriptionId);

    if (prescription == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ordonnance')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Ordonnance introuvable. Elle a peut-être été supprimée '
              'ou n\'a pas été persistée (mode démo en mémoire).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final dateFr = DateFormat('dd MMMM yyyy · HH:mm', 'fr_FR')
        .format(prescription.issuedAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordonnance'),
        actions: [
          IconButton(
            tooltip: 'Partager / Télécharger',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _share(context, ref, prescription),
          ),
          IconButton(
            tooltip: 'Imprimer',
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _print(context, ref, prescription),
          ),
        ],
      ),
      body: Column(
        children: [
          _HeaderBanner(prescription: prescription, dateFr: dateFr),
          Expanded(
            child: PdfPreview(
              build: (format) async {
                final service = ref.read(prescriptionPdfServiceProvider);
                return service.build(prescription);
              },
              allowSharing: false,
              allowPrinting: false,
              canChangePageFormat: false,
              canDebug: false,
              canChangeOrientation: false,
              maxPageWidth: 700,
              actionBarTheme: const PdfActionBarTheme(
                backgroundColor: AppTheme.primaryColor,
                iconColor: Colors.white,
              ),
              pdfFileName: 'ordonnance-${prescription.publicReference}.pdf',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _print(
    BuildContext context,
    WidgetRef ref,
    Prescription prescription,
  ) async {
    final service = ref.read(prescriptionPdfServiceProvider);
    final bytes = await service.build(prescription);
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    Prescription prescription,
  ) async {
    final service = ref.read(prescriptionPdfServiceProvider);
    final bytes = await service.build(prescription);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'ordonnance-${prescription.publicReference}.pdf',
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final Prescription prescription;
  final String dateFr;

  const _HeaderBanner({required this.prescription, required this.dateFr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        border: const Border(
          bottom: BorderSide(color: AppTheme.primaryColor, width: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prescription.publicReference,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${prescription.patientName} · $dateFr',
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.neutralGray500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 14, color: AppTheme.successColor),
                const SizedBox(width: 4),
                Text(
                  'Validée',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
