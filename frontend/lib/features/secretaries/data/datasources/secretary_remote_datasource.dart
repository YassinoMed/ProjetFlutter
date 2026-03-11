library;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/doctor_secretary_delegation_model.dart';

abstract class SecretaryRemoteDataSource {
  Future<List<DoctorSecretaryDelegationModel>> listDoctorSecretaries();
  Future<DoctorSecretaryDelegationModel> inviteSecretary({
    required String email,
    required String firstName,
    required String lastName,
    required List<String> permissions,
    int expiresInHours = 72,
  });
  Future<DoctorSecretaryDelegationModel> updatePermissions({
    required String delegationId,
    required List<String> permissions,
  });
  Future<DoctorSecretaryDelegationModel> suspend({
    required String delegationId,
    String? reason,
  });
  Future<DoctorSecretaryDelegationModel> reactivate({
    required String delegationId,
  });
  Future<void> revoke({required String delegationId});
  Future<List<DoctorSecretaryDelegationModel>> getMyDelegations();
  Future<DoctorSecretaryDelegationModel> switchDoctorContext({
    required String doctorUserId,
  });
}

class SecretaryRemoteDataSourceImpl implements SecretaryRemoteDataSource {
  final Dio dio;

  SecretaryRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<DoctorSecretaryDelegationModel>> listDoctorSecretaries() async {
    final response = await dio.get(ApiConstants.doctorSecretaries);
    final items = _extractList(response.data);

    return items
        .map((item) => DoctorSecretaryDelegationModel.fromJson(item))
        .toList();
  }

  @override
  Future<DoctorSecretaryDelegationModel> inviteSecretary({
    required String email,
    required String firstName,
    required String lastName,
    required List<String> permissions,
    int expiresInHours = 72,
  }) async {
    final response = await dio.post(
      ApiConstants.doctorSecretaries + '/invite',
      data: {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'permissions': permissions,
        'expires_in_hours': expiresInHours,
      },
    );

    return DoctorSecretaryDelegationModel.fromJson(
      _extractDelegation(response.data),
    );
  }

  @override
  Future<DoctorSecretaryDelegationModel> updatePermissions({
    required String delegationId,
    required List<String> permissions,
  }) async {
    final response = await dio.patch(
      '${ApiConstants.doctorSecretaries}/$delegationId/permissions',
      data: {'permissions': permissions},
    );

    return DoctorSecretaryDelegationModel.fromJson(
      _extractDelegation(response.data),
    );
  }

  @override
  Future<DoctorSecretaryDelegationModel> suspend({
    required String delegationId,
    String? reason,
  }) async {
    final response = await dio.patch(
      '${ApiConstants.doctorSecretaries}/$delegationId/suspend',
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );

    return DoctorSecretaryDelegationModel.fromJson(
      _extractDelegation(response.data),
    );
  }

  @override
  Future<DoctorSecretaryDelegationModel> reactivate({
    required String delegationId,
  }) async {
    final response = await dio.patch(
      '${ApiConstants.doctorSecretaries}/$delegationId/reactivate',
    );

    return DoctorSecretaryDelegationModel.fromJson(
      _extractDelegation(response.data),
    );
  }

  @override
  Future<void> revoke({required String delegationId}) async {
    await dio.delete('${ApiConstants.doctorSecretaries}/$delegationId');
  }

  @override
  Future<List<DoctorSecretaryDelegationModel>> getMyDelegations() async {
    final response = await dio.get(ApiConstants.meDelegations);
    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final items = ((data['data'] as Map<String, dynamic>?)?['delegations']
            as List<dynamic>?) ??
        const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(DoctorSecretaryDelegationModel.fromJson)
        .toList();
  }

  @override
  Future<DoctorSecretaryDelegationModel> switchDoctorContext({
    required String doctorUserId,
  }) async {
    final response = await dio.post(
      ApiConstants.switchDoctorContext,
      data: {'doctor_user_id': doctorUserId},
      options: Options(headers: {'X-Acting-Doctor-Id': doctorUserId}),
    );

    return DoctorSecretaryDelegationModel.fromJson(
      _extractDelegation(response.data),
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }

    if (payload is List) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }

    return const [];
  }

  Map<String, dynamic> _extractDelegation(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];

      if (data is Map<String, dynamic> &&
          data['delegation'] is Map<String, dynamic>) {
        return data['delegation'] as Map<String, dynamic>;
      }

      if (data is Map<String, dynamic>) {
        return data;
      }
    }

    return payload is Map<String, dynamic> ? payload : <String, dynamic>{};
  }
}
