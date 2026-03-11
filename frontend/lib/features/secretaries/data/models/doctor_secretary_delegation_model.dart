library;

import '../../domain/entities/doctor_secretary_delegation_entity.dart';

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}

class DoctorSecretaryDelegationModel extends DoctorSecretaryDelegationEntity {
  const DoctorSecretaryDelegationModel({
    required super.id,
    required super.doctorUserId,
    required super.secretaryUserId,
    required super.invitedEmail,
    required super.invitedFirstName,
    required super.invitedLastName,
    required super.status,
    required super.permissions,
    super.doctor,
    super.secretary,
    super.latestInvitation,
    super.activatedAtUtc,
    super.suspendedAtUtc,
    super.revokedAtUtc,
    super.lastUsedAtUtc,
  });

  factory DoctorSecretaryDelegationModel.fromJson(Map<String, dynamic> json) {
    return DoctorSecretaryDelegationModel(
      id: json['id']?.toString() ?? '',
      doctorUserId: json['doctor_user_id']?.toString() ?? '',
      secretaryUserId: json['secretary_user_id']?.toString(),
      invitedEmail: json['invited_email'] as String? ?? '',
      invitedFirstName: json['invited_first_name'] as String? ?? '',
      invitedLastName: json['invited_last_name'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      permissions: ((json['permissions'] as List?) ?? const [])
          .map((permission) => permission.toString())
          .toList(),
      doctor: _parseUser(json['doctor']),
      secretary: _parseUser(json['secretary']),
      latestInvitation: _parseInvitation(json['latest_invitation']),
      activatedAtUtc: _parseDate(json['activated_at_utc']),
      suspendedAtUtc: _parseDate(json['suspended_at_utc']),
      revokedAtUtc: _parseDate(json['revoked_at_utc']),
      lastUsedAtUtc: _parseDate(json['last_used_at_utc']),
    );
  }

  static DelegationUserSummary? _parseUser(dynamic value) {
    if (value is! Map<String, dynamic>) return null;

    final firstName = value['first_name'] as String? ?? '';
    final lastName = value['last_name'] as String? ?? '';

    return DelegationUserSummary(
      id: value['id']?.toString() ?? '',
      fullName: '$firstName $lastName'.trim(),
      email: value['email'] as String? ?? '',
    );
  }

  static SecretaryInvitationSummary? _parseInvitation(dynamic value) {
    if (value is! Map<String, dynamic>) return null;

    return SecretaryInvitationSummary(
      status: value['status'] as String? ?? 'PENDING',
      expiresAtUtc: _parseDate(value['expires_at_utc']),
      acceptedAtUtc: _parseDate(value['accepted_at_utc']),
    );
  }
}
