import '../../domain/entities/doctor_entity.dart';

class DoctorModel extends Doctor {
  const DoctorModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.speciality,
    super.avatarUrl,
    super.rating,
    super.address,
    super.phone,
    super.isAvailable,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id']?.toString() ?? '',
      firstName:
          (json['first_name'] ?? json['user']?['first_name']) as String? ?? '',
      lastName:
          (json['last_name'] ?? json['user']?['last_name']) as String? ?? '',
      speciality: json['speciality'] as String? ?? 'Généraliste',
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'speciality': speciality,
      'avatar_url': avatarUrl,
      'rating': rating,
      'address': address,
      'phone': phone,
      'is_available': isAvailable,
    };
  }
}
