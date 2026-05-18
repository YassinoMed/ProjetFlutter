/// Génération de l'ordonnance PDF à partir d'une [Prescription].
///
/// Layout: en-tête MediConnect + bloc médecin + bloc patient + tableau
/// médicaments + cachet numérique fictif (marqué « VALIDÉE PAR DR X »).
/// Pour la démo PFE, aucune signature électronique qualifiée — c'est un
/// rendu visuel professionnel mais sans valeur légale. Documenté tel quel.
library;

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/prescription_entity.dart';

class PrescriptionPdfService {
  const PrescriptionPdfService();

  Future<Uint8List> build(Prescription prescription) async {
    final doc = pw.Document(
      title: 'Ordonnance — ${prescription.publicReference}',
      author: prescription.doctorName,
      creator: 'MediConnect Pro',
    );

    final dateFr = DateFormat('dd MMMM yyyy', 'fr_FR')
        .format(prescription.issuedAt.toLocal());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(),
              pw.SizedBox(height: 24),
              _doctorBlock(prescription),
              pw.SizedBox(height: 18),
              _patientBlock(prescription, dateFr),
              pw.SizedBox(height: 22),
              pw.Text(
                'PRESCRIPTION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 8),
              ..._items(prescription),
              pw.SizedBox(height: 16),
              if (prescription.additionalNotes != null &&
                  prescription.additionalNotes!.trim().isNotEmpty)
                _notesBlock(prescription.additionalNotes!),
              pw.Spacer(),
              _stamp(prescription, dateFr),
              pw.SizedBox(height: 8),
              _footer(prescription),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _header() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'MediConnect Pro',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Plateforme de télémédecine sécurisée',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
          ),
          child: pw.Text(
            'ORDONNANCE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _doctorBlock(Prescription p) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            p.doctorName,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          if (p.doctorSpeciality != null && p.doctorSpeciality!.isNotEmpty)
            pw.Text(
              p.doctorSpeciality!,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
            ),
          if (p.doctorLicenseNumber != null &&
              p.doctorLicenseNumber!.isNotEmpty)
            pw.Text(
              'N° ordre: ${p.doctorLicenseNumber}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
        ],
      ),
    );
  }

  pw.Widget _patientBlock(Prescription p, String dateFr) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Patient',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              p.patientName,
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Émise le',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              dateFr,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _items(Prescription p) {
    return p.items.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 22,
                  height: 22,
                  alignment: pw.Alignment.center,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue900,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Text(
                    '$index',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item.name,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Dosage: ${item.dosage}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Fréquence: ${item.frequency}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Durée: ${item.duration}',
                      style: const pw.TextStyle(fontSize: 10)),
                  if (item.notes != null && item.notes!.trim().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'Note: ${item.notes}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.deepOrange,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  pw.Widget _notesBlock(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.amber200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Recommandations',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _stamp(Prescription p, String dateFr) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'VALIDÉE NUMÉRIQUEMENT',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(p.doctorName,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(dateFr,
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              color: PdfColors.blue50,
              child: pw.Text(
                p.publicReference,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.blue900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _footer(Prescription p) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Ordonnance émise via MediConnect Pro · ${p.publicReference}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page 1/1',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
