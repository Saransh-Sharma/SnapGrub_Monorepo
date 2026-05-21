insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('meal-originals-private', 'meal-originals-private', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('meal-thumbnails-private', 'meal-thumbnails-private', false, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
  ('exports-private', 'exports-private', false, 52428800, array['application/json', 'text/csv', 'application/zip'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy upload_own_meal_originals
on storage.objects for insert to authenticated
with check (
  bucket_id = 'meal-originals-private'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy read_own_meal_originals
on storage.objects for select to authenticated
using (
  bucket_id = 'meal-originals-private'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy upload_own_meal_thumbnails
on storage.objects for insert to authenticated
with check (
  bucket_id = 'meal-thumbnails-private'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy read_own_meal_thumbnails
on storage.objects for select to authenticated
using (
  bucket_id = 'meal-thumbnails-private'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy read_own_exports
on storage.objects for select to authenticated
using (
  bucket_id = 'exports-private'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
