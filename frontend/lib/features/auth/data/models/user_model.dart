/// User Model - Data layer with manual JSON serialization
/// CDC: Modèle utilisateur avec support Patient/Médecin
library;

import '../../domain/entities/user_entity.dart';

// ── Safe JSON helpers (backend may return num OR String) ────
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _toBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String? speciality;
  final String? licenseNumber;
  final double? rating;
  final String? address;
  final String? tenantId;
  final bool isAvailable;
  final bool isVerified;
  final String? createdAt;
  final String? updatedAt;

  const UserModel({
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
    this.isAvailable = true,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle backend returning 'first_name' and 'last_name' instead of 'name'
    String name = json['name'] as String? ?? '';
    if (name.isEmpty) {
      final firstName = json['first_name'] as String? ?? '';
      final lastName = json['last_name'] as String? ?? '';
      name = '$firstName $lastName'.trim();
    }

    final role = (json['role'] as String? ?? 'patient').toLowerCase();

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: name,
      email: json['email'] as String? ?? '',
      role: role,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      speciality: json['speciality'] as String?,
      licenseNumber: json['license_number'] as String?,
      rating: _toDouble(json['rating']),
      address: json['address'] as String?,
      tenantId: json['tenant_id']?.toString(),
      isAvailable: _toBool(json['is_available'], fallback: true),
      isVerified: _toBool(json['is_verified'], fallback: false),
      createdAt: (json['created_at'] ?? json['created_at_utc']) as String?,
      updatedAt: (json['updated_at'] ?? json['updated_at_utc']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'speciality': speciality,
      'license_number': licenseNumber,
      'rating': rating,
      'address': address,
      'tenant_id': tenantId,
      'is_available': isAvailable,
      'is_verified': isVerified,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      phone: phone,
      avatarUrl: avatarUrl,
      speciality: speciality,
      licenseNumber: licenseNumber,
      rating: rating,
      address: address,
      tenantId: tenantId,
      emailVerified: isVerified,
    );
  }
}

class LoginResponseModel {
  final UserModel user;
  final String accessToken;
  final String tokenType;

  const LoginResponseModel({
    required this.user,
    required this.accessToken,
    this.tokenType = 'Bearer',
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Sanctum returns { user: {...}, token: "5|abc..." }
    // Fallback to 'access_token' or nested tokens for compatibility
    final tokens = json['tokens'] as Map<String, dynamic>?;

    return LoginResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: (json['token'] ??
              tokens?['access_token'] ??
              json['access_token']) as String? ??
          '',
      tokenType:
          (json['token_type'] ?? tokens?['token_type']) as String? ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': accessToken,
      'token_type': tokenType,
    };
  }
}
