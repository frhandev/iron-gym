-- Expected for a fresh, standalone iron_gym database:
-- 13 base tables and 14 foreign key constraints.
SELECT count(*) AS base_tables FROM information_schema.tables
 WHERE table_schema='public' AND table_type='BASE TABLE';
SELECT count(*) AS foreign_keys FROM pg_constraint
 WHERE contype='f' AND connamespace='public'::regnamespace;
SELECT conrelid::regclass AS table_name,conname,pg_get_constraintdef(oid) AS definition
 FROM pg_constraint WHERE connamespace='public'::regnamespace
 ORDER BY conrelid::regclass::text,conname;
SELECT event_object_table,trigger_name FROM information_schema.triggers
 WHERE trigger_schema='public' ORDER BY event_object_table,trigger_name;
