library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/secretary_repository_impl.dart';
import '../../domain/entities/doctor_secretary_delegation_entity.dart';

const List<String> allSecretaryPermissions = [
  'MANAGE_APPOINTMENTS',
  'MANAGE_SCHEDULE',
  'VIEW_PATIENT_DIRECTORY',
  'SEND_ADMIN_MESSAGES',
  'VIEW_ADMINISTRATIVE_DATA',
];

final doctorSecretariesProvider =
    FutureProvider<List<DoctorSecretaryDelegationEntity>>((ref) async {
  return ref.watch(secretaryRepositoryProvider).listDoctorSecretaries();
});

final myDelegationsProvider =
    FutureProvider<List<DoctorSecretaryDelegationEntity>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user?.isSecretary != true) return const [];

  return ref.watch(secretaryRepositoryProvider).getMyDelegations();
});

class SecretaryContextNotifier
    extends AsyncNotifier<DoctorSecretaryDelegationEntity?> {
  @override
  Future<DoctorSecretaryDelegationEntity?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user?.isSecretary != true) {
      await _clearPersistedContext();
      return null;
    }

    final storedDoctorUserId = await _storage.read(
      key: AppConstants.keyActingDoctorUserId,
    );
    if (storedDoctorUserId == null || storedDoctorUserId.isEmpty) {
      return null;
    }

    final delegations = await ref.watch(myDelegationsProvider.future);

    return delegations.cast<DoctorSecretaryDelegationEntity?>().firstWhere(
          (delegation) => delegation?.doctorUserId == storedDoctorUserId,
          orElse: () => null,
        );
  }

  SecureStorageService get _storage => ref.read(secureStorageProvider);

  Future<void> switchDoctor(DoctorSecretaryDelegationEntity delegation) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final confirmed = await ref
          .read(secretaryRepositoryProvider)
          .switchDoctorContext(doctorUserId: delegation.doctorUserId);

      await _storage.write(
        key: AppConstants.keyActingDoctorUserId,
        value: confirmed.doctorUserId,
      );

      ref.invalidate(myAppointmentsProvider);
      return confirmed;
    });
  }

  Future<void> clear() async {
    await _clearPersistedContext();
    ref.invalidate(myAppointmentsProvider);
    state = const AsyncData(null);
  }

  Future<void> _clearPersistedContext() async {
    await _storage.delete(key: AppConstants.keyActingDoctorUserId);
  }
}

final secretaryContextProvider = AsyncNotifierProvider<
    SecretaryContextNotifier, DoctorSecretaryDelegationEntity?>(
  SecretaryContextNotifier.new,
);

class SecretaryActionsController {
  final Ref ref;

  SecretaryActionsController(this.ref);

  SecretaryRepositoryImpl get _repository => ref.read(secretaryRepositoryProvider);

  Future<void> invite({
    required String email,
    required String firstName,
    required String lastName,
    required List<String> permissions,
    int expiresInHours = 72,
  }) async {
    await _repository.inviteSecretary(
      email: email,
      firstName: firstName,
      lastName: lastName,
      permissions: permissions,
      expiresInHours: expiresInHours,
    );

    ref.invalidate(doctorSecretariesProvider);
  }

  Future<void> updatePermissions({
    required String delegationId,
    required List<String> permissions,
  }) async {
    await _repository.updatePermissions(
      delegationId: delegationId,
      permissions: permissions,
    );

    ref.invalidate(doctorSecretariesProvider);
    ref.invalidate(myDelegationsProvider);
  }

  Future<void> suspend({
    required String delegationId,
    String? reason,
  }) async {
    await _repository.suspend(delegationId: delegationId, reason: reason);

    ref.invalidate(doctorSecretariesProvider);
    ref.invalidate(myDelegationsProvider);
  }

  Future<void> reactivate({required String delegationId}) async {
    await _repository.reactivate(delegationId: delegationId);

    ref.invalidate(doctorSecretariesProvider);
    ref.invalidate(myDelegationsProvider);
  }

  Future<void> revoke({required String delegationId}) async {
    await _repository.revoke(delegationId: delegationId);

    ref.invalidate(doctorSecretariesProvider);
    ref.invalidate(myDelegationsProvider);
  }
}

final secretaryActionsProvider = Provider<SecretaryActionsController>((ref) {
  return SecretaryActionsController(ref);
});
