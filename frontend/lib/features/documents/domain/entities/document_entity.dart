library;

import 'package:equatable/equatable.dart';

class DocumentSummaryItem extends Equatable {
  final String id;
  final int version;
  final String status;
  final String audience;
  final String format;
  final String summaryText;
  final Map<String, dynamic>? structuredPayload;
  final List<dynamic>? factualBasis;
  final List<dynamic>? missingFields;
  final double? confidenceScore;
  final DateTime? generatedAtUtc;

  const DocumentSummaryItem({
    required this.id,
    required this.version,
    required this.status,
    required this.audience,
    required this.format,
    required this.summaryText,
    this.structuredPayload,
    this.factualBasis,
    this.missingFields,
    this.confidenceScore,
    this.generatedAtUtc,
  });

  @override
  List<Object?> get props => [
        id,
        version,
        status,
        audience,
        format,
        summaryText,
        structuredPayload,
        factualBasis,
        missingFields,
        confidenceScore,
        generatedAtUtc,
      ];
}

class DocumentExtractedEntity extends Equatable {
  final String id;
  final int version;
  final String entityType;
  final String label;
  final String value;
  final bool isSensitive;
  final double? confidenceScore;
  final Map<String, dynamic>? qualifiers;

  const DocumentExtractedEntity({
    required this.id,
    required this.version,
    required this.entityType,
    required this.label,
    required this.value,
    required this.isSensitive,
    this.confidenceScore,
    this.qualifiers,
  });

  @override
  List<Object?> get props => [
        id,
        version,
        entityType,
        label,
        value,
        isSensitive,
        confidenceScore,
        qualifiers,
      ];
}

class DocumentExtraction extends Equatable {
  final String? id;
  final int? version;
  final String? status;
  final String? source;
  final String? engine;
  final String? languageCode;
  final String? rawText;
  final String? normalizedText;
  final Map<String, dynamic>? structuredPayload;
  final List<dynamic>? missingSections;
  final double? confidenceScore;
  final Map<String, dynamic>? meta;

  const DocumentExtraction({
    this.id,
    this.version,
    this.status,
    this.source,
    this.engine,
    this.languageCode,
    this.rawText,
    this.normalizedText,
    this.structuredPayload,
    this.missingSections,
    this.confidenceScore,
    this.meta,
  });

  @override
  List<Object?> get props => [
        id,
        version,
        status,
        source,
        engine,
        languageCode,
        rawText,
        normalizedText,
        structuredPayload,
        missingSections,
        confidenceScore,
        meta,
      ];
}

class DocumentAnswerEvidence extends Equatable {
  final String source;
  final String? field;
  final String excerpt;
  final String? certainty;

  const DocumentAnswerEvidence({
    required this.source,
    this.field,
    required this.excerpt,
    this.certainty,
  });

  @override
  List<Object?> get props => [source, field, excerpt, certainty];
}

class DocumentQuestionAnswer extends Equatable {
  final String question;
  final String audience;
  final String answer;
  final bool insufficientEvidence;
  final List<DocumentAnswerEvidence> evidence;
  final List<String> uncertaintyNotes;
  final List<String> usedStructuredFields;
  final double? confidenceScore;
  final String? disclaimer;

  const DocumentQuestionAnswer({
    required this.question,
    required this.audience,
    required this.answer,
    required this.insufficientEvidence,
    this.evidence = const [],
    this.uncertaintyNotes = const [],
    this.usedStructuredFields = const [],
    this.confidenceScore,
    this.disclaimer,
  });

  @override
  List<Object?> get props => [
        question,
        audience,
        answer,
        insufficientEvidence,
        evidence,
        uncertaintyNotes,
        usedStructuredFields,
        confidenceScore,
        disclaimer,
      ];
}

class MedicalDocument extends Equatable {
  final String id;
  final String title;
  final String? patientUserId;
  final String? doctorUserId;
  final String uploadedByUserId;
  final String originalFilename;
  final String mimeType;
  final String? fileExtension;
  final int fileSizeBytes;
  final String? documentType;
  final String processingStatus;
  final String extractionStatus;
  final String summaryStatus;
  final bool ocrRequired;
  final bool ocrUsed;
  final String? urgencyLevel;
  final String? languageCode;
  final double? classificationConfidence;
  final DateTime? documentDateUtc;
  final DateTime? processedAtUtc;
  final DateTime? failedAtUtc;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final Map<String, dynamic>? sourceMetadata;
  final List<Map<String, dynamic>> tags;
  final DocumentExtraction? latestExtraction;
  final List<DocumentSummaryItem> summaries;
  final List<DocumentExtractedEntity> entities;

  const MedicalDocument({
    required this.id,
    required this.title,
    this.patientUserId,
    this.doctorUserId,
    required this.uploadedByUserId,
    required this.originalFilename,
    required this.mimeType,
    this.fileExtension,
    required this.fileSizeBytes,
    this.documentType,
    required this.processingStatus,
    required this.extractionStatus,
    required this.summaryStatus,
    required this.ocrRequired,
    required this.ocrUsed,
    this.urgencyLevel,
    this.languageCode,
    this.classificationConfidence,
    this.documentDateUtc,
    this.processedAtUtc,
    this.failedAtUtc,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.sourceMetadata,
    this.tags = const [],
    this.latestExtraction,
    this.summaries = const [],
    this.entities = const [],
  });

  bool get isPending => processingStatus == 'PENDING';
  bool get isProcessing => processingStatus == 'PROCESSING';
  bool get isCompleted => processingStatus == 'COMPLETED';
  bool get isFailed => processingStatus == 'FAILED';

  @override
  List<Object?> get props => [
        id,
        title,
        patientUserId,
        doctorUserId,
        uploadedByUserId,
        originalFilename,
        mimeType,
        fileExtension,
        fileSizeBytes,
        documentType,
        processingStatus,
        extractionStatus,
        summaryStatus,
        ocrRequired,
        ocrUsed,
        urgencyLevel,
        languageCode,
        classificationConfidence,
        documentDateUtc,
        processedAtUtc,
        failedAtUtc,
        lastErrorCode,
        lastErrorMessage,
        sourceMetadata,
        tags,
        latestExtraction,
        summaries,
        entities,
      ];
}
