library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/document_entity.dart';
import '../datasources/document_remote_datasource.dart';

class DocumentRepositoryImpl {
  final DocumentRemoteDataSource remoteDataSource;

  DocumentRepositoryImpl({required this.remoteDataSource});

  Future<List<MedicalDocument>> listDocuments({
    String? query,
    String? status,
    String? documentType,
    String? patientUserId,
  }) {
    return remoteDataSource.listDocuments(
      query: query,
      status: status,
      documentType: documentType,
      patientUserId: patientUserId,
    );
  }

  Future<MedicalDocument> getDocument(String documentId) {
    return remoteDataSource.getDocument(documentId);
  }

  Future<List<DocumentSummaryItem>> getSummaries(String documentId) {
    return remoteDataSource.getSummaries(documentId);
  }

  Future<List<DocumentExtractedEntity>> getEntities(String documentId) {
    return remoteDataSource.getEntities(documentId);
  }

  Future<MedicalDocument> uploadDocument({
    required File file,
    required String title,
    String? patientUserId,
    String? doctorUserId,
    String? documentTypeHint,
    DateTime? documentDateUtc,
  }) {
    return remoteDataSource.uploadDocument(
      file: file,
      title: title,
      patientUserId: patientUserId,
      doctorUserId: doctorUserId,
      documentTypeHint: documentTypeHint,
      documentDateUtc: documentDateUtc,
    );
  }

  Future<MedicalDocument> reanalyze(String documentId) {
    return remoteDataSource.reanalyze(documentId);
  }

  Future<DocumentQuestionAnswer> askQuestion({
    required String documentId,
    required String question,
    String? audience,
  }) {
    return remoteDataSource.askQuestion(
      documentId: documentId,
      question: question,
      audience: audience,
    );
  }

  Future<void> deleteDocument(String documentId) {
    return remoteDataSource.deleteDocument(documentId);
  }
}

final documentRemoteDataSourceProvider =
    Provider<DocumentRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DocumentRemoteDataSource(dio: dio);
});

final documentRepositoryProvider = Provider<DocumentRepositoryImpl>((ref) {
  return DocumentRepositoryImpl(
    remoteDataSource: ref.watch(documentRemoteDataSourceProvider),
  );
});
