library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../../../../core/constants/api_constants.dart';
import '../models/document_model.dart';

class DocumentRemoteDataSource {
  final Dio dio;

  DocumentRemoteDataSource({required this.dio});

  Future<List<MedicalDocumentModel>> listDocuments({
    String? query,
    String? status,
    String? documentType,
    String? patientUserId,
  }) async {
    final response = await dio.get(
      ApiConstants.documents,
      queryParameters: {
        'per_page': 20,
        if (query != null && query.isNotEmpty) 'q': query,
        if (status != null && status.isNotEmpty) 'status': status,
        if (documentType != null && documentType.isNotEmpty)
          'document_type': documentType,
        if (patientUserId != null && patientUserId.isNotEmpty)
          'patient_user_id': patientUserId,
      },
    );

    final data = (response.data['data'] as List<dynamic>? ?? const []);

    return data
        .whereType<Map<String, dynamic>>()
        .map(MedicalDocumentModel.fromJson)
        .toList();
  }

  Future<MedicalDocumentModel> getDocument(String documentId) async {
    final response = await dio.get(
      ApiConstants.documentShow.replaceFirst('{id}', documentId),
    );

    final data = (response.data['data'] as Map<String, dynamic>?)?['document']
        as Map<String, dynamic>;

    return MedicalDocumentModel.fromJson(data);
  }

  Future<List<DocumentProcessingJobEntryModel>> getProcessingJobs(
    String documentId,
  ) async {
    final response = await dio.get(
      ApiConstants.documentProcessing.replaceFirst('{id}', documentId),
    );

    final data = ((response.data['data']
            as Map<String, dynamic>?)?['processing_jobs'] as List?) ??
        const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(DocumentProcessingJobEntryModel.fromJson)
        .toList();
  }

  Future<List<DocumentSummaryModel>> getSummaries(String documentId) async {
    final response = await dio.get(
      ApiConstants.documentSummary.replaceFirst('{id}', documentId),
    );

    final data = ((response.data['data'] as Map<String, dynamic>?)?['summaries']
            as List?) ??
        const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(DocumentSummaryModel.fromJson)
        .toList();
  }

  Future<List<DocumentExtractedEntityModel>> getEntities(
      String documentId) async {
    final response = await dio.get(
      ApiConstants.documentEntities.replaceFirst('{id}', documentId),
    );

    final data = ((response.data['data'] as Map<String, dynamic>?)?['entities']
            as List?) ??
        const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(DocumentExtractedEntityModel.fromJson)
        .toList();
  }

  Future<MedicalDocumentModel> uploadDocument({
    required File file,
    required String title,
    String? patientUserId,
    String? doctorUserId,
    String? documentTypeHint,
    DateTime? documentDateUtc,
    String? clientOcrText,
    String? clientOcrEngine,
    String? clientOcrLanguage,
    double? clientOcrConfidence,
    double? clientImageQualityScore,
    int? clientImageWidth,
    int? clientImageHeight,
    List<String>? clientImageQualityWarnings,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: path.basename(file.path),
      ),
      if (patientUserId != null) 'patient_user_id': patientUserId,
      if (doctorUserId != null) 'doctor_user_id': doctorUserId,
      if (documentTypeHint != null) 'document_type_hint': documentTypeHint,
      if (documentDateUtc != null)
        'document_date_utc': documentDateUtc.toUtc().toIso8601String(),
      if (clientOcrText != null && clientOcrText.trim().isNotEmpty)
        'client_ocr_text': clientOcrText.trim(),
      if (clientOcrEngine != null && clientOcrEngine.trim().isNotEmpty)
        'client_ocr_engine': clientOcrEngine.trim(),
      if (clientOcrLanguage != null && clientOcrLanguage.trim().isNotEmpty)
        'client_ocr_language': clientOcrLanguage.trim(),
      if (clientOcrConfidence != null)
        'client_ocr_confidence': clientOcrConfidence,
      if (clientImageQualityScore != null)
        'client_image_quality_score': clientImageQualityScore,
      if (clientImageWidth != null) 'client_image_width': clientImageWidth,
      if (clientImageHeight != null) 'client_image_height': clientImageHeight,
      if (clientImageQualityWarnings != null &&
          clientImageQualityWarnings.isNotEmpty)
        'client_image_quality_warnings': jsonEncode(clientImageQualityWarnings),
    });

    final response = await dio.post(
      ApiConstants.documentUpload,
      data: formData,
    );

    final data = (response.data['data'] as Map<String, dynamic>?)?['document']
        as Map<String, dynamic>;

    return MedicalDocumentModel.fromJson(data);
  }

  Future<MedicalDocumentModel> reanalyze(String documentId) async {
    final response = await dio.post(
      ApiConstants.documentReanalyze.replaceFirst('{id}', documentId),
    );

    final data = (response.data['data'] as Map<String, dynamic>?)?['document']
        as Map<String, dynamic>;

    return MedicalDocumentModel.fromJson(data);
  }

  Future<DocumentQuestionAnswerModel> askQuestion({
    required String documentId,
    required String question,
    String? audience,
  }) async {
    final response = await dio.post(
      ApiConstants.documentAsk.replaceFirst('{id}', documentId),
      data: {
        'question': question,
        if (audience != null && audience.isNotEmpty) 'audience': audience,
      },
    );

    final data = (response.data['data'] as Map<String, dynamic>?)?['answer']
        as Map<String, dynamic>;

    return DocumentQuestionAnswerModel.fromJson(data);
  }

  Future<void> deleteDocument(String documentId) async {
    await dio
        .delete(ApiConstants.documentShow.replaceFirst('{id}', documentId));
  }
}
