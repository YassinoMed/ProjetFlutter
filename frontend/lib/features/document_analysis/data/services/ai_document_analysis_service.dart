import '../../../documents/domain/entities/document_entity.dart';
import '../../domain/entities/medical_document_analysis_model.dart';

class AiDocumentAnalysisService {
  const AiDocumentAnalysisService();

  MedicalDocumentAnalysisModel fromDocument(MedicalDocument document) {
    final patientSummaries = document.summaries
        .where((summary) => summary.audience.toLowerCase() == 'patient')
        .toList(growable: false);
    final doctorSummaries = document.summaries
        .where((summary) => summary.audience.toLowerCase() == 'doctor')
        .toList(growable: false);

    final importantEntities = document.entities
        .where((entity) => entity.isSensitive || _isImportant(entity))
        .take(12)
        .toList(growable: false);

    final pointsToVerify = <String>[
      if (document.documentType == null)
        'Type de document non confirmé automatiquement.',
      if (document.classificationConfidence != null &&
          document.classificationConfidence! < 0.70)
        'Classification à relire: confiance inférieure à 70%.',
      if (document.latestExtraction?.confidenceScore != null &&
          document.latestExtraction!.confidenceScore! < 0.70)
        'OCR à vérifier: qualité d’extraction limitée.',
      if (document.summaries.isEmpty)
        'Aucun résumé validé disponible pour ce document.',
      ...?document.latestExtraction?.missingSections?.map((item) {
        return 'Section possiblement manquante: $item';
      }),
    ];

    return MedicalDocumentAnalysisModel(
      documentId: document.id,
      title: document.title,
      detectedType: document.documentType ?? 'autre',
      confidenceScore: document.classificationConfidence,
      patientSummaries: patientSummaries,
      doctorSummaries: doctorSummaries,
      importantEntities: importantEntities,
      pointsToVerify: pointsToVerify,
    );
  }

  bool _isImportant(DocumentExtractedEntity entity) {
    final type = entity.entityType.toLowerCase();
    return type.contains('medication') ||
        type.contains('allergy') ||
        type.contains('diagnosis') ||
        type.contains('dosage') ||
        type.contains('date') ||
        type.contains('lab');
  }
}
