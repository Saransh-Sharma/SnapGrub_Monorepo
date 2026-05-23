update public.meal_assets ma
set retention_until = coalesce(ma.retention_until, now() + interval '24 hours')
from public.profiles p
where p.id = ma.user_id
  and ma.deleted_at is null
  and ma.retention_until is null
  and (
    p.cloud_media_storage is false
    or p.save_original_photos is false
  );

