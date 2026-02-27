import '../../domain/entities/doctor_entity.dart';

class DoctorModel extends DoctorEntity {
  const DoctorModel({
    required super.userId,
    required super.firstName,
    required super.lastName,
    super.email,
    super.phone,
    super.rpps,
    super.specialty,
    super.bio,
    super.consultationFee,
    super.city,
    super.address,
    super.latitude,
    super.longitude,
    super.avatarUrl,
    super.rating,
    super.totalReviews,
    super.isAvailableForVideo,
    super.schedules,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final entity = DoctorEntity.fromJson(json);
    return DoctorModel(
      userId: entity.userId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      phone: entity.phone,
      rpps: entity.rpps,
      specialty: entity.specialty,
      bio: entity.bio,
      consultationFee: entity.consultationFee,
      city: entity.city,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      avatarUrl: entity.avatarUrl,
      rating: entity.rating,
      totalReviews: entity.totalReviews,
      isAvailableForVideo: entity.isAvailableForVideo,
      schedules: entity.schedules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'rpps': rpps,
      'specialty': specialty,
      'bio': bio,
      'consultation_fee': consultationFee,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'avatar_url': avatarUrl,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_available_for_video': isAvailableForVideo,
    };
  }
}
