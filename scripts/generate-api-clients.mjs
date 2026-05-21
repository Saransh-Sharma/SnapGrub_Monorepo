import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'yaml';

const check = process.argv.includes('--check');
const root = process.cwd();
const openApiPath = path.join(root, 'packages/api-contracts/openapi.yaml');
const openApi = parse(fs.readFileSync(openApiPath, 'utf8'));

const dartPath = path.join(root, 'packages/api-contracts/generated/dart/lib/src/contracts.dart');
const tsPath = path.join(root, 'packages/api-contracts/generated/typescript/src/index.ts');

const schemas = openApi.components.schemas;
const enumValues = (schemaName) => schemas[schemaName].enum;

const dart = `// GENERATED CODE - DO NOT EDIT.
// Source: packages/api-contracts/openapi.yaml

typedef JsonMap = Map<String, dynamic>;

enum UnitSystem { ${enumValues('UnitSystem').join(', ')} }

enum GoalType { ${enumValues('GoalType').join(', ')} }

class ErrorEnvelope {
  const ErrorEnvelope({
    required this.code,
    required this.message,
    required this.userMessage,
    required this.retryable,
    required this.requestId,
    required this.details,
  });

  final String code;
  final String message;
  final String userMessage;
  final bool retryable;
  final String requestId;
  final JsonMap details;

  factory ErrorEnvelope.fromJson(JsonMap json) => ErrorEnvelope(
        code: json['code'] as String,
        message: json['message'] as String,
        userMessage: json['user_message'] as String,
        retryable: json['retryable'] as bool,
        requestId: json['request_id'] as String,
        details: Map<String, dynamic>.from(json['details'] as Map? ?? const {}),
      );
}

class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.locale,
    required this.timezone,
    required this.unitSystem,
    required this.cuisinePreferences,
    required this.cloudMediaStorage,
    required this.saveOriginalPhotos,
    required this.aiImprovementConsent,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.avatarPath,
    this.countryCode,
    this.onboardingCompletedAt,
  });

  final String id;
  final String? displayName;
  final String? avatarPath;
  final String locale;
  final String timezone;
  final UnitSystem unitSystem;
  final String? countryCode;
  final List<String> cuisinePreferences;
  final bool cloudMediaStorage;
  final bool saveOriginalPhotos;
  final bool aiImprovementConsent;
  final DateTime? onboardingCompletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProfileDto.fromJson(JsonMap json) => ProfileDto(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        avatarPath: json['avatar_path'] as String?,
        locale: json['locale'] as String,
        timezone: json['timezone'] as String,
        unitSystem: UnitSystem.values.byName(json['unit_system'] as String),
        countryCode: json['country_code'] as String?,
        cuisinePreferences: List<String>.from(json['cuisine_preferences'] as List? ?? const []),
        cloudMediaStorage: json['cloud_media_storage'] as bool? ?? true,
        saveOriginalPhotos: json['save_original_photos'] as bool? ?? false,
        aiImprovementConsent: json['ai_improvement_consent'] as bool? ?? false,
        onboardingCompletedAt: _dateOrNull(json['onboarding_completed_at']),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class NutritionGoalDto {
  const NutritionGoalDto({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.startsOn,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.fiberG,
    this.endsOn,
  });

  final String id;
  final String userId;
  final GoalType goalType;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final DateTime startsOn;
  final DateTime? endsOn;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NutritionGoalDto.fromJson(JsonMap json) => NutritionGoalDto(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        goalType: GoalType.values.byName(json['goal_type'] as String),
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        fiberG: (json['fiber_g'] as num?)?.toDouble(),
        startsOn: DateTime.parse(json['starts_on'] as String),
        endsOn: _dateOrNull(json['ends_on']),
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class DeviceDto {
  const DeviceDto({
    required this.id,
    required this.userId,
    required this.installId,
    required this.platform,
    required this.lastSeenAt,
    this.appVersion,
    this.buildNumber,
  });

  final String id;
  final String userId;
  final String installId;
  final String platform;
  final String? appVersion;
  final String? buildNumber;
  final DateTime lastSeenAt;

  factory DeviceDto.fromJson(JsonMap json) => DeviceDto(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        installId: json['install_id'] as String,
        platform: json['platform'] as String,
        appVersion: json['app_version'] as String?,
        buildNumber: json['build_number'] as String?,
        lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      );
}

class ProfileBootstrapRequestDto {
  const ProfileBootstrapRequestDto({
    required this.installId,
    required this.platform,
    required this.timezone,
    this.appVersion,
    this.buildNumber,
    this.locale = 'en-US',
  });

  final String installId;
  final String platform;
  final String? appVersion;
  final String? buildNumber;
  final String locale;
  final String timezone;

  JsonMap toJson() => {
        'install_id': installId,
        'platform': platform,
        'app_version': appVersion,
        'build_number': buildNumber,
        'locale': locale,
        'timezone': timezone,
      };
}

class ProfileBootstrapResponseDto {
  const ProfileBootstrapResponseDto({
    required this.profile,
    required this.device,
    required this.featureFlags,
    required this.serverTime,
    required this.requestId,
    this.activeGoal,
  });

  final ProfileDto profile;
  final NutritionGoalDto? activeGoal;
  final DeviceDto device;
  final JsonMap featureFlags;
  final DateTime serverTime;
  final String requestId;

  factory ProfileBootstrapResponseDto.fromJson(JsonMap json) => ProfileBootstrapResponseDto(
        profile: ProfileDto.fromJson(Map<String, dynamic>.from(json['profile'] as Map)),
        activeGoal: json['active_goal'] == null
            ? null
            : NutritionGoalDto.fromJson(Map<String, dynamic>.from(json['active_goal'] as Map)),
        device: DeviceDto.fromJson(Map<String, dynamic>.from(json['device'] as Map)),
        featureFlags: Map<String, dynamic>.from(json['feature_flags'] as Map? ?? const {}),
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

class SettingsPatchRequestDto {
  const SettingsPatchRequestDto({
    required this.clientRequestId,
    this.profilePatch,
    this.activeGoalPatch,
    this.bodyMeasurement,
  });

  final String clientRequestId;
  final JsonMap? profilePatch;
  final JsonMap? activeGoalPatch;
  final JsonMap? bodyMeasurement;

  JsonMap toJson() => {
        'client_request_id': clientRequestId,
        if (profilePatch != null) 'profile_patch': profilePatch,
        if (activeGoalPatch != null) 'active_goal_patch': activeGoalPatch,
        if (bodyMeasurement != null) 'body_measurement': bodyMeasurement,
      };
}

class SettingsPatchResponseDto {
  const SettingsPatchResponseDto({
    required this.profile,
    required this.serverTime,
    required this.requestId,
    this.activeGoal,
    this.bodyMeasurement,
  });

  final ProfileDto profile;
  final NutritionGoalDto? activeGoal;
  final JsonMap? bodyMeasurement;
  final DateTime serverTime;
  final String requestId;

  factory SettingsPatchResponseDto.fromJson(JsonMap json) => SettingsPatchResponseDto(
        profile: ProfileDto.fromJson(Map<String, dynamic>.from(json['profile'] as Map)),
        activeGoal: json['active_goal'] == null
            ? null
            : NutritionGoalDto.fromJson(Map<String, dynamic>.from(json['active_goal'] as Map)),
        bodyMeasurement: json['body_measurement'] == null
            ? null
            : Map<String, dynamic>.from(json['body_measurement'] as Map),
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

class MealItemDto {
  const MealItemDto({
    required this.id,
    required this.mealId,
    required this.userId,
    required this.clientId,
    required this.position,
    required this.name,
    required this.foodRefKind,
    required this.quantity,
    required this.unit,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.createdAt,
    required this.updatedAt,
    this.canonicalFoodId,
    this.brandedProductId,
    this.customFoodId,
    this.gramsEstimated,
    this.confidence,
    this.sourceType,
    this.sourceId,
    this.notes,
  });

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

  factory MealItemDto.fromJson(JsonMap json) => MealItemDto(
        id: json['id'] as String,
        mealId: json['meal_id'] as String,
        userId: json['user_id'] as String,
        clientId: json['client_id'] as String,
        position: (json['position'] as num).toInt(),
        name: json['name'] as String,
        foodRefKind: json['food_ref_kind'] as String? ?? 'manual',
        canonicalFoodId: json['canonical_food_id'] as String?,
        brandedProductId: json['branded_product_id'] as String?,
        customFoodId: json['custom_food_id'] as String?,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        gramsEstimated: (json['grams_estimated'] as num?)?.toDouble(),
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble(),
        sourceType: json['source_type'] as String?,
        sourceId: json['source_id'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class MealDto {
  const MealDto({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.title,
    required this.mealType,
    required this.source,
    required this.loggedAt,
    required this.timezone,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.revision,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.analysisJobId,
    this.confidenceOverall,
    this.provenanceType,
    this.photoAssetId,
    this.deletedAt,
  });

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
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MealItemDto> items;

  factory MealDto.fromJson(JsonMap json) => MealDto(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        clientId: json['client_id'] as String,
        analysisJobId: json['analysis_job_id'] as String?,
        title: json['title'] as String,
        mealType: json['meal_type'] as String,
        source: json['source'] as String,
        loggedAt: DateTime.parse(json['logged_at'] as String),
        timezone: json['timezone'] as String,
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        confidenceOverall: (json['confidence_overall'] as num?)?.toDouble(),
        provenanceType: json['provenance_type'] as String?,
        photoAssetId: json['photo_asset_id'] as String?,
        revision: (json['revision'] as num).toInt(),
        deletedAt: _dateOrNull(json['deleted_at']),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        items: (json['items'] as List? ?? const [])
            .map((item) => MealItemDto.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class MealItemWriteDto {
  const MealItemWriteDto({
    required this.clientId,
    required this.position,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.foodRefKind = 'manual',
    this.canonicalFoodId,
    this.brandedProductId,
    this.customFoodId,
    this.gramsEstimated,
    this.confidence,
    this.sourceType,
    this.sourceId,
    this.notes,
  });

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

  JsonMap toJson() => {
        'client_id': clientId,
        'position': position,
        'name': name,
        'food_ref_kind': foodRefKind,
        'canonical_food_id': canonicalFoodId,
        'branded_product_id': brandedProductId,
        'custom_food_id': customFoodId,
        'quantity': quantity,
        'unit': unit,
        'grams_estimated': gramsEstimated,
        'calories_kcal': caloriesKcal,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'confidence': confidence,
        'source_type': sourceType,
        'source_id': sourceId,
        'notes': notes,
      };
}

class MealWriteRequestDto {
  const MealWriteRequestDto({
    required this.clientRequestId,
    this.id,
    required this.clientId,
    required this.title,
    required this.mealType,
    required this.source,
    required this.loggedAt,
    required this.timezone,
    required this.items,
    this.expectedRevision,
    this.confidenceOverall,
    this.provenanceType,
    this.analysisJobId,
    this.photoAssetId,
  });

  final String clientRequestId;
  final String? id;
  final String clientId;
  final int? expectedRevision;
  final String title;
  final String mealType;
  final String source;
  final DateTime loggedAt;
  final String timezone;
  final double? confidenceOverall;
  final String? provenanceType;
  final String? analysisJobId;
  final String? photoAssetId;
  final List<MealItemWriteDto> items;

  JsonMap toJson() => {
        'client_request_id': clientRequestId,
        if (id != null) 'id': id,
        'client_id': clientId,
        if (expectedRevision != null) 'expected_revision': expectedRevision,
        'title': title,
        'meal_type': mealType,
        'source': source,
        'logged_at': loggedAt.toUtc().toIso8601String(),
        'timezone': timezone,
        'confidence_overall': confidenceOverall,
        'provenance_type': provenanceType,
        'analysis_job_id': analysisJobId,
        'photo_asset_id': photoAssetId,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

class DailyRollupDto {
  const DailyRollupDto({
    required this.userId,
    required this.day,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealCount,
    required this.hasPhotoMeal,
    required this.updatedAt,
  });

  final String userId;
  final DateTime day;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;
  final bool hasPhotoMeal;
  final DateTime updatedAt;

  factory DailyRollupDto.fromJson(JsonMap json) => DailyRollupDto(
        userId: json['user_id'] as String,
        day: DateTime.parse(json['day'] as String),
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        mealCount: (json['meal_count'] as num).toInt(),
        hasPhotoMeal: json['has_photo_meal'] as bool,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class CorrectionEventDto {
  const CorrectionEventDto({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.createdAt,
    this.mealId,
    this.analysisJobId,
    this.fieldName,
    this.beforeValue,
    this.afterValue,
    this.reason,
  });

  final String id;
  final String userId;
  final String? mealId;
  final String? analysisJobId;
  final String eventType;
  final String? fieldName;
  final JsonMap? beforeValue;
  final JsonMap? afterValue;
  final String? reason;
  final DateTime createdAt;

  factory CorrectionEventDto.fromJson(JsonMap json) => CorrectionEventDto(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        mealId: json['meal_id'] as String?,
        analysisJobId: json['analysis_job_id'] as String?,
        eventType: json['event_type'] as String,
        fieldName: json['field_name'] as String?,
        beforeValue: json['before_value'] == null
            ? null
            : Map<String, dynamic>.from(json['before_value'] as Map),
        afterValue: json['after_value'] == null
            ? null
            : Map<String, dynamic>.from(json['after_value'] as Map),
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class MealWriteResponseDto {
  const MealWriteResponseDto({
    required this.meal,
    required this.dailyRollup,
    required this.correctionEvents,
    required this.serverTime,
    required this.requestId,
  });

  final MealDto meal;
  final DailyRollupDto dailyRollup;
  final List<CorrectionEventDto> correctionEvents;
  final DateTime serverTime;
  final String requestId;

  factory MealWriteResponseDto.fromJson(JsonMap json) => MealWriteResponseDto(
        meal: MealDto.fromJson(Map<String, dynamic>.from(json['meal'] as Map)),
        dailyRollup: DailyRollupDto.fromJson(Map<String, dynamic>.from(json['daily_rollup'] as Map)),
        correctionEvents: (json['correction_events'] as List? ?? const [])
            .map((event) => CorrectionEventDto.fromJson(Map<String, dynamic>.from(event as Map)))
            .toList(),
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

class MealListResponseDto {
  const MealListResponseDto({
    required this.meals,
    required this.dailyRollups,
    required this.serverTime,
    required this.requestId,
  });

  final List<MealDto> meals;
  final List<DailyRollupDto> dailyRollups;
  final DateTime serverTime;
  final String requestId;

  factory MealListResponseDto.fromJson(JsonMap json) => MealListResponseDto(
        meals: (json['meals'] as List? ?? const [])
            .map((meal) => MealDto.fromJson(Map<String, dynamic>.from(meal as Map)))
            .toList(),
        dailyRollups: (json['daily_rollups'] as List? ?? const [])
            .map((rollup) => DailyRollupDto.fromJson(Map<String, dynamic>.from(rollup as Map)))
            .toList(),
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

class FoodSearchRequestDto {
  const FoodSearchRequestDto({
    required this.query,
    this.locale = 'en-US',
    this.region,
    this.limit = 10,
  });

  final String query;
  final String locale;
  final String? region;
  final int limit;

  JsonMap toJson() => {
        'query': query,
        'locale': locale,
        'region': region,
        'limit': limit,
      };
}

class CatalogProvenanceDto {
  const CatalogProvenanceDto({
    required this.sourceType,
    this.sourceId,
    this.licenseTag,
    this.sourceQuality,
    this.raw = const {},
  });

  final String sourceType;
  final String? sourceId;
  final String? licenseTag;
  final String? sourceQuality;
  final JsonMap raw;

  factory CatalogProvenanceDto.fromJson(JsonMap json) => CatalogProvenanceDto(
        sourceType: json['source_type'] as String,
        sourceId: json['source_id'] as String?,
        licenseTag: json['license_tag'] as String?,
        sourceQuality: json['source_quality'] as String?,
        raw: Map<String, dynamic>.from(json['raw'] as Map? ?? const {}),
      );
}

class FoodSearchResultDto {
  const FoodSearchResultDto({
    required this.id,
    required this.resultType,
    required this.name,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
    required this.provenance,
    this.brand,
    this.servingQuantity,
    this.servingUnit,
    this.servingGrams,
  });

  final String id;
  final String resultType;
  final String name;
  final String? brand;
  final double? servingQuantity;
  final String? servingUnit;
  final double? servingGrams;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double confidence;
  final CatalogProvenanceDto provenance;

  factory FoodSearchResultDto.fromJson(JsonMap json) => FoodSearchResultDto(
        id: json['id'] as String,
        resultType: json['result_type'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        servingQuantity: (json['serving_quantity'] as num?)?.toDouble(),
        servingUnit: json['serving_unit'] as String?,
        servingGrams: (json['serving_grams'] as num?)?.toDouble(),
        caloriesKcal: (json['calories_kcal'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        provenance: CatalogProvenanceDto.fromJson(Map<String, dynamic>.from(json['provenance'] as Map)),
      );
}

class FoodsSearchResponseDto {
  const FoodsSearchResponseDto({
    required this.results,
    required this.serverTime,
    required this.requestId,
  });

  final List<FoodSearchResultDto> results;
  final DateTime serverTime;
  final String requestId;

  factory FoodsSearchResponseDto.fromJson(JsonMap json) => FoodsSearchResponseDto(
        results: (json['results'] as List? ?? const [])
            .map((result) => FoodSearchResultDto.fromJson(Map<String, dynamic>.from(result as Map)))
            .toList(),
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

class PhotoAnalysisCreateRequestDto {
  const PhotoAnalysisCreateRequestDto({
    required this.clientRequestId,
    required this.storagePath,
    required this.locale,
    required this.timezone,
    this.storageBucket = 'meal-originals-private',
    this.thumbStoragePath,
    this.assetSha256,
    this.mimeType = 'image/jpeg',
    this.width,
    this.height,
    this.sizeBytes,
    this.mealTypeHint,
    this.cuisineHints = const [],
    this.userHintText,
  });

  final String clientRequestId;
  final String storageBucket;
  final String storagePath;
  final String? thumbStoragePath;
  final String? assetSha256;
  final String mimeType;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final String? mealTypeHint;
  final String locale;
  final String timezone;
  final List<String> cuisineHints;
  final String? userHintText;

  JsonMap toJson() => {
        'client_request_id': clientRequestId,
        'storage_bucket': storageBucket,
        'storage_path': storagePath,
        'thumb_storage_path': thumbStoragePath,
        'asset_sha256': assetSha256,
        'mime_type': mimeType,
        'width': width,
        'height': height,
        'size_bytes': sizeBytes,
        'meal_type_hint': mealTypeHint,
        'locale': locale,
        'timezone': timezone,
        'cuisine_hints': cuisineHints,
        'user_hint_text': userHintText,
      };
}

class AnalysisWarningDto {
  const AnalysisWarningDto({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final String severity;

  factory AnalysisWarningDto.fromJson(JsonMap json) => AnalysisWarningDto(
        code: json['code'] as String,
        message: json['message'] as String,
        severity: json['severity'] as String,
      );
}

class AnalysisConfidenceDto {
  const AnalysisConfidenceDto({
    required this.overall,
    required this.itemIdentification,
    required this.portionEstimation,
    required this.nutritionSourceQuality,
    required this.warnings,
  });

  final double overall;
  final double itemIdentification;
  final double portionEstimation;
  final double nutritionSourceQuality;
  final List<AnalysisWarningDto> warnings;

  factory AnalysisConfidenceDto.fromJson(JsonMap json) => AnalysisConfidenceDto(
        overall: (json['overall'] as num).toDouble(),
        itemIdentification: (json['item_identification'] as num).toDouble(),
        portionEstimation: (json['portion_estimation'] as num).toDouble(),
        nutritionSourceQuality: (json['nutrition_source_quality'] as num).toDouble(),
        warnings: (json['warnings'] as List? ?? const [])
            .map((warning) => AnalysisWarningDto.fromJson(Map<String, dynamic>.from(warning as Map)))
            .toList(),
      );
}

class EditableMealDraftDto {
  const EditableMealDraftDto({
    required this.title,
    required this.mealType,
    required this.loggedAt,
    required this.timezone,
    required this.total,
    required this.confidence,
    required this.components,
    required this.provenance,
    this.alternatives = const [],
  });

  final String title;
  final String mealType;
  final DateTime loggedAt;
  final String timezone;
  final JsonMap total;
  final AnalysisConfidenceDto confidence;
  final List<MealItemWriteDto> components;
  final List<JsonMap> alternatives;
  final JsonMap provenance;

  factory EditableMealDraftDto.fromJson(JsonMap json) => EditableMealDraftDto(
        title: json['title'] as String,
        mealType: json['meal_type'] as String,
        loggedAt: DateTime.parse(json['logged_at'] as String),
        timezone: json['timezone'] as String,
        total: Map<String, dynamic>.from(json['total'] as Map),
        confidence: AnalysisConfidenceDto.fromJson(Map<String, dynamic>.from(json['confidence'] as Map)),
        components: (json['components'] as List? ?? const [])
            .map((item) => _mealItemWriteFromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        alternatives: (json['alternatives'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        provenance: Map<String, dynamic>.from(json['provenance'] as Map? ?? const {}),
      );
}

class PhotoAnalysisResponseDto {
  const PhotoAnalysisResponseDto({
    required this.analysisId,
    required this.status,
    required this.serverTime,
    required this.requestId,
    this.assetId,
    this.result,
    this.errorCode,
    this.retryable = false,
  });

  final String analysisId;
  final String? assetId;
  final String status;
  final EditableMealDraftDto? result;
  final String? errorCode;
  final bool retryable;
  final DateTime serverTime;
  final String requestId;

  factory PhotoAnalysisResponseDto.fromJson(JsonMap json) => PhotoAnalysisResponseDto(
        analysisId: json['analysis_id'] as String,
        assetId: json['asset_id'] as String?,
        status: json['status'] as String,
        result: json['result'] == null
            ? null
            : EditableMealDraftDto.fromJson(Map<String, dynamic>.from(json['result'] as Map)),
        errorCode: json['error_code'] as String?,
        retryable: json['retryable'] as bool? ?? false,
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

class BarcodeResolveRequestDto {
  const BarcodeResolveRequestDto({
    required this.barcode,
    required this.locale,
    required this.timezone,
    this.region,
  });

  final String barcode;
  final String locale;
  final String timezone;
  final String? region;

  JsonMap toJson() => {
        'barcode': barcode,
        'locale': locale,
        'timezone': timezone,
        'region': region,
      };
}

class BarcodeResolveResponseDto {
  const BarcodeResolveResponseDto({
    required this.barcode,
    required this.status,
    required this.serverTime,
    required this.requestId,
    this.product,
    this.draft,
    this.fallbackReason,
  });

  final String barcode;
  final String status;
  final FoodSearchResultDto? product;
  final EditableMealDraftDto? draft;
  final String? fallbackReason;
  final DateTime serverTime;
  final String requestId;

  factory BarcodeResolveResponseDto.fromJson(JsonMap json) => BarcodeResolveResponseDto(
        barcode: json['barcode'] as String,
        status: json['status'] as String,
        product: json['product'] == null
            ? null
            : FoodSearchResultDto.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
        draft: json['draft'] == null
            ? null
            : EditableMealDraftDto.fromJson(Map<String, dynamic>.from(json['draft'] as Map)),
        fallbackReason: json['fallback_reason'] as String?,
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

class TextAnalysisCreateRequestDto {
  const TextAnalysisCreateRequestDto({
    required this.clientRequestId,
    required this.text,
    required this.locale,
    required this.timezone,
    this.mealTypeHint,
    this.cuisineHints = const [],
  });

  final String clientRequestId;
  final String text;
  final String? mealTypeHint;
  final String locale;
  final String timezone;
  final List<String> cuisineHints;

  JsonMap toJson() => {
        'client_request_id': clientRequestId,
        'text': text,
        'meal_type_hint': mealTypeHint,
        'locale': locale,
        'timezone': timezone,
        'cuisine_hints': cuisineHints,
      };
}

class LabelAnalysisCreateRequestDto {
  const LabelAnalysisCreateRequestDto({
    required this.clientRequestId,
    required this.ocrText,
    required this.locale,
    required this.timezone,
    this.barcode,
    this.productNameHint,
    this.rawImageOptIn = false,
  });

  final String clientRequestId;
  final String ocrText;
  final String? barcode;
  final String? productNameHint;
  final String locale;
  final String timezone;
  final bool rawImageOptIn;

  JsonMap toJson() => {
        'client_request_id': clientRequestId,
        'ocr_text': ocrText,
        'barcode': barcode,
        'product_name_hint': productNameHint,
        'locale': locale,
        'timezone': timezone,
        'raw_image_opt_in': rawImageOptIn,
      };
}

class VoiceAnalysisCreateRequestDto {
  const VoiceAnalysisCreateRequestDto({
    required this.clientRequestId,
    required this.transcript,
    required this.locale,
    required this.timezone,
    this.transcriptConfidence,
    this.mealTypeHint,
    this.cuisineHints = const [],
  });

  final String clientRequestId;
  final String transcript;
  final double? transcriptConfidence;
  final String? mealTypeHint;
  final String locale;
  final String timezone;
  final List<String> cuisineHints;

  JsonMap toJson() => {
        'client_request_id': clientRequestId,
        'transcript': transcript,
        'transcript_confidence': transcriptConfidence,
        'meal_type_hint': mealTypeHint,
        'locale': locale,
        'timezone': timezone,
        'cuisine_hints': cuisineHints,
      };
}

class MultimodalAnalysisResponseDto {
  const MultimodalAnalysisResponseDto({
    required this.analysisId,
    required this.status,
    required this.result,
    required this.serverTime,
    required this.requestId,
    this.errorCode,
    this.retryable = false,
  });

  final String analysisId;
  final String status;
  final EditableMealDraftDto result;
  final String? errorCode;
  final bool retryable;
  final DateTime serverTime;
  final String requestId;

  factory MultimodalAnalysisResponseDto.fromJson(JsonMap json) => MultimodalAnalysisResponseDto(
        analysisId: json['analysis_id'] as String,
        status: json['status'] as String,
        result: EditableMealDraftDto.fromJson(Map<String, dynamic>.from(json['result'] as Map)),
        errorCode: json['error_code'] as String?,
        retryable: json['retryable'] as bool? ?? false,
        serverTime: DateTime.parse(json['server_time'] as String),
        requestId: json['request_id'] as String,
      );
}

MealItemWriteDto _mealItemWriteFromJson(JsonMap json) => MealItemWriteDto(
      clientId: json['client_id'] as String,
      position: (json['position'] as num).toInt(),
      name: json['name'] as String,
      foodRefKind: json['food_ref_kind'] as String? ?? 'manual',
      canonicalFoodId: json['canonical_food_id'] as String?,
      brandedProductId: json['branded_product_id'] as String?,
      customFoodId: json['custom_food_id'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      gramsEstimated: (json['grams_estimated'] as num?)?.toDouble(),
      caloriesKcal: (json['calories_kcal'] as num).toDouble(),
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      sourceType: json['source_type'] as String?,
      sourceId: json['source_id'] as String?,
      notes: json['notes'] as String?,
    );

DateTime? _dateOrNull(Object? value) => value == null ? null : DateTime.parse(value as String);
`;

const ts = `// GENERATED CODE - DO NOT EDIT.
// Source: packages/api-contracts/openapi.yaml

export type UnitSystem = '${enumValues('UnitSystem').join("' | '")}';
export type GoalType = '${enumValues('GoalType').join("' | '")}';

export type JsonMap = Record<string, unknown>;

export type ErrorEnvelope = {
  code: 'AUTH_REQUIRED' | 'INVALID_INPUT' | 'NOT_FOUND' | 'IDEMPOTENCY_CONFLICT' | 'CONFLICT' | 'UNKNOWN';
  message: string;
  user_message: string;
  retryable: boolean;
  request_id: string;
  details: JsonMap;
};

export type Profile = {
  id: string;
  display_name: string | null;
  avatar_path: string | null;
  locale: string;
  timezone: string;
  unit_system: UnitSystem;
  country_code: string | null;
  cuisine_preferences: string[];
  cloud_media_storage: boolean;
  save_original_photos: boolean;
  ai_improvement_consent: boolean;
  onboarding_completed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type NutritionGoal = {
  id: string;
  user_id: string;
  goal_type: GoalType;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  fiber_g: number | null;
  starts_on: string;
  ends_on: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type Device = {
  id: string;
  user_id: string;
  install_id: string;
  platform: 'ios' | 'android';
  app_version: string | null;
  build_number: string | null;
  last_seen_at: string;
};

export type ProfileBootstrapRequest = {
  install_id: string;
  platform: 'ios' | 'android';
  app_version?: string | null;
  build_number?: string | null;
  locale?: string;
  timezone: string;
};

export type ProfileBootstrapResponse = {
  profile: Profile;
  active_goal: NutritionGoal | null;
  device: Device;
  feature_flags: JsonMap;
  server_time: string;
  request_id: string;
};

export type SettingsPatchRequest = {
  client_request_id: string;
  profile_patch?: JsonMap;
  active_goal_patch?: JsonMap;
  body_measurement?: JsonMap | null;
};

export type SettingsPatchResponse = {
  profile: Profile;
  active_goal: NutritionGoal | null;
  body_measurement: JsonMap | null;
  server_time: string;
  request_id: string;
};

export type MealItem = {
  id: string;
  meal_id: string;
  user_id: string;
  client_id: string;
  position: number;
  name: string;
  food_ref_kind: 'canonical' | 'branded' | 'custom' | 'manual';
  canonical_food_id: string | null;
  branded_product_id: string | null;
  custom_food_id: string | null;
  quantity: number;
  unit: string;
  grams_estimated: number | null;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  confidence: number | null;
  source_type: string | null;
  source_id: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type Meal = {
  id: string;
  user_id: string;
  client_id: string;
  analysis_job_id: string | null;
  title: string;
  meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'unknown';
  source: 'photo' | 'barcode' | 'text' | 'voice' | 'manual' | 'duplicate';
  logged_at: string;
  timezone: string;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  confidence_overall: number | null;
  provenance_type: string | null;
  photo_asset_id: string | null;
  revision: number;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
  items: MealItem[];
};

export type MealItemWrite = Omit<MealItem, 'id' | 'meal_id' | 'user_id' | 'created_at' | 'updated_at'>;

export type MealWriteRequest = {
  client_request_id: string;
  id?: string | null;
  client_id: string;
  expected_revision?: number;
  title: string;
  meal_type: Meal['meal_type'];
  source: Meal['source'];
  logged_at: string;
  timezone: string;
  confidence_overall?: number | null;
  provenance_type?: string | null;
  analysis_job_id?: string | null;
  photo_asset_id?: string | null;
  items: MealItemWrite[];
};

export type DailyRollup = {
  user_id: string;
  day: string;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  meal_count: number;
  has_photo_meal: boolean;
  updated_at: string;
};

export type CorrectionEvent = {
  id: string;
  user_id: string;
  meal_id: string | null;
  analysis_job_id: string | null;
  event_type: string;
  field_name: string | null;
  before_value: JsonMap | null;
  after_value: JsonMap | null;
  reason: string | null;
  created_at: string;
};

export type MealWriteResponse = {
  meal: Meal;
  daily_rollup: DailyRollup;
  correction_events: CorrectionEvent[];
  server_time: string;
  request_id: string;
};

export type MealListResponse = {
  meals: Meal[];
  daily_rollups: DailyRollup[];
  server_time: string;
  request_id: string;
};

export type AnalysisStatus = 'queued' | 'processing' | 'completed' | 'failed';

export type CatalogProvenance = {
  source_type: string;
  source_id: string | null;
  license_tag: string | null;
  source_quality: string | null;
  raw?: JsonMap;
};

export type FoodSearchRequest = {
  query: string;
  locale?: string;
  region?: string | null;
  limit?: number;
};

export type FoodSearchResult = {
  id: string;
  result_type: 'canonical' | 'branded' | 'custom' | 'recent';
  name: string;
  brand?: string | null;
  serving_quantity?: number | null;
  serving_unit?: string | null;
  serving_grams?: number | null;
  calories_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  confidence: number;
  provenance: CatalogProvenance;
};

export type FoodsSearchResponse = {
  results: FoodSearchResult[];
  server_time: string;
  request_id: string;
};

export type PhotoAnalysisCreateRequest = {
  client_request_id: string;
  storage_bucket?: string;
  storage_path: string;
  thumb_storage_path?: string | null;
  asset_sha256?: string | null;
  mime_type?: string;
  width?: number | null;
  height?: number | null;
  size_bytes?: number | null;
  meal_type_hint?: Meal['meal_type'] | null;
  locale: string;
  timezone: string;
  cuisine_hints?: string[];
  user_hint_text?: string | null;
};

export type AnalysisWarning = {
  code: string;
  message: string;
  severity: 'info' | 'review' | 'high';
};

export type AnalysisConfidence = {
  overall: number;
  item_identification: number;
  portion_estimation: number;
  nutrition_source_quality: number;
  warnings: AnalysisWarning[];
};

export type EditableMealDraft = {
  title: string;
  meal_type: Meal['meal_type'];
  logged_at: string;
  timezone: string;
  total: {
    calories_kcal: number;
    protein_g: number;
    carbs_g: number;
    fat_g: number;
  };
  confidence: AnalysisConfidence;
  components: MealItemWrite[];
  alternatives?: JsonMap[];
  provenance: JsonMap;
};

export type PhotoAnalysisResponse = {
  analysis_id: string;
  asset_id: string | null;
  status: AnalysisStatus;
  result: EditableMealDraft | null;
  error_code: string | null;
  retryable: boolean;
  server_time: string;
  request_id: string;
};

export type BarcodeResolveRequest = {
  barcode: string;
  locale: string;
  timezone: string;
  region?: string | null;
};

export type BarcodeResolveResponse = {
  barcode: string;
  status: 'matched' | 'not_found' | 'fallback';
  product: FoodSearchResult | null;
  draft: EditableMealDraft | null;
  fallback_reason: string | null;
  server_time: string;
  request_id: string;
};

export type TextAnalysisCreateRequest = {
  client_request_id: string;
  text: string;
  meal_type_hint?: Meal['meal_type'] | null;
  locale: string;
  timezone: string;
  cuisine_hints?: string[];
};

export type LabelAnalysisCreateRequest = {
  client_request_id: string;
  ocr_text: string;
  barcode?: string | null;
  product_name_hint?: string | null;
  locale: string;
  timezone: string;
  raw_image_opt_in?: boolean;
};

export type VoiceAnalysisCreateRequest = {
  client_request_id: string;
  transcript: string;
  transcript_confidence?: number | null;
  meal_type_hint?: Meal['meal_type'] | null;
  locale: string;
  timezone: string;
  cuisine_hints?: string[];
};

export type MultimodalAnalysisResponse = {
  analysis_id: string;
  status: AnalysisStatus;
  result: EditableMealDraft;
  error_code: string | null;
  retryable: boolean;
  server_time: string;
  request_id: string;
};
`;

function writeOrCheck(filePath, contents) {
  if (check) {
    const current = fs.existsSync(filePath) ? fs.readFileSync(filePath, 'utf8') : '';
    if (current !== contents) {
      console.error(`Generated file is stale: ${path.relative(root, filePath)}`);
      process.exitCode = 1;
    }
    return;
  }
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, contents);
}

writeOrCheck(dartPath, dart);
writeOrCheck(tsPath, ts);

if (!process.exitCode) {
  console.log(check ? 'Generated API clients are fresh.' : 'Generated API clients updated.');
}
