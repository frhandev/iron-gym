BEGIN;
CREATE TABLE "Users" (
 user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 full_name VARCHAR(100) NOT NULL,
 email VARCHAR(255) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 phone VARCHAR(20),
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX ux_users_email_ci ON "Users"(lower(email));
CREATE TABLE "Roles" (
 role_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 role_name VARCHAR(30) NOT NULL UNIQUE,
 description VARCHAR(255)
);
CREATE TABLE "UserRoles" (
 user_id BIGINT NOT NULL REFERENCES "Users"(user_id),
 role_id BIGINT NOT NULL REFERENCES "Roles"(role_id),
 assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(user_id,role_id)
);
CREATE TABLE "MemberProfiles" (
 member_id BIGINT PRIMARY KEY REFERENCES "Users"(user_id),
 member_number VARCHAR(30) NOT NULL UNIQUE,
 joined_at DATE NOT NULL DEFAULT CURRENT_DATE,
 emergency_contact_phone VARCHAR(20)
);
CREATE TABLE "TrainerProfiles" (
 trainer_id BIGINT PRIMARY KEY REFERENCES "Users"(user_id),
 specialty VARCHAR(100) NOT NULL,
 hire_date DATE NOT NULL,
 experience_years SMALLINT NOT NULL DEFAULT 0 CHECK (experience_years>=0)
);
CREATE TABLE "MembershipPackages" (
 package_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 package_name VARCHAR(80) NOT NULL UNIQUE,
 duration_months SMALLINT NOT NULL CHECK(duration_months>0),
 price DECIMAL(10,2) NOT NULL CHECK(price>0),
 description TEXT,
 is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE "Memberships" (
 membership_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 member_id BIGINT NOT NULL REFERENCES "MemberProfiles"(member_id),
 package_id BIGINT NOT NULL REFERENCES "MembershipPackages"(package_id),
 agreed_price DECIMAL(10,2) NOT NULL CHECK(agreed_price>0),
 start_date DATE NOT NULL,
 end_date DATE NOT NULL,
 status VARCHAR(20) NOT NULL DEFAULT 'active'
     CHECK(status IN ('active','expired','cancelled')),
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT ck_membership_dates CHECK(end_date>start_date)
);
CREATE TABLE "Payments" (
 payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 membership_id BIGINT NOT NULL REFERENCES "Memberships"(membership_id),
 amount DECIMAL(10,2) NOT NULL CHECK(amount>0),
 payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 payment_method VARCHAR(20) NOT NULL
     CHECK(payment_method IN ('cash','card','bank_transfer')),
 receipt_no VARCHAR(40) UNIQUE
);
CREATE TABLE "GroupClasses" (
 class_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 class_name VARCHAR(80) NOT NULL UNIQUE,
 description TEXT,
 is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE "Rooms" (
 room_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 room_name VARCHAR(60) NOT NULL UNIQUE,
 capacity SMALLINT NOT NULL CHECK(capacity>0),
 is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE "ClassSessions" (
 session_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 class_id BIGINT NOT NULL REFERENCES "GroupClasses"(class_id),
 trainer_id BIGINT NOT NULL REFERENCES "TrainerProfiles"(trainer_id),
 room_id BIGINT NOT NULL REFERENCES "Rooms"(room_id),
 start_time TIMESTAMP NOT NULL,
 end_time TIMESTAMP NOT NULL,
 capacity SMALLINT NOT NULL CHECK(capacity>0),
 status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
   CHECK(status IN ('scheduled','completed','cancelled')),
 CONSTRAINT ck_session_time CHECK(end_time>start_time)
);
CREATE TABLE "Reservations" (
 reservation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 member_id BIGINT NOT NULL REFERENCES "MemberProfiles"(member_id),
 session_id BIGINT NOT NULL REFERENCES "ClassSessions"(session_id),
 reserved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK(status IN ('active','cancelled')),
 CONSTRAINT uq_member_session UNIQUE(member_id,session_id)
);
CREATE TABLE "AttendanceRecords" (
 attendance_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 reservation_id BIGINT NOT NULL UNIQUE REFERENCES "Reservations"(reservation_id),
 attendance_status VARCHAR(15) NOT NULL
   CHECK(attendance_status IN ('present','absent')),
 recorded_by BIGINT NOT NULL REFERENCES "Users"(user_id),
 recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_memberships_member ON "Memberships"(member_id);
CREATE INDEX ix_payments_membership ON "Payments"(membership_id);
CREATE INDEX ix_sessions_class ON "ClassSessions"(class_id);
CREATE INDEX ix_reservations_member ON "Reservations"(member_id);
CREATE INDEX ix_reservations_session_status ON "Reservations"(session_id,status);
CREATE INDEX ix_attendance_recorder ON "AttendanceRecords"(recorded_by);
COMMIT;
