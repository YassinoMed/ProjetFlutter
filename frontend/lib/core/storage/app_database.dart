/// Drift Database Configuration with SQLCipher Encryption
/// CDC page 16: Base locale sécurisée AES-256
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../constants/app_constants.dart';
import '../security/secure_storage_service.dart';

part 'app_database.g.dart';

// ── Table Definitions ─────────────────────────────────────────

/// Cached appointments table (offline-first)
class CachedAppointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get patientId => text()();
  TextColumn get doctorId => text()();
  TextColumn get doctorName => text()();
  TextColumn get speciality => text().nullable()();
  DateTimeColumn get appointmentDateTime => dateTime()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(30))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get type => text().withDefault(const Constant('consultation'))();
  TextColumn get notes => text().nullable()();
  TextColumn get location => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cached messages for chat (offline-first)
class CachedMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get status => text().withDefault(const Constant('sent'))();
  TextColumn get attachmentUrl => text().nullable()();
  TextColumn get attachmentType => text().nullable()();
  BoolColumn get isEncrypted => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Medical records table
class CachedMedicalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get patientId => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get encryptedData => text()();
  TextColumn get doctorName => text().nullable()();
  TextColumn get fileUrl => text().nullable()();
  DateTimeColumn get recordDate => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Notification cache
class CachedNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get data => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Offline sync queue
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()();
  TextColumn get payload => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// User profile cache
class CachedUsers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get role => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get speciality => text().nullable()();
  TextColumn get licenseNumber => text().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Database Class ──────────────────────────────────────────

@DriftDatabase(tables: [
  CachedAppointments,
  CachedMessages,
  CachedMedicalRecords,
  CachedNotifications,
  SyncQueue,
  CachedUsers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations will go here
    },
  );
}

// ── Database Initialization ─────────────────────────────────

LazyDatabase _openDatabase(String encryptionKey) {
  return LazyDatabase(() async {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mediconnect_pro.db'));

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute("PRAGMA key = '$encryptionKey'");
        db.execute('PRAGMA journal_mode = WAL');
        db.execute('PRAGMA foreign_keys = ON');
        db.execute('PRAGMA cache_size = -8000');
      },
    );
  });
}

Future<String> _getOrCreateDbKey(SecureStorageService secureStorage) async {
  var key = await secureStorage.read(key: AppConstants.keyDbEncryptionKey);
  if (key == null) {
    final random = sql.sqlite3.openInMemory();
    random.execute("SELECT hex(randomblob(32))");
    key = random.select("SELECT hex(randomblob(32))").first.values.first as String;
    random.dispose();
    await secureStorage.write(key: AppConstants.keyDbEncryptionKey, value: key);
  }
  return key;
}

/// Provider for the encrypted database
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final encryptionKey = await _getOrCreateDbKey(secureStorage);
  final db = AppDatabase(_openDatabase(encryptionKey));
  ref.onDispose(() => db.close());
  return db;
});
