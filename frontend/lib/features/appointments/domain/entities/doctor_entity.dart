import 'package:equatable/equatable.dart';

// ── Safe JSON helpers (backend may return num OR String) ────
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _toBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

class DoctorEntity extends Equatable {
  final String userId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? rpps;
  final String? specialty;
  final String? bio;
  final String? consultationFee;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? avatarUrl;
  final double rating;
  final int totalReviews;
  final bool isAvailableForVideo;
  final List<ScheduleSlot> schedules;

  const DoctorEntity({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.rpps,
    this.specialty,
    this.bio,
    this.consultationFee,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.avatarUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isAvailableForVideo = true,
    this.schedules = const [],
  });

  String get fullName => 'Dr. $firstName $lastName';

  @override
  List<Object?> get props => [userId, firstName, lastName, specialty, city];

  factory DoctorEntity.fromJson(Map<String, dynamic> json) {
    final schedulesList = (json['schedules'] as List<dynamic>?)
            ?.map((s) => ScheduleSlot.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return DoctorEntity(
      userId: json['user_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      rpps: json['rpps']?.toString(),
      specialty: json['specialty']?.toString(),
      bio: json['bio']?.toString(),
      consultationFee: json['consultation_fee']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      avatarUrl: json['avatar_url']?.toString(),
      rating: _toDouble(json['rating']) ?? 0.0,
      totalReviews: _toInt(json['total_reviews']) ?? 0,
      isAvailableForVideo:
          _toBool(json['is_available_for_video'], fallback: true),
      schedules: schedulesList,
    );
  }
}

class ScheduleSlot extends Equatable {
  final String id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final bool isActive;

  const ScheduleSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.slotDurationMinutes = 30,
    this.isActive = true,
  });

  String get dayLabel => switch (dayOfWeek) {
        0 => 'Dimanche',
        1 => 'Lundi',
        2 => 'Mardi',
        3 => 'Mercredi',
        4 => 'Jeudi',
        5 => 'Vendredi',
        6 => 'Samedi',
        _ => '',
      };

  @override
  List<Object?> get props => [id, dayOfWeek, startTime, endTime];

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id']?.toString() ?? '',
      dayOfWeek: _toInt(json['day_of_week']) ?? 0,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      slotDurationMinutes: _toInt(json['slot_duration_minutes']) ?? 30,
      isActive: _toBool(json['is_active'], fallback: true),
    );
  }
}

class TimeSlot extends Equatable {
  final DateTime startsAtUtc;
  final DateTime endsAtUtc;
  final int durationMinutes;
  final bool isAvailable;

  const TimeSlot({
    required this.startsAtUtc,
    required this.endsAtUtc,
    required this.durationMinutes,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [startsAtUtc, endsAtUtc, isAvailable];

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startsAtUtc: DateTime.parse(json['starts_at_utc']),
      endsAtUtc: DateTime.parse(json['ends_at_utc']),
      durationMinutes: _toInt(json['duration_minutes']) ?? 30,
      isAvailable: _toBool(json['is_available'], fallback: false),
    );
  }
}
