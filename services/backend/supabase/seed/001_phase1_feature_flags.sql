insert into public.feature_flags (key, enabled, rollout_percent, description)
values
  ('snapstrip.enabled', true, 100, 'Camera-first home capture strip'),
  ('photo_analysis.enabled', true, 100, 'Photo meal analysis entry point'),
  ('barcode.enabled', true, 100, 'Barcode packaged food entry point'),
  ('voice_capture.enabled', true, 100, 'Push-to-talk short meal entry'),
  ('ocr_assist.enabled', true, 100, 'Nutrition label OCR assist'),
  ('cloud_media_storage.enabled', true, 100, 'Private cloud media storage')
on conflict (key) do update set
  enabled = excluded.enabled,
  rollout_percent = excluded.rollout_percent,
  description = excluded.description,
  updated_at = now();
