library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/document_repository_impl.dart';
import '../../domain/entities/document_entity.dart';

final documentSearchQueryProvider = StateProvider<String>((ref) => '');
final documentStatusFilterProvider = StateProvider<String?>((ref) => null);
final documentTypeFilterProvider = StateProvider<String?>((ref) => null);
final documentPatientFilterProvider = StateProvider<String?>((ref) => null);

final documentsProvider = FutureProvider<List<MedicalDocument>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final query = ref.watch(documentSearchQueryProvider);
  final status = ref.watch(documentStatusFilterProvider);
  final type = ref.watch(documentTypeFilterProvider);
  final patientUserId = ref.watch(documentPatientFilterProvider);

  return repository.listDocuments(
    query: query,
    status: status,
    documentType: type,
    patientUserId: patientUserId,
  );
});

final documentDetailProvider =
    FutureProvider.family<MedicalDocument, String>((ref, documentId) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getDocument(documentId);
});

class DocumentActionsController {
  final Ref ref;

  DocumentActionsController(this.ref);

  DocumentRepositoryImpl get _repository => ref.read(documentRepositoryProvider);

  Future<MedicalDocument> upload({
    required File file,
    required String title,
    String? patientUserId,
    String? doctorUserId,
    String? documentTypeHint,
    DateTime? documentDateUtc,
  }) async {
    final document = await _repository.uploadDocument(
      file: file,
      title: title,
      patientUserId: patientUserId,
      doctorUserId: doctorUserId,
      documentTypeHint: documentTypeHint,
      documentDateUtc: documentDateUtc,
    );

    ref.invalidate(documentsProvider);
    ref.invalidate(documentDetailProvider(document.id));
    return document;
  }

  Future<MedicalDocument> reanalyze(String documentId) async {
    final document = await _repository.reanalyze(documentId);

    ref.invalidate(documentsProvider);
    ref.invalidate(documentDetailProvider(documentId));
    return document;
  }

  Future<void> delete(String documentId) async {
    await _repository.deleteDocument(documentId);
    ref.invalidate(documentsProvider);
  }
}

final documentActionsProvider = Provider<DocumentActionsController>((ref) {
  return DocumentActionsController(ref);
});
