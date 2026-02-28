/// User Entity - Domain layer
/// Clean Architecture: Entity is framework-independent
library;

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'patient' or 'doctor'
  final String? phone;
  final String? avatarUrl;
  final String? speciality; // For doctors
  final String? licenseNumber; // For doctors
  final double? rating;
  final String? address;
  final String? tenantId;
  final bool emailVerified;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.speciality,
    this.licenseNumber,
    this.rating,
    this.address,
    this.tenantId,
    this.emailVerified = false,
    this.createdAt,
  });

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatarUrl,
    String? speciality,
    String? licenseNumber,
    double? rating,
    String? address,
    String? tenantId,
    bool? emailVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      speciality: speciality ?? this.speciality,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      tenantId: tenantId ?? this.tenantId,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        phone,
        avatarUrl,
        speciality,
        licenseNumber,
        rating,
        address,
        tenantId,
        emailVerified,
        createdAt,
      ];
}
