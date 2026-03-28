import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/teleconsultation_repository_impl.dart';
import '../../domain/entities/teleconsultation_entity.dart';

final teleconsultationStatusFilterProvider =
    StateProvider<String?>((ref) => null);

final teleconsultationsProvider =
    FutureProvider<List<TeleconsultationEntity>>((ref) async {
  final repository = ref.watch(teleconsultationRepositoryProvider);
  final status = ref.watch(teleconsultationStatusFilterProvider);

  return repository.listTeleconsultations(status: status);
});

final teleconsultationDetailProvider =
    FutureProvider.family<TeleconsultationEntity, String>((ref, id) async {
  final repository = ref.watch(teleconsultationRepositoryProvider);
  return repository.getTeleconsultation(id);
});

final teleconsultationEventsProvider = FutureProvider.family<
    List<TeleconsultationEventEntity>, String>((ref, id) async {
  final repository = ref.watch(teleconsultationRepositoryProvider);
  return repository.getEvents(id);
});

final teleconsultationActionsProvider = Provider<TeleconsultationActions>((ref) {
  return TeleconsultationActions(ref);
});

class TeleconsultationActions {
  final Ref ref;

  TeleconsultationActions(this.ref);

  Future<void> cancel(String id) async {
    final repository = ref.read(teleconsultationRepositoryProvider);
    await repository.cancelTeleconsultation(id);
    ref.invalidate(teleconsultationsProvider);
    ref.invalidate(teleconsultationDetailProvider(id));
    ref.invalidate(teleconsultationEventsProvider(id));
  }
}
