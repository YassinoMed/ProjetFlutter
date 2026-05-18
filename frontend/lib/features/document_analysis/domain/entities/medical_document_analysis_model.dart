import 'package:equatable/equatable.dart';

import '../../../documents/domain/entities/document_entity.dart';

class MedicalDocumentAnalysisModel extends Equatable {
  final String documentId;
  final String title;
  final String detectedType;
  final double? confidenceScore;
  final List<DocumentSummaryItem> patientSummaries;
  final List<DocumentSummaryItem> doctorSummaries;
  final List<DocumentExtractedEntity> importantEntities;
  final List<String> pointsToVerify;
  final String disclaimer;

  const MedicalDocumentAnalysisModel({
    required this.documentId,
    required this.title,
    required this.detectedType,
    this.confidenceScore,
    this.patientSummaries = const [],
    this.doctorSummaries = const [],
    this.importantEntities = const [],
    this.pointsToVerify = const [],
    this.disclaimer =
        'Cette analyse est une aide à la lecture et ne remplace pas l’avis d’un professionnel de santé.',
  });

  @override
  List<Object?> get props => [
        documentId,
        title,
        detectedType,
        confidenceScore,
        patientSummaries,
        doctorSummaries,
        importantEntities,
        pointsToVerify,
        disclaimer,
      ];
}
