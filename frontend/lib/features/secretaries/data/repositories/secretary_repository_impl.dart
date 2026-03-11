library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/doctor_secretary_delegation_entity.dart';
import '../datasources/secretary_remote_datasource.dart';

class SecretaryRepositoryImpl {
  final SecretaryRemoteDataSource remoteDataSource;

  SecretaryRepositoryImpl({required this.remoteDataSource});

  Future<List<DoctorSecretaryDelegationEntity>> listDoctorSecretaries() {
    return remoteDataSource.listDoctorSecretaries();
  }

  Future<DoctorSecretaryDelegationEntity> inviteSecretary({
    required String email,
    required String firstName,
    required String lastName,
    required List<String> permissions,
    int expiresInHours = 72,
  }) {
    return remoteDataSource.inviteSecretary(
      email: email,
      firstName: firstName,
      lastName: lastName,
      permissions: permissions,
      expiresInHours: expiresInHours,
    );
  }

  Future<DoctorSecretaryDelegationEntity> updatePermissions({
    required String delegationId,
    required List<String> permissions,
  }) {
    return remoteDataSource.updatePermissions(
      delegationId: delegationId,
      permissions: permissions,
    );
  }

  Future<DoctorSecretaryDelegationEntity> suspend({
    required String delegationId,
    String? reason,
  }) {
    return remoteDataSource.suspend(
      delegationId: delegationId,
      reason: reason,
    );
  }

  Future<DoctorSecretaryDelegationEntity> reactivate({
    required String delegationId,
  }) {
    return remoteDataSource.reactivate(delegationId: delegationId);
  }

  Future<void> revoke({required String delegationId}) {
    return remoteDataSource.revoke(delegationId: delegationId);
  }

  Future<List<DoctorSecretaryDelegationEntity>> getMyDelegations() {
    return remoteDataSource.getMyDelegations();
  }

  Future<DoctorSecretaryDelegationEntity> switchDoctorContext({
    required String doctorUserId,
  }) {
    return remoteDataSource.switchDoctorContext(doctorUserId: doctorUserId);
  }
}

final secretaryRemoteDataSourceProvider =
    Provider<SecretaryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return SecretaryRemoteDataSourceImpl(dio: dio);
});

final secretaryRepositoryProvider = Provider<SecretaryRepositoryImpl>((ref) {
  return SecretaryRepositoryImpl(
    remoteDataSource: ref.watch(secretaryRemoteDataSourceProvider),
  );
});
