BEGIN;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- BR-03: Inclusive membership dates, only 'active' records excluded.
ALTER TABLE "Memberships" ADD CONSTRAINT ex_active_memberships
 EXCLUDE USING gist (
  member_id WITH =, daterange(start_date,end_date,'[]') WITH &&
 ) WHERE (status='active');

-- BR-08: Half-open [start,end) intervals permit back-to-back sessions.
ALTER TABLE "ClassSessions" ADD CONSTRAINT ex_trainer_schedule
 EXCLUDE USING gist (
  trainer_id WITH =, tsrange(start_time,end_time,'[)') WITH &&
 ) WHERE (status<>'cancelled');

ALTER TABLE "ClassSessions" ADD CONSTRAINT ex_room_schedule
 EXCLUDE USING gist (
  room_id WITH =, tsrange(start_time,end_time,'[)') WITH &&
 ) WHERE (status<>'cancelled');

-- Locking the room stabilizes capacity validation against room changes.
CREATE OR REPLACE FUNCTION gym_validate_session() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE room_limit SMALLINT; booking_count BIGINT;
BEGIN
 SELECT capacity INTO room_limit FROM "Rooms" WHERE room_id=NEW.room_id FOR SHARE;
 IF NEW.capacity>room_limit THEN
   RAISE EXCEPTION 'Session capacity exceeds room capacity';
 END IF;
 IF TG_OP='UPDATE' THEN
  SELECT COUNT(*) INTO booking_count FROM "Reservations"
   WHERE session_id=NEW.session_id AND status='active';
  IF NEW.capacity<booking_count THEN
   RAISE EXCEPTION 'Session capacity below active bookings';
  END IF;
  IF NEW.status='cancelled' AND booking_count>0 THEN
   RAISE EXCEPTION 'Cancel reservations before cancelling session';
  END IF;
  IF booking_count>0 AND
      (OLD.class_id,OLD.trainer_id,OLD.room_id,OLD.start_time,OLD.end_time)
      IS DISTINCT FROM
      (NEW.class_id,NEW.trainer_id,NEW.room_id,NEW.start_time,NEW.end_time)
  THEN RAISE EXCEPTION 'Cannot reschedule session with active reservations';
  END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER trg_gym_session BEFORE INSERT OR UPDATE ON "ClassSessions"
 FOR EACH ROW EXECUTE FUNCTION gym_validate_session();

CREATE OR REPLACE FUNCTION gym_validate_room() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
 IF EXISTS(SELECT 1 FROM "ClassSessions"
           WHERE room_id=NEW.room_id AND status<>'cancelled' AND capacity>NEW.capacity)
 THEN RAISE EXCEPTION 'Room smaller than scheduled session capacity';
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER trg_gym_room BEFORE UPDATE OF capacity ON "Rooms"
 FOR EACH ROW EXECUTE FUNCTION gym_validate_room();

-- BR-05, BR-06, BR-07: Book only when membership valid on booking date.
-- Rows of ClassSessions are locked so concurrent reservations serialize
-- at default READ COMMITTED isolation level.
CREATE OR REPLACE FUNCTION gym_validate_reservation() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE s_start TIMESTAMP; s_capacity SMALLINT; s_status TEXT; reserved_count BIGINT;
BEGIN
 IF TG_OP='UPDATE' THEN
  IF (OLD.member_id,OLD.session_id,OLD.reserved_at)
     IS DISTINCT FROM (NEW.member_id,NEW.session_id,NEW.reserved_at)
  THEN RAISE EXCEPTION 'Reservation identity is immutable'; END IF;
  IF NEW.status=OLD.status THEN RETURN NEW; END IF;
 ELSE
  IF NEW.status<>'active' THEN
   RAISE EXCEPTION 'New reservations must be active';
  END IF;
  NEW.reserved_at:=LOCALTIMESTAMP;
 END IF;
 IF NEW.status='cancelled' THEN RETURN NEW; END IF;

 SELECT start_time, capacity, status INTO s_start,s_capacity,s_status
 FROM "ClassSessions" WHERE session_id=NEW.session_id FOR UPDATE;
 IF s_status<>'scheduled' OR s_start<=LOCALTIMESTAMP THEN
  RAISE EXCEPTION 'Session is unavailable for booking';
 END IF;
 IF NOT EXISTS(
  SELECT 1 FROM "Memberships" m JOIN "Users" u ON u.user_id=m.member_id
  WHERE m.member_id=NEW.member_id AND u.is_active
    AND m.status='active'
    AND NEW.reserved_at::date BETWEEN m.start_date AND m.end_date
 ) THEN
  RAISE EXCEPTION 'No active membership on reservation date';
 END IF;
 SELECT COUNT(*) INTO reserved_count FROM "Reservations"
 WHERE session_id=NEW.session_id AND status='active'
   AND reservation_id<>NEW.reservation_id;
 IF reserved_count>=s_capacity THEN RAISE EXCEPTION 'Session is full'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER trg_gym_reservation BEFORE INSERT OR UPDATE ON "Reservations"
 FOR EACH ROW EXECUTE FUNCTION gym_validate_reservation();

-- Attendance must refer to an active reservation and assigned trainer.
-- The API must authenticate the user and derive recorded_by server-side.
CREATE OR REPLACE FUNCTION gym_validate_attendance() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE r_status TEXT; s_status TEXT; instructor BIGINT;
BEGIN
 SELECT r.status,s.status,s.trainer_id INTO r_status,s_status,instructor
 FROM "Reservations" r JOIN "ClassSessions" s ON s.session_id=r.session_id
 WHERE r.reservation_id=NEW.reservation_id;
 IF r_status<>'active' OR s_status='cancelled' THEN
  RAISE EXCEPTION 'Attendance requires active reservation and noncancelled session';
 END IF;
 IF NEW.recorded_by<>instructor THEN
  RAISE EXCEPTION 'Only assigned trainer may record attendance';
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER trg_gym_attendance BEFORE INSERT OR UPDATE ON "AttendanceRecords"
 FOR EACH ROW EXECUTE FUNCTION gym_validate_attendance();

-- Member/trainer profiles require their corresponding role at creation.
CREATE OR REPLACE FUNCTION gym_profile_role() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE uid BIGINT; required_name TEXT;
BEGIN
 IF TG_TABLE_NAME='MemberProfiles' THEN uid:=NEW.member_id; required_name:='Üye';
 ELSE uid:=NEW.trainer_id; required_name:='Eğitmen'; END IF;
 IF NOT EXISTS (
  SELECT 1 FROM "UserRoles" ur JOIN "Roles" r ON r.role_id=ur.role_id
  WHERE ur.user_id=uid AND r.role_name=required_name
 ) THEN RAISE EXCEPTION 'Profile requires role %', required_name; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER trg_member_role BEFORE INSERT OR UPDATE ON "MemberProfiles"
 FOR EACH ROW EXECUTE FUNCTION gym_profile_role();
CREATE TRIGGER trg_trainer_role BEFORE INSERT OR UPDATE ON "TrainerProfiles"
 FOR EACH ROW EXECUTE FUNCTION gym_profile_role();

CREATE OR REPLACE FUNCTION gym_protect_profile_role() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE current_name TEXT;
BEGIN
 IF TG_OP='UPDATE' AND (OLD.user_id,OLD.role_id)=(NEW.user_id,NEW.role_id) THEN RETURN NEW; END IF;
 SELECT role_name INTO current_name FROM "Roles" WHERE role_id=OLD.role_id;
 IF current_name='Üye' AND EXISTS(SELECT 1 FROM "MemberProfiles" WHERE member_id=OLD.user_id)
 THEN RAISE EXCEPTION 'Remove member profile before Üye role'; END IF;
 IF current_name='Eğitmen' AND EXISTS(SELECT 1 FROM "TrainerProfiles" WHERE trainer_id=OLD.user_id)
 THEN RAISE EXCEPTION 'Remove trainer profile before Eğitmen role'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END $$;
CREATE TRIGGER trg_protect_profile_role
 BEFORE DELETE OR UPDATE OF user_id,role_id ON "UserRoles"
 FOR EACH ROW EXECUTE FUNCTION gym_protect_profile_role();
COMMIT;
