library;

import 'package:equatable/equatable.dart';

class DelegationUserSummary extends Equatable {
  final String id;
  final String fullName;
  final String email;

  const DelegationUserSummary({
    required this.id,
    required this.fullName,
    required this.email,
  });

  @override
  List<Object?> get props => [id, fullName, email];
}

class SecretaryInvitationSummary extends Equatable {
  final String status;
  final DateTime? expiresAtUtc;
  final DateTime? acceptedAtUtc;

  const SecretaryInvitationSummary({
    required this.status,
    this.expiresAtUtc,
    this.acceptedAtUtc,
  });

  bool get isExpired =>
      expiresAtUtc != null && expiresAtUtc!.isBefore(DateTime.now().toUtc());

  @override
  List<Object?> get props => [status, expiresAtUtc, acceptedAtUtc];
}

class DoctorSecretaryDelegationEntity extends Equatable {
  final String id;
  final String doctorUserId;
  final String? secretaryUserId;
  final String invitedEmail;
  final String invitedFirstName;
  final String invitedLastName;
  final String status;
  final List<String> permissions;
  final DelegationUserSummary? doctor;
  final DelegationUserSummary? secretary;
  final SecretaryInvitationSummary? latestInvitation;
  final DateTime? activatedAtUtc;
  final DateTime? suspendedAtUtc;
  final DateTime? revokedAtUtc;
  final DateTime? lastUsedAtUtc;

  const DoctorSecretaryDelegationEntity({
    required this.id,
    required this.doctorUserId,
    required this.secretaryUserId,
    required this.invitedEmail,
    required this.invitedFirstName,
    required this.invitedLastName,
    required this.status,
    required this.permissions,
    this.doctor,
    this.secretary,
    this.latestInvitation,
    this.activatedAtUtc,
    this.suspendedAtUtc,
    this.revokedAtUtc,
    this.lastUsedAtUtc,
  });

  String get inviteeDisplayName {
    final fullName = '$invitedFirstName $invitedLastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    return secretary?.fullName ?? invitedEmail;
  }

  bool get isActive => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isPending => status == 'PENDING';

  @override
  List<Object?> get props => [
        id,
        doctorUserId,
        secretaryUserId,
        invitedEmail,
        invitedFirstName,
        invitedLastName,
        status,
        permissions,
        doctor,
        secretary,
        latestInvitation,
        activatedAtUtc,
        suspendedAtUtc,
        revokedAtUtc,
        lastUsedAtUtc,
      ];
}
