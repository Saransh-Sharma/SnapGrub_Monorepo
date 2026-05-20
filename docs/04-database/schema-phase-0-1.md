# Phase 0/1 Schema

This page summarizes current migrations. Migration SQL is the final source of truth.

## User-Owned Tables

- `profiles`: one row per auth user, locale/timezone/unit/profile preferences, onboarding completion.
- `nutrition_goals`: active calorie and macro goals; partial unique index enforces one active goal per user.
- `devices`: stable install ID, platform, app/build versions, push token, sync cursor.
- `body_measurements`: weight/body-fat measurements from onboarding or manual entry.

## Shared Or Service Tables

- `feature_flags`: authenticated users can read global flags.
- `feature_flag_overrides`: service-side override rules, not client-readable.
- `analytics_events`: append-only client inserts; no client reads.
- `api_idempotency`: stores endpoint/key/hash/response snapshots for idempotent replay.

## Storage

Private buckets are created for meal originals, thumbnails, and exports. Phase 1 does not implement camera or meal upload behavior.

## Indexes And Constraints

- `one_active_goal_per_user` enforces one active goal.
- User/time indexes support profile-related reads.
- Check constraints validate unit systems, goal type, macro ranges, measurement ranges, and device platform.
