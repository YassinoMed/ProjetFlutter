library;

import '../../domain/entities/document_entity.dart';

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class MedicalDocumentModel extends MedicalDocument {
  const MedicalDocumentModel({
    required super.id,
    required super.title,
    super.patientUserId,
    super.doctorUserId,
    required super.uploadedByUserId,
    required super.originalFilename,
    required super.mimeType,
    super.fileExtension,
    required super.fileSizeBytes,
    super.documentType,
    required super.processingStatus,
    required super.extractionStatus,
    required super.summaryStatus,
    required super.ocrRequired,
    required super.ocrUsed,
    super.urgencyLevel,
    super.languageCode,
    super.classificationConfidence,
    super.documentDateUtc,
    super.processedAtUtc,
    super.failedAtUtc,
    super.lastErrorCode,
    super.lastErrorMessage,
    super.tags,
    super.latestExtraction,
    super.summaries,
    super.entities,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json) {
    return MedicalDocumentModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      patientUserId: json['patient_user_id']?.toString(),
      doctorUserId: json['doctor_user_id']?.toString(),
      uploadedByUserId: json['uploaded_by_user_id']?.toString() ?? '',
      originalFilename: json['original_filename'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      fileExtension: json['file_extension'] as String?,
      fileSizeBytes: _parseInt(json['file_size_bytes']),
      documentType: json['document_type'] as String?,
      processingStatus: json['processing_status'] as String? ?? 'PENDING',
      extractionStatus: json['extraction_status'] as String? ?? 'PENDING',
      summaryStatus: json['summary_status'] as String? ?? 'PENDING',
      ocrRequired: json['ocr_required'] == true,
      ocrUsed: json['ocr_used'] == true,
      urgencyLevel: json['urgency_level'] as String?,
      languageCode: json['language_code'] as String?,
      classificationConfidence: _parseDouble(json['classification_confidence']),
      documentDateUtc: _parseDate(json['document_date_utc']),
      processedAtUtc: _parseDate(json['processed_at_utc']),
      failedAtUtc: _parseDate(json['failed_at_utc']),
      lastErrorCode: json['last_error_code'] as String?,
      lastErrorMessage: json['last_error_message_sanitized'] as String?,
      tags: ((json['tags'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      latestExtraction: _parseExtraction(json['latest_extraction']),
      summaries: ((json['summaries'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DocumentSummaryModel.fromJson)
          .toList(),
      entities: ((json['entities'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DocumentExtractedEntityModel.fromJson)
          .toList(),
    );
  }

  static DocumentExtraction? _parseExtraction(dynamic value) {
    if (value is! Map<String, dynamic>) return null;

    return DocumentExtraction(
      id: value['id']?.toString(),
      version: _parseInt(value['version']),
      status: value['status'] as String?,
      source: value['source'] as String?,
      engine: value['engine'] as String?,
      languageCode: value['language_code'] as String?,
      rawText: value['raw_text'] as String?,
      normalizedText: value['normalized_text'] as String?,
      structuredPayload: value['structured_payload'] as Map<String, dynamic>?,
      missingSections: value['missing_sections'] as List<dynamic>?,
      confidenceScore: _parseDouble(value['confidence_score']),
    );
  }
}

class DocumentSummaryModel extends DocumentSummaryItem {
  const DocumentSummaryModel({
    required super.id,
    required super.version,
    required super.status,
    required super.audience,
    required super.format,
    required super.summaryText,
    super.structuredPayload,
    super.factualBasis,
    super.missingFields,
    super.confidenceScore,
    super.generatedAtUtc,
  });

  factory DocumentSummaryModel.fromJson(Map<String, dynamic> json) {
    return DocumentSummaryModel(
      id: json['id']?.toString() ?? '',
      version: _parseInt(json['version']),
      status: json['status'] as String? ?? 'COMPLETED',
      audience: json['audience'] as String? ?? 'PATIENT',
      format: json['format'] as String? ?? 'SHORT',
      summaryText: json['summary_text'] as String? ?? '',
      structuredPayload: json['structured_payload'] as Map<String, dynamic>?,
      factualBasis: json['factual_basis'] as List<dynamic>?,
      missingFields: json['missing_fields'] as List<dynamic>?,
      confidenceScore: _parseDouble(json['confidence_score']),
      generatedAtUtc: _parseDate(json['generated_at_utc']),
    );
  }
}

class DocumentExtractedEntityModel extends DocumentExtractedEntity {
  const DocumentExtractedEntityModel({
    required super.id,
    required super.version,
    required super.entityType,
    required super.label,
    required super.value,
    required super.isSensitive,
    super.confidenceScore,
    super.qualifiers,
  });

  factory DocumentExtractedEntityModel.fromJson(Map<String, dynamic> json) {
    return DocumentExtractedEntityModel(
      id: json['id']?.toString() ?? '',
      version: _parseInt(json['version']),
      entityType: json['entity_type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      isSensitive: json['is_sensitive'] == true,
      confidenceScore: _parseDouble(json['confidence_score']),
      qualifiers: json['qualifiers'] as Map<String, dynamic>?,
    );
  }
}
