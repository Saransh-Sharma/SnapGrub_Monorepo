// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesLocalTable extends ProfilesLocal
    with TableInfo<$ProfilesLocalTable, ProfilesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('en-US'));
  static const VerificationMeta _timezoneMeta =
      const VerificationMeta('timezone');
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
      'timezone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitSystemMeta =
      const VerificationMeta('unitSystem');
  @override
  late final GeneratedColumn<String> unitSystem = GeneratedColumn<String>(
      'unit_system', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('metric'));
  static const VerificationMeta _countryCodeMeta =
      const VerificationMeta('countryCode');
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
      'country_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cuisinePreferencesJsonMeta =
      const VerificationMeta('cuisinePreferencesJson');
  @override
  late final GeneratedColumn<String> cuisinePreferencesJson =
      GeneratedColumn<String>('cuisine_preferences_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _cloudMediaStorageMeta =
      const VerificationMeta('cloudMediaStorage');
  @override
  late final GeneratedColumn<bool> cloudMediaStorage = GeneratedColumn<bool>(
      'cloud_media_storage', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("cloud_media_storage" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _saveOriginalPhotosMeta =
      const VerificationMeta('saveOriginalPhotos');
  @override
  late final GeneratedColumn<bool> saveOriginalPhotos = GeneratedColumn<bool>(
      'save_original_photos', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("save_original_photos" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _aiImprovementConsentMeta =
      const VerificationMeta('aiImprovementConsent');
  @override
  late final GeneratedColumn<bool> aiImprovementConsent = GeneratedColumn<bool>(
      'ai_improvement_consent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("ai_improvement_consent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _onboardingCompletedAtMeta =
      const VerificationMeta('onboardingCompletedAt');
  @override
  late final GeneratedColumn<DateTime> onboardingCompletedAt =
      GeneratedColumn<DateTime>('onboarding_completed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
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
        displayName,
        locale,
        timezone,
        unitSystem,
        countryCode,
        cuisinePreferencesJson,
        cloudMediaStorage,
        saveOriginalPhotos,
        aiImprovementConsent,
        onboardingCompletedAt,
        syncStatus,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles_local';
  @override
  VerificationContext validateIntegrity(Insertable<ProfilesLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    }
    if (data.containsKey('timezone')) {
      context.handle(_timezoneMeta,
          timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta));
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('unit_system')) {
      context.handle(
          _unitSystemMeta,
          unitSystem.isAcceptableOrUnknown(
              data['unit_system']!, _unitSystemMeta));
    }
    if (data.containsKey('country_code')) {
      context.handle(
          _countryCodeMeta,
          countryCode.isAcceptableOrUnknown(
              data['country_code']!, _countryCodeMeta));
    }
    if (data.containsKey('cuisine_preferences_json')) {
      context.handle(
          _cuisinePreferencesJsonMeta,
          cuisinePreferencesJson.isAcceptableOrUnknown(
              data['cuisine_preferences_json']!, _cuisinePreferencesJsonMeta));
    }
    if (data.containsKey('cloud_media_storage')) {
      context.handle(
          _cloudMediaStorageMeta,
          cloudMediaStorage.isAcceptableOrUnknown(
              data['cloud_media_storage']!, _cloudMediaStorageMeta));
    }
    if (data.containsKey('save_original_photos')) {
      context.handle(
          _saveOriginalPhotosMeta,
          saveOriginalPhotos.isAcceptableOrUnknown(
              data['save_original_photos']!, _saveOriginalPhotosMeta));
    }
    if (data.containsKey('ai_improvement_consent')) {
      context.handle(
          _aiImprovementConsentMeta,
          aiImprovementConsent.isAcceptableOrUnknown(
              data['ai_improvement_consent']!, _aiImprovementConsentMeta));
    }
    if (data.containsKey('onboarding_completed_at')) {
      context.handle(
          _onboardingCompletedAtMeta,
          onboardingCompletedAt.isAcceptableOrUnknown(
              data['onboarding_completed_at']!, _onboardingCompletedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
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
  ProfilesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfilesLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
      timezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timezone'])!,
      unitSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_system'])!,
      countryCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country_code']),
      cuisinePreferencesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cuisine_preferences_json'])!,
      cloudMediaStorage: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}cloud_media_storage'])!,
      saveOriginalPhotos: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}save_original_photos'])!,
      aiImprovementConsent: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}ai_improvement_consent'])!,
      onboardingCompletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}onboarding_completed_at']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProfilesLocalTable createAlias(String alias) {
    return $ProfilesLocalTable(attachedDatabase, alias);
  }
}

class ProfilesLocalData extends DataClass
    implements Insertable<ProfilesLocalData> {
  final String id;
  final String? displayName;
  final String locale;
  final String timezone;
  final String unitSystem;
  final String? countryCode;
  final String cuisinePreferencesJson;
  final bool cloudMediaStorage;
  final bool saveOriginalPhotos;
  final bool aiImprovementConsent;
  final DateTime? onboardingCompletedAt;
  final String syncStatus;
  final DateTime updatedAt;
  const ProfilesLocalData(
      {required this.id,
      this.displayName,
      required this.locale,
      required this.timezone,
      required this.unitSystem,
      this.countryCode,
      required this.cuisinePreferencesJson,
      required this.cloudMediaStorage,
      required this.saveOriginalPhotos,
      required this.aiImprovementConsent,
      this.onboardingCompletedAt,
      required this.syncStatus,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['locale'] = Variable<String>(locale);
    map['timezone'] = Variable<String>(timezone);
    map['unit_system'] = Variable<String>(unitSystem);
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    map['cuisine_preferences_json'] = Variable<String>(cuisinePreferencesJson);
    map['cloud_media_storage'] = Variable<bool>(cloudMediaStorage);
    map['save_original_photos'] = Variable<bool>(saveOriginalPhotos);
    map['ai_improvement_consent'] = Variable<bool>(aiImprovementConsent);
    if (!nullToAbsent || onboardingCompletedAt != null) {
      map['onboarding_completed_at'] =
          Variable<DateTime>(onboardingCompletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesLocalCompanion toCompanion(bool nullToAbsent) {
    return ProfilesLocalCompanion(
      id: Value(id),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      locale: Value(locale),
      timezone: Value(timezone),
      unitSystem: Value(unitSystem),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      cuisinePreferencesJson: Value(cuisinePreferencesJson),
      cloudMediaStorage: Value(cloudMediaStorage),
      saveOriginalPhotos: Value(saveOriginalPhotos),
      aiImprovementConsent: Value(aiImprovementConsent),
      onboardingCompletedAt: onboardingCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingCompletedAt),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfilesLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfilesLocalData(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      locale: serializer.fromJson<String>(json['locale']),
      timezone: serializer.fromJson<String>(json['timezone']),
      unitSystem: serializer.fromJson<String>(json['unitSystem']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      cuisinePreferencesJson:
          serializer.fromJson<String>(json['cuisinePreferencesJson']),
      cloudMediaStorage: serializer.fromJson<bool>(json['cloudMediaStorage']),
      saveOriginalPhotos: serializer.fromJson<bool>(json['saveOriginalPhotos']),
      aiImprovementConsent:
          serializer.fromJson<bool>(json['aiImprovementConsent']),
      onboardingCompletedAt:
          serializer.fromJson<DateTime?>(json['onboardingCompletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String?>(displayName),
      'locale': serializer.toJson<String>(locale),
      'timezone': serializer.toJson<String>(timezone),
      'unitSystem': serializer.toJson<String>(unitSystem),
      'countryCode': serializer.toJson<String?>(countryCode),
      'cuisinePreferencesJson':
          serializer.toJson<String>(cuisinePreferencesJson),
      'cloudMediaStorage': serializer.toJson<bool>(cloudMediaStorage),
      'saveOriginalPhotos': serializer.toJson<bool>(saveOriginalPhotos),
      'aiImprovementConsent': serializer.toJson<bool>(aiImprovementConsent),
      'onboardingCompletedAt':
          serializer.toJson<DateTime?>(onboardingCompletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfilesLocalData copyWith(
          {String? id,
          Value<String?> displayName = const Value.absent(),
          String? locale,
          String? timezone,
          String? unitSystem,
          Value<String?> countryCode = const Value.absent(),
          String? cuisinePreferencesJson,
          bool? cloudMediaStorage,
          bool? saveOriginalPhotos,
          bool? aiImprovementConsent,
          Value<DateTime?> onboardingCompletedAt = const Value.absent(),
          String? syncStatus,
          DateTime? updatedAt}) =>
      ProfilesLocalData(
        id: id ?? this.id,
        displayName: displayName.present ? displayName.value : this.displayName,
        locale: locale ?? this.locale,
        timezone: timezone ?? this.timezone,
        unitSystem: unitSystem ?? this.unitSystem,
        countryCode: countryCode.present ? countryCode.value : this.countryCode,
        cuisinePreferencesJson:
            cuisinePreferencesJson ?? this.cuisinePreferencesJson,
        cloudMediaStorage: cloudMediaStorage ?? this.cloudMediaStorage,
        saveOriginalPhotos: saveOriginalPhotos ?? this.saveOriginalPhotos,
        aiImprovementConsent: aiImprovementConsent ?? this.aiImprovementConsent,
        onboardingCompletedAt: onboardingCompletedAt.present
            ? onboardingCompletedAt.value
            : this.onboardingCompletedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProfilesLocalData copyWithCompanion(ProfilesLocalCompanion data) {
    return ProfilesLocalData(
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      locale: data.locale.present ? data.locale.value : this.locale,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      unitSystem:
          data.unitSystem.present ? data.unitSystem.value : this.unitSystem,
      countryCode:
          data.countryCode.present ? data.countryCode.value : this.countryCode,
      cuisinePreferencesJson: data.cuisinePreferencesJson.present
          ? data.cuisinePreferencesJson.value
          : this.cuisinePreferencesJson,
      cloudMediaStorage: data.cloudMediaStorage.present
          ? data.cloudMediaStorage.value
          : this.cloudMediaStorage,
      saveOriginalPhotos: data.saveOriginalPhotos.present
          ? data.saveOriginalPhotos.value
          : this.saveOriginalPhotos,
      aiImprovementConsent: data.aiImprovementConsent.present
          ? data.aiImprovementConsent.value
          : this.aiImprovementConsent,
      onboardingCompletedAt: data.onboardingCompletedAt.present
          ? data.onboardingCompletedAt.value
          : this.onboardingCompletedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesLocalData(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('locale: $locale, ')
          ..write('timezone: $timezone, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('countryCode: $countryCode, ')
          ..write('cuisinePreferencesJson: $cuisinePreferencesJson, ')
          ..write('cloudMediaStorage: $cloudMediaStorage, ')
          ..write('saveOriginalPhotos: $saveOriginalPhotos, ')
          ..write('aiImprovementConsent: $aiImprovementConsent, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      displayName,
      locale,
      timezone,
      unitSystem,
      countryCode,
      cuisinePreferencesJson,
      cloudMediaStorage,
      saveOriginalPhotos,
      aiImprovementConsent,
      onboardingCompletedAt,
      syncStatus,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfilesLocalData &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.locale == this.locale &&
          other.timezone == this.timezone &&
          other.unitSystem == this.unitSystem &&
          other.countryCode == this.countryCode &&
          other.cuisinePreferencesJson == this.cuisinePreferencesJson &&
          other.cloudMediaStorage == this.cloudMediaStorage &&
          other.saveOriginalPhotos == this.saveOriginalPhotos &&
          other.aiImprovementConsent == this.aiImprovementConsent &&
          other.onboardingCompletedAt == this.onboardingCompletedAt &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class ProfilesLocalCompanion extends UpdateCompanion<ProfilesLocalData> {
  final Value<String> id;
  final Value<String?> displayName;
  final Value<String> locale;
  final Value<String> timezone;
  final Value<String> unitSystem;
  final Value<String?> countryCode;
  final Value<String> cuisinePreferencesJson;
  final Value<bool> cloudMediaStorage;
  final Value<bool> saveOriginalPhotos;
  final Value<bool> aiImprovementConsent;
  final Value<DateTime?> onboardingCompletedAt;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfilesLocalCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.locale = const Value.absent(),
    this.timezone = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.cuisinePreferencesJson = const Value.absent(),
    this.cloudMediaStorage = const Value.absent(),
    this.saveOriginalPhotos = const Value.absent(),
    this.aiImprovementConsent = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesLocalCompanion.insert({
    required String id,
    this.displayName = const Value.absent(),
    this.locale = const Value.absent(),
    required String timezone,
    this.unitSystem = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.cuisinePreferencesJson = const Value.absent(),
    this.cloudMediaStorage = const Value.absent(),
    this.saveOriginalPhotos = const Value.absent(),
    this.aiImprovementConsent = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        timezone = Value(timezone);
  static Insertable<ProfilesLocalData> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? locale,
    Expression<String>? timezone,
    Expression<String>? unitSystem,
    Expression<String>? countryCode,
    Expression<String>? cuisinePreferencesJson,
    Expression<bool>? cloudMediaStorage,
    Expression<bool>? saveOriginalPhotos,
    Expression<bool>? aiImprovementConsent,
    Expression<DateTime>? onboardingCompletedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (locale != null) 'locale': locale,
      if (timezone != null) 'timezone': timezone,
      if (unitSystem != null) 'unit_system': unitSystem,
      if (countryCode != null) 'country_code': countryCode,
      if (cuisinePreferencesJson != null)
        'cuisine_preferences_json': cuisinePreferencesJson,
      if (cloudMediaStorage != null) 'cloud_media_storage': cloudMediaStorage,
      if (saveOriginalPhotos != null)
        'save_original_photos': saveOriginalPhotos,
      if (aiImprovementConsent != null)
        'ai_improvement_consent': aiImprovementConsent,
      if (onboardingCompletedAt != null)
        'onboarding_completed_at': onboardingCompletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesLocalCompanion copyWith(
      {Value<String>? id,
      Value<String?>? displayName,
      Value<String>? locale,
      Value<String>? timezone,
      Value<String>? unitSystem,
      Value<String?>? countryCode,
      Value<String>? cuisinePreferencesJson,
      Value<bool>? cloudMediaStorage,
      Value<bool>? saveOriginalPhotos,
      Value<bool>? aiImprovementConsent,
      Value<DateTime?>? onboardingCompletedAt,
      Value<String>? syncStatus,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProfilesLocalCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      unitSystem: unitSystem ?? this.unitSystem,
      countryCode: countryCode ?? this.countryCode,
      cuisinePreferencesJson:
          cuisinePreferencesJson ?? this.cuisinePreferencesJson,
      cloudMediaStorage: cloudMediaStorage ?? this.cloudMediaStorage,
      saveOriginalPhotos: saveOriginalPhotos ?? this.saveOriginalPhotos,
      aiImprovementConsent: aiImprovementConsent ?? this.aiImprovementConsent,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (unitSystem.present) {
      map['unit_system'] = Variable<String>(unitSystem.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (cuisinePreferencesJson.present) {
      map['cuisine_preferences_json'] =
          Variable<String>(cuisinePreferencesJson.value);
    }
    if (cloudMediaStorage.present) {
      map['cloud_media_storage'] = Variable<bool>(cloudMediaStorage.value);
    }
    if (saveOriginalPhotos.present) {
      map['save_original_photos'] = Variable<bool>(saveOriginalPhotos.value);
    }
    if (aiImprovementConsent.present) {
      map['ai_improvement_consent'] =
          Variable<bool>(aiImprovementConsent.value);
    }
    if (onboardingCompletedAt.present) {
      map['onboarding_completed_at'] =
          Variable<DateTime>(onboardingCompletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesLocalCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('locale: $locale, ')
          ..write('timezone: $timezone, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('countryCode: $countryCode, ')
          ..write('cuisinePreferencesJson: $cuisinePreferencesJson, ')
          ..write('cloudMediaStorage: $cloudMediaStorage, ')
          ..write('saveOriginalPhotos: $saveOriginalPhotos, ')
          ..write('aiImprovementConsent: $aiImprovementConsent, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NutritionGoalsLocalTable extends NutritionGoalsLocal
    with TableInfo<$NutritionGoalsLocalTable, NutritionGoalsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionGoalsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _goalTypeMeta =
      const VerificationMeta('goalType');
  @override
  late final GeneratedColumn<String> goalType = GeneratedColumn<String>(
      'goal_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caloriesKcalMeta =
      const VerificationMeta('caloriesKcal');
  @override
  late final GeneratedColumn<double> caloriesKcal = GeneratedColumn<double>(
      'calories_kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
      'fiber_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _startsOnMeta =
      const VerificationMeta('startsOn');
  @override
  late final GeneratedColumn<DateTime> startsOn = GeneratedColumn<DateTime>(
      'starts_on', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<DateTime> endsOn = GeneratedColumn<DateTime>(
      'ends_on', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
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
        userId,
        goalType,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        fiberG,
        startsOn,
        endsOn,
        isActive,
        syncStatus,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_goals_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<NutritionGoalsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('goal_type')) {
      context.handle(_goalTypeMeta,
          goalType.isAcceptableOrUnknown(data['goal_type']!, _goalTypeMeta));
    } else if (isInserting) {
      context.missing(_goalTypeMeta);
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
          _caloriesKcalMeta,
          caloriesKcal.isAcceptableOrUnknown(
              data['calories_kcal']!, _caloriesKcalMeta));
    } else if (isInserting) {
      context.missing(_caloriesKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('fiber_g')) {
      context.handle(_fiberGMeta,
          fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta));
    }
    if (data.containsKey('starts_on')) {
      context.handle(_startsOnMeta,
          startsOn.isAcceptableOrUnknown(data['starts_on']!, _startsOnMeta));
    } else if (isInserting) {
      context.missing(_startsOnMeta);
    }
    if (data.containsKey('ends_on')) {
      context.handle(_endsOnMeta,
          endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
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
  NutritionGoalsLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionGoalsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      goalType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_type'])!,
      caloriesKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calories_kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      fiberG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fiber_g']),
      startsOn: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}starts_on'])!,
      endsOn: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ends_on']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NutritionGoalsLocalTable createAlias(String alias) {
    return $NutritionGoalsLocalTable(attachedDatabase, alias);
  }
}

class NutritionGoalsLocalData extends DataClass
    implements Insertable<NutritionGoalsLocalData> {
  final String id;
  final String userId;
  final String goalType;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final DateTime startsOn;
  final DateTime? endsOn;
  final bool isActive;
  final String syncStatus;
  final DateTime updatedAt;
  const NutritionGoalsLocalData(
      {required this.id,
      required this.userId,
      required this.goalType,
      required this.caloriesKcal,
      required this.proteinG,
      required this.carbsG,
      required this.fatG,
      this.fiberG,
      required this.startsOn,
      this.endsOn,
      required this.isActive,
      required this.syncStatus,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['goal_type'] = Variable<String>(goalType);
    map['calories_kcal'] = Variable<double>(caloriesKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || fiberG != null) {
      map['fiber_g'] = Variable<double>(fiberG);
    }
    map['starts_on'] = Variable<DateTime>(startsOn);
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<DateTime>(endsOn);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NutritionGoalsLocalCompanion toCompanion(bool nullToAbsent) {
    return NutritionGoalsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      goalType: Value(goalType),
      caloriesKcal: Value(caloriesKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      fiberG:
          fiberG == null && nullToAbsent ? const Value.absent() : Value(fiberG),
      startsOn: Value(startsOn),
      endsOn:
          endsOn == null && nullToAbsent ? const Value.absent() : Value(endsOn),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory NutritionGoalsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionGoalsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      goalType: serializer.fromJson<String>(json['goalType']),
      caloriesKcal: serializer.fromJson<double>(json['caloriesKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      fiberG: serializer.fromJson<double?>(json['fiberG']),
      startsOn: serializer.fromJson<DateTime>(json['startsOn']),
      endsOn: serializer.fromJson<DateTime?>(json['endsOn']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'goalType': serializer.toJson<String>(goalType),
      'caloriesKcal': serializer.toJson<double>(caloriesKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'fiberG': serializer.toJson<double?>(fiberG),
      'startsOn': serializer.toJson<DateTime>(startsOn),
      'endsOn': serializer.toJson<DateTime?>(endsOn),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NutritionGoalsLocalData copyWith(
          {String? id,
          String? userId,
          String? goalType,
          double? caloriesKcal,
          double? proteinG,
          double? carbsG,
          double? fatG,
          Value<double?> fiberG = const Value.absent(),
          DateTime? startsOn,
          Value<DateTime?> endsOn = const Value.absent(),
          bool? isActive,
          String? syncStatus,
          DateTime? updatedAt}) =>
      NutritionGoalsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        goalType: goalType ?? this.goalType,
        caloriesKcal: caloriesKcal ?? this.caloriesKcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        fiberG: fiberG.present ? fiberG.value : this.fiberG,
        startsOn: startsOn ?? this.startsOn,
        endsOn: endsOn.present ? endsOn.value : this.endsOn,
        isActive: isActive ?? this.isActive,
        syncStatus: syncStatus ?? this.syncStatus,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  NutritionGoalsLocalData copyWithCompanion(NutritionGoalsLocalCompanion data) {
    return NutritionGoalsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      startsOn: data.startsOn.present ? data.startsOn.value : this.startsOn,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionGoalsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('goalType: $goalType, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, goalType, caloriesKcal, proteinG,
      carbsG, fatG, fiberG, startsOn, endsOn, isActive, syncStatus, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionGoalsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.goalType == this.goalType &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.fiberG == this.fiberG &&
          other.startsOn == this.startsOn &&
          other.endsOn == this.endsOn &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class NutritionGoalsLocalCompanion
    extends UpdateCompanion<NutritionGoalsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> goalType;
  final Value<double> caloriesKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<double?> fiberG;
  final Value<DateTime> startsOn;
  final Value<DateTime?> endsOn;
  final Value<bool> isActive;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NutritionGoalsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.goalType = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NutritionGoalsLocalCompanion.insert({
    required String id,
    required String userId,
    required String goalType,
    required double caloriesKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.fiberG = const Value.absent(),
    required DateTime startsOn,
    this.endsOn = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        goalType = Value(goalType),
        caloriesKcal = Value(caloriesKcal),
        proteinG = Value(proteinG),
        carbsG = Value(carbsG),
        fatG = Value(fatG),
        startsOn = Value(startsOn);
  static Insertable<NutritionGoalsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? goalType,
    Expression<double>? caloriesKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<double>? fiberG,
    Expression<DateTime>? startsOn,
    Expression<DateTime>? endsOn,
    Expression<bool>? isActive,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (goalType != null) 'goal_type': goalType,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (startsOn != null) 'starts_on': startsOn,
      if (endsOn != null) 'ends_on': endsOn,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NutritionGoalsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? goalType,
      Value<double>? caloriesKcal,
      Value<double>? proteinG,
      Value<double>? carbsG,
      Value<double>? fatG,
      Value<double?>? fiberG,
      Value<DateTime>? startsOn,
      Value<DateTime?>? endsOn,
      Value<bool>? isActive,
      Value<String>? syncStatus,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return NutritionGoalsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(goalType.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<double>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (startsOn.present) {
      map['starts_on'] = Variable<DateTime>(startsOn.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<DateTime>(endsOn.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionGoalsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('goalType: $goalType, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsLocalTable extends BodyMeasurementsLocal
    with TableInfo<$BodyMeasurementsLocalTable, BodyMeasurementsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _measuredAtMeta =
      const VerificationMeta('measuredAt');
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
      'measured_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bodyFatPctMeta =
      const VerificationMeta('bodyFatPct');
  @override
  late final GeneratedColumn<double> bodyFatPct = GeneratedColumn<double>(
      'body_fat_pct', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
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
        userId,
        measuredAt,
        weightKg,
        bodyFatPct,
        source,
        syncStatus,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<BodyMeasurementsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
          _measuredAtMeta,
          measuredAt.isAcceptableOrUnknown(
              data['measured_at']!, _measuredAtMeta));
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    }
    if (data.containsKey('body_fat_pct')) {
      context.handle(
          _bodyFatPctMeta,
          bodyFatPct.isAcceptableOrUnknown(
              data['body_fat_pct']!, _bodyFatPctMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
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
  BodyMeasurementsLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurementsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      measuredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}measured_at'])!,
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg']),
      bodyFatPct: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}body_fat_pct']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BodyMeasurementsLocalTable createAlias(String alias) {
    return $BodyMeasurementsLocalTable(attachedDatabase, alias);
  }
}

class BodyMeasurementsLocalData extends DataClass
    implements Insertable<BodyMeasurementsLocalData> {
  final String id;
  final String userId;
  final DateTime measuredAt;
  final double? weightKg;
  final double? bodyFatPct;
  final String source;
  final String syncStatus;
  final DateTime updatedAt;
  const BodyMeasurementsLocalData(
      {required this.id,
      required this.userId,
      required this.measuredAt,
      this.weightKg,
      this.bodyFatPct,
      required this.source,
      required this.syncStatus,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || bodyFatPct != null) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct);
    }
    map['source'] = Variable<String>(source);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BodyMeasurementsLocalCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      measuredAt: Value(measuredAt),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      bodyFatPct: bodyFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPct),
      source: Value(source),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory BodyMeasurementsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurementsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      bodyFatPct: serializer.fromJson<double?>(json['bodyFatPct']),
      source: serializer.fromJson<String>(json['source']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'weightKg': serializer.toJson<double?>(weightKg),
      'bodyFatPct': serializer.toJson<double?>(bodyFatPct),
      'source': serializer.toJson<String>(source),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BodyMeasurementsLocalData copyWith(
          {String? id,
          String? userId,
          DateTime? measuredAt,
          Value<double?> weightKg = const Value.absent(),
          Value<double?> bodyFatPct = const Value.absent(),
          String? source,
          String? syncStatus,
          DateTime? updatedAt}) =>
      BodyMeasurementsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        measuredAt: measuredAt ?? this.measuredAt,
        weightKg: weightKg.present ? weightKg.value : this.weightKg,
        bodyFatPct: bodyFatPct.present ? bodyFatPct.value : this.bodyFatPct,
        source: source ?? this.source,
        syncStatus: syncStatus ?? this.syncStatus,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BodyMeasurementsLocalData copyWithCompanion(
      BodyMeasurementsLocalCompanion data) {
    return BodyMeasurementsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      measuredAt:
          data.measuredAt.present ? data.measuredAt.value : this.measuredAt,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      bodyFatPct:
          data.bodyFatPct.present ? data.bodyFatPct.value : this.bodyFatPct,
      source: data.source.present ? data.source.value : this.source,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('source: $source, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, measuredAt, weightKg, bodyFatPct,
      source, syncStatus, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurementsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.measuredAt == this.measuredAt &&
          other.weightKg == this.weightKg &&
          other.bodyFatPct == this.bodyFatPct &&
          other.source == this.source &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class BodyMeasurementsLocalCompanion
    extends UpdateCompanion<BodyMeasurementsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> measuredAt;
  final Value<double?> weightKg;
  final Value<double?> bodyFatPct;
  final Value<String> source;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BodyMeasurementsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.source = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyMeasurementsLocalCompanion.insert({
    required String id,
    required String userId,
    required DateTime measuredAt,
    this.weightKg = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.source = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        measuredAt = Value(measuredAt);
  static Insertable<BodyMeasurementsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? measuredAt,
    Expression<double>? weightKg,
    Expression<double>? bodyFatPct,
    Expression<String>? source,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
      if (source != null) 'source': source,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyMeasurementsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? measuredAt,
      Value<double?>? weightKg,
      Value<double?>? bodyFatPct,
      Value<String>? source,
      Value<String>? syncStatus,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BodyMeasurementsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      source: source ?? this.source,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (bodyFatPct.present) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('source: $source, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesLocalTable extends DevicesLocal
    with TableInfo<$DevicesLocalTable, DevicesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _installIdMeta =
      const VerificationMeta('installId');
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
      'install_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appVersionMeta =
      const VerificationMeta('appVersion');
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
      'app_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _buildNumberMeta =
      const VerificationMeta('buildNumber');
  @override
  late final GeneratedColumn<String> buildNumber = GeneratedColumn<String>(
      'build_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenAtMeta =
      const VerificationMeta('lastSeenAt');
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
      'last_seen_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncCursorMeta =
      const VerificationMeta('lastSyncCursor');
  @override
  late final GeneratedColumn<String> lastSyncCursor = GeneratedColumn<String>(
      'last_sync_cursor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        installId,
        platform,
        appVersion,
        buildNumber,
        lastSeenAt,
        lastSyncCursor
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices_local';
  @override
  VerificationContext validateIntegrity(Insertable<DevicesLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('install_id')) {
      context.handle(_installIdMeta,
          installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta));
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
          _appVersionMeta,
          appVersion.isAcceptableOrUnknown(
              data['app_version']!, _appVersionMeta));
    }
    if (data.containsKey('build_number')) {
      context.handle(
          _buildNumberMeta,
          buildNumber.isAcceptableOrUnknown(
              data['build_number']!, _buildNumberMeta));
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
          _lastSeenAtMeta,
          lastSeenAt.isAcceptableOrUnknown(
              data['last_seen_at']!, _lastSeenAtMeta));
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('last_sync_cursor')) {
      context.handle(
          _lastSyncCursorMeta,
          lastSyncCursor.isAcceptableOrUnknown(
              data['last_sync_cursor']!, _lastSyncCursorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DevicesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DevicesLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      installId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}install_id'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      appVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_version']),
      buildNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}build_number']),
      lastSeenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen_at'])!,
      lastSyncCursor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_sync_cursor']),
    );
  }

  @override
  $DevicesLocalTable createAlias(String alias) {
    return $DevicesLocalTable(attachedDatabase, alias);
  }
}

class DevicesLocalData extends DataClass
    implements Insertable<DevicesLocalData> {
  final String id;
  final String userId;
  final String installId;
  final String platform;
  final String? appVersion;
  final String? buildNumber;
  final DateTime lastSeenAt;
  final String? lastSyncCursor;
  const DevicesLocalData(
      {required this.id,
      required this.userId,
      required this.installId,
      required this.platform,
      this.appVersion,
      this.buildNumber,
      required this.lastSeenAt,
      this.lastSyncCursor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['install_id'] = Variable<String>(installId);
    map['platform'] = Variable<String>(platform);
    if (!nullToAbsent || appVersion != null) {
      map['app_version'] = Variable<String>(appVersion);
    }
    if (!nullToAbsent || buildNumber != null) {
      map['build_number'] = Variable<String>(buildNumber);
    }
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    if (!nullToAbsent || lastSyncCursor != null) {
      map['last_sync_cursor'] = Variable<String>(lastSyncCursor);
    }
    return map;
  }

  DevicesLocalCompanion toCompanion(bool nullToAbsent) {
    return DevicesLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      installId: Value(installId),
      platform: Value(platform),
      appVersion: appVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(appVersion),
      buildNumber: buildNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(buildNumber),
      lastSeenAt: Value(lastSeenAt),
      lastSyncCursor: lastSyncCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncCursor),
    );
  }

  factory DevicesLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DevicesLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      installId: serializer.fromJson<String>(json['installId']),
      platform: serializer.fromJson<String>(json['platform']),
      appVersion: serializer.fromJson<String?>(json['appVersion']),
      buildNumber: serializer.fromJson<String?>(json['buildNumber']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      lastSyncCursor: serializer.fromJson<String?>(json['lastSyncCursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'installId': serializer.toJson<String>(installId),
      'platform': serializer.toJson<String>(platform),
      'appVersion': serializer.toJson<String?>(appVersion),
      'buildNumber': serializer.toJson<String?>(buildNumber),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'lastSyncCursor': serializer.toJson<String?>(lastSyncCursor),
    };
  }

  DevicesLocalData copyWith(
          {String? id,
          String? userId,
          String? installId,
          String? platform,
          Value<String?> appVersion = const Value.absent(),
          Value<String?> buildNumber = const Value.absent(),
          DateTime? lastSeenAt,
          Value<String?> lastSyncCursor = const Value.absent()}) =>
      DevicesLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        installId: installId ?? this.installId,
        platform: platform ?? this.platform,
        appVersion: appVersion.present ? appVersion.value : this.appVersion,
        buildNumber: buildNumber.present ? buildNumber.value : this.buildNumber,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        lastSyncCursor:
            lastSyncCursor.present ? lastSyncCursor.value : this.lastSyncCursor,
      );
  DevicesLocalData copyWithCompanion(DevicesLocalCompanion data) {
    return DevicesLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      installId: data.installId.present ? data.installId.value : this.installId,
      platform: data.platform.present ? data.platform.value : this.platform,
      appVersion:
          data.appVersion.present ? data.appVersion.value : this.appVersion,
      buildNumber:
          data.buildNumber.present ? data.buildNumber.value : this.buildNumber,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
      lastSyncCursor: data.lastSyncCursor.present
          ? data.lastSyncCursor.value
          : this.lastSyncCursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DevicesLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('installId: $installId, ')
          ..write('platform: $platform, ')
          ..write('appVersion: $appVersion, ')
          ..write('buildNumber: $buildNumber, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastSyncCursor: $lastSyncCursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, installId, platform, appVersion,
      buildNumber, lastSeenAt, lastSyncCursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DevicesLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.installId == this.installId &&
          other.platform == this.platform &&
          other.appVersion == this.appVersion &&
          other.buildNumber == this.buildNumber &&
          other.lastSeenAt == this.lastSeenAt &&
          other.lastSyncCursor == this.lastSyncCursor);
}

class DevicesLocalCompanion extends UpdateCompanion<DevicesLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> installId;
  final Value<String> platform;
  final Value<String?> appVersion;
  final Value<String?> buildNumber;
  final Value<DateTime> lastSeenAt;
  final Value<String?> lastSyncCursor;
  final Value<int> rowid;
  const DevicesLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.installId = const Value.absent(),
    this.platform = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.buildNumber = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.lastSyncCursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesLocalCompanion.insert({
    required String id,
    required String userId,
    required String installId,
    required String platform,
    this.appVersion = const Value.absent(),
    this.buildNumber = const Value.absent(),
    required DateTime lastSeenAt,
    this.lastSyncCursor = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        installId = Value(installId),
        platform = Value(platform),
        lastSeenAt = Value(lastSeenAt);
  static Insertable<DevicesLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? installId,
    Expression<String>? platform,
    Expression<String>? appVersion,
    Expression<String>? buildNumber,
    Expression<DateTime>? lastSeenAt,
    Expression<String>? lastSyncCursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (installId != null) 'install_id': installId,
      if (platform != null) 'platform': platform,
      if (appVersion != null) 'app_version': appVersion,
      if (buildNumber != null) 'build_number': buildNumber,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (lastSyncCursor != null) 'last_sync_cursor': lastSyncCursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? installId,
      Value<String>? platform,
      Value<String?>? appVersion,
      Value<String?>? buildNumber,
      Value<DateTime>? lastSeenAt,
      Value<String?>? lastSyncCursor,
      Value<int>? rowid}) {
    return DevicesLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      installId: installId ?? this.installId,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastSyncCursor: lastSyncCursor ?? this.lastSyncCursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (buildNumber.present) {
      map['build_number'] = Variable<String>(buildNumber.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (lastSyncCursor.present) {
      map['last_sync_cursor'] = Variable<String>(lastSyncCursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('installId: $installId, ')
          ..write('platform: $platform, ')
          ..write('appVersion: $appVersion, ')
          ..write('buildNumber: $buildNumber, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastSyncCursor: $lastSyncCursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeatureFlagsLocalTable extends FeatureFlagsLocal
    with TableInfo<$FeatureFlagsLocalTable, FeatureFlagsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeatureFlagsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueJsonMeta =
      const VerificationMeta('valueJson');
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
      'value_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exposedAtMeta =
      const VerificationMeta('exposedAt');
  @override
  late final GeneratedColumn<DateTime> exposedAt = GeneratedColumn<DateTime>(
      'exposed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, valueJson, exposedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feature_flags_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<FeatureFlagsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(_valueJsonMeta,
          valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta));
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('exposed_at')) {
      context.handle(_exposedAtMeta,
          exposedAt.isAcceptableOrUnknown(data['exposed_at']!, _exposedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  FeatureFlagsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeatureFlagsLocalData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      valueJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_json'])!,
      exposedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}exposed_at'])!,
    );
  }

  @override
  $FeatureFlagsLocalTable createAlias(String alias) {
    return $FeatureFlagsLocalTable(attachedDatabase, alias);
  }
}

class FeatureFlagsLocalData extends DataClass
    implements Insertable<FeatureFlagsLocalData> {
  final String key;
  final String valueJson;
  final DateTime exposedAt;
  const FeatureFlagsLocalData(
      {required this.key, required this.valueJson, required this.exposedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['exposed_at'] = Variable<DateTime>(exposedAt);
    return map;
  }

  FeatureFlagsLocalCompanion toCompanion(bool nullToAbsent) {
    return FeatureFlagsLocalCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      exposedAt: Value(exposedAt),
    );
  }

  factory FeatureFlagsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeatureFlagsLocalData(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      exposedAt: serializer.fromJson<DateTime>(json['exposedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'exposedAt': serializer.toJson<DateTime>(exposedAt),
    };
  }

  FeatureFlagsLocalData copyWith(
          {String? key, String? valueJson, DateTime? exposedAt}) =>
      FeatureFlagsLocalData(
        key: key ?? this.key,
        valueJson: valueJson ?? this.valueJson,
        exposedAt: exposedAt ?? this.exposedAt,
      );
  FeatureFlagsLocalData copyWithCompanion(FeatureFlagsLocalCompanion data) {
    return FeatureFlagsLocalData(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      exposedAt: data.exposedAt.present ? data.exposedAt.value : this.exposedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeatureFlagsLocalData(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('exposedAt: $exposedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, exposedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeatureFlagsLocalData &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.exposedAt == this.exposedAt);
}

class FeatureFlagsLocalCompanion
    extends UpdateCompanion<FeatureFlagsLocalData> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<DateTime> exposedAt;
  final Value<int> rowid;
  const FeatureFlagsLocalCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.exposedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeatureFlagsLocalCompanion.insert({
    required String key,
    required String valueJson,
    this.exposedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        valueJson = Value(valueJson);
  static Insertable<FeatureFlagsLocalData> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<DateTime>? exposedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (exposedAt != null) 'exposed_at': exposedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeatureFlagsLocalCompanion copyWith(
      {Value<String>? key,
      Value<String>? valueJson,
      Value<DateTime>? exposedAt,
      Value<int>? rowid}) {
    return FeatureFlagsLocalCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      exposedAt: exposedAt ?? this.exposedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (exposedAt.present) {
      map['exposed_at'] = Variable<DateTime>(exposedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeatureFlagsLocalCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('exposedAt: $exposedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
      'cursor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, cursor, lastSyncedAt, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(_cursorMeta,
          cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      cursor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cursor']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String? cursor;
  final DateTime? lastSyncedAt;
  final String? lastError;
  const SyncStateData(
      {required this.key, this.cursor, this.lastSyncedAt, this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      key: Value(key),
      cursor:
          cursor == null && nullToAbsent ? const Value.absent() : Value(cursor),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'cursor': serializer.toJson<String?>(cursor),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncStateData copyWith(
          {String? key,
          Value<String?> cursor = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          Value<String?> lastError = const Value.absent()}) =>
      SyncStateData(
        key: key ?? this.key,
        cursor: cursor.present ? cursor.value : this.cursor,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, cursor, lastSyncedAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.cursor == this.cursor &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.lastError == this.lastError);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String?> cursor;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    this.cursor = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? cursor,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (cursor != null) 'cursor': cursor,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith(
      {Value<String>? key,
      Value<String?>? cursor,
      Value<DateTime?>? lastSyncedAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncStateCompanion(
      key: key ?? this.key,
      cursor: cursor ?? this.cursor,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxCommandsTable extends OutboxCommands
    with TableInfo<$OutboxCommandsTable, OutboxCommand> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxCommandsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _commandTypeMeta =
      const VerificationMeta('commandType');
  @override
  late final GeneratedColumn<String> commandType = GeneratedColumn<String>(
      'command_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadHashMeta =
      const VerificationMeta('payloadHash');
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
      'payload_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientRequestIdMeta =
      const VerificationMeta('clientRequestId');
  @override
  late final GeneratedColumn<String> clientRequestId = GeneratedColumn<String>(
      'client_request_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dependencyCommandIdMeta =
      const VerificationMeta('dependencyCommandId');
  @override
  late final GeneratedColumn<String> dependencyCommandId =
      GeneratedColumn<String>('dependency_command_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        userId,
        commandType,
        payloadJson,
        payloadHash,
        clientRequestId,
        dependencyCommandId,
        status,
        retryCount,
        nextRetryAt,
        lastError,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_commands';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxCommand> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('command_type')) {
      context.handle(
          _commandTypeMeta,
          commandType.isAcceptableOrUnknown(
              data['command_type']!, _commandTypeMeta));
    } else if (isInserting) {
      context.missing(_commandTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
          _payloadHashMeta,
          payloadHash.isAcceptableOrUnknown(
              data['payload_hash']!, _payloadHashMeta));
    }
    if (data.containsKey('client_request_id')) {
      context.handle(
          _clientRequestIdMeta,
          clientRequestId.isAcceptableOrUnknown(
              data['client_request_id']!, _clientRequestIdMeta));
    } else if (isInserting) {
      context.missing(_clientRequestIdMeta);
    }
    if (data.containsKey('dependency_command_id')) {
      context.handle(
          _dependencyCommandIdMeta,
          dependencyCommandId.isAcceptableOrUnknown(
              data['dependency_command_id']!, _dependencyCommandIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
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
  OutboxCommand map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxCommand(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      commandType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}command_type'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      payloadHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_hash']),
      clientRequestId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_request_id'])!,
      dependencyCommandId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dependency_command_id']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OutboxCommandsTable createAlias(String alias) {
    return $OutboxCommandsTable(attachedDatabase, alias);
  }
}

class OutboxCommand extends DataClass implements Insertable<OutboxCommand> {
  final String id;
  final String userId;
  final String commandType;
  final String payloadJson;
  final String? payloadHash;
  final String clientRequestId;
  final String? dependencyCommandId;
  final String status;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OutboxCommand(
      {required this.id,
      required this.userId,
      required this.commandType,
      required this.payloadJson,
      this.payloadHash,
      required this.clientRequestId,
      this.dependencyCommandId,
      required this.status,
      required this.retryCount,
      this.nextRetryAt,
      this.lastError,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['command_type'] = Variable<String>(commandType);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || payloadHash != null) {
      map['payload_hash'] = Variable<String>(payloadHash);
    }
    map['client_request_id'] = Variable<String>(clientRequestId);
    if (!nullToAbsent || dependencyCommandId != null) {
      map['dependency_command_id'] = Variable<String>(dependencyCommandId);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxCommandsCompanion toCompanion(bool nullToAbsent) {
    return OutboxCommandsCompanion(
      id: Value(id),
      userId: Value(userId),
      commandType: Value(commandType),
      payloadJson: Value(payloadJson),
      payloadHash: payloadHash == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadHash),
      clientRequestId: Value(clientRequestId),
      dependencyCommandId: dependencyCommandId == null && nullToAbsent
          ? const Value.absent()
          : Value(dependencyCommandId),
      status: Value(status),
      retryCount: Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxCommand.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxCommand(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      commandType: serializer.fromJson<String>(json['commandType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      payloadHash: serializer.fromJson<String?>(json['payloadHash']),
      clientRequestId: serializer.fromJson<String>(json['clientRequestId']),
      dependencyCommandId:
          serializer.fromJson<String?>(json['dependencyCommandId']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'commandType': serializer.toJson<String>(commandType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'payloadHash': serializer.toJson<String?>(payloadHash),
      'clientRequestId': serializer.toJson<String>(clientRequestId),
      'dependencyCommandId': serializer.toJson<String?>(dependencyCommandId),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxCommand copyWith(
          {String? id,
          String? userId,
          String? commandType,
          String? payloadJson,
          Value<String?> payloadHash = const Value.absent(),
          String? clientRequestId,
          Value<String?> dependencyCommandId = const Value.absent(),
          String? status,
          int? retryCount,
          Value<DateTime?> nextRetryAt = const Value.absent(),
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      OutboxCommand(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        commandType: commandType ?? this.commandType,
        payloadJson: payloadJson ?? this.payloadJson,
        payloadHash: payloadHash.present ? payloadHash.value : this.payloadHash,
        clientRequestId: clientRequestId ?? this.clientRequestId,
        dependencyCommandId: dependencyCommandId.present
            ? dependencyCommandId.value
            : this.dependencyCommandId,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OutboxCommand copyWithCompanion(OutboxCommandsCompanion data) {
    return OutboxCommand(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      commandType:
          data.commandType.present ? data.commandType.value : this.commandType,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      payloadHash:
          data.payloadHash.present ? data.payloadHash.value : this.payloadHash,
      clientRequestId: data.clientRequestId.present
          ? data.clientRequestId.value
          : this.clientRequestId,
      dependencyCommandId: data.dependencyCommandId.present
          ? data.dependencyCommandId.value
          : this.dependencyCommandId,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCommand(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('commandType: $commandType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('dependencyCommandId: $dependencyCommandId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      commandType,
      payloadJson,
      payloadHash,
      clientRequestId,
      dependencyCommandId,
      status,
      retryCount,
      nextRetryAt,
      lastError,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxCommand &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.commandType == this.commandType &&
          other.payloadJson == this.payloadJson &&
          other.payloadHash == this.payloadHash &&
          other.clientRequestId == this.clientRequestId &&
          other.dependencyCommandId == this.dependencyCommandId &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxCommandsCompanion extends UpdateCompanion<OutboxCommand> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> commandType;
  final Value<String> payloadJson;
  final Value<String?> payloadHash;
  final Value<String> clientRequestId;
  final Value<String?> dependencyCommandId;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutboxCommandsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.commandType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.clientRequestId = const Value.absent(),
    this.dependencyCommandId = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCommandsCompanion.insert({
    required String id,
    required String userId,
    required String commandType,
    required String payloadJson,
    this.payloadHash = const Value.absent(),
    required String clientRequestId,
    this.dependencyCommandId = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        commandType = Value(commandType),
        payloadJson = Value(payloadJson),
        clientRequestId = Value(clientRequestId);
  static Insertable<OutboxCommand> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? commandType,
    Expression<String>? payloadJson,
    Expression<String>? payloadHash,
    Expression<String>? clientRequestId,
    Expression<String>? dependencyCommandId,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (commandType != null) 'command_type': commandType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (clientRequestId != null) 'client_request_id': clientRequestId,
      if (dependencyCommandId != null)
        'dependency_command_id': dependencyCommandId,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCommandsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? commandType,
      Value<String>? payloadJson,
      Value<String?>? payloadHash,
      Value<String>? clientRequestId,
      Value<String?>? dependencyCommandId,
      Value<String>? status,
      Value<int>? retryCount,
      Value<DateTime?>? nextRetryAt,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return OutboxCommandsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      commandType: commandType ?? this.commandType,
      payloadJson: payloadJson ?? this.payloadJson,
      payloadHash: payloadHash ?? this.payloadHash,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      dependencyCommandId: dependencyCommandId ?? this.dependencyCommandId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (commandType.present) {
      map['command_type'] = Variable<String>(commandType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (clientRequestId.present) {
      map['client_request_id'] = Variable<String>(clientRequestId.value);
    }
    if (dependencyCommandId.present) {
      map['dependency_command_id'] =
          Variable<String>(dependencyCommandId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCommandsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('commandType: $commandType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('dependencyCommandId: $dependencyCommandId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealAssetsLocalTable extends MealAssetsLocal
    with TableInfo<$MealAssetsLocalTable, MealAssetsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealAssetsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storageBucketMeta =
      const VerificationMeta('storageBucket');
  @override
  late final GeneratedColumn<String> storageBucket = GeneratedColumn<String>(
      'storage_bucket', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('meal-originals-private'));
  static const VerificationMeta _storagePathMeta =
      const VerificationMeta('storagePath');
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
      'storage_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbLocalPathMeta =
      const VerificationMeta('thumbLocalPath');
  @override
  late final GeneratedColumn<String> thumbLocalPath = GeneratedColumn<String>(
      'thumb_local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbStoragePathMeta =
      const VerificationMeta('thumbStoragePath');
  @override
  late final GeneratedColumn<String> thumbStoragePath = GeneratedColumn<String>(
      'thumb_storage_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
      'sha256', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('image/jpeg'));
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uploadStatusMeta =
      const VerificationMeta('uploadStatus');
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
      'upload_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _uploadedAtMeta =
      const VerificationMeta('uploadedAt');
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
      'uploaded_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        localPath,
        storageBucket,
        storagePath,
        thumbLocalPath,
        thumbStoragePath,
        sha256,
        mimeType,
        width,
        height,
        sizeBytes,
        uploadStatus,
        createdAt,
        uploadedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_assets_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<MealAssetsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('storage_bucket')) {
      context.handle(
          _storageBucketMeta,
          storageBucket.isAcceptableOrUnknown(
              data['storage_bucket']!, _storageBucketMeta));
    }
    if (data.containsKey('storage_path')) {
      context.handle(
          _storagePathMeta,
          storagePath.isAcceptableOrUnknown(
              data['storage_path']!, _storagePathMeta));
    } else if (isInserting) {
      context.missing(_storagePathMeta);
    }
    if (data.containsKey('thumb_local_path')) {
      context.handle(
          _thumbLocalPathMeta,
          thumbLocalPath.isAcceptableOrUnknown(
              data['thumb_local_path']!, _thumbLocalPathMeta));
    }
    if (data.containsKey('thumb_storage_path')) {
      context.handle(
          _thumbStoragePathMeta,
          thumbStoragePath.isAcceptableOrUnknown(
              data['thumb_storage_path']!, _thumbStoragePathMeta));
    }
    if (data.containsKey('sha256')) {
      context.handle(_sha256Meta,
          sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta));
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('upload_status')) {
      context.handle(
          _uploadStatusMeta,
          uploadStatus.isAcceptableOrUnknown(
              data['upload_status']!, _uploadStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
          _uploadedAtMeta,
          uploadedAt.isAcceptableOrUnknown(
              data['uploaded_at']!, _uploadedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealAssetsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealAssetsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      storageBucket: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_bucket'])!,
      storagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_path'])!,
      thumbLocalPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}thumb_local_path']),
      thumbStoragePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}thumb_storage_path']),
      sha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes']),
      uploadStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upload_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      uploadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}uploaded_at']),
    );
  }

  @override
  $MealAssetsLocalTable createAlias(String alias) {
    return $MealAssetsLocalTable(attachedDatabase, alias);
  }
}

class MealAssetsLocalData extends DataClass
    implements Insertable<MealAssetsLocalData> {
  final String id;
  final String userId;
  final String localPath;
  final String storageBucket;
  final String storagePath;
  final String? thumbLocalPath;
  final String? thumbStoragePath;
  final String sha256;
  final String mimeType;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final String uploadStatus;
  final DateTime createdAt;
  final DateTime? uploadedAt;
  const MealAssetsLocalData(
      {required this.id,
      required this.userId,
      required this.localPath,
      required this.storageBucket,
      required this.storagePath,
      this.thumbLocalPath,
      this.thumbStoragePath,
      required this.sha256,
      required this.mimeType,
      this.width,
      this.height,
      this.sizeBytes,
      required this.uploadStatus,
      required this.createdAt,
      this.uploadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['local_path'] = Variable<String>(localPath);
    map['storage_bucket'] = Variable<String>(storageBucket);
    map['storage_path'] = Variable<String>(storagePath);
    if (!nullToAbsent || thumbLocalPath != null) {
      map['thumb_local_path'] = Variable<String>(thumbLocalPath);
    }
    if (!nullToAbsent || thumbStoragePath != null) {
      map['thumb_storage_path'] = Variable<String>(thumbStoragePath);
    }
    map['sha256'] = Variable<String>(sha256);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['upload_status'] = Variable<String>(uploadStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || uploadedAt != null) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    }
    return map;
  }

  MealAssetsLocalCompanion toCompanion(bool nullToAbsent) {
    return MealAssetsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      localPath: Value(localPath),
      storageBucket: Value(storageBucket),
      storagePath: Value(storagePath),
      thumbLocalPath: thumbLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbLocalPath),
      thumbStoragePath: thumbStoragePath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbStoragePath),
      sha256: Value(sha256),
      mimeType: Value(mimeType),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      uploadStatus: Value(uploadStatus),
      createdAt: Value(createdAt),
      uploadedAt: uploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedAt),
    );
  }

  factory MealAssetsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealAssetsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      storageBucket: serializer.fromJson<String>(json['storageBucket']),
      storagePath: serializer.fromJson<String>(json['storagePath']),
      thumbLocalPath: serializer.fromJson<String?>(json['thumbLocalPath']),
      thumbStoragePath: serializer.fromJson<String?>(json['thumbStoragePath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uploadedAt: serializer.fromJson<DateTime?>(json['uploadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'localPath': serializer.toJson<String>(localPath),
      'storageBucket': serializer.toJson<String>(storageBucket),
      'storagePath': serializer.toJson<String>(storagePath),
      'thumbLocalPath': serializer.toJson<String?>(thumbLocalPath),
      'thumbStoragePath': serializer.toJson<String?>(thumbStoragePath),
      'sha256': serializer.toJson<String>(sha256),
      'mimeType': serializer.toJson<String>(mimeType),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uploadedAt': serializer.toJson<DateTime?>(uploadedAt),
    };
  }

  MealAssetsLocalData copyWith(
          {String? id,
          String? userId,
          String? localPath,
          String? storageBucket,
          String? storagePath,
          Value<String?> thumbLocalPath = const Value.absent(),
          Value<String?> thumbStoragePath = const Value.absent(),
          String? sha256,
          String? mimeType,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<int?> sizeBytes = const Value.absent(),
          String? uploadStatus,
          DateTime? createdAt,
          Value<DateTime?> uploadedAt = const Value.absent()}) =>
      MealAssetsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        localPath: localPath ?? this.localPath,
        storageBucket: storageBucket ?? this.storageBucket,
        storagePath: storagePath ?? this.storagePath,
        thumbLocalPath:
            thumbLocalPath.present ? thumbLocalPath.value : this.thumbLocalPath,
        thumbStoragePath: thumbStoragePath.present
            ? thumbStoragePath.value
            : this.thumbStoragePath,
        sha256: sha256 ?? this.sha256,
        mimeType: mimeType ?? this.mimeType,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
        uploadStatus: uploadStatus ?? this.uploadStatus,
        createdAt: createdAt ?? this.createdAt,
        uploadedAt: uploadedAt.present ? uploadedAt.value : this.uploadedAt,
      );
  MealAssetsLocalData copyWithCompanion(MealAssetsLocalCompanion data) {
    return MealAssetsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      storageBucket: data.storageBucket.present
          ? data.storageBucket.value
          : this.storageBucket,
      storagePath:
          data.storagePath.present ? data.storagePath.value : this.storagePath,
      thumbLocalPath: data.thumbLocalPath.present
          ? data.thumbLocalPath.value
          : this.thumbLocalPath,
      thumbStoragePath: data.thumbStoragePath.present
          ? data.thumbStoragePath.value
          : this.thumbStoragePath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uploadedAt:
          data.uploadedAt.present ? data.uploadedAt.value : this.uploadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealAssetsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localPath: $localPath, ')
          ..write('storageBucket: $storageBucket, ')
          ..write('storagePath: $storagePath, ')
          ..write('thumbLocalPath: $thumbLocalPath, ')
          ..write('thumbStoragePath: $thumbStoragePath, ')
          ..write('sha256: $sha256, ')
          ..write('mimeType: $mimeType, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('uploadedAt: $uploadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      localPath,
      storageBucket,
      storagePath,
      thumbLocalPath,
      thumbStoragePath,
      sha256,
      mimeType,
      width,
      height,
      sizeBytes,
      uploadStatus,
      createdAt,
      uploadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealAssetsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.localPath == this.localPath &&
          other.storageBucket == this.storageBucket &&
          other.storagePath == this.storagePath &&
          other.thumbLocalPath == this.thumbLocalPath &&
          other.thumbStoragePath == this.thumbStoragePath &&
          other.sha256 == this.sha256 &&
          other.mimeType == this.mimeType &&
          other.width == this.width &&
          other.height == this.height &&
          other.sizeBytes == this.sizeBytes &&
          other.uploadStatus == this.uploadStatus &&
          other.createdAt == this.createdAt &&
          other.uploadedAt == this.uploadedAt);
}

class MealAssetsLocalCompanion extends UpdateCompanion<MealAssetsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> localPath;
  final Value<String> storageBucket;
  final Value<String> storagePath;
  final Value<String?> thumbLocalPath;
  final Value<String?> thumbStoragePath;
  final Value<String> sha256;
  final Value<String> mimeType;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> sizeBytes;
  final Value<String> uploadStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime?> uploadedAt;
  final Value<int> rowid;
  const MealAssetsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.storageBucket = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.thumbLocalPath = const Value.absent(),
    this.thumbStoragePath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealAssetsLocalCompanion.insert({
    required String id,
    required String userId,
    required String localPath,
    this.storageBucket = const Value.absent(),
    required String storagePath,
    this.thumbLocalPath = const Value.absent(),
    this.thumbStoragePath = const Value.absent(),
    required String sha256,
    this.mimeType = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        localPath = Value(localPath),
        storagePath = Value(storagePath),
        sha256 = Value(sha256);
  static Insertable<MealAssetsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? localPath,
    Expression<String>? storageBucket,
    Expression<String>? storagePath,
    Expression<String>? thumbLocalPath,
    Expression<String>? thumbStoragePath,
    Expression<String>? sha256,
    Expression<String>? mimeType,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? sizeBytes,
    Expression<String>? uploadStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? uploadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (localPath != null) 'local_path': localPath,
      if (storageBucket != null) 'storage_bucket': storageBucket,
      if (storagePath != null) 'storage_path': storagePath,
      if (thumbLocalPath != null) 'thumb_local_path': thumbLocalPath,
      if (thumbStoragePath != null) 'thumb_storage_path': thumbStoragePath,
      if (sha256 != null) 'sha256': sha256,
      if (mimeType != null) 'mime_type': mimeType,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealAssetsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? localPath,
      Value<String>? storageBucket,
      Value<String>? storagePath,
      Value<String?>? thumbLocalPath,
      Value<String?>? thumbStoragePath,
      Value<String>? sha256,
      Value<String>? mimeType,
      Value<int?>? width,
      Value<int?>? height,
      Value<int?>? sizeBytes,
      Value<String>? uploadStatus,
      Value<DateTime>? createdAt,
      Value<DateTime?>? uploadedAt,
      Value<int>? rowid}) {
    return MealAssetsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      localPath: localPath ?? this.localPath,
      storageBucket: storageBucket ?? this.storageBucket,
      storagePath: storagePath ?? this.storagePath,
      thumbLocalPath: thumbLocalPath ?? this.thumbLocalPath,
      thumbStoragePath: thumbStoragePath ?? this.thumbStoragePath,
      sha256: sha256 ?? this.sha256,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (storageBucket.present) {
      map['storage_bucket'] = Variable<String>(storageBucket.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (thumbLocalPath.present) {
      map['thumb_local_path'] = Variable<String>(thumbLocalPath.value);
    }
    if (thumbStoragePath.present) {
      map['thumb_storage_path'] = Variable<String>(thumbStoragePath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealAssetsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('localPath: $localPath, ')
          ..write('storageBucket: $storageBucket, ')
          ..write('storagePath: $storagePath, ')
          ..write('thumbLocalPath: $thumbLocalPath, ')
          ..write('thumbStoragePath: $thumbStoragePath, ')
          ..write('sha256: $sha256, ')
          ..write('mimeType: $mimeType, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealsLocalTable extends MealsLocal
    with TableInfo<$MealsLocalTable, MealsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _analysisJobIdMeta =
      const VerificationMeta('analysisJobId');
  @override
  late final GeneratedColumn<String> analysisJobId = GeneratedColumn<String>(
      'analysis_job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mealTypeMeta =
      const VerificationMeta('mealType');
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
      'meal_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _loggedAtMeta =
      const VerificationMeta('loggedAt');
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
      'logged_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _timezoneMeta =
      const VerificationMeta('timezone');
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
      'timezone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caloriesKcalMeta =
      const VerificationMeta('caloriesKcal');
  @override
  late final GeneratedColumn<double> caloriesKcal = GeneratedColumn<double>(
      'calories_kcal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _confidenceOverallMeta =
      const VerificationMeta('confidenceOverall');
  @override
  late final GeneratedColumn<double> confidenceOverall =
      GeneratedColumn<double>('confidence_overall', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _provenanceTypeMeta =
      const VerificationMeta('provenanceType');
  @override
  late final GeneratedColumn<String> provenanceType = GeneratedColumn<String>(
      'provenance_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoAssetIdMeta =
      const VerificationMeta('photoAssetId');
  @override
  late final GeneratedColumn<String> photoAssetId = GeneratedColumn<String>(
      'photo_asset_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _revisionMeta =
      const VerificationMeta('revision');
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
      'revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
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
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        clientId,
        analysisJobId,
        title,
        mealType,
        source,
        loggedAt,
        timezone,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        confidenceOverall,
        provenanceType,
        photoAssetId,
        revision,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals_local';
  @override
  VerificationContext validateIntegrity(Insertable<MealsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('analysis_job_id')) {
      context.handle(
          _analysisJobIdMeta,
          analysisJobId.isAcceptableOrUnknown(
              data['analysis_job_id']!, _analysisJobIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(_mealTypeMeta,
          mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta));
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(_loggedAtMeta,
          loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta));
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(_timezoneMeta,
          timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta));
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
          _caloriesKcalMeta,
          caloriesKcal.isAcceptableOrUnknown(
              data['calories_kcal']!, _caloriesKcalMeta));
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('confidence_overall')) {
      context.handle(
          _confidenceOverallMeta,
          confidenceOverall.isAcceptableOrUnknown(
              data['confidence_overall']!, _confidenceOverallMeta));
    }
    if (data.containsKey('provenance_type')) {
      context.handle(
          _provenanceTypeMeta,
          provenanceType.isAcceptableOrUnknown(
              data['provenance_type']!, _provenanceTypeMeta));
    }
    if (data.containsKey('photo_asset_id')) {
      context.handle(
          _photoAssetIdMeta,
          photoAssetId.isAcceptableOrUnknown(
              data['photo_asset_id']!, _photoAssetIdMeta));
    }
    if (data.containsKey('revision')) {
      context.handle(_revisionMeta,
          revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      analysisJobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis_job_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      mealType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_type'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      loggedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}logged_at'])!,
      timezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timezone'])!,
      caloriesKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calories_kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      confidenceOverall: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}confidence_overall']),
      provenanceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provenance_type']),
      photoAssetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_asset_id']),
      revision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}revision'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $MealsLocalTable createAlias(String alias) {
    return $MealsLocalTable(attachedDatabase, alias);
  }
}

class MealsLocalData extends DataClass implements Insertable<MealsLocalData> {
  final String id;
  final String userId;
  final String clientId;
  final String? analysisJobId;
  final String title;
  final String mealType;
  final String source;
  final DateTime loggedAt;
  final String timezone;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? confidenceOverall;
  final String? provenanceType;
  final String? photoAssetId;
  final int revision;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MealsLocalData(
      {required this.id,
      required this.userId,
      required this.clientId,
      this.analysisJobId,
      required this.title,
      required this.mealType,
      required this.source,
      required this.loggedAt,
      required this.timezone,
      required this.caloriesKcal,
      required this.proteinG,
      required this.carbsG,
      required this.fatG,
      this.confidenceOverall,
      this.provenanceType,
      this.photoAssetId,
      required this.revision,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || analysisJobId != null) {
      map['analysis_job_id'] = Variable<String>(analysisJobId);
    }
    map['title'] = Variable<String>(title);
    map['meal_type'] = Variable<String>(mealType);
    map['source'] = Variable<String>(source);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['timezone'] = Variable<String>(timezone);
    map['calories_kcal'] = Variable<double>(caloriesKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || confidenceOverall != null) {
      map['confidence_overall'] = Variable<double>(confidenceOverall);
    }
    if (!nullToAbsent || provenanceType != null) {
      map['provenance_type'] = Variable<String>(provenanceType);
    }
    if (!nullToAbsent || photoAssetId != null) {
      map['photo_asset_id'] = Variable<String>(photoAssetId);
    }
    map['revision'] = Variable<int>(revision);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MealsLocalCompanion toCompanion(bool nullToAbsent) {
    return MealsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      clientId: Value(clientId),
      analysisJobId: analysisJobId == null && nullToAbsent
          ? const Value.absent()
          : Value(analysisJobId),
      title: Value(title),
      mealType: Value(mealType),
      source: Value(source),
      loggedAt: Value(loggedAt),
      timezone: Value(timezone),
      caloriesKcal: Value(caloriesKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      confidenceOverall: confidenceOverall == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceOverall),
      provenanceType: provenanceType == null && nullToAbsent
          ? const Value.absent()
          : Value(provenanceType),
      photoAssetId: photoAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(photoAssetId),
      revision: Value(revision),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MealsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      analysisJobId: serializer.fromJson<String?>(json['analysisJobId']),
      title: serializer.fromJson<String>(json['title']),
      mealType: serializer.fromJson<String>(json['mealType']),
      source: serializer.fromJson<String>(json['source']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      timezone: serializer.fromJson<String>(json['timezone']),
      caloriesKcal: serializer.fromJson<double>(json['caloriesKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      confidenceOverall:
          serializer.fromJson<double?>(json['confidenceOverall']),
      provenanceType: serializer.fromJson<String?>(json['provenanceType']),
      photoAssetId: serializer.fromJson<String?>(json['photoAssetId']),
      revision: serializer.fromJson<int>(json['revision']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'clientId': serializer.toJson<String>(clientId),
      'analysisJobId': serializer.toJson<String?>(analysisJobId),
      'title': serializer.toJson<String>(title),
      'mealType': serializer.toJson<String>(mealType),
      'source': serializer.toJson<String>(source),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'timezone': serializer.toJson<String>(timezone),
      'caloriesKcal': serializer.toJson<double>(caloriesKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'confidenceOverall': serializer.toJson<double?>(confidenceOverall),
      'provenanceType': serializer.toJson<String?>(provenanceType),
      'photoAssetId': serializer.toJson<String?>(photoAssetId),
      'revision': serializer.toJson<int>(revision),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MealsLocalData copyWith(
          {String? id,
          String? userId,
          String? clientId,
          Value<String?> analysisJobId = const Value.absent(),
          String? title,
          String? mealType,
          String? source,
          DateTime? loggedAt,
          String? timezone,
          double? caloriesKcal,
          double? proteinG,
          double? carbsG,
          double? fatG,
          Value<double?> confidenceOverall = const Value.absent(),
          Value<String?> provenanceType = const Value.absent(),
          Value<String?> photoAssetId = const Value.absent(),
          int? revision,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      MealsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        clientId: clientId ?? this.clientId,
        analysisJobId:
            analysisJobId.present ? analysisJobId.value : this.analysisJobId,
        title: title ?? this.title,
        mealType: mealType ?? this.mealType,
        source: source ?? this.source,
        loggedAt: loggedAt ?? this.loggedAt,
        timezone: timezone ?? this.timezone,
        caloriesKcal: caloriesKcal ?? this.caloriesKcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        confidenceOverall: confidenceOverall.present
            ? confidenceOverall.value
            : this.confidenceOverall,
        provenanceType:
            provenanceType.present ? provenanceType.value : this.provenanceType,
        photoAssetId:
            photoAssetId.present ? photoAssetId.value : this.photoAssetId,
        revision: revision ?? this.revision,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  MealsLocalData copyWithCompanion(MealsLocalCompanion data) {
    return MealsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      analysisJobId: data.analysisJobId.present
          ? data.analysisJobId.value
          : this.analysisJobId,
      title: data.title.present ? data.title.value : this.title,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      source: data.source.present ? data.source.value : this.source,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      confidenceOverall: data.confidenceOverall.present
          ? data.confidenceOverall.value
          : this.confidenceOverall,
      provenanceType: data.provenanceType.present
          ? data.provenanceType.value
          : this.provenanceType,
      photoAssetId: data.photoAssetId.present
          ? data.photoAssetId.value
          : this.photoAssetId,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('analysisJobId: $analysisJobId, ')
          ..write('title: $title, ')
          ..write('mealType: $mealType, ')
          ..write('source: $source, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('timezone: $timezone, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidenceOverall: $confidenceOverall, ')
          ..write('provenanceType: $provenanceType, ')
          ..write('photoAssetId: $photoAssetId, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        userId,
        clientId,
        analysisJobId,
        title,
        mealType,
        source,
        loggedAt,
        timezone,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        confidenceOverall,
        provenanceType,
        photoAssetId,
        revision,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.clientId == this.clientId &&
          other.analysisJobId == this.analysisJobId &&
          other.title == this.title &&
          other.mealType == this.mealType &&
          other.source == this.source &&
          other.loggedAt == this.loggedAt &&
          other.timezone == this.timezone &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.confidenceOverall == this.confidenceOverall &&
          other.provenanceType == this.provenanceType &&
          other.photoAssetId == this.photoAssetId &&
          other.revision == this.revision &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MealsLocalCompanion extends UpdateCompanion<MealsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> clientId;
  final Value<String?> analysisJobId;
  final Value<String> title;
  final Value<String> mealType;
  final Value<String> source;
  final Value<DateTime> loggedAt;
  final Value<String> timezone;
  final Value<double> caloriesKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<double?> confidenceOverall;
  final Value<String?> provenanceType;
  final Value<String?> photoAssetId;
  final Value<int> revision;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MealsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.analysisJobId = const Value.absent(),
    this.title = const Value.absent(),
    this.mealType = const Value.absent(),
    this.source = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.timezone = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.confidenceOverall = const Value.absent(),
    this.provenanceType = const Value.absent(),
    this.photoAssetId = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealsLocalCompanion.insert({
    required String id,
    required String userId,
    required String clientId,
    this.analysisJobId = const Value.absent(),
    required String title,
    required String mealType,
    required String source,
    required DateTime loggedAt,
    required String timezone,
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.confidenceOverall = const Value.absent(),
    this.provenanceType = const Value.absent(),
    this.photoAssetId = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        clientId = Value(clientId),
        title = Value(title),
        mealType = Value(mealType),
        source = Value(source),
        loggedAt = Value(loggedAt),
        timezone = Value(timezone);
  static Insertable<MealsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? clientId,
    Expression<String>? analysisJobId,
    Expression<String>? title,
    Expression<String>? mealType,
    Expression<String>? source,
    Expression<DateTime>? loggedAt,
    Expression<String>? timezone,
    Expression<double>? caloriesKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<double>? confidenceOverall,
    Expression<String>? provenanceType,
    Expression<String>? photoAssetId,
    Expression<int>? revision,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (clientId != null) 'client_id': clientId,
      if (analysisJobId != null) 'analysis_job_id': analysisJobId,
      if (title != null) 'title': title,
      if (mealType != null) 'meal_type': mealType,
      if (source != null) 'source': source,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (timezone != null) 'timezone': timezone,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (confidenceOverall != null) 'confidence_overall': confidenceOverall,
      if (provenanceType != null) 'provenance_type': provenanceType,
      if (photoAssetId != null) 'photo_asset_id': photoAssetId,
      if (revision != null) 'revision': revision,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? clientId,
      Value<String?>? analysisJobId,
      Value<String>? title,
      Value<String>? mealType,
      Value<String>? source,
      Value<DateTime>? loggedAt,
      Value<String>? timezone,
      Value<double>? caloriesKcal,
      Value<double>? proteinG,
      Value<double>? carbsG,
      Value<double>? fatG,
      Value<double?>? confidenceOverall,
      Value<String?>? provenanceType,
      Value<String?>? photoAssetId,
      Value<int>? revision,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return MealsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      analysisJobId: analysisJobId ?? this.analysisJobId,
      title: title ?? this.title,
      mealType: mealType ?? this.mealType,
      source: source ?? this.source,
      loggedAt: loggedAt ?? this.loggedAt,
      timezone: timezone ?? this.timezone,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      confidenceOverall: confidenceOverall ?? this.confidenceOverall,
      provenanceType: provenanceType ?? this.provenanceType,
      photoAssetId: photoAssetId ?? this.photoAssetId,
      revision: revision ?? this.revision,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (analysisJobId.present) {
      map['analysis_job_id'] = Variable<String>(analysisJobId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<double>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (confidenceOverall.present) {
      map['confidence_overall'] = Variable<double>(confidenceOverall.value);
    }
    if (provenanceType.present) {
      map['provenance_type'] = Variable<String>(provenanceType.value);
    }
    if (photoAssetId.present) {
      map['photo_asset_id'] = Variable<String>(photoAssetId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('analysisJobId: $analysisJobId, ')
          ..write('title: $title, ')
          ..write('mealType: $mealType, ')
          ..write('source: $source, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('timezone: $timezone, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidenceOverall: $confidenceOverall, ')
          ..write('provenanceType: $provenanceType, ')
          ..write('photoAssetId: $photoAssetId, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealItemsLocalTable extends MealItemsLocal
    with TableInfo<$MealItemsLocalTable, MealItemsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealItemsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
      'meal_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodRefKindMeta =
      const VerificationMeta('foodRefKind');
  @override
  late final GeneratedColumn<String> foodRefKind = GeneratedColumn<String>(
      'food_ref_kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _canonicalFoodIdMeta =
      const VerificationMeta('canonicalFoodId');
  @override
  late final GeneratedColumn<String> canonicalFoodId = GeneratedColumn<String>(
      'canonical_food_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _brandedProductIdMeta =
      const VerificationMeta('brandedProductId');
  @override
  late final GeneratedColumn<String> brandedProductId = GeneratedColumn<String>(
      'branded_product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customFoodIdMeta =
      const VerificationMeta('customFoodId');
  @override
  late final GeneratedColumn<String> customFoodId = GeneratedColumn<String>(
      'custom_food_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gramsEstimatedMeta =
      const VerificationMeta('gramsEstimated');
  @override
  late final GeneratedColumn<double> gramsEstimated = GeneratedColumn<double>(
      'grams_estimated', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _caloriesKcalMeta =
      const VerificationMeta('caloriesKcal');
  @override
  late final GeneratedColumn<double> caloriesKcal = GeneratedColumn<double>(
      'calories_kcal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        mealId,
        userId,
        clientId,
        position,
        name,
        foodRefKind,
        canonicalFoodId,
        brandedProductId,
        customFoodId,
        quantity,
        unit,
        gramsEstimated,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        confidence,
        sourceType,
        sourceId,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_items_local';
  @override
  VerificationContext validateIntegrity(Insertable<MealItemsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('food_ref_kind')) {
      context.handle(
          _foodRefKindMeta,
          foodRefKind.isAcceptableOrUnknown(
              data['food_ref_kind']!, _foodRefKindMeta));
    }
    if (data.containsKey('canonical_food_id')) {
      context.handle(
          _canonicalFoodIdMeta,
          canonicalFoodId.isAcceptableOrUnknown(
              data['canonical_food_id']!, _canonicalFoodIdMeta));
    }
    if (data.containsKey('branded_product_id')) {
      context.handle(
          _brandedProductIdMeta,
          brandedProductId.isAcceptableOrUnknown(
              data['branded_product_id']!, _brandedProductIdMeta));
    }
    if (data.containsKey('custom_food_id')) {
      context.handle(
          _customFoodIdMeta,
          customFoodId.isAcceptableOrUnknown(
              data['custom_food_id']!, _customFoodIdMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('grams_estimated')) {
      context.handle(
          _gramsEstimatedMeta,
          gramsEstimated.isAcceptableOrUnknown(
              data['grams_estimated']!, _gramsEstimatedMeta));
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
          _caloriesKcalMeta,
          caloriesKcal.isAcceptableOrUnknown(
              data['calories_kcal']!, _caloriesKcalMeta));
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
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
  MealItemsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealItemsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      foodRefKind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_ref_kind'])!,
      canonicalFoodId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}canonical_food_id']),
      brandedProductId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}branded_product_id']),
      customFoodId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_food_id']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      gramsEstimated: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}grams_estimated']),
      caloriesKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calories_kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence']),
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type']),
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MealItemsLocalTable createAlias(String alias) {
    return $MealItemsLocalTable(attachedDatabase, alias);
  }
}

class MealItemsLocalData extends DataClass
    implements Insertable<MealItemsLocalData> {
  final String id;
  final String mealId;
  final String userId;
  final String clientId;
  final int position;
  final String name;
  final String foodRefKind;
  final String? canonicalFoodId;
  final String? brandedProductId;
  final String? customFoodId;
  final double quantity;
  final String unit;
  final double? gramsEstimated;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? confidence;
  final String? sourceType;
  final String? sourceId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MealItemsLocalData(
      {required this.id,
      required this.mealId,
      required this.userId,
      required this.clientId,
      required this.position,
      required this.name,
      required this.foodRefKind,
      this.canonicalFoodId,
      this.brandedProductId,
      this.customFoodId,
      required this.quantity,
      required this.unit,
      this.gramsEstimated,
      required this.caloriesKcal,
      required this.proteinG,
      required this.carbsG,
      required this.fatG,
      this.confidence,
      this.sourceType,
      this.sourceId,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meal_id'] = Variable<String>(mealId);
    map['user_id'] = Variable<String>(userId);
    map['client_id'] = Variable<String>(clientId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['food_ref_kind'] = Variable<String>(foodRefKind);
    if (!nullToAbsent || canonicalFoodId != null) {
      map['canonical_food_id'] = Variable<String>(canonicalFoodId);
    }
    if (!nullToAbsent || brandedProductId != null) {
      map['branded_product_id'] = Variable<String>(brandedProductId);
    }
    if (!nullToAbsent || customFoodId != null) {
      map['custom_food_id'] = Variable<String>(customFoodId);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || gramsEstimated != null) {
      map['grams_estimated'] = Variable<double>(gramsEstimated);
    }
    map['calories_kcal'] = Variable<double>(caloriesKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MealItemsLocalCompanion toCompanion(bool nullToAbsent) {
    return MealItemsLocalCompanion(
      id: Value(id),
      mealId: Value(mealId),
      userId: Value(userId),
      clientId: Value(clientId),
      position: Value(position),
      name: Value(name),
      foodRefKind: Value(foodRefKind),
      canonicalFoodId: canonicalFoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalFoodId),
      brandedProductId: brandedProductId == null && nullToAbsent
          ? const Value.absent()
          : Value(brandedProductId),
      customFoodId: customFoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(customFoodId),
      quantity: Value(quantity),
      unit: Value(unit),
      gramsEstimated: gramsEstimated == null && nullToAbsent
          ? const Value.absent()
          : Value(gramsEstimated),
      caloriesKcal: Value(caloriesKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MealItemsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealItemsLocalData(
      id: serializer.fromJson<String>(json['id']),
      mealId: serializer.fromJson<String>(json['mealId']),
      userId: serializer.fromJson<String>(json['userId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      foodRefKind: serializer.fromJson<String>(json['foodRefKind']),
      canonicalFoodId: serializer.fromJson<String?>(json['canonicalFoodId']),
      brandedProductId: serializer.fromJson<String?>(json['brandedProductId']),
      customFoodId: serializer.fromJson<String?>(json['customFoodId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      gramsEstimated: serializer.fromJson<double?>(json['gramsEstimated']),
      caloriesKcal: serializer.fromJson<double>(json['caloriesKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mealId': serializer.toJson<String>(mealId),
      'userId': serializer.toJson<String>(userId),
      'clientId': serializer.toJson<String>(clientId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'foodRefKind': serializer.toJson<String>(foodRefKind),
      'canonicalFoodId': serializer.toJson<String?>(canonicalFoodId),
      'brandedProductId': serializer.toJson<String?>(brandedProductId),
      'customFoodId': serializer.toJson<String?>(customFoodId),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'gramsEstimated': serializer.toJson<double?>(gramsEstimated),
      'caloriesKcal': serializer.toJson<double>(caloriesKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'confidence': serializer.toJson<double?>(confidence),
      'sourceType': serializer.toJson<String?>(sourceType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MealItemsLocalData copyWith(
          {String? id,
          String? mealId,
          String? userId,
          String? clientId,
          int? position,
          String? name,
          String? foodRefKind,
          Value<String?> canonicalFoodId = const Value.absent(),
          Value<String?> brandedProductId = const Value.absent(),
          Value<String?> customFoodId = const Value.absent(),
          double? quantity,
          String? unit,
          Value<double?> gramsEstimated = const Value.absent(),
          double? caloriesKcal,
          double? proteinG,
          double? carbsG,
          double? fatG,
          Value<double?> confidence = const Value.absent(),
          Value<String?> sourceType = const Value.absent(),
          Value<String?> sourceId = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MealItemsLocalData(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        userId: userId ?? this.userId,
        clientId: clientId ?? this.clientId,
        position: position ?? this.position,
        name: name ?? this.name,
        foodRefKind: foodRefKind ?? this.foodRefKind,
        canonicalFoodId: canonicalFoodId.present
            ? canonicalFoodId.value
            : this.canonicalFoodId,
        brandedProductId: brandedProductId.present
            ? brandedProductId.value
            : this.brandedProductId,
        customFoodId:
            customFoodId.present ? customFoodId.value : this.customFoodId,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        gramsEstimated:
            gramsEstimated.present ? gramsEstimated.value : this.gramsEstimated,
        caloriesKcal: caloriesKcal ?? this.caloriesKcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        confidence: confidence.present ? confidence.value : this.confidence,
        sourceType: sourceType.present ? sourceType.value : this.sourceType,
        sourceId: sourceId.present ? sourceId.value : this.sourceId,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MealItemsLocalData copyWithCompanion(MealItemsLocalCompanion data) {
    return MealItemsLocalData(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      userId: data.userId.present ? data.userId.value : this.userId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      foodRefKind:
          data.foodRefKind.present ? data.foodRefKind.value : this.foodRefKind,
      canonicalFoodId: data.canonicalFoodId.present
          ? data.canonicalFoodId.value
          : this.canonicalFoodId,
      brandedProductId: data.brandedProductId.present
          ? data.brandedProductId.value
          : this.brandedProductId,
      customFoodId: data.customFoodId.present
          ? data.customFoodId.value
          : this.customFoodId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      gramsEstimated: data.gramsEstimated.present
          ? data.gramsEstimated.value
          : this.gramsEstimated,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealItemsLocalData(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('foodRefKind: $foodRefKind, ')
          ..write('canonicalFoodId: $canonicalFoodId, ')
          ..write('brandedProductId: $brandedProductId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('gramsEstimated: $gramsEstimated, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidence: $confidence, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        mealId,
        userId,
        clientId,
        position,
        name,
        foodRefKind,
        canonicalFoodId,
        brandedProductId,
        customFoodId,
        quantity,
        unit,
        gramsEstimated,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        confidence,
        sourceType,
        sourceId,
        notes,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealItemsLocalData &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.userId == this.userId &&
          other.clientId == this.clientId &&
          other.position == this.position &&
          other.name == this.name &&
          other.foodRefKind == this.foodRefKind &&
          other.canonicalFoodId == this.canonicalFoodId &&
          other.brandedProductId == this.brandedProductId &&
          other.customFoodId == this.customFoodId &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.gramsEstimated == this.gramsEstimated &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.confidence == this.confidence &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MealItemsLocalCompanion extends UpdateCompanion<MealItemsLocalData> {
  final Value<String> id;
  final Value<String> mealId;
  final Value<String> userId;
  final Value<String> clientId;
  final Value<int> position;
  final Value<String> name;
  final Value<String> foodRefKind;
  final Value<String?> canonicalFoodId;
  final Value<String?> brandedProductId;
  final Value<String?> customFoodId;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<double?> gramsEstimated;
  final Value<double> caloriesKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<double?> confidence;
  final Value<String?> sourceType;
  final Value<String?> sourceId;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MealItemsLocalCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.userId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.foodRefKind = const Value.absent(),
    this.canonicalFoodId = const Value.absent(),
    this.brandedProductId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.gramsEstimated = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.confidence = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealItemsLocalCompanion.insert({
    required String id,
    required String mealId,
    required String userId,
    required String clientId,
    required int position,
    required String name,
    this.foodRefKind = const Value.absent(),
    this.canonicalFoodId = const Value.absent(),
    this.brandedProductId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    required double quantity,
    required String unit,
    this.gramsEstimated = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.confidence = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        mealId = Value(mealId),
        userId = Value(userId),
        clientId = Value(clientId),
        position = Value(position),
        name = Value(name),
        quantity = Value(quantity),
        unit = Value(unit);
  static Insertable<MealItemsLocalData> custom({
    Expression<String>? id,
    Expression<String>? mealId,
    Expression<String>? userId,
    Expression<String>? clientId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? foodRefKind,
    Expression<String>? canonicalFoodId,
    Expression<String>? brandedProductId,
    Expression<String>? customFoodId,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<double>? gramsEstimated,
    Expression<double>? caloriesKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<double>? confidence,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (userId != null) 'user_id': userId,
      if (clientId != null) 'client_id': clientId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (foodRefKind != null) 'food_ref_kind': foodRefKind,
      if (canonicalFoodId != null) 'canonical_food_id': canonicalFoodId,
      if (brandedProductId != null) 'branded_product_id': brandedProductId,
      if (customFoodId != null) 'custom_food_id': customFoodId,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (gramsEstimated != null) 'grams_estimated': gramsEstimated,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (confidence != null) 'confidence': confidence,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealItemsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? mealId,
      Value<String>? userId,
      Value<String>? clientId,
      Value<int>? position,
      Value<String>? name,
      Value<String>? foodRefKind,
      Value<String?>? canonicalFoodId,
      Value<String?>? brandedProductId,
      Value<String?>? customFoodId,
      Value<double>? quantity,
      Value<String>? unit,
      Value<double?>? gramsEstimated,
      Value<double>? caloriesKcal,
      Value<double>? proteinG,
      Value<double>? carbsG,
      Value<double>? fatG,
      Value<double?>? confidence,
      Value<String?>? sourceType,
      Value<String?>? sourceId,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return MealItemsLocalCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      position: position ?? this.position,
      name: name ?? this.name,
      foodRefKind: foodRefKind ?? this.foodRefKind,
      canonicalFoodId: canonicalFoodId ?? this.canonicalFoodId,
      brandedProductId: brandedProductId ?? this.brandedProductId,
      customFoodId: customFoodId ?? this.customFoodId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      gramsEstimated: gramsEstimated ?? this.gramsEstimated,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      confidence: confidence ?? this.confidence,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (foodRefKind.present) {
      map['food_ref_kind'] = Variable<String>(foodRefKind.value);
    }
    if (canonicalFoodId.present) {
      map['canonical_food_id'] = Variable<String>(canonicalFoodId.value);
    }
    if (brandedProductId.present) {
      map['branded_product_id'] = Variable<String>(brandedProductId.value);
    }
    if (customFoodId.present) {
      map['custom_food_id'] = Variable<String>(customFoodId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (gramsEstimated.present) {
      map['grams_estimated'] = Variable<double>(gramsEstimated.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<double>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealItemsLocalCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('foodRefKind: $foodRefKind, ')
          ..write('canonicalFoodId: $canonicalFoodId, ')
          ..write('brandedProductId: $brandedProductId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('gramsEstimated: $gramsEstimated, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('confidence: $confidence, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealTemplatesLocalTable extends MealTemplatesLocal
    with TableInfo<$MealTemplatesLocalTable, MealTemplatesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTemplatesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _snapshotJsonMeta =
      const VerificationMeta('snapshotJson');
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
      'snapshot_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMealIdMeta =
      const VerificationMeta('sourceMealId');
  @override
  late final GeneratedColumn<String> sourceMealId = GeneratedColumn<String>(
      'source_meal_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
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
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        clientId,
        title,
        snapshotJson,
        sourceMealId,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_templates_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<MealTemplatesLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
          _snapshotJsonMeta,
          snapshotJson.isAcceptableOrUnknown(
              data['snapshot_json']!, _snapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('source_meal_id')) {
      context.handle(
          _sourceMealIdMeta,
          sourceMealId.isAcceptableOrUnknown(
              data['source_meal_id']!, _sourceMealIdMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTemplatesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTemplatesLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      snapshotJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_json'])!,
      sourceMealId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_meal_id']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $MealTemplatesLocalTable createAlias(String alias) {
    return $MealTemplatesLocalTable(attachedDatabase, alias);
  }
}

class MealTemplatesLocalData extends DataClass
    implements Insertable<MealTemplatesLocalData> {
  final String id;
  final String userId;
  final String clientId;
  final String title;
  final String snapshotJson;
  final String? sourceMealId;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const MealTemplatesLocalData(
      {required this.id,
      required this.userId,
      required this.clientId,
      required this.title,
      required this.snapshotJson,
      this.sourceMealId,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['client_id'] = Variable<String>(clientId);
    map['title'] = Variable<String>(title);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    if (!nullToAbsent || sourceMealId != null) {
      map['source_meal_id'] = Variable<String>(sourceMealId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  MealTemplatesLocalCompanion toCompanion(bool nullToAbsent) {
    return MealTemplatesLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      clientId: Value(clientId),
      title: Value(title),
      snapshotJson: Value(snapshotJson),
      sourceMealId: sourceMealId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMealId),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MealTemplatesLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTemplatesLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      title: serializer.fromJson<String>(json['title']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      sourceMealId: serializer.fromJson<String?>(json['sourceMealId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'clientId': serializer.toJson<String>(clientId),
      'title': serializer.toJson<String>(title),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'sourceMealId': serializer.toJson<String?>(sourceMealId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  MealTemplatesLocalData copyWith(
          {String? id,
          String? userId,
          String? clientId,
          String? title,
          String? snapshotJson,
          Value<String?> sourceMealId = const Value.absent(),
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      MealTemplatesLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        clientId: clientId ?? this.clientId,
        title: title ?? this.title,
        snapshotJson: snapshotJson ?? this.snapshotJson,
        sourceMealId:
            sourceMealId.present ? sourceMealId.value : this.sourceMealId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  MealTemplatesLocalData copyWithCompanion(MealTemplatesLocalCompanion data) {
    return MealTemplatesLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      title: data.title.present ? data.title.value : this.title,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      sourceMealId: data.sourceMealId.present
          ? data.sourceMealId.value
          : this.sourceMealId,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplatesLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('title: $title, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('sourceMealId: $sourceMealId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, clientId, title, snapshotJson,
      sourceMealId, syncStatus, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTemplatesLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.clientId == this.clientId &&
          other.title == this.title &&
          other.snapshotJson == this.snapshotJson &&
          other.sourceMealId == this.sourceMealId &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MealTemplatesLocalCompanion
    extends UpdateCompanion<MealTemplatesLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> clientId;
  final Value<String> title;
  final Value<String> snapshotJson;
  final Value<String?> sourceMealId;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const MealTemplatesLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.title = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.sourceMealId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealTemplatesLocalCompanion.insert({
    required String id,
    required String userId,
    required String clientId,
    required String title,
    required String snapshotJson,
    this.sourceMealId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        clientId = Value(clientId),
        title = Value(title),
        snapshotJson = Value(snapshotJson);
  static Insertable<MealTemplatesLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? clientId,
    Expression<String>? title,
    Expression<String>? snapshotJson,
    Expression<String>? sourceMealId,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (clientId != null) 'client_id': clientId,
      if (title != null) 'title': title,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (sourceMealId != null) 'source_meal_id': sourceMealId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealTemplatesLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? clientId,
      Value<String>? title,
      Value<String>? snapshotJson,
      Value<String?>? sourceMealId,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return MealTemplatesLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      sourceMealId: sourceMealId ?? this.sourceMealId,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (sourceMealId.present) {
      map['source_meal_id'] = Variable<String>(sourceMealId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplatesLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('title: $title, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('sourceMealId: $sourceMealId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomFoodsLocalTable extends CustomFoodsLocal
    with TableInfo<$CustomFoodsLocalTable, CustomFoodsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFoodsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
      'brand', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _servingQuantityMeta =
      const VerificationMeta('servingQuantity');
  @override
  late final GeneratedColumn<double> servingQuantity = GeneratedColumn<double>(
      'serving_quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _servingUnitMeta =
      const VerificationMeta('servingUnit');
  @override
  late final GeneratedColumn<String> servingUnit = GeneratedColumn<String>(
      'serving_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _servingGramsMeta =
      const VerificationMeta('servingGrams');
  @override
  late final GeneratedColumn<double> servingGrams = GeneratedColumn<double>(
      'serving_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _caloriesKcalMeta =
      const VerificationMeta('caloriesKcal');
  @override
  late final GeneratedColumn<double> caloriesKcal = GeneratedColumn<double>(
      'calories_kcal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
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
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        clientId,
        name,
        brand,
        servingQuantity,
        servingUnit,
        servingGrams,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_foods_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<CustomFoodsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
          _brandMeta, brand.isAcceptableOrUnknown(data['brand']!, _brandMeta));
    }
    if (data.containsKey('serving_quantity')) {
      context.handle(
          _servingQuantityMeta,
          servingQuantity.isAcceptableOrUnknown(
              data['serving_quantity']!, _servingQuantityMeta));
    }
    if (data.containsKey('serving_unit')) {
      context.handle(
          _servingUnitMeta,
          servingUnit.isAcceptableOrUnknown(
              data['serving_unit']!, _servingUnitMeta));
    }
    if (data.containsKey('serving_grams')) {
      context.handle(
          _servingGramsMeta,
          servingGrams.isAcceptableOrUnknown(
              data['serving_grams']!, _servingGramsMeta));
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
          _caloriesKcalMeta,
          caloriesKcal.isAcceptableOrUnknown(
              data['calories_kcal']!, _caloriesKcalMeta));
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFoodsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFoodsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      brand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brand']),
      servingQuantity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}serving_quantity']),
      servingUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}serving_unit']),
      servingGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}serving_grams']),
      caloriesKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calories_kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $CustomFoodsLocalTable createAlias(String alias) {
    return $CustomFoodsLocalTable(attachedDatabase, alias);
  }
}

class CustomFoodsLocalData extends DataClass
    implements Insertable<CustomFoodsLocalData> {
  final String id;
  final String userId;
  final String clientId;
  final String name;
  final String? brand;
  final double? servingQuantity;
  final String? servingUnit;
  final double? servingGrams;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const CustomFoodsLocalData(
      {required this.id,
      required this.userId,
      required this.clientId,
      required this.name,
      this.brand,
      this.servingQuantity,
      this.servingUnit,
      this.servingGrams,
      required this.caloriesKcal,
      required this.proteinG,
      required this.carbsG,
      required this.fatG,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['client_id'] = Variable<String>(clientId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || servingQuantity != null) {
      map['serving_quantity'] = Variable<double>(servingQuantity);
    }
    if (!nullToAbsent || servingUnit != null) {
      map['serving_unit'] = Variable<String>(servingUnit);
    }
    if (!nullToAbsent || servingGrams != null) {
      map['serving_grams'] = Variable<double>(servingGrams);
    }
    map['calories_kcal'] = Variable<double>(caloriesKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CustomFoodsLocalCompanion toCompanion(bool nullToAbsent) {
    return CustomFoodsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      clientId: Value(clientId),
      name: Value(name),
      brand:
          brand == null && nullToAbsent ? const Value.absent() : Value(brand),
      servingQuantity: servingQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(servingQuantity),
      servingUnit: servingUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(servingUnit),
      servingGrams: servingGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(servingGrams),
      caloriesKcal: Value(caloriesKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CustomFoodsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFoodsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      servingQuantity: serializer.fromJson<double?>(json['servingQuantity']),
      servingUnit: serializer.fromJson<String?>(json['servingUnit']),
      servingGrams: serializer.fromJson<double?>(json['servingGrams']),
      caloriesKcal: serializer.fromJson<double>(json['caloriesKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'clientId': serializer.toJson<String>(clientId),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'servingQuantity': serializer.toJson<double?>(servingQuantity),
      'servingUnit': serializer.toJson<String?>(servingUnit),
      'servingGrams': serializer.toJson<double?>(servingGrams),
      'caloriesKcal': serializer.toJson<double>(caloriesKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CustomFoodsLocalData copyWith(
          {String? id,
          String? userId,
          String? clientId,
          String? name,
          Value<String?> brand = const Value.absent(),
          Value<double?> servingQuantity = const Value.absent(),
          Value<String?> servingUnit = const Value.absent(),
          Value<double?> servingGrams = const Value.absent(),
          double? caloriesKcal,
          double? proteinG,
          double? carbsG,
          double? fatG,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      CustomFoodsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        clientId: clientId ?? this.clientId,
        name: name ?? this.name,
        brand: brand.present ? brand.value : this.brand,
        servingQuantity: servingQuantity.present
            ? servingQuantity.value
            : this.servingQuantity,
        servingUnit: servingUnit.present ? servingUnit.value : this.servingUnit,
        servingGrams:
            servingGrams.present ? servingGrams.value : this.servingGrams,
        caloriesKcal: caloriesKcal ?? this.caloriesKcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  CustomFoodsLocalData copyWithCompanion(CustomFoodsLocalCompanion data) {
    return CustomFoodsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      servingQuantity: data.servingQuantity.present
          ? data.servingQuantity.value
          : this.servingQuantity,
      servingUnit:
          data.servingUnit.present ? data.servingUnit.value : this.servingUnit,
      servingGrams: data.servingGrams.present
          ? data.servingGrams.value
          : this.servingGrams,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFoodsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('servingQuantity: $servingQuantity, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      clientId,
      name,
      brand,
      servingQuantity,
      servingUnit,
      servingGrams,
      caloriesKcal,
      proteinG,
      carbsG,
      fatG,
      syncStatus,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFoodsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.clientId == this.clientId &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.servingQuantity == this.servingQuantity &&
          other.servingUnit == this.servingUnit &&
          other.servingGrams == this.servingGrams &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CustomFoodsLocalCompanion extends UpdateCompanion<CustomFoodsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> clientId;
  final Value<String> name;
  final Value<String?> brand;
  final Value<double?> servingQuantity;
  final Value<String?> servingUnit;
  final Value<double?> servingGrams;
  final Value<double> caloriesKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CustomFoodsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.servingQuantity = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomFoodsLocalCompanion.insert({
    required String id,
    required String userId,
    required String clientId,
    required String name,
    this.brand = const Value.absent(),
    this.servingQuantity = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.servingGrams = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        clientId = Value(clientId),
        name = Value(name);
  static Insertable<CustomFoodsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? clientId,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? servingQuantity,
    Expression<String>? servingUnit,
    Expression<double>? servingGrams,
    Expression<double>? caloriesKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (clientId != null) 'client_id': clientId,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (servingQuantity != null) 'serving_quantity': servingQuantity,
      if (servingUnit != null) 'serving_unit': servingUnit,
      if (servingGrams != null) 'serving_grams': servingGrams,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomFoodsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? clientId,
      Value<String>? name,
      Value<String?>? brand,
      Value<double?>? servingQuantity,
      Value<String?>? servingUnit,
      Value<double?>? servingGrams,
      Value<double>? caloriesKcal,
      Value<double>? proteinG,
      Value<double>? carbsG,
      Value<double>? fatG,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return CustomFoodsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      servingUnit: servingUnit ?? this.servingUnit,
      servingGrams: servingGrams ?? this.servingGrams,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (servingQuantity.present) {
      map['serving_quantity'] = Variable<double>(servingQuantity.value);
    }
    if (servingUnit.present) {
      map['serving_unit'] = Variable<String>(servingUnit.value);
    }
    if (servingGrams.present) {
      map['serving_grams'] = Variable<double>(servingGrams.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<double>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFoodsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('clientId: $clientId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('servingQuantity: $servingQuantity, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('servingGrams: $servingGrams, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyRollupsLocalTable extends DailyRollupsLocal
    with TableInfo<$DailyRollupsLocalTable, DailyRollupsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRollupsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
      'day', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _caloriesKcalMeta =
      const VerificationMeta('caloriesKcal');
  @override
  late final GeneratedColumn<double> caloriesKcal = GeneratedColumn<double>(
      'calories_kcal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _mealCountMeta =
      const VerificationMeta('mealCount');
  @override
  late final GeneratedColumn<int> mealCount = GeneratedColumn<int>(
      'meal_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hasPhotoMealMeta =
      const VerificationMeta('hasPhotoMeal');
  @override
  late final GeneratedColumn<bool> hasPhotoMeal = GeneratedColumn<bool>(
      'has_photo_meal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_photo_meal" IN (0, 1))'),
      defaultValue: const Constant(false));
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
        userId,
        day,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        mealCount,
        hasPhotoMeal,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_rollups_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<DailyRollupsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
          _caloriesKcalMeta,
          caloriesKcal.isAcceptableOrUnknown(
              data['calories_kcal']!, _caloriesKcalMeta));
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('meal_count')) {
      context.handle(_mealCountMeta,
          mealCount.isAcceptableOrUnknown(data['meal_count']!, _mealCountMeta));
    }
    if (data.containsKey('has_photo_meal')) {
      context.handle(
          _hasPhotoMealMeta,
          hasPhotoMeal.isAcceptableOrUnknown(
              data['has_photo_meal']!, _hasPhotoMealMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, day};
  @override
  DailyRollupsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRollupsLocalData(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}day'])!,
      caloriesKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calories_kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      mealCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meal_count'])!,
      hasPhotoMeal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_photo_meal'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DailyRollupsLocalTable createAlias(String alias) {
    return $DailyRollupsLocalTable(attachedDatabase, alias);
  }
}

class DailyRollupsLocalData extends DataClass
    implements Insertable<DailyRollupsLocalData> {
  final String userId;
  final DateTime day;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;
  final bool hasPhotoMeal;
  final DateTime updatedAt;
  const DailyRollupsLocalData(
      {required this.userId,
      required this.day,
      required this.caloriesKcal,
      required this.proteinG,
      required this.carbsG,
      required this.fatG,
      required this.mealCount,
      required this.hasPhotoMeal,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['day'] = Variable<DateTime>(day);
    map['calories_kcal'] = Variable<double>(caloriesKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['meal_count'] = Variable<int>(mealCount);
    map['has_photo_meal'] = Variable<bool>(hasPhotoMeal);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyRollupsLocalCompanion toCompanion(bool nullToAbsent) {
    return DailyRollupsLocalCompanion(
      userId: Value(userId),
      day: Value(day),
      caloriesKcal: Value(caloriesKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      mealCount: Value(mealCount),
      hasPhotoMeal: Value(hasPhotoMeal),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyRollupsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRollupsLocalData(
      userId: serializer.fromJson<String>(json['userId']),
      day: serializer.fromJson<DateTime>(json['day']),
      caloriesKcal: serializer.fromJson<double>(json['caloriesKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      mealCount: serializer.fromJson<int>(json['mealCount']),
      hasPhotoMeal: serializer.fromJson<bool>(json['hasPhotoMeal']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'day': serializer.toJson<DateTime>(day),
      'caloriesKcal': serializer.toJson<double>(caloriesKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'mealCount': serializer.toJson<int>(mealCount),
      'hasPhotoMeal': serializer.toJson<bool>(hasPhotoMeal),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyRollupsLocalData copyWith(
          {String? userId,
          DateTime? day,
          double? caloriesKcal,
          double? proteinG,
          double? carbsG,
          double? fatG,
          int? mealCount,
          bool? hasPhotoMeal,
          DateTime? updatedAt}) =>
      DailyRollupsLocalData(
        userId: userId ?? this.userId,
        day: day ?? this.day,
        caloriesKcal: caloriesKcal ?? this.caloriesKcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        mealCount: mealCount ?? this.mealCount,
        hasPhotoMeal: hasPhotoMeal ?? this.hasPhotoMeal,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DailyRollupsLocalData copyWithCompanion(DailyRollupsLocalCompanion data) {
    return DailyRollupsLocalData(
      userId: data.userId.present ? data.userId.value : this.userId,
      day: data.day.present ? data.day.value : this.day,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      mealCount: data.mealCount.present ? data.mealCount.value : this.mealCount,
      hasPhotoMeal: data.hasPhotoMeal.present
          ? data.hasPhotoMeal.value
          : this.hasPhotoMeal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRollupsLocalData(')
          ..write('userId: $userId, ')
          ..write('day: $day, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('mealCount: $mealCount, ')
          ..write('hasPhotoMeal: $hasPhotoMeal, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, day, caloriesKcal, proteinG, carbsG,
      fatG, mealCount, hasPhotoMeal, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRollupsLocalData &&
          other.userId == this.userId &&
          other.day == this.day &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.mealCount == this.mealCount &&
          other.hasPhotoMeal == this.hasPhotoMeal &&
          other.updatedAt == this.updatedAt);
}

class DailyRollupsLocalCompanion
    extends UpdateCompanion<DailyRollupsLocalData> {
  final Value<String> userId;
  final Value<DateTime> day;
  final Value<double> caloriesKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int> mealCount;
  final Value<bool> hasPhotoMeal;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyRollupsLocalCompanion({
    this.userId = const Value.absent(),
    this.day = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.mealCount = const Value.absent(),
    this.hasPhotoMeal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyRollupsLocalCompanion.insert({
    required String userId,
    required DateTime day,
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.mealCount = const Value.absent(),
    this.hasPhotoMeal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        day = Value(day);
  static Insertable<DailyRollupsLocalData> custom({
    Expression<String>? userId,
    Expression<DateTime>? day,
    Expression<double>? caloriesKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<int>? mealCount,
    Expression<bool>? hasPhotoMeal,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (day != null) 'day': day,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (mealCount != null) 'meal_count': mealCount,
      if (hasPhotoMeal != null) 'has_photo_meal': hasPhotoMeal,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyRollupsLocalCompanion copyWith(
      {Value<String>? userId,
      Value<DateTime>? day,
      Value<double>? caloriesKcal,
      Value<double>? proteinG,
      Value<double>? carbsG,
      Value<double>? fatG,
      Value<int>? mealCount,
      Value<bool>? hasPhotoMeal,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DailyRollupsLocalCompanion(
      userId: userId ?? this.userId,
      day: day ?? this.day,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      mealCount: mealCount ?? this.mealCount,
      hasPhotoMeal: hasPhotoMeal ?? this.hasPhotoMeal,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<double>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (mealCount.present) {
      map['meal_count'] = Variable<int>(mealCount.value);
    }
    if (hasPhotoMeal.present) {
      map['has_photo_meal'] = Variable<bool>(hasPhotoMeal.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRollupsLocalCompanion(')
          ..write('userId: $userId, ')
          ..write('day: $day, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('mealCount: $mealCount, ')
          ..write('hasPhotoMeal: $hasPhotoMeal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CorrectionEventsLocalTable extends CorrectionEventsLocal
    with TableInfo<$CorrectionEventsLocalTable, CorrectionEventsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CorrectionEventsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
      'meal_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _analysisJobIdMeta =
      const VerificationMeta('analysisJobId');
  @override
  late final GeneratedColumn<String> analysisJobId = GeneratedColumn<String>(
      'analysis_job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldNameMeta =
      const VerificationMeta('fieldName');
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
      'field_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _beforeValueJsonMeta =
      const VerificationMeta('beforeValueJson');
  @override
  late final GeneratedColumn<String> beforeValueJson = GeneratedColumn<String>(
      'before_value_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _afterValueJsonMeta =
      const VerificationMeta('afterValueJson');
  @override
  late final GeneratedColumn<String> afterValueJson = GeneratedColumn<String>(
      'after_value_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        userId,
        mealId,
        analysisJobId,
        eventType,
        fieldName,
        beforeValueJson,
        afterValueJson,
        reason,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'correction_events_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<CorrectionEventsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    }
    if (data.containsKey('analysis_job_id')) {
      context.handle(
          _analysisJobIdMeta,
          analysisJobId.isAcceptableOrUnknown(
              data['analysis_job_id']!, _analysisJobIdMeta));
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(_fieldNameMeta,
          fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta));
    }
    if (data.containsKey('before_value_json')) {
      context.handle(
          _beforeValueJsonMeta,
          beforeValueJson.isAcceptableOrUnknown(
              data['before_value_json']!, _beforeValueJsonMeta));
    }
    if (data.containsKey('after_value_json')) {
      context.handle(
          _afterValueJsonMeta,
          afterValueJson.isAcceptableOrUnknown(
              data['after_value_json']!, _afterValueJsonMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
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
  CorrectionEventsLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CorrectionEventsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_id']),
      analysisJobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis_job_id']),
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      fieldName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_name']),
      beforeValueJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}before_value_json']),
      afterValueJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}after_value_json']),
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CorrectionEventsLocalTable createAlias(String alias) {
    return $CorrectionEventsLocalTable(attachedDatabase, alias);
  }
}

class CorrectionEventsLocalData extends DataClass
    implements Insertable<CorrectionEventsLocalData> {
  final String id;
  final String userId;
  final String? mealId;
  final String? analysisJobId;
  final String eventType;
  final String? fieldName;
  final String? beforeValueJson;
  final String? afterValueJson;
  final String? reason;
  final DateTime createdAt;
  const CorrectionEventsLocalData(
      {required this.id,
      required this.userId,
      this.mealId,
      this.analysisJobId,
      required this.eventType,
      this.fieldName,
      this.beforeValueJson,
      this.afterValueJson,
      this.reason,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || mealId != null) {
      map['meal_id'] = Variable<String>(mealId);
    }
    if (!nullToAbsent || analysisJobId != null) {
      map['analysis_job_id'] = Variable<String>(analysisJobId);
    }
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || fieldName != null) {
      map['field_name'] = Variable<String>(fieldName);
    }
    if (!nullToAbsent || beforeValueJson != null) {
      map['before_value_json'] = Variable<String>(beforeValueJson);
    }
    if (!nullToAbsent || afterValueJson != null) {
      map['after_value_json'] = Variable<String>(afterValueJson);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CorrectionEventsLocalCompanion toCompanion(bool nullToAbsent) {
    return CorrectionEventsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      mealId:
          mealId == null && nullToAbsent ? const Value.absent() : Value(mealId),
      analysisJobId: analysisJobId == null && nullToAbsent
          ? const Value.absent()
          : Value(analysisJobId),
      eventType: Value(eventType),
      fieldName: fieldName == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldName),
      beforeValueJson: beforeValueJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeValueJson),
      afterValueJson: afterValueJson == null && nullToAbsent
          ? const Value.absent()
          : Value(afterValueJson),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory CorrectionEventsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CorrectionEventsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      mealId: serializer.fromJson<String?>(json['mealId']),
      analysisJobId: serializer.fromJson<String?>(json['analysisJobId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      fieldName: serializer.fromJson<String?>(json['fieldName']),
      beforeValueJson: serializer.fromJson<String?>(json['beforeValueJson']),
      afterValueJson: serializer.fromJson<String?>(json['afterValueJson']),
      reason: serializer.fromJson<String?>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'mealId': serializer.toJson<String?>(mealId),
      'analysisJobId': serializer.toJson<String?>(analysisJobId),
      'eventType': serializer.toJson<String>(eventType),
      'fieldName': serializer.toJson<String?>(fieldName),
      'beforeValueJson': serializer.toJson<String?>(beforeValueJson),
      'afterValueJson': serializer.toJson<String?>(afterValueJson),
      'reason': serializer.toJson<String?>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CorrectionEventsLocalData copyWith(
          {String? id,
          String? userId,
          Value<String?> mealId = const Value.absent(),
          Value<String?> analysisJobId = const Value.absent(),
          String? eventType,
          Value<String?> fieldName = const Value.absent(),
          Value<String?> beforeValueJson = const Value.absent(),
          Value<String?> afterValueJson = const Value.absent(),
          Value<String?> reason = const Value.absent(),
          DateTime? createdAt}) =>
      CorrectionEventsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        mealId: mealId.present ? mealId.value : this.mealId,
        analysisJobId:
            analysisJobId.present ? analysisJobId.value : this.analysisJobId,
        eventType: eventType ?? this.eventType,
        fieldName: fieldName.present ? fieldName.value : this.fieldName,
        beforeValueJson: beforeValueJson.present
            ? beforeValueJson.value
            : this.beforeValueJson,
        afterValueJson:
            afterValueJson.present ? afterValueJson.value : this.afterValueJson,
        reason: reason.present ? reason.value : this.reason,
        createdAt: createdAt ?? this.createdAt,
      );
  CorrectionEventsLocalData copyWithCompanion(
      CorrectionEventsLocalCompanion data) {
    return CorrectionEventsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      analysisJobId: data.analysisJobId.present
          ? data.analysisJobId.value
          : this.analysisJobId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      beforeValueJson: data.beforeValueJson.present
          ? data.beforeValueJson.value
          : this.beforeValueJson,
      afterValueJson: data.afterValueJson.present
          ? data.afterValueJson.value
          : this.afterValueJson,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionEventsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mealId: $mealId, ')
          ..write('analysisJobId: $analysisJobId, ')
          ..write('eventType: $eventType, ')
          ..write('fieldName: $fieldName, ')
          ..write('beforeValueJson: $beforeValueJson, ')
          ..write('afterValueJson: $afterValueJson, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, mealId, analysisJobId, eventType,
      fieldName, beforeValueJson, afterValueJson, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CorrectionEventsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.mealId == this.mealId &&
          other.analysisJobId == this.analysisJobId &&
          other.eventType == this.eventType &&
          other.fieldName == this.fieldName &&
          other.beforeValueJson == this.beforeValueJson &&
          other.afterValueJson == this.afterValueJson &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class CorrectionEventsLocalCompanion
    extends UpdateCompanion<CorrectionEventsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> mealId;
  final Value<String?> analysisJobId;
  final Value<String> eventType;
  final Value<String?> fieldName;
  final Value<String?> beforeValueJson;
  final Value<String?> afterValueJson;
  final Value<String?> reason;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CorrectionEventsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.mealId = const Value.absent(),
    this.analysisJobId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.beforeValueJson = const Value.absent(),
    this.afterValueJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CorrectionEventsLocalCompanion.insert({
    required String id,
    required String userId,
    this.mealId = const Value.absent(),
    this.analysisJobId = const Value.absent(),
    required String eventType,
    this.fieldName = const Value.absent(),
    this.beforeValueJson = const Value.absent(),
    this.afterValueJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        eventType = Value(eventType);
  static Insertable<CorrectionEventsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? mealId,
    Expression<String>? analysisJobId,
    Expression<String>? eventType,
    Expression<String>? fieldName,
    Expression<String>? beforeValueJson,
    Expression<String>? afterValueJson,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (mealId != null) 'meal_id': mealId,
      if (analysisJobId != null) 'analysis_job_id': analysisJobId,
      if (eventType != null) 'event_type': eventType,
      if (fieldName != null) 'field_name': fieldName,
      if (beforeValueJson != null) 'before_value_json': beforeValueJson,
      if (afterValueJson != null) 'after_value_json': afterValueJson,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CorrectionEventsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? mealId,
      Value<String?>? analysisJobId,
      Value<String>? eventType,
      Value<String?>? fieldName,
      Value<String?>? beforeValueJson,
      Value<String?>? afterValueJson,
      Value<String?>? reason,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CorrectionEventsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mealId: mealId ?? this.mealId,
      analysisJobId: analysisJobId ?? this.analysisJobId,
      eventType: eventType ?? this.eventType,
      fieldName: fieldName ?? this.fieldName,
      beforeValueJson: beforeValueJson ?? this.beforeValueJson,
      afterValueJson: afterValueJson ?? this.afterValueJson,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (analysisJobId.present) {
      map['analysis_job_id'] = Variable<String>(analysisJobId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (beforeValueJson.present) {
      map['before_value_json'] = Variable<String>(beforeValueJson.value);
    }
    if (afterValueJson.present) {
      map['after_value_json'] = Variable<String>(afterValueJson.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionEventsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mealId: $mealId, ')
          ..write('analysisJobId: $analysisJobId, ')
          ..write('eventType: $eventType, ')
          ..write('fieldName: $fieldName, ')
          ..write('beforeValueJson: $beforeValueJson, ')
          ..write('afterValueJson: $afterValueJson, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeeklyInsightsLocalTable extends WeeklyInsightsLocal
    with TableInfo<$WeeklyInsightsLocalTable, WeeklyInsightsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyInsightsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<DateTime> weekStart = GeneratedColumn<DateTime>(
      'week_start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _insightTypeMeta =
      const VerificationMeta('insightType');
  @override
  late final GeneratedColumn<String> insightType = GeneratedColumn<String>(
      'insight_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ready'));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
        userId,
        weekStart,
        insightType,
        title,
        summary,
        payloadJson,
        status,
        generatedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_insights_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<WeeklyInsightsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('insight_type')) {
      context.handle(
          _insightTypeMeta,
          insightType.isAcceptableOrUnknown(
              data['insight_type']!, _insightTypeMeta));
    } else if (isInserting) {
      context.missing(_insightTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
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
  WeeklyInsightsLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyInsightsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}week_start'])!,
      insightType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}insight_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WeeklyInsightsLocalTable createAlias(String alias) {
    return $WeeklyInsightsLocalTable(attachedDatabase, alias);
  }
}

class WeeklyInsightsLocalData extends DataClass
    implements Insertable<WeeklyInsightsLocalData> {
  final String id;
  final String userId;
  final DateTime weekStart;
  final String insightType;
  final String title;
  final String summary;
  final String payloadJson;
  final String status;
  final DateTime? generatedAt;
  final DateTime updatedAt;
  const WeeklyInsightsLocalData(
      {required this.id,
      required this.userId,
      required this.weekStart,
      required this.insightType,
      required this.title,
      required this.summary,
      required this.payloadJson,
      required this.status,
      this.generatedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['week_start'] = Variable<DateTime>(weekStart);
    map['insight_type'] = Variable<String>(insightType);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || generatedAt != null) {
      map['generated_at'] = Variable<DateTime>(generatedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WeeklyInsightsLocalCompanion toCompanion(bool nullToAbsent) {
    return WeeklyInsightsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      weekStart: Value(weekStart),
      insightType: Value(insightType),
      title: Value(title),
      summary: Value(summary),
      payloadJson: Value(payloadJson),
      status: Value(status),
      generatedAt: generatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(generatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeeklyInsightsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyInsightsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      weekStart: serializer.fromJson<DateTime>(json['weekStart']),
      insightType: serializer.fromJson<String>(json['insightType']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      generatedAt: serializer.fromJson<DateTime?>(json['generatedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'weekStart': serializer.toJson<DateTime>(weekStart),
      'insightType': serializer.toJson<String>(insightType),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'generatedAt': serializer.toJson<DateTime?>(generatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WeeklyInsightsLocalData copyWith(
          {String? id,
          String? userId,
          DateTime? weekStart,
          String? insightType,
          String? title,
          String? summary,
          String? payloadJson,
          String? status,
          Value<DateTime?> generatedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      WeeklyInsightsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        weekStart: weekStart ?? this.weekStart,
        insightType: insightType ?? this.insightType,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        payloadJson: payloadJson ?? this.payloadJson,
        status: status ?? this.status,
        generatedAt: generatedAt.present ? generatedAt.value : this.generatedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WeeklyInsightsLocalData copyWithCompanion(WeeklyInsightsLocalCompanion data) {
    return WeeklyInsightsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      insightType:
          data.insightType.present ? data.insightType.value : this.insightType,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyInsightsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('weekStart: $weekStart, ')
          ..write('insightType: $insightType, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, weekStart, insightType, title,
      summary, payloadJson, status, generatedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyInsightsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.weekStart == this.weekStart &&
          other.insightType == this.insightType &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.generatedAt == this.generatedAt &&
          other.updatedAt == this.updatedAt);
}

class WeeklyInsightsLocalCompanion
    extends UpdateCompanion<WeeklyInsightsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> weekStart;
  final Value<String> insightType;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<DateTime?> generatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WeeklyInsightsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.insightType = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeeklyInsightsLocalCompanion.insert({
    required String id,
    required String userId,
    required DateTime weekStart,
    required String insightType,
    required String title,
    required String summary,
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        weekStart = Value(weekStart),
        insightType = Value(insightType),
        title = Value(title),
        summary = Value(summary);
  static Insertable<WeeklyInsightsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? weekStart,
    Expression<String>? insightType,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<DateTime>? generatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (weekStart != null) 'week_start': weekStart,
      if (insightType != null) 'insight_type': insightType,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeeklyInsightsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? weekStart,
      Value<String>? insightType,
      Value<String>? title,
      Value<String>? summary,
      Value<String>? payloadJson,
      Value<String>? status,
      Value<DateTime?>? generatedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return WeeklyInsightsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStart: weekStart ?? this.weekStart,
      insightType: insightType ?? this.insightType,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<DateTime>(weekStart.value);
    }
    if (insightType.present) {
      map['insight_type'] = Variable<String>(insightType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyInsightsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('weekStart: $weekStart, ')
          ..write('insightType: $insightType, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserFoodDefaultsLocalTable extends UserFoodDefaultsLocal
    with TableInfo<$UserFoodDefaultsLocalTable, UserFoodDefaultsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFoodDefaultsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodRefKindMeta =
      const VerificationMeta('foodRefKind');
  @override
  late final GeneratedColumn<String> foodRefKind = GeneratedColumn<String>(
      'food_ref_kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodRefIdMeta =
      const VerificationMeta('foodRefId');
  @override
  late final GeneratedColumn<String> foodRefId = GeneratedColumn<String>(
      'food_ref_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodNameMeta =
      const VerificationMeta('foodName');
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
      'food_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _preferredQuantityMeta =
      const VerificationMeta('preferredQuantity');
  @override
  late final GeneratedColumn<double> preferredQuantity =
      GeneratedColumn<double>('preferred_quantity', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _preferredUnitMeta =
      const VerificationMeta('preferredUnit');
  @override
  late final GeneratedColumn<String> preferredUnit = GeneratedColumn<String>(
      'preferred_unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _preferredGramsMeta =
      const VerificationMeta('preferredGrams');
  @override
  late final GeneratedColumn<double> preferredGrams = GeneratedColumn<double>(
      'preferred_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _caloriesKcalMeta =
      const VerificationMeta('caloriesKcal');
  @override
  late final GeneratedColumn<double> caloriesKcal = GeneratedColumn<double>(
      'calories_kcal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
      'carbs_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _useCountMeta =
      const VerificationMeta('useCount');
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
      'use_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
        userId,
        foodRefKind,
        foodRefId,
        foodName,
        preferredQuantity,
        preferredUnit,
        preferredGrams,
        caloriesKcal,
        proteinG,
        carbsG,
        fatG,
        useCount,
        lastUsedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_food_defaults_local';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserFoodDefaultsLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('food_ref_kind')) {
      context.handle(
          _foodRefKindMeta,
          foodRefKind.isAcceptableOrUnknown(
              data['food_ref_kind']!, _foodRefKindMeta));
    } else if (isInserting) {
      context.missing(_foodRefKindMeta);
    }
    if (data.containsKey('food_ref_id')) {
      context.handle(
          _foodRefIdMeta,
          foodRefId.isAcceptableOrUnknown(
              data['food_ref_id']!, _foodRefIdMeta));
    } else if (isInserting) {
      context.missing(_foodRefIdMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(_foodNameMeta,
          foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta));
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('preferred_quantity')) {
      context.handle(
          _preferredQuantityMeta,
          preferredQuantity.isAcceptableOrUnknown(
              data['preferred_quantity']!, _preferredQuantityMeta));
    }
    if (data.containsKey('preferred_unit')) {
      context.handle(
          _preferredUnitMeta,
          preferredUnit.isAcceptableOrUnknown(
              data['preferred_unit']!, _preferredUnitMeta));
    } else if (isInserting) {
      context.missing(_preferredUnitMeta);
    }
    if (data.containsKey('preferred_grams')) {
      context.handle(
          _preferredGramsMeta,
          preferredGrams.isAcceptableOrUnknown(
              data['preferred_grams']!, _preferredGramsMeta));
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
          _caloriesKcalMeta,
          caloriesKcal.isAcceptableOrUnknown(
              data['calories_kcal']!, _caloriesKcalMeta));
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carbs_g')) {
      context.handle(_carbsGMeta,
          carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('use_count')) {
      context.handle(_useCountMeta,
          useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
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
  UserFoodDefaultsLocalData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFoodDefaultsLocalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      foodRefKind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_ref_kind'])!,
      foodRefId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_ref_id'])!,
      foodName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_name'])!,
      preferredQuantity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}preferred_quantity'])!,
      preferredUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preferred_unit'])!,
      preferredGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}preferred_grams']),
      caloriesKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calories_kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      carbsG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      useCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}use_count'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserFoodDefaultsLocalTable createAlias(String alias) {
    return $UserFoodDefaultsLocalTable(attachedDatabase, alias);
  }
}

class UserFoodDefaultsLocalData extends DataClass
    implements Insertable<UserFoodDefaultsLocalData> {
  final String id;
  final String userId;
  final String foodRefKind;
  final String foodRefId;
  final String foodName;
  final double preferredQuantity;
  final String preferredUnit;
  final double? preferredGrams;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int useCount;
  final DateTime? lastUsedAt;
  final DateTime updatedAt;
  const UserFoodDefaultsLocalData(
      {required this.id,
      required this.userId,
      required this.foodRefKind,
      required this.foodRefId,
      required this.foodName,
      required this.preferredQuantity,
      required this.preferredUnit,
      this.preferredGrams,
      required this.caloriesKcal,
      required this.proteinG,
      required this.carbsG,
      required this.fatG,
      required this.useCount,
      this.lastUsedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['food_ref_kind'] = Variable<String>(foodRefKind);
    map['food_ref_id'] = Variable<String>(foodRefId);
    map['food_name'] = Variable<String>(foodName);
    map['preferred_quantity'] = Variable<double>(preferredQuantity);
    map['preferred_unit'] = Variable<String>(preferredUnit);
    if (!nullToAbsent || preferredGrams != null) {
      map['preferred_grams'] = Variable<double>(preferredGrams);
    }
    map['calories_kcal'] = Variable<double>(caloriesKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserFoodDefaultsLocalCompanion toCompanion(bool nullToAbsent) {
    return UserFoodDefaultsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      foodRefKind: Value(foodRefKind),
      foodRefId: Value(foodRefId),
      foodName: Value(foodName),
      preferredQuantity: Value(preferredQuantity),
      preferredUnit: Value(preferredUnit),
      preferredGrams: preferredGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredGrams),
      caloriesKcal: Value(caloriesKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserFoodDefaultsLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFoodDefaultsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      foodRefKind: serializer.fromJson<String>(json['foodRefKind']),
      foodRefId: serializer.fromJson<String>(json['foodRefId']),
      foodName: serializer.fromJson<String>(json['foodName']),
      preferredQuantity: serializer.fromJson<double>(json['preferredQuantity']),
      preferredUnit: serializer.fromJson<String>(json['preferredUnit']),
      preferredGrams: serializer.fromJson<double?>(json['preferredGrams']),
      caloriesKcal: serializer.fromJson<double>(json['caloriesKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'foodRefKind': serializer.toJson<String>(foodRefKind),
      'foodRefId': serializer.toJson<String>(foodRefId),
      'foodName': serializer.toJson<String>(foodName),
      'preferredQuantity': serializer.toJson<double>(preferredQuantity),
      'preferredUnit': serializer.toJson<String>(preferredUnit),
      'preferredGrams': serializer.toJson<double?>(preferredGrams),
      'caloriesKcal': serializer.toJson<double>(caloriesKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserFoodDefaultsLocalData copyWith(
          {String? id,
          String? userId,
          String? foodRefKind,
          String? foodRefId,
          String? foodName,
          double? preferredQuantity,
          String? preferredUnit,
          Value<double?> preferredGrams = const Value.absent(),
          double? caloriesKcal,
          double? proteinG,
          double? carbsG,
          double? fatG,
          int? useCount,
          Value<DateTime?> lastUsedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      UserFoodDefaultsLocalData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        foodRefKind: foodRefKind ?? this.foodRefKind,
        foodRefId: foodRefId ?? this.foodRefId,
        foodName: foodName ?? this.foodName,
        preferredQuantity: preferredQuantity ?? this.preferredQuantity,
        preferredUnit: preferredUnit ?? this.preferredUnit,
        preferredGrams:
            preferredGrams.present ? preferredGrams.value : this.preferredGrams,
        caloriesKcal: caloriesKcal ?? this.caloriesKcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        useCount: useCount ?? this.useCount,
        lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserFoodDefaultsLocalData copyWithCompanion(
      UserFoodDefaultsLocalCompanion data) {
    return UserFoodDefaultsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      foodRefKind:
          data.foodRefKind.present ? data.foodRefKind.value : this.foodRefKind,
      foodRefId: data.foodRefId.present ? data.foodRefId.value : this.foodRefId,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      preferredQuantity: data.preferredQuantity.present
          ? data.preferredQuantity.value
          : this.preferredQuantity,
      preferredUnit: data.preferredUnit.present
          ? data.preferredUnit.value
          : this.preferredUnit,
      preferredGrams: data.preferredGrams.present
          ? data.preferredGrams.value
          : this.preferredGrams,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFoodDefaultsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('foodRefKind: $foodRefKind, ')
          ..write('foodRefId: $foodRefId, ')
          ..write('foodName: $foodName, ')
          ..write('preferredQuantity: $preferredQuantity, ')
          ..write('preferredUnit: $preferredUnit, ')
          ..write('preferredGrams: $preferredGrams, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      foodRefKind,
      foodRefId,
      foodName,
      preferredQuantity,
      preferredUnit,
      preferredGrams,
      caloriesKcal,
      proteinG,
      carbsG,
      fatG,
      useCount,
      lastUsedAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFoodDefaultsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.foodRefKind == this.foodRefKind &&
          other.foodRefId == this.foodRefId &&
          other.foodName == this.foodName &&
          other.preferredQuantity == this.preferredQuantity &&
          other.preferredUnit == this.preferredUnit &&
          other.preferredGrams == this.preferredGrams &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.updatedAt == this.updatedAt);
}

class UserFoodDefaultsLocalCompanion
    extends UpdateCompanion<UserFoodDefaultsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> foodRefKind;
  final Value<String> foodRefId;
  final Value<String> foodName;
  final Value<double> preferredQuantity;
  final Value<String> preferredUnit;
  final Value<double?> preferredGrams;
  final Value<double> caloriesKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int> useCount;
  final Value<DateTime?> lastUsedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserFoodDefaultsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.foodRefKind = const Value.absent(),
    this.foodRefId = const Value.absent(),
    this.foodName = const Value.absent(),
    this.preferredQuantity = const Value.absent(),
    this.preferredUnit = const Value.absent(),
    this.preferredGrams = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserFoodDefaultsLocalCompanion.insert({
    required String id,
    required String userId,
    required String foodRefKind,
    required String foodRefId,
    required String foodName,
    this.preferredQuantity = const Value.absent(),
    required String preferredUnit,
    this.preferredGrams = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        foodRefKind = Value(foodRefKind),
        foodRefId = Value(foodRefId),
        foodName = Value(foodName),
        preferredUnit = Value(preferredUnit);
  static Insertable<UserFoodDefaultsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? foodRefKind,
    Expression<String>? foodRefId,
    Expression<String>? foodName,
    Expression<double>? preferredQuantity,
    Expression<String>? preferredUnit,
    Expression<double>? preferredGrams,
    Expression<double>? caloriesKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (foodRefKind != null) 'food_ref_kind': foodRefKind,
      if (foodRefId != null) 'food_ref_id': foodRefId,
      if (foodName != null) 'food_name': foodName,
      if (preferredQuantity != null) 'preferred_quantity': preferredQuantity,
      if (preferredUnit != null) 'preferred_unit': preferredUnit,
      if (preferredGrams != null) 'preferred_grams': preferredGrams,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserFoodDefaultsLocalCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? foodRefKind,
      Value<String>? foodRefId,
      Value<String>? foodName,
      Value<double>? preferredQuantity,
      Value<String>? preferredUnit,
      Value<double?>? preferredGrams,
      Value<double>? caloriesKcal,
      Value<double>? proteinG,
      Value<double>? carbsG,
      Value<double>? fatG,
      Value<int>? useCount,
      Value<DateTime?>? lastUsedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserFoodDefaultsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodRefKind: foodRefKind ?? this.foodRefKind,
      foodRefId: foodRefId ?? this.foodRefId,
      foodName: foodName ?? this.foodName,
      preferredQuantity: preferredQuantity ?? this.preferredQuantity,
      preferredUnit: preferredUnit ?? this.preferredUnit,
      preferredGrams: preferredGrams ?? this.preferredGrams,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (foodRefKind.present) {
      map['food_ref_kind'] = Variable<String>(foodRefKind.value);
    }
    if (foodRefId.present) {
      map['food_ref_id'] = Variable<String>(foodRefId.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (preferredQuantity.present) {
      map['preferred_quantity'] = Variable<double>(preferredQuantity.value);
    }
    if (preferredUnit.present) {
      map['preferred_unit'] = Variable<String>(preferredUnit.value);
    }
    if (preferredGrams.present) {
      map['preferred_grams'] = Variable<double>(preferredGrams.value);
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<double>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFoodDefaultsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('foodRefKind: $foodRefKind, ')
          ..write('foodRefId: $foodRefId, ')
          ..write('foodName: $foodName, ')
          ..write('preferredQuantity: $preferredQuantity, ')
          ..write('preferredUnit: $preferredUnit, ')
          ..write('preferredGrams: $preferredGrams, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesLocalTable profilesLocal = $ProfilesLocalTable(this);
  late final $NutritionGoalsLocalTable nutritionGoalsLocal =
      $NutritionGoalsLocalTable(this);
  late final $BodyMeasurementsLocalTable bodyMeasurementsLocal =
      $BodyMeasurementsLocalTable(this);
  late final $DevicesLocalTable devicesLocal = $DevicesLocalTable(this);
  late final $FeatureFlagsLocalTable featureFlagsLocal =
      $FeatureFlagsLocalTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $OutboxCommandsTable outboxCommands = $OutboxCommandsTable(this);
  late final $MealAssetsLocalTable mealAssetsLocal =
      $MealAssetsLocalTable(this);
  late final $MealsLocalTable mealsLocal = $MealsLocalTable(this);
  late final $MealItemsLocalTable mealItemsLocal = $MealItemsLocalTable(this);
  late final $MealTemplatesLocalTable mealTemplatesLocal =
      $MealTemplatesLocalTable(this);
  late final $CustomFoodsLocalTable customFoodsLocal =
      $CustomFoodsLocalTable(this);
  late final $DailyRollupsLocalTable dailyRollupsLocal =
      $DailyRollupsLocalTable(this);
  late final $CorrectionEventsLocalTable correctionEventsLocal =
      $CorrectionEventsLocalTable(this);
  late final $WeeklyInsightsLocalTable weeklyInsightsLocal =
      $WeeklyInsightsLocalTable(this);
  late final $UserFoodDefaultsLocalTable userFoodDefaultsLocal =
      $UserFoodDefaultsLocalTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profilesLocal,
        nutritionGoalsLocal,
        bodyMeasurementsLocal,
        devicesLocal,
        featureFlagsLocal,
        syncState,
        outboxCommands,
        mealAssetsLocal,
        mealsLocal,
        mealItemsLocal,
        mealTemplatesLocal,
        customFoodsLocal,
        dailyRollupsLocal,
        correctionEventsLocal,
        weeklyInsightsLocal,
        userFoodDefaultsLocal
      ];
}

typedef $$ProfilesLocalTableCreateCompanionBuilder = ProfilesLocalCompanion
    Function({
  required String id,
  Value<String?> displayName,
  Value<String> locale,
  required String timezone,
  Value<String> unitSystem,
  Value<String?> countryCode,
  Value<String> cuisinePreferencesJson,
  Value<bool> cloudMediaStorage,
  Value<bool> saveOriginalPhotos,
  Value<bool> aiImprovementConsent,
  Value<DateTime?> onboardingCompletedAt,
  Value<String> syncStatus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ProfilesLocalTableUpdateCompanionBuilder = ProfilesLocalCompanion
    Function({
  Value<String> id,
  Value<String?> displayName,
  Value<String> locale,
  Value<String> timezone,
  Value<String> unitSystem,
  Value<String?> countryCode,
  Value<String> cuisinePreferencesJson,
  Value<bool> cloudMediaStorage,
  Value<bool> saveOriginalPhotos,
  Value<bool> aiImprovementConsent,
  Value<DateTime?> onboardingCompletedAt,
  Value<String> syncStatus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProfilesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesLocalTable> {
  $$ProfilesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locale => $composableBuilder(
      column: $table.locale, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitSystem => $composableBuilder(
      column: $table.unitSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get countryCode => $composableBuilder(
      column: $table.countryCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cuisinePreferencesJson => $composableBuilder(
      column: $table.cuisinePreferencesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get cloudMediaStorage => $composableBuilder(
      column: $table.cloudMediaStorage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get saveOriginalPhotos => $composableBuilder(
      column: $table.saveOriginalPhotos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get aiImprovementConsent => $composableBuilder(
      column: $table.aiImprovementConsent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get onboardingCompletedAt => $composableBuilder(
      column: $table.onboardingCompletedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProfilesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesLocalTable> {
  $$ProfilesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locale => $composableBuilder(
      column: $table.locale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitSystem => $composableBuilder(
      column: $table.unitSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get countryCode => $composableBuilder(
      column: $table.countryCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cuisinePreferencesJson => $composableBuilder(
      column: $table.cuisinePreferencesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get cloudMediaStorage => $composableBuilder(
      column: $table.cloudMediaStorage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get saveOriginalPhotos => $composableBuilder(
      column: $table.saveOriginalPhotos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get aiImprovementConsent => $composableBuilder(
      column: $table.aiImprovementConsent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get onboardingCompletedAt => $composableBuilder(
      column: $table.onboardingCompletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesLocalTable> {
  $$ProfilesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get unitSystem => $composableBuilder(
      column: $table.unitSystem, builder: (column) => column);

  GeneratedColumn<String> get countryCode => $composableBuilder(
      column: $table.countryCode, builder: (column) => column);

  GeneratedColumn<String> get cuisinePreferencesJson => $composableBuilder(
      column: $table.cuisinePreferencesJson, builder: (column) => column);

  GeneratedColumn<bool> get cloudMediaStorage => $composableBuilder(
      column: $table.cloudMediaStorage, builder: (column) => column);

  GeneratedColumn<bool> get saveOriginalPhotos => $composableBuilder(
      column: $table.saveOriginalPhotos, builder: (column) => column);

  GeneratedColumn<bool> get aiImprovementConsent => $composableBuilder(
      column: $table.aiImprovementConsent, builder: (column) => column);

  GeneratedColumn<DateTime> get onboardingCompletedAt => $composableBuilder(
      column: $table.onboardingCompletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesLocalTable,
    ProfilesLocalData,
    $$ProfilesLocalTableFilterComposer,
    $$ProfilesLocalTableOrderingComposer,
    $$ProfilesLocalTableAnnotationComposer,
    $$ProfilesLocalTableCreateCompanionBuilder,
    $$ProfilesLocalTableUpdateCompanionBuilder,
    (
      ProfilesLocalData,
      BaseReferences<_$AppDatabase, $ProfilesLocalTable, ProfilesLocalData>
    ),
    ProfilesLocalData,
    PrefetchHooks Function()> {
  $$ProfilesLocalTableTableManager(_$AppDatabase db, $ProfilesLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String> locale = const Value.absent(),
            Value<String> timezone = const Value.absent(),
            Value<String> unitSystem = const Value.absent(),
            Value<String?> countryCode = const Value.absent(),
            Value<String> cuisinePreferencesJson = const Value.absent(),
            Value<bool> cloudMediaStorage = const Value.absent(),
            Value<bool> saveOriginalPhotos = const Value.absent(),
            Value<bool> aiImprovementConsent = const Value.absent(),
            Value<DateTime?> onboardingCompletedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesLocalCompanion(
            id: id,
            displayName: displayName,
            locale: locale,
            timezone: timezone,
            unitSystem: unitSystem,
            countryCode: countryCode,
            cuisinePreferencesJson: cuisinePreferencesJson,
            cloudMediaStorage: cloudMediaStorage,
            saveOriginalPhotos: saveOriginalPhotos,
            aiImprovementConsent: aiImprovementConsent,
            onboardingCompletedAt: onboardingCompletedAt,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> displayName = const Value.absent(),
            Value<String> locale = const Value.absent(),
            required String timezone,
            Value<String> unitSystem = const Value.absent(),
            Value<String?> countryCode = const Value.absent(),
            Value<String> cuisinePreferencesJson = const Value.absent(),
            Value<bool> cloudMediaStorage = const Value.absent(),
            Value<bool> saveOriginalPhotos = const Value.absent(),
            Value<bool> aiImprovementConsent = const Value.absent(),
            Value<DateTime?> onboardingCompletedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesLocalCompanion.insert(
            id: id,
            displayName: displayName,
            locale: locale,
            timezone: timezone,
            unitSystem: unitSystem,
            countryCode: countryCode,
            cuisinePreferencesJson: cuisinePreferencesJson,
            cloudMediaStorage: cloudMediaStorage,
            saveOriginalPhotos: saveOriginalPhotos,
            aiImprovementConsent: aiImprovementConsent,
            onboardingCompletedAt: onboardingCompletedAt,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfilesLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesLocalTable,
    ProfilesLocalData,
    $$ProfilesLocalTableFilterComposer,
    $$ProfilesLocalTableOrderingComposer,
    $$ProfilesLocalTableAnnotationComposer,
    $$ProfilesLocalTableCreateCompanionBuilder,
    $$ProfilesLocalTableUpdateCompanionBuilder,
    (
      ProfilesLocalData,
      BaseReferences<_$AppDatabase, $ProfilesLocalTable, ProfilesLocalData>
    ),
    ProfilesLocalData,
    PrefetchHooks Function()>;
typedef $$NutritionGoalsLocalTableCreateCompanionBuilder
    = NutritionGoalsLocalCompanion Function({
  required String id,
  required String userId,
  required String goalType,
  required double caloriesKcal,
  required double proteinG,
  required double carbsG,
  required double fatG,
  Value<double?> fiberG,
  required DateTime startsOn,
  Value<DateTime?> endsOn,
  Value<bool> isActive,
  Value<String> syncStatus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$NutritionGoalsLocalTableUpdateCompanionBuilder
    = NutritionGoalsLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> goalType,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<double?> fiberG,
  Value<DateTime> startsOn,
  Value<DateTime?> endsOn,
  Value<bool> isActive,
  Value<String> syncStatus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$NutritionGoalsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $NutritionGoalsLocalTable> {
  $$NutritionGoalsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get goalType => $composableBuilder(
      column: $table.goalType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fiberG => $composableBuilder(
      column: $table.fiberG, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startsOn => $composableBuilder(
      column: $table.startsOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endsOn => $composableBuilder(
      column: $table.endsOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$NutritionGoalsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $NutritionGoalsLocalTable> {
  $$NutritionGoalsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goalType => $composableBuilder(
      column: $table.goalType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fiberG => $composableBuilder(
      column: $table.fiberG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startsOn => $composableBuilder(
      column: $table.startsOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endsOn => $composableBuilder(
      column: $table.endsOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$NutritionGoalsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $NutritionGoalsLocalTable> {
  $$NutritionGoalsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<DateTime> get startsOn =>
      $composableBuilder(column: $table.startsOn, builder: (column) => column);

  GeneratedColumn<DateTime> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NutritionGoalsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NutritionGoalsLocalTable,
    NutritionGoalsLocalData,
    $$NutritionGoalsLocalTableFilterComposer,
    $$NutritionGoalsLocalTableOrderingComposer,
    $$NutritionGoalsLocalTableAnnotationComposer,
    $$NutritionGoalsLocalTableCreateCompanionBuilder,
    $$NutritionGoalsLocalTableUpdateCompanionBuilder,
    (
      NutritionGoalsLocalData,
      BaseReferences<_$AppDatabase, $NutritionGoalsLocalTable,
          NutritionGoalsLocalData>
    ),
    NutritionGoalsLocalData,
    PrefetchHooks Function()> {
  $$NutritionGoalsLocalTableTableManager(
      _$AppDatabase db, $NutritionGoalsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionGoalsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionGoalsLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionGoalsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> goalType = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double?> fiberG = const Value.absent(),
            Value<DateTime> startsOn = const Value.absent(),
            Value<DateTime?> endsOn = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NutritionGoalsLocalCompanion(
            id: id,
            userId: userId,
            goalType: goalType,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG,
            startsOn: startsOn,
            endsOn: endsOn,
            isActive: isActive,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String goalType,
            required double caloriesKcal,
            required double proteinG,
            required double carbsG,
            required double fatG,
            Value<double?> fiberG = const Value.absent(),
            required DateTime startsOn,
            Value<DateTime?> endsOn = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NutritionGoalsLocalCompanion.insert(
            id: id,
            userId: userId,
            goalType: goalType,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG,
            startsOn: startsOn,
            endsOn: endsOn,
            isActive: isActive,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NutritionGoalsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NutritionGoalsLocalTable,
    NutritionGoalsLocalData,
    $$NutritionGoalsLocalTableFilterComposer,
    $$NutritionGoalsLocalTableOrderingComposer,
    $$NutritionGoalsLocalTableAnnotationComposer,
    $$NutritionGoalsLocalTableCreateCompanionBuilder,
    $$NutritionGoalsLocalTableUpdateCompanionBuilder,
    (
      NutritionGoalsLocalData,
      BaseReferences<_$AppDatabase, $NutritionGoalsLocalTable,
          NutritionGoalsLocalData>
    ),
    NutritionGoalsLocalData,
    PrefetchHooks Function()>;
typedef $$BodyMeasurementsLocalTableCreateCompanionBuilder
    = BodyMeasurementsLocalCompanion Function({
  required String id,
  required String userId,
  required DateTime measuredAt,
  Value<double?> weightKg,
  Value<double?> bodyFatPct,
  Value<String> source,
  Value<String> syncStatus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$BodyMeasurementsLocalTableUpdateCompanionBuilder
    = BodyMeasurementsLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> measuredAt,
  Value<double?> weightKg,
  Value<double?> bodyFatPct,
  Value<String> source,
  Value<String> syncStatus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BodyMeasurementsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsLocalTable> {
  $$BodyMeasurementsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyFatPct => $composableBuilder(
      column: $table.bodyFatPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BodyMeasurementsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsLocalTable> {
  $$BodyMeasurementsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyFatPct => $composableBuilder(
      column: $table.bodyFatPct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BodyMeasurementsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsLocalTable> {
  $$BodyMeasurementsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPct => $composableBuilder(
      column: $table.bodyFatPct, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BodyMeasurementsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BodyMeasurementsLocalTable,
    BodyMeasurementsLocalData,
    $$BodyMeasurementsLocalTableFilterComposer,
    $$BodyMeasurementsLocalTableOrderingComposer,
    $$BodyMeasurementsLocalTableAnnotationComposer,
    $$BodyMeasurementsLocalTableCreateCompanionBuilder,
    $$BodyMeasurementsLocalTableUpdateCompanionBuilder,
    (
      BodyMeasurementsLocalData,
      BaseReferences<_$AppDatabase, $BodyMeasurementsLocalTable,
          BodyMeasurementsLocalData>
    ),
    BodyMeasurementsLocalData,
    PrefetchHooks Function()> {
  $$BodyMeasurementsLocalTableTableManager(
      _$AppDatabase db, $BodyMeasurementsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> measuredAt = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<double?> bodyFatPct = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BodyMeasurementsLocalCompanion(
            id: id,
            userId: userId,
            measuredAt: measuredAt,
            weightKg: weightKg,
            bodyFatPct: bodyFatPct,
            source: source,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime measuredAt,
            Value<double?> weightKg = const Value.absent(),
            Value<double?> bodyFatPct = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BodyMeasurementsLocalCompanion.insert(
            id: id,
            userId: userId,
            measuredAt: measuredAt,
            weightKg: weightKg,
            bodyFatPct: bodyFatPct,
            source: source,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BodyMeasurementsLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $BodyMeasurementsLocalTable,
        BodyMeasurementsLocalData,
        $$BodyMeasurementsLocalTableFilterComposer,
        $$BodyMeasurementsLocalTableOrderingComposer,
        $$BodyMeasurementsLocalTableAnnotationComposer,
        $$BodyMeasurementsLocalTableCreateCompanionBuilder,
        $$BodyMeasurementsLocalTableUpdateCompanionBuilder,
        (
          BodyMeasurementsLocalData,
          BaseReferences<_$AppDatabase, $BodyMeasurementsLocalTable,
              BodyMeasurementsLocalData>
        ),
        BodyMeasurementsLocalData,
        PrefetchHooks Function()>;
typedef $$DevicesLocalTableCreateCompanionBuilder = DevicesLocalCompanion
    Function({
  required String id,
  required String userId,
  required String installId,
  required String platform,
  Value<String?> appVersion,
  Value<String?> buildNumber,
  required DateTime lastSeenAt,
  Value<String?> lastSyncCursor,
  Value<int> rowid,
});
typedef $$DevicesLocalTableUpdateCompanionBuilder = DevicesLocalCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> installId,
  Value<String> platform,
  Value<String?> appVersion,
  Value<String?> buildNumber,
  Value<DateTime> lastSeenAt,
  Value<String?> lastSyncCursor,
  Value<int> rowid,
});

class $$DevicesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesLocalTable> {
  $$DevicesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get installId => $composableBuilder(
      column: $table.installId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appVersion => $composableBuilder(
      column: $table.appVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get buildNumber => $composableBuilder(
      column: $table.buildNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSyncCursor => $composableBuilder(
      column: $table.lastSyncCursor,
      builder: (column) => ColumnFilters(column));
}

class $$DevicesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesLocalTable> {
  $$DevicesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get installId => $composableBuilder(
      column: $table.installId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appVersion => $composableBuilder(
      column: $table.appVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get buildNumber => $composableBuilder(
      column: $table.buildNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSyncCursor => $composableBuilder(
      column: $table.lastSyncCursor,
      builder: (column) => ColumnOrderings(column));
}

class $$DevicesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesLocalTable> {
  $$DevicesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
      column: $table.appVersion, builder: (column) => column);

  GeneratedColumn<String> get buildNumber => $composableBuilder(
      column: $table.buildNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => column);

  GeneratedColumn<String> get lastSyncCursor => $composableBuilder(
      column: $table.lastSyncCursor, builder: (column) => column);
}

class $$DevicesLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DevicesLocalTable,
    DevicesLocalData,
    $$DevicesLocalTableFilterComposer,
    $$DevicesLocalTableOrderingComposer,
    $$DevicesLocalTableAnnotationComposer,
    $$DevicesLocalTableCreateCompanionBuilder,
    $$DevicesLocalTableUpdateCompanionBuilder,
    (
      DevicesLocalData,
      BaseReferences<_$AppDatabase, $DevicesLocalTable, DevicesLocalData>
    ),
    DevicesLocalData,
    PrefetchHooks Function()> {
  $$DevicesLocalTableTableManager(_$AppDatabase db, $DevicesLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> installId = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String?> appVersion = const Value.absent(),
            Value<String?> buildNumber = const Value.absent(),
            Value<DateTime> lastSeenAt = const Value.absent(),
            Value<String?> lastSyncCursor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesLocalCompanion(
            id: id,
            userId: userId,
            installId: installId,
            platform: platform,
            appVersion: appVersion,
            buildNumber: buildNumber,
            lastSeenAt: lastSeenAt,
            lastSyncCursor: lastSyncCursor,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String installId,
            required String platform,
            Value<String?> appVersion = const Value.absent(),
            Value<String?> buildNumber = const Value.absent(),
            required DateTime lastSeenAt,
            Value<String?> lastSyncCursor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesLocalCompanion.insert(
            id: id,
            userId: userId,
            installId: installId,
            platform: platform,
            appVersion: appVersion,
            buildNumber: buildNumber,
            lastSeenAt: lastSeenAt,
            lastSyncCursor: lastSyncCursor,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DevicesLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DevicesLocalTable,
    DevicesLocalData,
    $$DevicesLocalTableFilterComposer,
    $$DevicesLocalTableOrderingComposer,
    $$DevicesLocalTableAnnotationComposer,
    $$DevicesLocalTableCreateCompanionBuilder,
    $$DevicesLocalTableUpdateCompanionBuilder,
    (
      DevicesLocalData,
      BaseReferences<_$AppDatabase, $DevicesLocalTable, DevicesLocalData>
    ),
    DevicesLocalData,
    PrefetchHooks Function()>;
typedef $$FeatureFlagsLocalTableCreateCompanionBuilder
    = FeatureFlagsLocalCompanion Function({
  required String key,
  required String valueJson,
  Value<DateTime> exposedAt,
  Value<int> rowid,
});
typedef $$FeatureFlagsLocalTableUpdateCompanionBuilder
    = FeatureFlagsLocalCompanion Function({
  Value<String> key,
  Value<String> valueJson,
  Value<DateTime> exposedAt,
  Value<int> rowid,
});

class $$FeatureFlagsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $FeatureFlagsLocalTable> {
  $$FeatureFlagsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueJson => $composableBuilder(
      column: $table.valueJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get exposedAt => $composableBuilder(
      column: $table.exposedAt, builder: (column) => ColumnFilters(column));
}

class $$FeatureFlagsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $FeatureFlagsLocalTable> {
  $$FeatureFlagsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueJson => $composableBuilder(
      column: $table.valueJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get exposedAt => $composableBuilder(
      column: $table.exposedAt, builder: (column) => ColumnOrderings(column));
}

class $$FeatureFlagsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeatureFlagsLocalTable> {
  $$FeatureFlagsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get exposedAt =>
      $composableBuilder(column: $table.exposedAt, builder: (column) => column);
}

class $$FeatureFlagsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FeatureFlagsLocalTable,
    FeatureFlagsLocalData,
    $$FeatureFlagsLocalTableFilterComposer,
    $$FeatureFlagsLocalTableOrderingComposer,
    $$FeatureFlagsLocalTableAnnotationComposer,
    $$FeatureFlagsLocalTableCreateCompanionBuilder,
    $$FeatureFlagsLocalTableUpdateCompanionBuilder,
    (
      FeatureFlagsLocalData,
      BaseReferences<_$AppDatabase, $FeatureFlagsLocalTable,
          FeatureFlagsLocalData>
    ),
    FeatureFlagsLocalData,
    PrefetchHooks Function()> {
  $$FeatureFlagsLocalTableTableManager(
      _$AppDatabase db, $FeatureFlagsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeatureFlagsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeatureFlagsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeatureFlagsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> valueJson = const Value.absent(),
            Value<DateTime> exposedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FeatureFlagsLocalCompanion(
            key: key,
            valueJson: valueJson,
            exposedAt: exposedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String valueJson,
            Value<DateTime> exposedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FeatureFlagsLocalCompanion.insert(
            key: key,
            valueJson: valueJson,
            exposedAt: exposedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FeatureFlagsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FeatureFlagsLocalTable,
    FeatureFlagsLocalData,
    $$FeatureFlagsLocalTableFilterComposer,
    $$FeatureFlagsLocalTableOrderingComposer,
    $$FeatureFlagsLocalTableAnnotationComposer,
    $$FeatureFlagsLocalTableCreateCompanionBuilder,
    $$FeatureFlagsLocalTableUpdateCompanionBuilder,
    (
      FeatureFlagsLocalData,
      BaseReferences<_$AppDatabase, $FeatureFlagsLocalTable,
          FeatureFlagsLocalData>
    ),
    FeatureFlagsLocalData,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  Value<String?> cursor,
  Value<DateTime?> lastSyncedAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String?> cursor,
  Value<DateTime?> lastSyncedAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cursor => $composableBuilder(
      column: $table.cursor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cursor => $composableBuilder(
      column: $table.cursor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> cursor = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion(
            key: key,
            cursor: cursor,
            lastSyncedAt: lastSyncedAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> cursor = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            key: key,
            cursor: cursor,
            lastSyncedAt: lastSyncedAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;
typedef $$OutboxCommandsTableCreateCompanionBuilder = OutboxCommandsCompanion
    Function({
  required String id,
  required String userId,
  required String commandType,
  required String payloadJson,
  Value<String?> payloadHash,
  required String clientRequestId,
  Value<String?> dependencyCommandId,
  Value<String> status,
  Value<int> retryCount,
  Value<DateTime?> nextRetryAt,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$OutboxCommandsTableUpdateCompanionBuilder = OutboxCommandsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> commandType,
  Value<String> payloadJson,
  Value<String?> payloadHash,
  Value<String> clientRequestId,
  Value<String?> dependencyCommandId,
  Value<String> status,
  Value<int> retryCount,
  Value<DateTime?> nextRetryAt,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$OutboxCommandsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxCommandsTable> {
  $$OutboxCommandsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get commandType => $composableBuilder(
      column: $table.commandType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadHash => $composableBuilder(
      column: $table.payloadHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientRequestId => $composableBuilder(
      column: $table.clientRequestId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dependencyCommandId => $composableBuilder(
      column: $table.dependencyCommandId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OutboxCommandsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxCommandsTable> {
  $$OutboxCommandsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get commandType => $composableBuilder(
      column: $table.commandType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadHash => $composableBuilder(
      column: $table.payloadHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientRequestId => $composableBuilder(
      column: $table.clientRequestId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dependencyCommandId => $composableBuilder(
      column: $table.dependencyCommandId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OutboxCommandsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxCommandsTable> {
  $$OutboxCommandsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get commandType => $composableBuilder(
      column: $table.commandType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get payloadHash => $composableBuilder(
      column: $table.payloadHash, builder: (column) => column);

  GeneratedColumn<String> get clientRequestId => $composableBuilder(
      column: $table.clientRequestId, builder: (column) => column);

  GeneratedColumn<String> get dependencyCommandId => $composableBuilder(
      column: $table.dependencyCommandId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxCommandsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxCommandsTable,
    OutboxCommand,
    $$OutboxCommandsTableFilterComposer,
    $$OutboxCommandsTableOrderingComposer,
    $$OutboxCommandsTableAnnotationComposer,
    $$OutboxCommandsTableCreateCompanionBuilder,
    $$OutboxCommandsTableUpdateCompanionBuilder,
    (
      OutboxCommand,
      BaseReferences<_$AppDatabase, $OutboxCommandsTable, OutboxCommand>
    ),
    OutboxCommand,
    PrefetchHooks Function()> {
  $$OutboxCommandsTableTableManager(
      _$AppDatabase db, $OutboxCommandsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxCommandsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxCommandsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxCommandsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> commandType = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String?> payloadHash = const Value.absent(),
            Value<String> clientRequestId = const Value.absent(),
            Value<String?> dependencyCommandId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxCommandsCompanion(
            id: id,
            userId: userId,
            commandType: commandType,
            payloadJson: payloadJson,
            payloadHash: payloadHash,
            clientRequestId: clientRequestId,
            dependencyCommandId: dependencyCommandId,
            status: status,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt,
            lastError: lastError,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String commandType,
            required String payloadJson,
            Value<String?> payloadHash = const Value.absent(),
            required String clientRequestId,
            Value<String?> dependencyCommandId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxCommandsCompanion.insert(
            id: id,
            userId: userId,
            commandType: commandType,
            payloadJson: payloadJson,
            payloadHash: payloadHash,
            clientRequestId: clientRequestId,
            dependencyCommandId: dependencyCommandId,
            status: status,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt,
            lastError: lastError,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxCommandsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxCommandsTable,
    OutboxCommand,
    $$OutboxCommandsTableFilterComposer,
    $$OutboxCommandsTableOrderingComposer,
    $$OutboxCommandsTableAnnotationComposer,
    $$OutboxCommandsTableCreateCompanionBuilder,
    $$OutboxCommandsTableUpdateCompanionBuilder,
    (
      OutboxCommand,
      BaseReferences<_$AppDatabase, $OutboxCommandsTable, OutboxCommand>
    ),
    OutboxCommand,
    PrefetchHooks Function()>;
typedef $$MealAssetsLocalTableCreateCompanionBuilder = MealAssetsLocalCompanion
    Function({
  required String id,
  required String userId,
  required String localPath,
  Value<String> storageBucket,
  required String storagePath,
  Value<String?> thumbLocalPath,
  Value<String?> thumbStoragePath,
  required String sha256,
  Value<String> mimeType,
  Value<int?> width,
  Value<int?> height,
  Value<int?> sizeBytes,
  Value<String> uploadStatus,
  Value<DateTime> createdAt,
  Value<DateTime?> uploadedAt,
  Value<int> rowid,
});
typedef $$MealAssetsLocalTableUpdateCompanionBuilder = MealAssetsLocalCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> localPath,
  Value<String> storageBucket,
  Value<String> storagePath,
  Value<String?> thumbLocalPath,
  Value<String?> thumbStoragePath,
  Value<String> sha256,
  Value<String> mimeType,
  Value<int?> width,
  Value<int?> height,
  Value<int?> sizeBytes,
  Value<String> uploadStatus,
  Value<DateTime> createdAt,
  Value<DateTime?> uploadedAt,
  Value<int> rowid,
});

class $$MealAssetsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MealAssetsLocalTable> {
  $$MealAssetsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storageBucket => $composableBuilder(
      column: $table.storageBucket, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbLocalPath => $composableBuilder(
      column: $table.thumbLocalPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbStoragePath => $composableBuilder(
      column: $table.thumbStoragePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnFilters(column));
}

class $$MealAssetsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MealAssetsLocalTable> {
  $$MealAssetsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storageBucket => $composableBuilder(
      column: $table.storageBucket,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbLocalPath => $composableBuilder(
      column: $table.thumbLocalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbStoragePath => $composableBuilder(
      column: $table.thumbStoragePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnOrderings(column));
}

class $$MealAssetsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealAssetsLocalTable> {
  $$MealAssetsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get storageBucket => $composableBuilder(
      column: $table.storageBucket, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => column);

  GeneratedColumn<String> get thumbLocalPath => $composableBuilder(
      column: $table.thumbLocalPath, builder: (column) => column);

  GeneratedColumn<String> get thumbStoragePath => $composableBuilder(
      column: $table.thumbStoragePath, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => column);
}

class $$MealAssetsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealAssetsLocalTable,
    MealAssetsLocalData,
    $$MealAssetsLocalTableFilterComposer,
    $$MealAssetsLocalTableOrderingComposer,
    $$MealAssetsLocalTableAnnotationComposer,
    $$MealAssetsLocalTableCreateCompanionBuilder,
    $$MealAssetsLocalTableUpdateCompanionBuilder,
    (
      MealAssetsLocalData,
      BaseReferences<_$AppDatabase, $MealAssetsLocalTable, MealAssetsLocalData>
    ),
    MealAssetsLocalData,
    PrefetchHooks Function()> {
  $$MealAssetsLocalTableTableManager(
      _$AppDatabase db, $MealAssetsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealAssetsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealAssetsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealAssetsLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String> storageBucket = const Value.absent(),
            Value<String> storagePath = const Value.absent(),
            Value<String?> thumbLocalPath = const Value.absent(),
            Value<String?> thumbStoragePath = const Value.absent(),
            Value<String> sha256 = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<String> uploadStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> uploadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealAssetsLocalCompanion(
            id: id,
            userId: userId,
            localPath: localPath,
            storageBucket: storageBucket,
            storagePath: storagePath,
            thumbLocalPath: thumbLocalPath,
            thumbStoragePath: thumbStoragePath,
            sha256: sha256,
            mimeType: mimeType,
            width: width,
            height: height,
            sizeBytes: sizeBytes,
            uploadStatus: uploadStatus,
            createdAt: createdAt,
            uploadedAt: uploadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String localPath,
            Value<String> storageBucket = const Value.absent(),
            required String storagePath,
            Value<String?> thumbLocalPath = const Value.absent(),
            Value<String?> thumbStoragePath = const Value.absent(),
            required String sha256,
            Value<String> mimeType = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<String> uploadStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> uploadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealAssetsLocalCompanion.insert(
            id: id,
            userId: userId,
            localPath: localPath,
            storageBucket: storageBucket,
            storagePath: storagePath,
            thumbLocalPath: thumbLocalPath,
            thumbStoragePath: thumbStoragePath,
            sha256: sha256,
            mimeType: mimeType,
            width: width,
            height: height,
            sizeBytes: sizeBytes,
            uploadStatus: uploadStatus,
            createdAt: createdAt,
            uploadedAt: uploadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealAssetsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealAssetsLocalTable,
    MealAssetsLocalData,
    $$MealAssetsLocalTableFilterComposer,
    $$MealAssetsLocalTableOrderingComposer,
    $$MealAssetsLocalTableAnnotationComposer,
    $$MealAssetsLocalTableCreateCompanionBuilder,
    $$MealAssetsLocalTableUpdateCompanionBuilder,
    (
      MealAssetsLocalData,
      BaseReferences<_$AppDatabase, $MealAssetsLocalTable, MealAssetsLocalData>
    ),
    MealAssetsLocalData,
    PrefetchHooks Function()>;
typedef $$MealsLocalTableCreateCompanionBuilder = MealsLocalCompanion Function({
  required String id,
  required String userId,
  required String clientId,
  Value<String?> analysisJobId,
  required String title,
  required String mealType,
  required String source,
  required DateTime loggedAt,
  required String timezone,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<double?> confidenceOverall,
  Value<String?> provenanceType,
  Value<String?> photoAssetId,
  Value<int> revision,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$MealsLocalTableUpdateCompanionBuilder = MealsLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> clientId,
  Value<String?> analysisJobId,
  Value<String> title,
  Value<String> mealType,
  Value<String> source,
  Value<DateTime> loggedAt,
  Value<String> timezone,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<double?> confidenceOverall,
  Value<String?> provenanceType,
  Value<String?> photoAssetId,
  Value<int> revision,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$MealsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MealsLocalTable> {
  $$MealsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisJobId => $composableBuilder(
      column: $table.analysisJobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidenceOverall => $composableBuilder(
      column: $table.confidenceOverall,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provenanceType => $composableBuilder(
      column: $table.provenanceType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoAssetId => $composableBuilder(
      column: $table.photoAssetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revision => $composableBuilder(
      column: $table.revision, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$MealsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsLocalTable> {
  $$MealsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisJobId => $composableBuilder(
      column: $table.analysisJobId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidenceOverall => $composableBuilder(
      column: $table.confidenceOverall,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provenanceType => $composableBuilder(
      column: $table.provenanceType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoAssetId => $composableBuilder(
      column: $table.photoAssetId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revision => $composableBuilder(
      column: $table.revision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$MealsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsLocalTable> {
  $$MealsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get analysisJobId => $composableBuilder(
      column: $table.analysisJobId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get confidenceOverall => $composableBuilder(
      column: $table.confidenceOverall, builder: (column) => column);

  GeneratedColumn<String> get provenanceType => $composableBuilder(
      column: $table.provenanceType, builder: (column) => column);

  GeneratedColumn<String> get photoAssetId => $composableBuilder(
      column: $table.photoAssetId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MealsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealsLocalTable,
    MealsLocalData,
    $$MealsLocalTableFilterComposer,
    $$MealsLocalTableOrderingComposer,
    $$MealsLocalTableAnnotationComposer,
    $$MealsLocalTableCreateCompanionBuilder,
    $$MealsLocalTableUpdateCompanionBuilder,
    (
      MealsLocalData,
      BaseReferences<_$AppDatabase, $MealsLocalTable, MealsLocalData>
    ),
    MealsLocalData,
    PrefetchHooks Function()> {
  $$MealsLocalTableTableManager(_$AppDatabase db, $MealsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<String?> analysisJobId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> mealType = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> loggedAt = const Value.absent(),
            Value<String> timezone = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double?> confidenceOverall = const Value.absent(),
            Value<String?> provenanceType = const Value.absent(),
            Value<String?> photoAssetId = const Value.absent(),
            Value<int> revision = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealsLocalCompanion(
            id: id,
            userId: userId,
            clientId: clientId,
            analysisJobId: analysisJobId,
            title: title,
            mealType: mealType,
            source: source,
            loggedAt: loggedAt,
            timezone: timezone,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            confidenceOverall: confidenceOverall,
            provenanceType: provenanceType,
            photoAssetId: photoAssetId,
            revision: revision,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String clientId,
            Value<String?> analysisJobId = const Value.absent(),
            required String title,
            required String mealType,
            required String source,
            required DateTime loggedAt,
            required String timezone,
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double?> confidenceOverall = const Value.absent(),
            Value<String?> provenanceType = const Value.absent(),
            Value<String?> photoAssetId = const Value.absent(),
            Value<int> revision = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealsLocalCompanion.insert(
            id: id,
            userId: userId,
            clientId: clientId,
            analysisJobId: analysisJobId,
            title: title,
            mealType: mealType,
            source: source,
            loggedAt: loggedAt,
            timezone: timezone,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            confidenceOverall: confidenceOverall,
            provenanceType: provenanceType,
            photoAssetId: photoAssetId,
            revision: revision,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealsLocalTable,
    MealsLocalData,
    $$MealsLocalTableFilterComposer,
    $$MealsLocalTableOrderingComposer,
    $$MealsLocalTableAnnotationComposer,
    $$MealsLocalTableCreateCompanionBuilder,
    $$MealsLocalTableUpdateCompanionBuilder,
    (
      MealsLocalData,
      BaseReferences<_$AppDatabase, $MealsLocalTable, MealsLocalData>
    ),
    MealsLocalData,
    PrefetchHooks Function()>;
typedef $$MealItemsLocalTableCreateCompanionBuilder = MealItemsLocalCompanion
    Function({
  required String id,
  required String mealId,
  required String userId,
  required String clientId,
  required int position,
  required String name,
  Value<String> foodRefKind,
  Value<String?> canonicalFoodId,
  Value<String?> brandedProductId,
  Value<String?> customFoodId,
  required double quantity,
  required String unit,
  Value<double?> gramsEstimated,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<double?> confidence,
  Value<String?> sourceType,
  Value<String?> sourceId,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$MealItemsLocalTableUpdateCompanionBuilder = MealItemsLocalCompanion
    Function({
  Value<String> id,
  Value<String> mealId,
  Value<String> userId,
  Value<String> clientId,
  Value<int> position,
  Value<String> name,
  Value<String> foodRefKind,
  Value<String?> canonicalFoodId,
  Value<String?> brandedProductId,
  Value<String?> customFoodId,
  Value<double> quantity,
  Value<String> unit,
  Value<double?> gramsEstimated,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<double?> confidence,
  Value<String?> sourceType,
  Value<String?> sourceId,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$MealItemsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MealItemsLocalTable> {
  $$MealItemsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodRefKind => $composableBuilder(
      column: $table.foodRefKind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get canonicalFoodId => $composableBuilder(
      column: $table.canonicalFoodId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brandedProductId => $composableBuilder(
      column: $table.brandedProductId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customFoodId => $composableBuilder(
      column: $table.customFoodId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gramsEstimated => $composableBuilder(
      column: $table.gramsEstimated,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MealItemsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MealItemsLocalTable> {
  $$MealItemsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodRefKind => $composableBuilder(
      column: $table.foodRefKind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get canonicalFoodId => $composableBuilder(
      column: $table.canonicalFoodId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brandedProductId => $composableBuilder(
      column: $table.brandedProductId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customFoodId => $composableBuilder(
      column: $table.customFoodId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gramsEstimated => $composableBuilder(
      column: $table.gramsEstimated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MealItemsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealItemsLocalTable> {
  $$MealItemsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get foodRefKind => $composableBuilder(
      column: $table.foodRefKind, builder: (column) => column);

  GeneratedColumn<String> get canonicalFoodId => $composableBuilder(
      column: $table.canonicalFoodId, builder: (column) => column);

  GeneratedColumn<String> get brandedProductId => $composableBuilder(
      column: $table.brandedProductId, builder: (column) => column);

  GeneratedColumn<String> get customFoodId => $composableBuilder(
      column: $table.customFoodId, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get gramsEstimated => $composableBuilder(
      column: $table.gramsEstimated, builder: (column) => column);

  GeneratedColumn<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MealItemsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealItemsLocalTable,
    MealItemsLocalData,
    $$MealItemsLocalTableFilterComposer,
    $$MealItemsLocalTableOrderingComposer,
    $$MealItemsLocalTableAnnotationComposer,
    $$MealItemsLocalTableCreateCompanionBuilder,
    $$MealItemsLocalTableUpdateCompanionBuilder,
    (
      MealItemsLocalData,
      BaseReferences<_$AppDatabase, $MealItemsLocalTable, MealItemsLocalData>
    ),
    MealItemsLocalData,
    PrefetchHooks Function()> {
  $$MealItemsLocalTableTableManager(
      _$AppDatabase db, $MealItemsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealItemsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealItemsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealItemsLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> mealId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> foodRefKind = const Value.absent(),
            Value<String?> canonicalFoodId = const Value.absent(),
            Value<String?> brandedProductId = const Value.absent(),
            Value<String?> customFoodId = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double?> gramsEstimated = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<String?> sourceType = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealItemsLocalCompanion(
            id: id,
            mealId: mealId,
            userId: userId,
            clientId: clientId,
            position: position,
            name: name,
            foodRefKind: foodRefKind,
            canonicalFoodId: canonicalFoodId,
            brandedProductId: brandedProductId,
            customFoodId: customFoodId,
            quantity: quantity,
            unit: unit,
            gramsEstimated: gramsEstimated,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            confidence: confidence,
            sourceType: sourceType,
            sourceId: sourceId,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String mealId,
            required String userId,
            required String clientId,
            required int position,
            required String name,
            Value<String> foodRefKind = const Value.absent(),
            Value<String?> canonicalFoodId = const Value.absent(),
            Value<String?> brandedProductId = const Value.absent(),
            Value<String?> customFoodId = const Value.absent(),
            required double quantity,
            required String unit,
            Value<double?> gramsEstimated = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<String?> sourceType = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealItemsLocalCompanion.insert(
            id: id,
            mealId: mealId,
            userId: userId,
            clientId: clientId,
            position: position,
            name: name,
            foodRefKind: foodRefKind,
            canonicalFoodId: canonicalFoodId,
            brandedProductId: brandedProductId,
            customFoodId: customFoodId,
            quantity: quantity,
            unit: unit,
            gramsEstimated: gramsEstimated,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            confidence: confidence,
            sourceType: sourceType,
            sourceId: sourceId,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealItemsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealItemsLocalTable,
    MealItemsLocalData,
    $$MealItemsLocalTableFilterComposer,
    $$MealItemsLocalTableOrderingComposer,
    $$MealItemsLocalTableAnnotationComposer,
    $$MealItemsLocalTableCreateCompanionBuilder,
    $$MealItemsLocalTableUpdateCompanionBuilder,
    (
      MealItemsLocalData,
      BaseReferences<_$AppDatabase, $MealItemsLocalTable, MealItemsLocalData>
    ),
    MealItemsLocalData,
    PrefetchHooks Function()>;
typedef $$MealTemplatesLocalTableCreateCompanionBuilder
    = MealTemplatesLocalCompanion Function({
  required String id,
  required String userId,
  required String clientId,
  required String title,
  required String snapshotJson,
  Value<String?> sourceMealId,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$MealTemplatesLocalTableUpdateCompanionBuilder
    = MealTemplatesLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> clientId,
  Value<String> title,
  Value<String> snapshotJson,
  Value<String?> sourceMealId,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$MealTemplatesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MealTemplatesLocalTable> {
  $$MealTemplatesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceMealId => $composableBuilder(
      column: $table.sourceMealId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$MealTemplatesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MealTemplatesLocalTable> {
  $$MealTemplatesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceMealId => $composableBuilder(
      column: $table.sourceMealId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$MealTemplatesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealTemplatesLocalTable> {
  $$MealTemplatesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => column);

  GeneratedColumn<String> get sourceMealId => $composableBuilder(
      column: $table.sourceMealId, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MealTemplatesLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealTemplatesLocalTable,
    MealTemplatesLocalData,
    $$MealTemplatesLocalTableFilterComposer,
    $$MealTemplatesLocalTableOrderingComposer,
    $$MealTemplatesLocalTableAnnotationComposer,
    $$MealTemplatesLocalTableCreateCompanionBuilder,
    $$MealTemplatesLocalTableUpdateCompanionBuilder,
    (
      MealTemplatesLocalData,
      BaseReferences<_$AppDatabase, $MealTemplatesLocalTable,
          MealTemplatesLocalData>
    ),
    MealTemplatesLocalData,
    PrefetchHooks Function()> {
  $$MealTemplatesLocalTableTableManager(
      _$AppDatabase db, $MealTemplatesLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTemplatesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealTemplatesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealTemplatesLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> snapshotJson = const Value.absent(),
            Value<String?> sourceMealId = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealTemplatesLocalCompanion(
            id: id,
            userId: userId,
            clientId: clientId,
            title: title,
            snapshotJson: snapshotJson,
            sourceMealId: sourceMealId,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String clientId,
            required String title,
            required String snapshotJson,
            Value<String?> sourceMealId = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealTemplatesLocalCompanion.insert(
            id: id,
            userId: userId,
            clientId: clientId,
            title: title,
            snapshotJson: snapshotJson,
            sourceMealId: sourceMealId,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealTemplatesLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealTemplatesLocalTable,
    MealTemplatesLocalData,
    $$MealTemplatesLocalTableFilterComposer,
    $$MealTemplatesLocalTableOrderingComposer,
    $$MealTemplatesLocalTableAnnotationComposer,
    $$MealTemplatesLocalTableCreateCompanionBuilder,
    $$MealTemplatesLocalTableUpdateCompanionBuilder,
    (
      MealTemplatesLocalData,
      BaseReferences<_$AppDatabase, $MealTemplatesLocalTable,
          MealTemplatesLocalData>
    ),
    MealTemplatesLocalData,
    PrefetchHooks Function()>;
typedef $$CustomFoodsLocalTableCreateCompanionBuilder
    = CustomFoodsLocalCompanion Function({
  required String id,
  required String userId,
  required String clientId,
  required String name,
  Value<String?> brand,
  Value<double?> servingQuantity,
  Value<String?> servingUnit,
  Value<double?> servingGrams,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$CustomFoodsLocalTableUpdateCompanionBuilder
    = CustomFoodsLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> clientId,
  Value<String> name,
  Value<String?> brand,
  Value<double?> servingQuantity,
  Value<String?> servingUnit,
  Value<double?> servingGrams,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$CustomFoodsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFoodsLocalTable> {
  $$CustomFoodsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get servingQuantity => $composableBuilder(
      column: $table.servingQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get servingUnit => $composableBuilder(
      column: $table.servingUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get servingGrams => $composableBuilder(
      column: $table.servingGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$CustomFoodsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFoodsLocalTable> {
  $$CustomFoodsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get servingQuantity => $composableBuilder(
      column: $table.servingQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get servingUnit => $composableBuilder(
      column: $table.servingUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get servingGrams => $composableBuilder(
      column: $table.servingGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomFoodsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFoodsLocalTable> {
  $$CustomFoodsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get servingQuantity => $composableBuilder(
      column: $table.servingQuantity, builder: (column) => column);

  GeneratedColumn<String> get servingUnit => $composableBuilder(
      column: $table.servingUnit, builder: (column) => column);

  GeneratedColumn<double> get servingGrams => $composableBuilder(
      column: $table.servingGrams, builder: (column) => column);

  GeneratedColumn<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CustomFoodsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomFoodsLocalTable,
    CustomFoodsLocalData,
    $$CustomFoodsLocalTableFilterComposer,
    $$CustomFoodsLocalTableOrderingComposer,
    $$CustomFoodsLocalTableAnnotationComposer,
    $$CustomFoodsLocalTableCreateCompanionBuilder,
    $$CustomFoodsLocalTableUpdateCompanionBuilder,
    (
      CustomFoodsLocalData,
      BaseReferences<_$AppDatabase, $CustomFoodsLocalTable,
          CustomFoodsLocalData>
    ),
    CustomFoodsLocalData,
    PrefetchHooks Function()> {
  $$CustomFoodsLocalTableTableManager(
      _$AppDatabase db, $CustomFoodsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFoodsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFoodsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFoodsLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> brand = const Value.absent(),
            Value<double?> servingQuantity = const Value.absent(),
            Value<String?> servingUnit = const Value.absent(),
            Value<double?> servingGrams = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomFoodsLocalCompanion(
            id: id,
            userId: userId,
            clientId: clientId,
            name: name,
            brand: brand,
            servingQuantity: servingQuantity,
            servingUnit: servingUnit,
            servingGrams: servingGrams,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String clientId,
            required String name,
            Value<String?> brand = const Value.absent(),
            Value<double?> servingQuantity = const Value.absent(),
            Value<String?> servingUnit = const Value.absent(),
            Value<double?> servingGrams = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomFoodsLocalCompanion.insert(
            id: id,
            userId: userId,
            clientId: clientId,
            name: name,
            brand: brand,
            servingQuantity: servingQuantity,
            servingUnit: servingUnit,
            servingGrams: servingGrams,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomFoodsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomFoodsLocalTable,
    CustomFoodsLocalData,
    $$CustomFoodsLocalTableFilterComposer,
    $$CustomFoodsLocalTableOrderingComposer,
    $$CustomFoodsLocalTableAnnotationComposer,
    $$CustomFoodsLocalTableCreateCompanionBuilder,
    $$CustomFoodsLocalTableUpdateCompanionBuilder,
    (
      CustomFoodsLocalData,
      BaseReferences<_$AppDatabase, $CustomFoodsLocalTable,
          CustomFoodsLocalData>
    ),
    CustomFoodsLocalData,
    PrefetchHooks Function()>;
typedef $$DailyRollupsLocalTableCreateCompanionBuilder
    = DailyRollupsLocalCompanion Function({
  required String userId,
  required DateTime day,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<int> mealCount,
  Value<bool> hasPhotoMeal,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$DailyRollupsLocalTableUpdateCompanionBuilder
    = DailyRollupsLocalCompanion Function({
  Value<String> userId,
  Value<DateTime> day,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<int> mealCount,
  Value<bool> hasPhotoMeal,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DailyRollupsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $DailyRollupsLocalTable> {
  $$DailyRollupsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mealCount => $composableBuilder(
      column: $table.mealCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasPhotoMeal => $composableBuilder(
      column: $table.hasPhotoMeal, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyRollupsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyRollupsLocalTable> {
  $$DailyRollupsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mealCount => $composableBuilder(
      column: $table.mealCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasPhotoMeal => $composableBuilder(
      column: $table.hasPhotoMeal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyRollupsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyRollupsLocalTable> {
  $$DailyRollupsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<int> get mealCount =>
      $composableBuilder(column: $table.mealCount, builder: (column) => column);

  GeneratedColumn<bool> get hasPhotoMeal => $composableBuilder(
      column: $table.hasPhotoMeal, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyRollupsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyRollupsLocalTable,
    DailyRollupsLocalData,
    $$DailyRollupsLocalTableFilterComposer,
    $$DailyRollupsLocalTableOrderingComposer,
    $$DailyRollupsLocalTableAnnotationComposer,
    $$DailyRollupsLocalTableCreateCompanionBuilder,
    $$DailyRollupsLocalTableUpdateCompanionBuilder,
    (
      DailyRollupsLocalData,
      BaseReferences<_$AppDatabase, $DailyRollupsLocalTable,
          DailyRollupsLocalData>
    ),
    DailyRollupsLocalData,
    PrefetchHooks Function()> {
  $$DailyRollupsLocalTableTableManager(
      _$AppDatabase db, $DailyRollupsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyRollupsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyRollupsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyRollupsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<DateTime> day = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<int> mealCount = const Value.absent(),
            Value<bool> hasPhotoMeal = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyRollupsLocalCompanion(
            userId: userId,
            day: day,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            mealCount: mealCount,
            hasPhotoMeal: hasPhotoMeal,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required DateTime day,
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<int> mealCount = const Value.absent(),
            Value<bool> hasPhotoMeal = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyRollupsLocalCompanion.insert(
            userId: userId,
            day: day,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            mealCount: mealCount,
            hasPhotoMeal: hasPhotoMeal,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyRollupsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyRollupsLocalTable,
    DailyRollupsLocalData,
    $$DailyRollupsLocalTableFilterComposer,
    $$DailyRollupsLocalTableOrderingComposer,
    $$DailyRollupsLocalTableAnnotationComposer,
    $$DailyRollupsLocalTableCreateCompanionBuilder,
    $$DailyRollupsLocalTableUpdateCompanionBuilder,
    (
      DailyRollupsLocalData,
      BaseReferences<_$AppDatabase, $DailyRollupsLocalTable,
          DailyRollupsLocalData>
    ),
    DailyRollupsLocalData,
    PrefetchHooks Function()>;
typedef $$CorrectionEventsLocalTableCreateCompanionBuilder
    = CorrectionEventsLocalCompanion Function({
  required String id,
  required String userId,
  Value<String?> mealId,
  Value<String?> analysisJobId,
  required String eventType,
  Value<String?> fieldName,
  Value<String?> beforeValueJson,
  Value<String?> afterValueJson,
  Value<String?> reason,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$CorrectionEventsLocalTableUpdateCompanionBuilder
    = CorrectionEventsLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> mealId,
  Value<String?> analysisJobId,
  Value<String> eventType,
  Value<String?> fieldName,
  Value<String?> beforeValueJson,
  Value<String?> afterValueJson,
  Value<String?> reason,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$CorrectionEventsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CorrectionEventsLocalTable> {
  $$CorrectionEventsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisJobId => $composableBuilder(
      column: $table.analysisJobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldName => $composableBuilder(
      column: $table.fieldName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get beforeValueJson => $composableBuilder(
      column: $table.beforeValueJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get afterValueJson => $composableBuilder(
      column: $table.afterValueJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CorrectionEventsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CorrectionEventsLocalTable> {
  $$CorrectionEventsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisJobId => $composableBuilder(
      column: $table.analysisJobId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldName => $composableBuilder(
      column: $table.fieldName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get beforeValueJson => $composableBuilder(
      column: $table.beforeValueJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get afterValueJson => $composableBuilder(
      column: $table.afterValueJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CorrectionEventsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CorrectionEventsLocalTable> {
  $$CorrectionEventsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get analysisJobId => $composableBuilder(
      column: $table.analysisJobId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get beforeValueJson => $composableBuilder(
      column: $table.beforeValueJson, builder: (column) => column);

  GeneratedColumn<String> get afterValueJson => $composableBuilder(
      column: $table.afterValueJson, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CorrectionEventsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CorrectionEventsLocalTable,
    CorrectionEventsLocalData,
    $$CorrectionEventsLocalTableFilterComposer,
    $$CorrectionEventsLocalTableOrderingComposer,
    $$CorrectionEventsLocalTableAnnotationComposer,
    $$CorrectionEventsLocalTableCreateCompanionBuilder,
    $$CorrectionEventsLocalTableUpdateCompanionBuilder,
    (
      CorrectionEventsLocalData,
      BaseReferences<_$AppDatabase, $CorrectionEventsLocalTable,
          CorrectionEventsLocalData>
    ),
    CorrectionEventsLocalData,
    PrefetchHooks Function()> {
  $$CorrectionEventsLocalTableTableManager(
      _$AppDatabase db, $CorrectionEventsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CorrectionEventsLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CorrectionEventsLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CorrectionEventsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> mealId = const Value.absent(),
            Value<String?> analysisJobId = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String?> fieldName = const Value.absent(),
            Value<String?> beforeValueJson = const Value.absent(),
            Value<String?> afterValueJson = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CorrectionEventsLocalCompanion(
            id: id,
            userId: userId,
            mealId: mealId,
            analysisJobId: analysisJobId,
            eventType: eventType,
            fieldName: fieldName,
            beforeValueJson: beforeValueJson,
            afterValueJson: afterValueJson,
            reason: reason,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> mealId = const Value.absent(),
            Value<String?> analysisJobId = const Value.absent(),
            required String eventType,
            Value<String?> fieldName = const Value.absent(),
            Value<String?> beforeValueJson = const Value.absent(),
            Value<String?> afterValueJson = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CorrectionEventsLocalCompanion.insert(
            id: id,
            userId: userId,
            mealId: mealId,
            analysisJobId: analysisJobId,
            eventType: eventType,
            fieldName: fieldName,
            beforeValueJson: beforeValueJson,
            afterValueJson: afterValueJson,
            reason: reason,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CorrectionEventsLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CorrectionEventsLocalTable,
        CorrectionEventsLocalData,
        $$CorrectionEventsLocalTableFilterComposer,
        $$CorrectionEventsLocalTableOrderingComposer,
        $$CorrectionEventsLocalTableAnnotationComposer,
        $$CorrectionEventsLocalTableCreateCompanionBuilder,
        $$CorrectionEventsLocalTableUpdateCompanionBuilder,
        (
          CorrectionEventsLocalData,
          BaseReferences<_$AppDatabase, $CorrectionEventsLocalTable,
              CorrectionEventsLocalData>
        ),
        CorrectionEventsLocalData,
        PrefetchHooks Function()>;
typedef $$WeeklyInsightsLocalTableCreateCompanionBuilder
    = WeeklyInsightsLocalCompanion Function({
  required String id,
  required String userId,
  required DateTime weekStart,
  required String insightType,
  required String title,
  required String summary,
  Value<String> payloadJson,
  Value<String> status,
  Value<DateTime?> generatedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$WeeklyInsightsLocalTableUpdateCompanionBuilder
    = WeeklyInsightsLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> weekStart,
  Value<String> insightType,
  Value<String> title,
  Value<String> summary,
  Value<String> payloadJson,
  Value<String> status,
  Value<DateTime?> generatedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$WeeklyInsightsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyInsightsLocalTable> {
  $$WeeklyInsightsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get insightType => $composableBuilder(
      column: $table.insightType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WeeklyInsightsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyInsightsLocalTable> {
  $$WeeklyInsightsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get insightType => $composableBuilder(
      column: $table.insightType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WeeklyInsightsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyInsightsLocalTable> {
  $$WeeklyInsightsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get insightType => $composableBuilder(
      column: $table.insightType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WeeklyInsightsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeeklyInsightsLocalTable,
    WeeklyInsightsLocalData,
    $$WeeklyInsightsLocalTableFilterComposer,
    $$WeeklyInsightsLocalTableOrderingComposer,
    $$WeeklyInsightsLocalTableAnnotationComposer,
    $$WeeklyInsightsLocalTableCreateCompanionBuilder,
    $$WeeklyInsightsLocalTableUpdateCompanionBuilder,
    (
      WeeklyInsightsLocalData,
      BaseReferences<_$AppDatabase, $WeeklyInsightsLocalTable,
          WeeklyInsightsLocalData>
    ),
    WeeklyInsightsLocalData,
    PrefetchHooks Function()> {
  $$WeeklyInsightsLocalTableTableManager(
      _$AppDatabase db, $WeeklyInsightsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyInsightsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyInsightsLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyInsightsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> weekStart = const Value.absent(),
            Value<String> insightType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> generatedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WeeklyInsightsLocalCompanion(
            id: id,
            userId: userId,
            weekStart: weekStart,
            insightType: insightType,
            title: title,
            summary: summary,
            payloadJson: payloadJson,
            status: status,
            generatedAt: generatedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime weekStart,
            required String insightType,
            required String title,
            required String summary,
            Value<String> payloadJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> generatedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WeeklyInsightsLocalCompanion.insert(
            id: id,
            userId: userId,
            weekStart: weekStart,
            insightType: insightType,
            title: title,
            summary: summary,
            payloadJson: payloadJson,
            status: status,
            generatedAt: generatedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeeklyInsightsLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeeklyInsightsLocalTable,
    WeeklyInsightsLocalData,
    $$WeeklyInsightsLocalTableFilterComposer,
    $$WeeklyInsightsLocalTableOrderingComposer,
    $$WeeklyInsightsLocalTableAnnotationComposer,
    $$WeeklyInsightsLocalTableCreateCompanionBuilder,
    $$WeeklyInsightsLocalTableUpdateCompanionBuilder,
    (
      WeeklyInsightsLocalData,
      BaseReferences<_$AppDatabase, $WeeklyInsightsLocalTable,
          WeeklyInsightsLocalData>
    ),
    WeeklyInsightsLocalData,
    PrefetchHooks Function()>;
typedef $$UserFoodDefaultsLocalTableCreateCompanionBuilder
    = UserFoodDefaultsLocalCompanion Function({
  required String id,
  required String userId,
  required String foodRefKind,
  required String foodRefId,
  required String foodName,
  Value<double> preferredQuantity,
  required String preferredUnit,
  Value<double?> preferredGrams,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<int> useCount,
  Value<DateTime?> lastUsedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserFoodDefaultsLocalTableUpdateCompanionBuilder
    = UserFoodDefaultsLocalCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> foodRefKind,
  Value<String> foodRefId,
  Value<String> foodName,
  Value<double> preferredQuantity,
  Value<String> preferredUnit,
  Value<double?> preferredGrams,
  Value<double> caloriesKcal,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<int> useCount,
  Value<DateTime?> lastUsedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserFoodDefaultsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $UserFoodDefaultsLocalTable> {
  $$UserFoodDefaultsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodRefKind => $composableBuilder(
      column: $table.foodRefKind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodRefId => $composableBuilder(
      column: $table.foodRefId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get preferredQuantity => $composableBuilder(
      column: $table.preferredQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get preferredUnit => $composableBuilder(
      column: $table.preferredUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get preferredGrams => $composableBuilder(
      column: $table.preferredGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get useCount => $composableBuilder(
      column: $table.useCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserFoodDefaultsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $UserFoodDefaultsLocalTable> {
  $$UserFoodDefaultsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodRefKind => $composableBuilder(
      column: $table.foodRefKind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodRefId => $composableBuilder(
      column: $table.foodRefId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get preferredQuantity => $composableBuilder(
      column: $table.preferredQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get preferredUnit => $composableBuilder(
      column: $table.preferredUnit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get preferredGrams => $composableBuilder(
      column: $table.preferredGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbsG => $composableBuilder(
      column: $table.carbsG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get useCount => $composableBuilder(
      column: $table.useCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserFoodDefaultsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserFoodDefaultsLocalTable> {
  $$UserFoodDefaultsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get foodRefKind => $composableBuilder(
      column: $table.foodRefKind, builder: (column) => column);

  GeneratedColumn<String> get foodRefId =>
      $composableBuilder(column: $table.foodRefId, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<double> get preferredQuantity => $composableBuilder(
      column: $table.preferredQuantity, builder: (column) => column);

  GeneratedColumn<String> get preferredUnit => $composableBuilder(
      column: $table.preferredUnit, builder: (column) => column);

  GeneratedColumn<double> get preferredGrams => $composableBuilder(
      column: $table.preferredGrams, builder: (column) => column);

  GeneratedColumn<double> get caloriesKcal => $composableBuilder(
      column: $table.caloriesKcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserFoodDefaultsLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserFoodDefaultsLocalTable,
    UserFoodDefaultsLocalData,
    $$UserFoodDefaultsLocalTableFilterComposer,
    $$UserFoodDefaultsLocalTableOrderingComposer,
    $$UserFoodDefaultsLocalTableAnnotationComposer,
    $$UserFoodDefaultsLocalTableCreateCompanionBuilder,
    $$UserFoodDefaultsLocalTableUpdateCompanionBuilder,
    (
      UserFoodDefaultsLocalData,
      BaseReferences<_$AppDatabase, $UserFoodDefaultsLocalTable,
          UserFoodDefaultsLocalData>
    ),
    UserFoodDefaultsLocalData,
    PrefetchHooks Function()> {
  $$UserFoodDefaultsLocalTableTableManager(
      _$AppDatabase db, $UserFoodDefaultsLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserFoodDefaultsLocalTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$UserFoodDefaultsLocalTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserFoodDefaultsLocalTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> foodRefKind = const Value.absent(),
            Value<String> foodRefId = const Value.absent(),
            Value<String> foodName = const Value.absent(),
            Value<double> preferredQuantity = const Value.absent(),
            Value<String> preferredUnit = const Value.absent(),
            Value<double?> preferredGrams = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserFoodDefaultsLocalCompanion(
            id: id,
            userId: userId,
            foodRefKind: foodRefKind,
            foodRefId: foodRefId,
            foodName: foodName,
            preferredQuantity: preferredQuantity,
            preferredUnit: preferredUnit,
            preferredGrams: preferredGrams,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            useCount: useCount,
            lastUsedAt: lastUsedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String foodRefKind,
            required String foodRefId,
            required String foodName,
            Value<double> preferredQuantity = const Value.absent(),
            required String preferredUnit,
            Value<double?> preferredGrams = const Value.absent(),
            Value<double> caloriesKcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> carbsG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<int> useCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserFoodDefaultsLocalCompanion.insert(
            id: id,
            userId: userId,
            foodRefKind: foodRefKind,
            foodRefId: foodRefId,
            foodName: foodName,
            preferredQuantity: preferredQuantity,
            preferredUnit: preferredUnit,
            preferredGrams: preferredGrams,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            useCount: useCount,
            lastUsedAt: lastUsedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserFoodDefaultsLocalTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserFoodDefaultsLocalTable,
        UserFoodDefaultsLocalData,
        $$UserFoodDefaultsLocalTableFilterComposer,
        $$UserFoodDefaultsLocalTableOrderingComposer,
        $$UserFoodDefaultsLocalTableAnnotationComposer,
        $$UserFoodDefaultsLocalTableCreateCompanionBuilder,
        $$UserFoodDefaultsLocalTableUpdateCompanionBuilder,
        (
          UserFoodDefaultsLocalData,
          BaseReferences<_$AppDatabase, $UserFoodDefaultsLocalTable,
              UserFoodDefaultsLocalData>
        ),
        UserFoodDefaultsLocalData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesLocalTableTableManager get profilesLocal =>
      $$ProfilesLocalTableTableManager(_db, _db.profilesLocal);
  $$NutritionGoalsLocalTableTableManager get nutritionGoalsLocal =>
      $$NutritionGoalsLocalTableTableManager(_db, _db.nutritionGoalsLocal);
  $$BodyMeasurementsLocalTableTableManager get bodyMeasurementsLocal =>
      $$BodyMeasurementsLocalTableTableManager(_db, _db.bodyMeasurementsLocal);
  $$DevicesLocalTableTableManager get devicesLocal =>
      $$DevicesLocalTableTableManager(_db, _db.devicesLocal);
  $$FeatureFlagsLocalTableTableManager get featureFlagsLocal =>
      $$FeatureFlagsLocalTableTableManager(_db, _db.featureFlagsLocal);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$OutboxCommandsTableTableManager get outboxCommands =>
      $$OutboxCommandsTableTableManager(_db, _db.outboxCommands);
  $$MealAssetsLocalTableTableManager get mealAssetsLocal =>
      $$MealAssetsLocalTableTableManager(_db, _db.mealAssetsLocal);
  $$MealsLocalTableTableManager get mealsLocal =>
      $$MealsLocalTableTableManager(_db, _db.mealsLocal);
  $$MealItemsLocalTableTableManager get mealItemsLocal =>
      $$MealItemsLocalTableTableManager(_db, _db.mealItemsLocal);
  $$MealTemplatesLocalTableTableManager get mealTemplatesLocal =>
      $$MealTemplatesLocalTableTableManager(_db, _db.mealTemplatesLocal);
  $$CustomFoodsLocalTableTableManager get customFoodsLocal =>
      $$CustomFoodsLocalTableTableManager(_db, _db.customFoodsLocal);
  $$DailyRollupsLocalTableTableManager get dailyRollupsLocal =>
      $$DailyRollupsLocalTableTableManager(_db, _db.dailyRollupsLocal);
  $$CorrectionEventsLocalTableTableManager get correctionEventsLocal =>
      $$CorrectionEventsLocalTableTableManager(_db, _db.correctionEventsLocal);
  $$WeeklyInsightsLocalTableTableManager get weeklyInsightsLocal =>
      $$WeeklyInsightsLocalTableTableManager(_db, _db.weeklyInsightsLocal);
  $$UserFoodDefaultsLocalTableTableManager get userFoodDefaultsLocal =>
      $$UserFoodDefaultsLocalTableTableManager(_db, _db.userFoodDefaultsLocal);
}
