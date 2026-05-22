grant usage on schema public to anon, authenticated, service_role;

grant select, insert, update, delete
on all tables in schema public
to authenticated;

grant usage, select, update
on all sequences in schema public
to authenticated;

grant all privileges
on all tables in schema public
to service_role;

grant all privileges
on all sequences in schema public
to service_role;

grant select, insert, update, delete
on storage.objects
to authenticated;

grant all privileges
on storage.objects
to service_role;
