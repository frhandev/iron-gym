-- Run only in a disposable database after scripts 01–03.
-- All generated test rows are rolled back.
BEGIN;
DO $$
DECLARE
 a BIGINT; b BIGINT; c BIGINT; instructor BIGINT;
 pkg BIGINT; classid BIGINT; room1 BIGINT; room2 BIGINT;
 membership_a BIGINT; sess BIGINT;
 starts TIMESTAMP := (CURRENT_DATE+2)::timestamp + INTERVAL '10 hours';
 failure_msg TEXT;
BEGIN
 SELECT package_id INTO pkg FROM "MembershipPackages" WHERE package_name='Gold';
 SELECT class_id INTO classid FROM "GroupClasses" WHERE class_name='Yoga';
 SELECT room_id INTO room1 FROM "Rooms" WHERE room_name='Yoga Room';
 SELECT room_id INTO room2 FROM "Rooms" WHERE room_name='Pilates Room';
 IF pkg IS NULL OR classid IS NULL OR room1 IS NULL OR room2 IS NULL THEN
  RAISE EXCEPTION 'Run seed first';
 END IF;
 INSERT INTO "Users"(full_name,email,password_hash)
 VALUES('Test A','a_'||txid_current()||'@example.invalid','TEST_ONLY_NOT_REAL_HASH') RETURNING user_id INTO a;
 INSERT INTO "Users"(full_name,email,password_hash)
 VALUES('Test B','b_'||txid_current()||'@example.invalid','TEST_ONLY_NOT_REAL_HASH') RETURNING user_id INTO b;
 INSERT INTO "Users"(full_name,email,password_hash)
 VALUES('Test C','c_'||txid_current()||'@example.invalid','TEST_ONLY_NOT_REAL_HASH') RETURNING user_id INTO c;
 INSERT INTO "Users"(full_name,email,password_hash)
 VALUES('Test Trainer','t_'||txid_current()||'@example.invalid','TEST_ONLY_NOT_REAL_HASH') RETURNING user_id INTO instructor;
 INSERT INTO "UserRoles"(user_id,role_id)
 SELECT ids.uid,r.role_id FROM (VALUES(a),(b),(c)) AS ids(uid)
 CROSS JOIN "Roles" r WHERE r.role_name='Üye';
 INSERT INTO "UserRoles"(user_id,role_id)
 SELECT instructor,role_id FROM "Roles" WHERE role_name='Eğitmen';
 INSERT INTO "MemberProfiles"(member_id,member_number)
 VALUES(a,'TEST-'||a),(b,'TEST-'||b),(c,'TEST-'||c);
 INSERT INTO "TrainerProfiles"(trainer_id,specialty,hire_date)
 VALUES(instructor,'Yoga',CURRENT_DATE);
 INSERT INTO "Memberships"(member_id,package_id,agreed_price,start_date,end_date)
 VALUES(a,pkg,2700,CURRENT_DATE,CURRENT_DATE+30) RETURNING membership_id INTO membership_a;
 INSERT INTO "Memberships"(member_id,package_id,agreed_price,start_date,end_date)
 VALUES(b,pkg,2700,CURRENT_DATE,CURRENT_DATE+30);
 INSERT INTO "ClassSessions"(class_id,trainer_id,room_id,start_time,end_time,capacity)
 VALUES(classid,instructor,room1,starts,starts+INTERVAL '1 hour',1)
 RETURNING session_id INTO sess;
 INSERT INTO "Reservations"(member_id,session_id) VALUES(a,sess);
 -- BR-01
 BEGIN
  INSERT INTO "Users"(full_name,email,password_hash)
  SELECT 'Duplicate',email,'TEST' FROM "Users" WHERE user_id=a;
  RAISE EXCEPTION 'BR-01 accepted invalid email';
 EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS BR-01'; END;
 -- BR-02
 BEGIN
  INSERT INTO "Memberships"(member_id,package_id,agreed_price,start_date,end_date)
  VALUES(a,pkg,2700,CURRENT_DATE,CURRENT_DATE);
  RAISE EXCEPTION 'BR-02 accepted invalid dates';
 EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS BR-02'; END;
 -- BR-03
 BEGIN
  INSERT INTO "Memberships"(member_id,package_id,agreed_price,start_date,end_date)
  VALUES(a,pkg,2700,CURRENT_DATE+3,CURRENT_DATE+20);
  RAISE EXCEPTION 'BR-03 accepted membership overlap';
 EXCEPTION WHEN exclusion_violation THEN RAISE NOTICE 'PASS BR-03'; END;
 -- BR-04
 BEGIN
  INSERT INTO "Payments"(membership_id,amount,payment_method)
  VALUES(membership_a,0,'cash');
  RAISE EXCEPTION 'BR-04 accepted zero payment';
 EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS BR-04'; END;
 -- BR-05: c has no membership
 BEGIN
  INSERT INTO "Reservations"(member_id,session_id) VALUES(c,sess);
  RAISE EXCEPTION 'BR-05 accepted ineligible member' USING ERRCODE='P9000';
 EXCEPTION WHEN SQLSTATE 'P0001' THEN
  GET STACKED DIAGNOSTICS failure_msg=MESSAGE_TEXT;
  IF failure_msg<>'No active membership on reservation date' THEN
    RAISE EXCEPTION 'Wrong BR-05 exception: %',failure_msg;
  END IF;
  RAISE NOTICE 'PASS BR-05';
 END;
 -- BR-06: repeated reservation
 BEGIN
  INSERT INTO "Reservations"(member_id,session_id) VALUES(a,sess);
  RAISE EXCEPTION 'BR-06 accepted duplicate';
 EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS BR-06'; END;
 -- BR-07: session full (capacity 1)
 BEGIN
  INSERT INTO "Reservations"(member_id,session_id) VALUES(b,sess);
  RAISE EXCEPTION 'BR-07 allowed overbooking' USING ERRCODE='P9000';
 EXCEPTION WHEN SQLSTATE 'P0001' THEN
  GET STACKED DIAGNOSTICS failure_msg=MESSAGE_TEXT;
  IF failure_msg<>'Session is full' THEN RAISE EXCEPTION 'Wrong BR-07 exception: %',failure_msg; END IF;
  RAISE NOTICE 'PASS BR-07';
 END;
 -- BR-08: same trainer in overlapping sessions
 BEGIN
  INSERT INTO "ClassSessions"(class_id,trainer_id,room_id,start_time,end_time,capacity)
  VALUES(classid,instructor,room2,starts+INTERVAL '30 minutes',starts+INTERVAL '90 minutes',10);
  RAISE EXCEPTION 'BR-08 accepted conflicting trainer';
 EXCEPTION WHEN exclusion_violation THEN RAISE NOTICE 'PASS BR-08'; END;
 RAISE NOTICE 'PASS: eight primary business-rule checks';
END $$;
ROLLBACK;
