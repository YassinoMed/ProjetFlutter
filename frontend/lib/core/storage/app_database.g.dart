// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedAppointmentsTable extends CachedAppointments
    with TableInfo<$CachedAppointmentsTable, CachedAppointment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAppointmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _patientIdMeta =
      const VerificationMeta('patientId');
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
      'patient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doctorIdMeta =
      const VerificationMeta('doctorId');
  @override
  late final GeneratedColumn<String> doctorId = GeneratedColumn<String>(
      'doctor_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doctorNameMeta =
      const VerificationMeta('doctorName');
  @override
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
      'doctor_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _specialityMeta =
      const VerificationMeta('speciality');
  @override
  late final GeneratedColumn<String> speciality = GeneratedColumn<String>(
      'speciality', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _appointmentDateTimeMeta =
      const VerificationMeta('appointmentDateTime');
  @override
  late final GeneratedColumn<DateTime> appointmentDateTime =
      GeneratedColumn<DateTime>('appointment_date_time', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(30));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('consultation'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        patientId,
        doctorId,
        doctorName,
        speciality,
        appointmentDateTime,
        durationMinutes,
        status,
        type,
        notes,
        location,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_appointments';
  @override
  VerificationContext validateIntegrity(Insertable<CachedAppointment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(_patientIdMeta,
          patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta));
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('doctor_id')) {
      context.handle(_doctorIdMeta,
          doctorId.isAcceptableOrUnknown(data['doctor_id']!, _doctorIdMeta));
    } else if (isInserting) {
      context.missing(_doctorIdMeta);
    }
    if (data.containsKey('doctor_name')) {
      context.handle(
          _doctorNameMeta,
          doctorName.isAcceptableOrUnknown(
              data['doctor_name']!, _doctorNameMeta));
    } else if (isInserting) {
      context.missing(_doctorNameMeta);
    }
    if (data.containsKey('speciality')) {
      context.handle(
          _specialityMeta,
          speciality.isAcceptableOrUnknown(
              data['speciality']!, _specialityMeta));
    }
    if (data.containsKey('appointment_date_time')) {
      context.handle(
          _appointmentDateTimeMeta,
          appointmentDateTime.isAcceptableOrUnknown(
              data['appointment_date_time']!, _appointmentDateTimeMeta));
    } else if (isInserting) {
      context.missing(_appointmentDateTimeMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAppointment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAppointment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id'])!,
      patientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patient_id'])!,
      doctorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_id'])!,
      doctorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_name'])!,
      speciality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}speciality']),
      appointmentDateTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}appointment_date_time'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CachedAppointmentsTable createAlias(String alias) {
    return $CachedAppointmentsTable(attachedDatabase, alias);
  }
}

class CachedAppointment extends DataClass
    implements Insertable<CachedAppointment> {
  final int id;
  final String remoteId;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String? speciality;
  final DateTime appointmentDateTime;
  final int durationMinutes;
  final String status;
  final String type;
  final String? notes;
  final String? location;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedAppointment(
      {required this.id,
      required this.remoteId,
      required this.patientId,
      required this.doctorId,
      required this.doctorName,
      this.speciality,
      required this.appointmentDateTime,
      required this.durationMinutes,
      required this.status,
      required this.type,
      this.notes,
      this.location,
      required this.isSynced,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['patient_id'] = Variable<String>(patientId);
    map['doctor_id'] = Variable<String>(doctorId);
    map['doctor_name'] = Variable<String>(doctorName);
    if (!nullToAbsent || speciality != null) {
      map['speciality'] = Variable<String>(speciality);
    }
    map['appointment_date_time'] = Variable<DateTime>(appointmentDateTime);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['status'] = Variable<String>(status);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedAppointmentsCompanion toCompanion(bool nullToAbsent) {
    return CachedAppointmentsCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      patientId: Value(patientId),
      doctorId: Value(doctorId),
      doctorName: Value(doctorName),
      speciality: speciality == null && nullToAbsent
          ? const Value.absent()
          : Value(speciality),
      appointmentDateTime: Value(appointmentDateTime),
      durationMinutes: Value(durationMinutes),
      status: Value(status),
      type: Value(type),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedAppointment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAppointment(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      doctorId: serializer.fromJson<String>(json['doctorId']),
      doctorName: serializer.fromJson<String>(json['doctorName']),
      speciality: serializer.fromJson<String?>(json['speciality']),
      appointmentDateTime:
          serializer.fromJson<DateTime>(json['appointmentDateTime']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      status: serializer.fromJson<String>(json['status']),
      type: serializer.fromJson<String>(json['type']),
      notes: serializer.fromJson<String?>(json['notes']),
      location: serializer.fromJson<String?>(json['location']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'patientId': serializer.toJson<String>(patientId),
      'doctorId': serializer.toJson<String>(doctorId),
      'doctorName': serializer.toJson<String>(doctorName),
      'speciality': serializer.toJson<String?>(speciality),
      'appointmentDateTime': serializer.toJson<DateTime>(appointmentDateTime),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'status': serializer.toJson<String>(status),
      'type': serializer.toJson<String>(type),
      'notes': serializer.toJson<String?>(notes),
      'location': serializer.toJson<String?>(location),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedAppointment copyWith(
          {int? id,
          String? remoteId,
          String? patientId,
          String? doctorId,
          String? doctorName,
          Value<String?> speciality = const Value.absent(),
          DateTime? appointmentDateTime,
          int? durationMinutes,
          String? status,
          String? type,
          Value<String?> notes = const Value.absent(),
          Value<String?> location = const Value.absent(),
          bool? isSynced,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CachedAppointment(
        id: id ?? this.id,
        remoteId: remoteId ?? this.remoteId,
        patientId: patientId ?? this.patientId,
        doctorId: doctorId ?? this.doctorId,
        doctorName: doctorName ?? this.doctorName,
        speciality: speciality.present ? speciality.value : this.speciality,
        appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        status: status ?? this.status,
        type: type ?? this.type,
        notes: notes.present ? notes.value : this.notes,
        location: location.present ? location.value : this.location,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedAppointment copyWithCompanion(CachedAppointmentsCompanion data) {
    return CachedAppointment(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      doctorId: data.doctorId.present ? data.doctorId.value : this.doctorId,
      doctorName:
          data.doctorName.present ? data.doctorName.value : this.doctorName,
      speciality:
          data.speciality.present ? data.speciality.value : this.speciality,
      appointmentDateTime: data.appointmentDateTime.present
          ? data.appointmentDateTime.value
          : this.appointmentDateTime,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      notes: data.notes.present ? data.notes.value : this.notes,
      location: data.location.present ? data.location.value : this.location,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAppointment(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('patientId: $patientId, ')
          ..write('doctorId: $doctorId, ')
          ..write('doctorName: $doctorName, ')
          ..write('speciality: $speciality, ')
          ..write('appointmentDateTime: $appointmentDateTime, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('location: $location, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      remoteId,
      patientId,
      doctorId,
      doctorName,
      speciality,
      appointmentDateTime,
      durationMinutes,
      status,
      type,
      notes,
      location,
      isSynced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAppointment &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.patientId == this.patientId &&
          other.doctorId == this.doctorId &&
          other.doctorName == this.doctorName &&
          other.speciality == this.speciality &&
          other.appointmentDateTime == this.appointmentDateTime &&
          other.durationMinutes == this.durationMinutes &&
          other.status == this.status &&
          other.type == this.type &&
          other.notes == this.notes &&
          other.location == this.location &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedAppointmentsCompanion extends UpdateCompanion<CachedAppointment> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> patientId;
  final Value<String> doctorId;
  final Value<String> doctorName;
  final Value<String?> speciality;
  final Value<DateTime> appointmentDateTime;
  final Value<int> durationMinutes;
  final Value<String> status;
  final Value<String> type;
  final Value<String?> notes;
  final Value<String?> location;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CachedAppointmentsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.doctorId = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.speciality = const Value.absent(),
    this.appointmentDateTime = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.notes = const Value.absent(),
    this.location = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CachedAppointmentsCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String patientId,
    required String doctorId,
    required String doctorName,
    this.speciality = const Value.absent(),
    required DateTime appointmentDateTime,
    this.durationMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.notes = const Value.absent(),
    this.location = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : remoteId = Value(remoteId),
        patientId = Value(patientId),
        doctorId = Value(doctorId),
        doctorName = Value(doctorName),
        appointmentDateTime = Value(appointmentDateTime);
  static Insertable<CachedAppointment> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? patientId,
    Expression<String>? doctorId,
    Expression<String>? doctorName,
    Expression<String>? speciality,
    Expression<DateTime>? appointmentDateTime,
    Expression<int>? durationMinutes,
    Expression<String>? status,
    Expression<String>? type,
    Expression<String>? notes,
    Expression<String>? location,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (doctorName != null) 'doctor_name': doctorName,
      if (speciality != null) 'speciality': speciality,
      if (appointmentDateTime != null)
        'appointment_date_time': appointmentDateTime,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (notes != null) 'notes': notes,
      if (location != null) 'location': location,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CachedAppointmentsCompanion copyWith(
      {Value<int>? id,
      Value<String>? remoteId,
      Value<String>? patientId,
      Value<String>? doctorId,
      Value<String>? doctorName,
      Value<String?>? speciality,
      Value<DateTime>? appointmentDateTime,
      Value<int>? durationMinutes,
      Value<String>? status,
      Value<String>? type,
      Value<String?>? notes,
      Value<String?>? location,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CachedAppointmentsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      speciality: speciality ?? this.speciality,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (doctorId.present) {
      map['doctor_id'] = Variable<String>(doctorId.value);
    }
    if (doctorName.present) {
      map['doctor_name'] = Variable<String>(doctorName.value);
    }
    if (speciality.present) {
      map['speciality'] = Variable<String>(speciality.value);
    }
    if (appointmentDateTime.present) {
      map['appointment_date_time'] =
          Variable<DateTime>(appointmentDateTime.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAppointmentsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('patientId: $patientId, ')
          ..write('doctorId: $doctorId, ')
          ..write('doctorName: $doctorName, ')
          ..write('speciality: $speciality, ')
          ..write('appointmentDateTime: $appointmentDateTime, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('location: $location, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedMessagesTable extends CachedMessages
    with TableInfo<$CachedMessagesTable, CachedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sent'));
  static const VerificationMeta _attachmentUrlMeta =
      const VerificationMeta('attachmentUrl');
  @override
  late final GeneratedColumn<String> attachmentUrl = GeneratedColumn<String>(
      'attachment_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attachmentTypeMeta =
      const VerificationMeta('attachmentType');
  @override
  late final GeneratedColumn<String> attachmentType = GeneratedColumn<String>(
      'attachment_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isEncryptedMeta =
      const VerificationMeta('isEncrypted');
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
      'is_encrypted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_encrypted" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        conversationId,
        senderId,
        content,
        type,
        status,
        attachmentUrl,
        attachmentType,
        isEncrypted,
        isSynced,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_messages';
  @override
  VerificationContext validateIntegrity(Insertable<CachedMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attachment_url')) {
      context.handle(
          _attachmentUrlMeta,
          attachmentUrl.isAcceptableOrUnknown(
              data['attachment_url']!, _attachmentUrlMeta));
    }
    if (data.containsKey('attachment_type')) {
      context.handle(
          _attachmentTypeMeta,
          attachmentType.isAcceptableOrUnknown(
              data['attachment_type']!, _attachmentTypeMeta));
    }
    if (data.containsKey('is_encrypted')) {
      context.handle(
          _isEncryptedMeta,
          isEncrypted.isAcceptableOrUnknown(
              data['is_encrypted']!, _isEncryptedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id']),
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attachmentUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachment_url']),
      attachmentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachment_type']),
      isEncrypted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_encrypted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CachedMessagesTable createAlias(String alias) {
    return $CachedMessagesTable(attachedDatabase, alias);
  }
}

class CachedMessage extends DataClass implements Insertable<CachedMessage> {
  final int id;
  final String? remoteId;
  final String conversationId;
  final String senderId;
  final String content;
  final String type;
  final String status;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool isEncrypted;
  final bool isSynced;
  final DateTime createdAt;
  const CachedMessage(
      {required this.id,
      this.remoteId,
      required this.conversationId,
      required this.senderId,
      required this.content,
      required this.type,
      required this.status,
      this.attachmentUrl,
      this.attachmentType,
      required this.isEncrypted,
      required this.isSynced,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['content'] = Variable<String>(content);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || attachmentUrl != null) {
      map['attachment_url'] = Variable<String>(attachmentUrl);
    }
    if (!nullToAbsent || attachmentType != null) {
      map['attachment_type'] = Variable<String>(attachmentType);
    }
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CachedMessagesCompanion toCompanion(bool nullToAbsent) {
    return CachedMessagesCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      content: Value(content),
      type: Value(type),
      status: Value(status),
      attachmentUrl: attachmentUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentUrl),
      attachmentType: attachmentType == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentType),
      isEncrypted: Value(isEncrypted),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory CachedMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessage(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      content: serializer.fromJson<String>(json['content']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      attachmentUrl: serializer.fromJson<String?>(json['attachmentUrl']),
      attachmentType: serializer.fromJson<String?>(json['attachmentType']),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'content': serializer.toJson<String>(content),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'attachmentUrl': serializer.toJson<String?>(attachmentUrl),
      'attachmentType': serializer.toJson<String?>(attachmentType),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CachedMessage copyWith(
          {int? id,
          Value<String?> remoteId = const Value.absent(),
          String? conversationId,
          String? senderId,
          String? content,
          String? type,
          String? status,
          Value<String?> attachmentUrl = const Value.absent(),
          Value<String?> attachmentType = const Value.absent(),
          bool? isEncrypted,
          bool? isSynced,
          DateTime? createdAt}) =>
      CachedMessage(
        id: id ?? this.id,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        conversationId: conversationId ?? this.conversationId,
        senderId: senderId ?? this.senderId,
        content: content ?? this.content,
        type: type ?? this.type,
        status: status ?? this.status,
        attachmentUrl:
            attachmentUrl.present ? attachmentUrl.value : this.attachmentUrl,
        attachmentType:
            attachmentType.present ? attachmentType.value : this.attachmentType,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
      );
  CachedMessage copyWithCompanion(CachedMessagesCompanion data) {
    return CachedMessage(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      content: data.content.present ? data.content.value : this.content,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      attachmentUrl: data.attachmentUrl.present
          ? data.attachmentUrl.value
          : this.attachmentUrl,
      attachmentType: data.attachmentType.present
          ? data.attachmentType.value
          : this.attachmentType,
      isEncrypted:
          data.isEncrypted.present ? data.isEncrypted.value : this.isEncrypted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessage(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('attachmentUrl: $attachmentUrl, ')
          ..write('attachmentType: $attachmentType, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      remoteId,
      conversationId,
      senderId,
      content,
      type,
      status,
      attachmentUrl,
      attachmentType,
      isEncrypted,
      isSynced,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessage &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.type == this.type &&
          other.status == this.status &&
          other.attachmentUrl == this.attachmentUrl &&
          other.attachmentType == this.attachmentType &&
          other.isEncrypted == this.isEncrypted &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class CachedMessagesCompanion extends UpdateCompanion<CachedMessage> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<String> content;
  final Value<String> type;
  final Value<String> status;
  final Value<String?> attachmentUrl;
  final Value<String?> attachmentType;
  final Value<bool> isEncrypted;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  const CachedMessagesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.attachmentUrl = const Value.absent(),
    this.attachmentType = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CachedMessagesCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String conversationId,
    required String senderId,
    required String content,
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.attachmentUrl = const Value.absent(),
    this.attachmentType = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : conversationId = Value(conversationId),
        senderId = Value(senderId),
        content = Value(content);
  static Insertable<CachedMessage> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<String>? type,
    Expression<String>? status,
    Expression<String>? attachmentUrl,
    Expression<String>? attachmentType,
    Expression<bool>? isEncrypted,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (attachmentType != null) 'attachment_type': attachmentType,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CachedMessagesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? remoteId,
      Value<String>? conversationId,
      Value<String>? senderId,
      Value<String>? content,
      Value<String>? type,
      Value<String>? status,
      Value<String?>? attachmentUrl,
      Value<String?>? attachmentType,
      Value<bool>? isEncrypted,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt}) {
    return CachedMessagesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attachmentUrl.present) {
      map['attachment_url'] = Variable<String>(attachmentUrl.value);
    }
    if (attachmentType.present) {
      map['attachment_type'] = Variable<String>(attachmentType.value);
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('attachmentUrl: $attachmentUrl, ')
          ..write('attachmentType: $attachmentType, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CachedMedicalRecordsTable extends CachedMedicalRecords
    with TableInfo<$CachedMedicalRecordsTable, CachedMedicalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMedicalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _patientIdMeta =
      const VerificationMeta('patientId');
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
      'patient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedDataMeta =
      const VerificationMeta('encryptedData');
  @override
  late final GeneratedColumn<String> encryptedData = GeneratedColumn<String>(
      'encrypted_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doctorNameMeta =
      const VerificationMeta('doctorName');
  @override
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
      'doctor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileUrlMeta =
      const VerificationMeta('fileUrl');
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
      'file_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordDateMeta =
      const VerificationMeta('recordDate');
  @override
  late final GeneratedColumn<DateTime> recordDate = GeneratedColumn<DateTime>(
      'record_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        patientId,
        title,
        type,
        encryptedData,
        doctorName,
        fileUrl,
        recordDate,
        isSynced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_medical_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<CachedMedicalRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(_patientIdMeta,
          patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta));
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('encrypted_data')) {
      context.handle(
          _encryptedDataMeta,
          encryptedData.isAcceptableOrUnknown(
              data['encrypted_data']!, _encryptedDataMeta));
    } else if (isInserting) {
      context.missing(_encryptedDataMeta);
    }
    if (data.containsKey('doctor_name')) {
      context.handle(
          _doctorNameMeta,
          doctorName.isAcceptableOrUnknown(
              data['doctor_name']!, _doctorNameMeta));
    }
    if (data.containsKey('file_url')) {
      context.handle(_fileUrlMeta,
          fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta));
    }
    if (data.containsKey('record_date')) {
      context.handle(
          _recordDateMeta,
          recordDate.isAcceptableOrUnknown(
              data['record_date']!, _recordDateMeta));
    } else if (isInserting) {
      context.missing(_recordDateMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMedicalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMedicalRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id'])!,
      patientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patient_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      encryptedData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}encrypted_data'])!,
      doctorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctor_name']),
      fileUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_url']),
      recordDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}record_date'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CachedMedicalRecordsTable createAlias(String alias) {
    return $CachedMedicalRecordsTable(attachedDatabase, alias);
  }
}

class CachedMedicalRecord extends DataClass
    implements Insertable<CachedMedicalRecord> {
  final int id;
  final String remoteId;
  final String patientId;
  final String title;
  final String type;
  final String encryptedData;
  final String? doctorName;
  final String? fileUrl;
  final DateTime recordDate;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CachedMedicalRecord(
      {required this.id,
      required this.remoteId,
      required this.patientId,
      required this.title,
      required this.type,
      required this.encryptedData,
      this.doctorName,
      this.fileUrl,
      required this.recordDate,
      required this.isSynced,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['patient_id'] = Variable<String>(patientId);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['encrypted_data'] = Variable<String>(encryptedData);
    if (!nullToAbsent || doctorName != null) {
      map['doctor_name'] = Variable<String>(doctorName);
    }
    if (!nullToAbsent || fileUrl != null) {
      map['file_url'] = Variable<String>(fileUrl);
    }
    map['record_date'] = Variable<DateTime>(recordDate);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMedicalRecordsCompanion toCompanion(bool nullToAbsent) {
    return CachedMedicalRecordsCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      patientId: Value(patientId),
      title: Value(title),
      type: Value(type),
      encryptedData: Value(encryptedData),
      doctorName: doctorName == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorName),
      fileUrl: fileUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fileUrl),
      recordDate: Value(recordDate),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedMedicalRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMedicalRecord(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      encryptedData: serializer.fromJson<String>(json['encryptedData']),
      doctorName: serializer.fromJson<String?>(json['doctorName']),
      fileUrl: serializer.fromJson<String?>(json['fileUrl']),
      recordDate: serializer.fromJson<DateTime>(json['recordDate']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'patientId': serializer.toJson<String>(patientId),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'encryptedData': serializer.toJson<String>(encryptedData),
      'doctorName': serializer.toJson<String?>(doctorName),
      'fileUrl': serializer.toJson<String?>(fileUrl),
      'recordDate': serializer.toJson<DateTime>(recordDate),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedMedicalRecord copyWith(
          {int? id,
          String? remoteId,
          String? patientId,
          String? title,
          String? type,
          String? encryptedData,
          Value<String?> doctorName = const Value.absent(),
          Value<String?> fileUrl = const Value.absent(),
          DateTime? recordDate,
          bool? isSynced,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CachedMedicalRecord(
        id: id ?? this.id,
        remoteId: remoteId ?? this.remoteId,
        patientId: patientId ?? this.patientId,
        title: title ?? this.title,
        type: type ?? this.type,
        encryptedData: encryptedData ?? this.encryptedData,
        doctorName: doctorName.present ? doctorName.value : this.doctorName,
        fileUrl: fileUrl.present ? fileUrl.value : this.fileUrl,
        recordDate: recordDate ?? this.recordDate,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedMedicalRecord copyWithCompanion(CachedMedicalRecordsCompanion data) {
    return CachedMedicalRecord(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      encryptedData: data.encryptedData.present
          ? data.encryptedData.value
          : this.encryptedData,
      doctorName:
          data.doctorName.present ? data.doctorName.value : this.doctorName,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      recordDate:
          data.recordDate.present ? data.recordDate.value : this.recordDate,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedicalRecord(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('patientId: $patientId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('encryptedData: $encryptedData, ')
          ..write('doctorName: $doctorName, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('recordDate: $recordDate, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      remoteId,
      patientId,
      title,
      type,
      encryptedData,
      doctorName,
      fileUrl,
      recordDate,
      isSynced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMedicalRecord &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.patientId == this.patientId &&
          other.title == this.title &&
          other.type == this.type &&
          other.encryptedData == this.encryptedData &&
          other.doctorName == this.doctorName &&
          other.fileUrl == this.fileUrl &&
          other.recordDate == this.recordDate &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CachedMedicalRecordsCompanion
    extends UpdateCompanion<CachedMedicalRecord> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> patientId;
  final Value<String> title;
  final Value<String> type;
  final Value<String> encryptedData;
  final Value<String?> doctorName;
  final Value<String?> fileUrl;
  final Value<DateTime> recordDate;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CachedMedicalRecordsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.encryptedData = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.recordDate = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CachedMedicalRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String patientId,
    required String title,
    required String type,
    required String encryptedData,
    this.doctorName = const Value.absent(),
    this.fileUrl = const Value.absent(),
    required DateTime recordDate,
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : remoteId = Value(remoteId),
        patientId = Value(patientId),
        title = Value(title),
        type = Value(type),
        encryptedData = Value(encryptedData),
        recordDate = Value(recordDate);
  static Insertable<CachedMedicalRecord> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? patientId,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? encryptedData,
    Expression<String>? doctorName,
    Expression<String>? fileUrl,
    Expression<DateTime>? recordDate,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (patientId != null) 'patient_id': patientId,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (encryptedData != null) 'encrypted_data': encryptedData,
      if (doctorName != null) 'doctor_name': doctorName,
      if (fileUrl != null) 'file_url': fileUrl,
      if (recordDate != null) 'record_date': recordDate,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CachedMedicalRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? remoteId,
      Value<String>? patientId,
      Value<String>? title,
      Value<String>? type,
      Value<String>? encryptedData,
      Value<String?>? doctorName,
      Value<String?>? fileUrl,
      Value<DateTime>? recordDate,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CachedMedicalRecordsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      type: type ?? this.type,
      encryptedData: encryptedData ?? this.encryptedData,
      doctorName: doctorName ?? this.doctorName,
      fileUrl: fileUrl ?? this.fileUrl,
      recordDate: recordDate ?? this.recordDate,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (encryptedData.present) {
      map['encrypted_data'] = Variable<String>(encryptedData.value);
    }
    if (doctorName.present) {
      map['doctor_name'] = Variable<String>(doctorName.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (recordDate.present) {
      map['record_date'] = Variable<DateTime>(recordDate.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedicalRecordsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('patientId: $patientId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('encryptedData: $encryptedData, ')
          ..write('doctorName: $doctorName, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('recordDate: $recordDate, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedNotificationsTable extends CachedNotifications
    with TableInfo<$CachedNotificationsTable, CachedNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, remoteId, type, title, body, data, isRead, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<CachedNotification> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNotification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data']),
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CachedNotificationsTable createAlias(String alias) {
    return $CachedNotificationsTable(attachedDatabase, alias);
  }
}

class CachedNotification extends DataClass
    implements Insertable<CachedNotification> {
  final int id;
  final String? remoteId;
  final String type;
  final String title;
  final String body;
  final String? data;
  final bool isRead;
  final DateTime createdAt;
  const CachedNotification(
      {required this.id,
      this.remoteId,
      required this.type,
      required this.title,
      required this.body,
      this.data,
      required this.isRead,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CachedNotificationsCompanion toCompanion(bool nullToAbsent) {
    return CachedNotificationsCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
    );
  }

  factory CachedNotification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNotification(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      data: serializer.fromJson<String?>(json['data']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'data': serializer.toJson<String?>(data),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CachedNotification copyWith(
          {int? id,
          Value<String?> remoteId = const Value.absent(),
          String? type,
          String? title,
          String? body,
          Value<String?> data = const Value.absent(),
          bool? isRead,
          DateTime? createdAt}) =>
      CachedNotification(
        id: id ?? this.id,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        data: data.present ? data.value : this.data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
  CachedNotification copyWithCompanion(CachedNotificationsCompanion data) {
    return CachedNotification(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      data: data.data.present ? data.data.value : this.data,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotification(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, remoteId, type, title, body, data, isRead, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNotification &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.data == this.data &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt);
}

class CachedNotificationsCompanion extends UpdateCompanion<CachedNotification> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<String> type;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> data;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  const CachedNotificationsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CachedNotificationsCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String type,
    required String title,
    required String body,
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : type = Value(type),
        title = Value(title),
        body = Value(body);
  static Insertable<CachedNotification> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? data,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (data != null) 'data': data,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CachedNotificationsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? remoteId,
      Value<String>? type,
      Value<String>? title,
      Value<String>? body,
      Value<String?>? data,
      Value<bool>? isRead,
      Value<DateTime>? createdAt}) {
    return CachedNotificationsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        action,
        payload,
        retryCount,
        isSynced,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final int retryCount;
  final bool isSynced;
  final DateTime createdAt;
  const SyncQueueData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.action,
      required this.payload,
      required this.retryCount,
      required this.isSynced,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['retry_count'] = Variable<int>(retryCount);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(payload),
      retryCount: Value(retryCount),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? action,
          String? payload,
          int? retryCount,
          bool? isSynced,
          DateTime? createdAt}) =>
      SyncQueueData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        retryCount: retryCount ?? this.retryCount,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, action, payload,
      retryCount, isSynced, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payload;
  final Value<int> retryCount;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
    this.retryCount = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        action = Value(action),
        payload = Value(payload);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<int>? retryCount,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? action,
      Value<String>? payload,
      Value<int>? retryCount,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CachedUsersTable extends CachedUsers
    with TableInfo<$CachedUsersTable, CachedUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specialityMeta =
      const VerificationMeta('speciality');
  @override
  late final GeneratedColumn<String> speciality = GeneratedColumn<String>(
      'speciality', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _licenseNumberMeta =
      const VerificationMeta('licenseNumber');
  @override
  late final GeneratedColumn<String> licenseNumber = GeneratedColumn<String>(
      'license_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        name,
        email,
        role,
        phone,
        avatarUrl,
        speciality,
        licenseNumber,
        rating,
        address,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_users';
  @override
  VerificationContext validateIntegrity(Insertable<CachedUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('speciality')) {
      context.handle(
          _specialityMeta,
          speciality.isAcceptableOrUnknown(
              data['speciality']!, _specialityMeta));
    }
    if (data.containsKey('license_number')) {
      context.handle(
          _licenseNumberMeta,
          licenseNumber.isAcceptableOrUnknown(
              data['license_number']!, _licenseNumberMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUser(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      speciality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}speciality']),
      licenseNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}license_number']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CachedUsersTable createAlias(String alias) {
    return $CachedUsersTable(attachedDatabase, alias);
  }
}

class CachedUser extends DataClass implements Insertable<CachedUser> {
  final int id;
  final String remoteId;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String? speciality;
  final String? licenseNumber;
  final double? rating;
  final String? address;
  final DateTime updatedAt;
  const CachedUser(
      {required this.id,
      required this.remoteId,
      required this.name,
      required this.email,
      required this.role,
      this.phone,
      this.avatarUrl,
      this.speciality,
      this.licenseNumber,
      this.rating,
      this.address,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || speciality != null) {
      map['speciality'] = Variable<String>(speciality);
    }
    if (!nullToAbsent || licenseNumber != null) {
      map['license_number'] = Variable<String>(licenseNumber);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedUsersCompanion toCompanion(bool nullToAbsent) {
    return CachedUsersCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      name: Value(name),
      email: Value(email),
      role: Value(role),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      speciality: speciality == null && nullToAbsent
          ? const Value.absent()
          : Value(speciality),
      licenseNumber: licenseNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseNumber),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUser(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      role: serializer.fromJson<String>(json['role']),
      phone: serializer.fromJson<String?>(json['phone']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      speciality: serializer.fromJson<String?>(json['speciality']),
      licenseNumber: serializer.fromJson<String?>(json['licenseNumber']),
      rating: serializer.fromJson<double?>(json['rating']),
      address: serializer.fromJson<String?>(json['address']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'role': serializer.toJson<String>(role),
      'phone': serializer.toJson<String?>(phone),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'speciality': serializer.toJson<String?>(speciality),
      'licenseNumber': serializer.toJson<String?>(licenseNumber),
      'rating': serializer.toJson<double?>(rating),
      'address': serializer.toJson<String?>(address),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedUser copyWith(
          {int? id,
          String? remoteId,
          String? name,
          String? email,
          String? role,
          Value<String?> phone = const Value.absent(),
          Value<String?> avatarUrl = const Value.absent(),
          Value<String?> speciality = const Value.absent(),
          Value<String?> licenseNumber = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<String?> address = const Value.absent(),
          DateTime? updatedAt}) =>
      CachedUser(
        id: id ?? this.id,
        remoteId: remoteId ?? this.remoteId,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        phone: phone.present ? phone.value : this.phone,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        speciality: speciality.present ? speciality.value : this.speciality,
        licenseNumber:
            licenseNumber.present ? licenseNumber.value : this.licenseNumber,
        rating: rating.present ? rating.value : this.rating,
        address: address.present ? address.value : this.address,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedUser copyWithCompanion(CachedUsersCompanion data) {
    return CachedUser(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      speciality:
          data.speciality.present ? data.speciality.value : this.speciality,
      licenseNumber: data.licenseNumber.present
          ? data.licenseNumber.value
          : this.licenseNumber,
      rating: data.rating.present ? data.rating.value : this.rating,
      address: data.address.present ? data.address.value : this.address,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUser(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('speciality: $speciality, ')
          ..write('licenseNumber: $licenseNumber, ')
          ..write('rating: $rating, ')
          ..write('address: $address, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, remoteId, name, email, role, phone,
      avatarUrl, speciality, licenseNumber, rating, address, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUser &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.email == this.email &&
          other.role == this.role &&
          other.phone == this.phone &&
          other.avatarUrl == this.avatarUrl &&
          other.speciality == this.speciality &&
          other.licenseNumber == this.licenseNumber &&
          other.rating == this.rating &&
          other.address == this.address &&
          other.updatedAt == this.updatedAt);
}

class CachedUsersCompanion extends UpdateCompanion<CachedUser> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> name;
  final Value<String> email;
  final Value<String> role;
  final Value<String?> phone;
  final Value<String?> avatarUrl;
  final Value<String?> speciality;
  final Value<String?> licenseNumber;
  final Value<double?> rating;
  final Value<String?> address;
  final Value<DateTime> updatedAt;
  const CachedUsersCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.speciality = const Value.absent(),
    this.licenseNumber = const Value.absent(),
    this.rating = const Value.absent(),
    this.address = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CachedUsersCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String name,
    required String email,
    required String role,
    this.phone = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.speciality = const Value.absent(),
    this.licenseNumber = const Value.absent(),
    this.rating = const Value.absent(),
    this.address = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : remoteId = Value(remoteId),
        name = Value(name),
        email = Value(email),
        role = Value(role);
  static Insertable<CachedUser> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<String>? avatarUrl,
    Expression<String>? speciality,
    Expression<String>? licenseNumber,
    Expression<double>? rating,
    Expression<String>? address,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (speciality != null) 'speciality': speciality,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (rating != null) 'rating': rating,
      if (address != null) 'address': address,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CachedUsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? remoteId,
      Value<String>? name,
      Value<String>? email,
      Value<String>? role,
      Value<String?>? phone,
      Value<String?>? avatarUrl,
      Value<String?>? speciality,
      Value<String?>? licenseNumber,
      Value<double?>? rating,
      Value<String?>? address,
      Value<DateTime>? updatedAt}) {
    return CachedUsersCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      speciality: speciality ?? this.speciality,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (speciality.present) {
      map['speciality'] = Variable<String>(speciality.value);
    }
    if (licenseNumber.present) {
      map['license_number'] = Variable<String>(licenseNumber.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUsersCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('speciality: $speciality, ')
          ..write('licenseNumber: $licenseNumber, ')
          ..write('rating: $rating, ')
          ..write('address: $address, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedAppointmentsTable cachedAppointments =
      $CachedAppointmentsTable(this);
  late final $CachedMessagesTable cachedMessages = $CachedMessagesTable(this);
  late final $CachedMedicalRecordsTable cachedMedicalRecords =
      $CachedMedicalRecordsTable(this);
  late final $CachedNotificationsTable cachedNotifications =
      $CachedNotificationsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CachedUsersTable cachedUsers = $CachedUsersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedAppointments,
        cachedMessages,
        cachedMedicalRecords,
        cachedNotifications,
        syncQueue,
        cachedUsers
      ];
}

typedef $$CachedAppointmentsTableCreateCompanionBuilder
    = CachedAppointmentsCompanion Function({
  Value<int> id,
  required String remoteId,
  required String patientId,
  required String doctorId,
  required String doctorName,
  Value<String?> speciality,
  required DateTime appointmentDateTime,
  Value<int> durationMinutes,
  Value<String> status,
  Value<String> type,
  Value<String?> notes,
  Value<String?> location,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CachedAppointmentsTableUpdateCompanionBuilder
    = CachedAppointmentsCompanion Function({
  Value<int> id,
  Value<String> remoteId,
  Value<String> patientId,
  Value<String> doctorId,
  Value<String> doctorName,
  Value<String?> speciality,
  Value<DateTime> appointmentDateTime,
  Value<int> durationMinutes,
  Value<String> status,
  Value<String> type,
  Value<String?> notes,
  Value<String?> location,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CachedAppointmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAppointmentsTable> {
  $$CachedAppointmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doctorId => $composableBuilder(
      column: $table.doctorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get speciality => $composableBuilder(
      column: $table.speciality, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get appointmentDateTime => $composableBuilder(
      column: $table.appointmentDateTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedAppointmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAppointmentsTable> {
  $$CachedAppointmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doctorId => $composableBuilder(
      column: $table.doctorId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get speciality => $composableBuilder(
      column: $table.speciality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get appointmentDateTime => $composableBuilder(
      column: $table.appointmentDateTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedAppointmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAppointmentsTable> {
  $$CachedAppointmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get doctorId =>
      $composableBuilder(column: $table.doctorId, builder: (column) => column);

  GeneratedColumn<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => column);

  GeneratedColumn<String> get speciality => $composableBuilder(
      column: $table.speciality, builder: (column) => column);

  GeneratedColumn<DateTime> get appointmentDateTime => $composableBuilder(
      column: $table.appointmentDateTime, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedAppointmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedAppointmentsTable,
    CachedAppointment,
    $$CachedAppointmentsTableFilterComposer,
    $$CachedAppointmentsTableOrderingComposer,
    $$CachedAppointmentsTableAnnotationComposer,
    $$CachedAppointmentsTableCreateCompanionBuilder,
    $$CachedAppointmentsTableUpdateCompanionBuilder,
    (
      CachedAppointment,
      BaseReferences<_$AppDatabase, $CachedAppointmentsTable, CachedAppointment>
    ),
    CachedAppointment,
    PrefetchHooks Function()> {
  $$CachedAppointmentsTableTableManager(
      _$AppDatabase db, $CachedAppointmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAppointmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAppointmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAppointmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> remoteId = const Value.absent(),
            Value<String> patientId = const Value.absent(),
            Value<String> doctorId = const Value.absent(),
            Value<String> doctorName = const Value.absent(),
            Value<String?> speciality = const Value.absent(),
            Value<DateTime> appointmentDateTime = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CachedAppointmentsCompanion(
            id: id,
            remoteId: remoteId,
            patientId: patientId,
            doctorId: doctorId,
            doctorName: doctorName,
            speciality: speciality,
            appointmentDateTime: appointmentDateTime,
            durationMinutes: durationMinutes,
            status: status,
            type: type,
            notes: notes,
            location: location,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String remoteId,
            required String patientId,
            required String doctorId,
            required String doctorName,
            Value<String?> speciality = const Value.absent(),
            required DateTime appointmentDateTime,
            Value<int> durationMinutes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CachedAppointmentsCompanion.insert(
            id: id,
            remoteId: remoteId,
            patientId: patientId,
            doctorId: doctorId,
            doctorName: doctorName,
            speciality: speciality,
            appointmentDateTime: appointmentDateTime,
            durationMinutes: durationMinutes,
            status: status,
            type: type,
            notes: notes,
            location: location,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedAppointmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedAppointmentsTable,
    CachedAppointment,
    $$CachedAppointmentsTableFilterComposer,
    $$CachedAppointmentsTableOrderingComposer,
    $$CachedAppointmentsTableAnnotationComposer,
    $$CachedAppointmentsTableCreateCompanionBuilder,
    $$CachedAppointmentsTableUpdateCompanionBuilder,
    (
      CachedAppointment,
      BaseReferences<_$AppDatabase, $CachedAppointmentsTable, CachedAppointment>
    ),
    CachedAppointment,
    PrefetchHooks Function()>;
typedef $$CachedMessagesTableCreateCompanionBuilder = CachedMessagesCompanion
    Function({
  Value<int> id,
  Value<String?> remoteId,
  required String conversationId,
  required String senderId,
  required String content,
  Value<String> type,
  Value<String> status,
  Value<String?> attachmentUrl,
  Value<String?> attachmentType,
  Value<bool> isEncrypted,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
});
typedef $$CachedMessagesTableUpdateCompanionBuilder = CachedMessagesCompanion
    Function({
  Value<int> id,
  Value<String?> remoteId,
  Value<String> conversationId,
  Value<String> senderId,
  Value<String> content,
  Value<String> type,
  Value<String> status,
  Value<String?> attachmentUrl,
  Value<String?> attachmentType,
  Value<bool> isEncrypted,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
});

class $$CachedMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachmentUrl => $composableBuilder(
      column: $table.attachmentUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachmentType => $composableBuilder(
      column: $table.attachmentType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CachedMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachmentUrl => $composableBuilder(
      column: $table.attachmentUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachmentType => $composableBuilder(
      column: $table.attachmentType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
      column: $table.conversationId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get attachmentUrl => $composableBuilder(
      column: $table.attachmentUrl, builder: (column) => column);

  GeneratedColumn<String> get attachmentType => $composableBuilder(
      column: $table.attachmentType, builder: (column) => column);

  GeneratedColumn<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedMessagesTable,
    CachedMessage,
    $$CachedMessagesTableFilterComposer,
    $$CachedMessagesTableOrderingComposer,
    $$CachedMessagesTableAnnotationComposer,
    $$CachedMessagesTableCreateCompanionBuilder,
    $$CachedMessagesTableUpdateCompanionBuilder,
    (
      CachedMessage,
      BaseReferences<_$AppDatabase, $CachedMessagesTable, CachedMessage>
    ),
    CachedMessage,
    PrefetchHooks Function()> {
  $$CachedMessagesTableTableManager(
      _$AppDatabase db, $CachedMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<String> conversationId = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> attachmentUrl = const Value.absent(),
            Value<String?> attachmentType = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CachedMessagesCompanion(
            id: id,
            remoteId: remoteId,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            type: type,
            status: status,
            attachmentUrl: attachmentUrl,
            attachmentType: attachmentType,
            isEncrypted: isEncrypted,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            required String conversationId,
            required String senderId,
            required String content,
            Value<String> type = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> attachmentUrl = const Value.absent(),
            Value<String?> attachmentType = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CachedMessagesCompanion.insert(
            id: id,
            remoteId: remoteId,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            type: type,
            status: status,
            attachmentUrl: attachmentUrl,
            attachmentType: attachmentType,
            isEncrypted: isEncrypted,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedMessagesTable,
    CachedMessage,
    $$CachedMessagesTableFilterComposer,
    $$CachedMessagesTableOrderingComposer,
    $$CachedMessagesTableAnnotationComposer,
    $$CachedMessagesTableCreateCompanionBuilder,
    $$CachedMessagesTableUpdateCompanionBuilder,
    (
      CachedMessage,
      BaseReferences<_$AppDatabase, $CachedMessagesTable, CachedMessage>
    ),
    CachedMessage,
    PrefetchHooks Function()>;
typedef $$CachedMedicalRecordsTableCreateCompanionBuilder
    = CachedMedicalRecordsCompanion Function({
  Value<int> id,
  required String remoteId,
  required String patientId,
  required String title,
  required String type,
  required String encryptedData,
  Value<String?> doctorName,
  Value<String?> fileUrl,
  required DateTime recordDate,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CachedMedicalRecordsTableUpdateCompanionBuilder
    = CachedMedicalRecordsCompanion Function({
  Value<int> id,
  Value<String> remoteId,
  Value<String> patientId,
  Value<String> title,
  Value<String> type,
  Value<String> encryptedData,
  Value<String?> doctorName,
  Value<String?> fileUrl,
  Value<DateTime> recordDate,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CachedMedicalRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMedicalRecordsTable> {
  $$CachedMedicalRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptedData => $composableBuilder(
      column: $table.encryptedData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileUrl => $composableBuilder(
      column: $table.fileUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedMedicalRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMedicalRecordsTable> {
  $$CachedMedicalRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptedData => $composableBuilder(
      column: $table.encryptedData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileUrl => $composableBuilder(
      column: $table.fileUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedMedicalRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMedicalRecordsTable> {
  $$CachedMedicalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get encryptedData => $composableBuilder(
      column: $table.encryptedData, builder: (column) => column);

  GeneratedColumn<String> get doctorName => $composableBuilder(
      column: $table.doctorName, builder: (column) => column);

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMedicalRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedMedicalRecordsTable,
    CachedMedicalRecord,
    $$CachedMedicalRecordsTableFilterComposer,
    $$CachedMedicalRecordsTableOrderingComposer,
    $$CachedMedicalRecordsTableAnnotationComposer,
    $$CachedMedicalRecordsTableCreateCompanionBuilder,
    $$CachedMedicalRecordsTableUpdateCompanionBuilder,
    (
      CachedMedicalRecord,
      BaseReferences<_$AppDatabase, $CachedMedicalRecordsTable,
          CachedMedicalRecord>
    ),
    CachedMedicalRecord,
    PrefetchHooks Function()> {
  $$CachedMedicalRecordsTableTableManager(
      _$AppDatabase db, $CachedMedicalRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMedicalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMedicalRecordsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMedicalRecordsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> remoteId = const Value.absent(),
            Value<String> patientId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> encryptedData = const Value.absent(),
            Value<String?> doctorName = const Value.absent(),
            Value<String?> fileUrl = const Value.absent(),
            Value<DateTime> recordDate = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CachedMedicalRecordsCompanion(
            id: id,
            remoteId: remoteId,
            patientId: patientId,
            title: title,
            type: type,
            encryptedData: encryptedData,
            doctorName: doctorName,
            fileUrl: fileUrl,
            recordDate: recordDate,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String remoteId,
            required String patientId,
            required String title,
            required String type,
            required String encryptedData,
            Value<String?> doctorName = const Value.absent(),
            Value<String?> fileUrl = const Value.absent(),
            required DateTime recordDate,
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CachedMedicalRecordsCompanion.insert(
            id: id,
            remoteId: remoteId,
            patientId: patientId,
            title: title,
            type: type,
            encryptedData: encryptedData,
            doctorName: doctorName,
            fileUrl: fileUrl,
            recordDate: recordDate,
            isSynced: isSynced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedMedicalRecordsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CachedMedicalRecordsTable,
        CachedMedicalRecord,
        $$CachedMedicalRecordsTableFilterComposer,
        $$CachedMedicalRecordsTableOrderingComposer,
        $$CachedMedicalRecordsTableAnnotationComposer,
        $$CachedMedicalRecordsTableCreateCompanionBuilder,
        $$CachedMedicalRecordsTableUpdateCompanionBuilder,
        (
          CachedMedicalRecord,
          BaseReferences<_$AppDatabase, $CachedMedicalRecordsTable,
              CachedMedicalRecord>
        ),
        CachedMedicalRecord,
        PrefetchHooks Function()>;
typedef $$CachedNotificationsTableCreateCompanionBuilder
    = CachedNotificationsCompanion Function({
  Value<int> id,
  Value<String?> remoteId,
  required String type,
  required String title,
  required String body,
  Value<String?> data,
  Value<bool> isRead,
  Value<DateTime> createdAt,
});
typedef $$CachedNotificationsTableUpdateCompanionBuilder
    = CachedNotificationsCompanion Function({
  Value<int> id,
  Value<String?> remoteId,
  Value<String> type,
  Value<String> title,
  Value<String> body,
  Value<String?> data,
  Value<bool> isRead,
  Value<DateTime> createdAt,
});

class $$CachedNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CachedNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedNotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedNotificationsTable,
    CachedNotification,
    $$CachedNotificationsTableFilterComposer,
    $$CachedNotificationsTableOrderingComposer,
    $$CachedNotificationsTableAnnotationComposer,
    $$CachedNotificationsTableCreateCompanionBuilder,
    $$CachedNotificationsTableUpdateCompanionBuilder,
    (
      CachedNotification,
      BaseReferences<_$AppDatabase, $CachedNotificationsTable,
          CachedNotification>
    ),
    CachedNotification,
    PrefetchHooks Function()> {
  $$CachedNotificationsTableTableManager(
      _$AppDatabase db, $CachedNotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNotificationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedNotificationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> data = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CachedNotificationsCompanion(
            id: id,
            remoteId: remoteId,
            type: type,
            title: title,
            body: body,
            data: data,
            isRead: isRead,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            required String type,
            required String title,
            required String body,
            Value<String?> data = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CachedNotificationsCompanion.insert(
            id: id,
            remoteId: remoteId,
            type: type,
            title: title,
            body: body,
            data: data,
            isRead: isRead,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedNotificationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedNotificationsTable,
    CachedNotification,
    $$CachedNotificationsTableFilterComposer,
    $$CachedNotificationsTableOrderingComposer,
    $$CachedNotificationsTableAnnotationComposer,
    $$CachedNotificationsTableCreateCompanionBuilder,
    $$CachedNotificationsTableUpdateCompanionBuilder,
    (
      CachedNotification,
      BaseReferences<_$AppDatabase, $CachedNotificationsTable,
          CachedNotification>
    ),
    CachedNotification,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String action,
  required String payload,
  Value<int> retryCount,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> action,
  Value<String> payload,
  Value<int> retryCount,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            retryCount: retryCount,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String action,
            required String payload,
            Value<int> retryCount = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            retryCount: retryCount,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$CachedUsersTableCreateCompanionBuilder = CachedUsersCompanion
    Function({
  Value<int> id,
  required String remoteId,
  required String name,
  required String email,
  required String role,
  Value<String?> phone,
  Value<String?> avatarUrl,
  Value<String?> speciality,
  Value<String?> licenseNumber,
  Value<double?> rating,
  Value<String?> address,
  Value<DateTime> updatedAt,
});
typedef $$CachedUsersTableUpdateCompanionBuilder = CachedUsersCompanion
    Function({
  Value<int> id,
  Value<String> remoteId,
  Value<String> name,
  Value<String> email,
  Value<String> role,
  Value<String?> phone,
  Value<String?> avatarUrl,
  Value<String?> speciality,
  Value<String?> licenseNumber,
  Value<double?> rating,
  Value<String?> address,
  Value<DateTime> updatedAt,
});

class $$CachedUsersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get speciality => $composableBuilder(
      column: $table.speciality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get licenseNumber => $composableBuilder(
      column: $table.licenseNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get speciality => $composableBuilder(
      column: $table.speciality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get licenseNumber => $composableBuilder(
      column: $table.licenseNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get speciality => $composableBuilder(
      column: $table.speciality, builder: (column) => column);

  GeneratedColumn<String> get licenseNumber => $composableBuilder(
      column: $table.licenseNumber, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedUsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedUsersTable,
    CachedUser,
    $$CachedUsersTableFilterComposer,
    $$CachedUsersTableOrderingComposer,
    $$CachedUsersTableAnnotationComposer,
    $$CachedUsersTableCreateCompanionBuilder,
    $$CachedUsersTableUpdateCompanionBuilder,
    (CachedUser, BaseReferences<_$AppDatabase, $CachedUsersTable, CachedUser>),
    CachedUser,
    PrefetchHooks Function()> {
  $$CachedUsersTableTableManager(_$AppDatabase db, $CachedUsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> remoteId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> speciality = const Value.absent(),
            Value<String?> licenseNumber = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CachedUsersCompanion(
            id: id,
            remoteId: remoteId,
            name: name,
            email: email,
            role: role,
            phone: phone,
            avatarUrl: avatarUrl,
            speciality: speciality,
            licenseNumber: licenseNumber,
            rating: rating,
            address: address,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String remoteId,
            required String name,
            required String email,
            required String role,
            Value<String?> phone = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<String?> speciality = const Value.absent(),
            Value<String?> licenseNumber = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CachedUsersCompanion.insert(
            id: id,
            remoteId: remoteId,
            name: name,
            email: email,
            role: role,
            phone: phone,
            avatarUrl: avatarUrl,
            speciality: speciality,
            licenseNumber: licenseNumber,
            rating: rating,
            address: address,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedUsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedUsersTable,
    CachedUser,
    $$CachedUsersTableFilterComposer,
    $$CachedUsersTableOrderingComposer,
    $$CachedUsersTableAnnotationComposer,
    $$CachedUsersTableCreateCompanionBuilder,
    $$CachedUsersTableUpdateCompanionBuilder,
    (CachedUser, BaseReferences<_$AppDatabase, $CachedUsersTable, CachedUser>),
    CachedUser,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedAppointmentsTableTableManager get cachedAppointments =>
      $$CachedAppointmentsTableTableManager(_db, _db.cachedAppointments);
  $$CachedMessagesTableTableManager get cachedMessages =>
      $$CachedMessagesTableTableManager(_db, _db.cachedMessages);
  $$CachedMedicalRecordsTableTableManager get cachedMedicalRecords =>
      $$CachedMedicalRecordsTableTableManager(_db, _db.cachedMedicalRecords);
  $$CachedNotificationsTableTableManager get cachedNotifications =>
      $$CachedNotificationsTableTableManager(_db, _db.cachedNotifications);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CachedUsersTableTableManager get cachedUsers =>
      $$CachedUsersTableTableManager(_db, _db.cachedUsers);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'7aae63de4f12449b78b46ad95a8e69b18b15328d';

/// Provider for the encrypted database
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = AutoDisposeFutureProvider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = AutoDisposeFutureProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
