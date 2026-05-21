// GENERATED CODE - DO NOT EDIT.
// Source: packages/api-contracts/openapi.yaml

export type UnitSystem = 'metric' | 'imperial';
export type GoalType = 'lose' | 'maintain' | 'gain' | 'custom';

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
