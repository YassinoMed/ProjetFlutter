import 'package:equatable/equatable.dart';

class ExportDataModel extends Equatable {
  final Map<String, dynamic> raw;
  final DateTime exportedAt;

  const ExportDataModel({
    required this.raw,
    required this.exportedAt,
  });

  Map<String, dynamic> get data {
    final nested = raw['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    return raw;
  }

  int count(String key) {
    final value = data[key];
    if (value is List) return value.length;
    return 0;
  }

  String? get patientEmail {
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return user['email']?.toString();
    }
    return null;
  }

  @override
  List<Object?> get props => [raw, exportedAt];
}
