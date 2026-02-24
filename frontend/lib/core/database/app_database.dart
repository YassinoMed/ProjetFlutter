import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Doctors extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get speciality => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get biography => text().nullable()();
  RealColumn get rating => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get doctorId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()();
  TextColumn get type => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MedicalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get type => text()(); // Consultation, Ordonnance, etc.
  TextColumn get title => text()();
  TextColumn get content => text()(); // Encrypted content
  TextColumn get fileUrl => text().nullable()(); // Encrypted file
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Doctors, Appointments, MedicalRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
