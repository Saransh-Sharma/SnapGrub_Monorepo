-- Placeholder smoke checks for CI wiring.
-- The full test runner should create two auth users and assert cross-user access is denied.

select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'profiles',
    'nutrition_goals',
    'devices',
    'feature_flags',
    'analytics_events',
    'body_measurements',
    'feature_flag_overrides',
    'meals',
    'meal_items',
    'meal_templates',
    'custom_foods',
    'daily_rollups',
    'correction_events'
  );
