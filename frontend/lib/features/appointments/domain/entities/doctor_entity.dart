import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String speciality;
  final String? avatarUrl;
  final double? rating;
  final String? address;
  final String? phone;
  final bool isAvailable;

  const Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.speciality,
    this.avatarUrl,
    this.rating,
    this.address,
    this.phone,
    this.isAvailable = true,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        speciality,
        avatarUrl,
        rating,
        address,
        phone,
        isAvailable
      ];
}
