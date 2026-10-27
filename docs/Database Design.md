# Section 2 — Database Design

**Project:** Iron Gym Membership & Management System  
**Model:** Relational ER / Crow's Foot  
**Scope:** Database design for Vize 2026–2027

## 2.1 Entities and decomposition

The system uses **13 interconnected tables** grouped into user/role management, memberships/payments, class scheduling, and reservations/attendance. Each entity serves a requirement from [Section 1](Project%20Requirements.md); no unrelated table is added.

1. **Users** — Identity module; 7 fields.
2. **Roles** — Identity module; 3 fields.
3. **UserRoles** — Identity module; 3 fields.
4. **MemberProfiles** — Identity module; 4 fields.
5. **TrainerProfiles** — Identity module; 4 fields.
6. **MembershipPackages** — Membership module; 6 fields.
7. **Memberships** — Membership module; 8 fields.
8. **Payments** — Membership module; 6 fields.
9. **GroupClasses** — Classes module; 4 fields.
10. **Rooms** — Classes module; 4 fields.
11. **ClassSessions** — Classes module; 8 fields.
12. **Reservations** — Reservations module; 5 fields.
13. **AttendanceRecords** — Reservations module; 5 fields.

## 2.2 Relationships

There are **14 foreign-key relationships**. All child FK columns are mandatory. On the parent side, the model permits zero children; for shared primary-key profiles and unique attendance FKs, the maximum is one child.

| # | Parent table | Child table | Multiplicity | Referencing field |
|---|---|---|---|---|
| 1 | `Users` | `UserRoles` | 1:N | `user_id` |
| 2 | `Roles` | `UserRoles` | 1:N | `role_id` |
| 3 | `Users` | `MemberProfiles` | 1:0..1 | `member_id` |
| 4 | `Users` | `TrainerProfiles` | 1:0..1 | `trainer_id` |
| 5 | `MemberProfiles` | `Memberships` | 1:N | `member_id` |
| 6 | `MembershipPackages` | `Memberships` | 1:N | `package_id` |
| 7 | `Memberships` | `Payments` | 1:N | `membership_id` |
| 8 | `GroupClasses` | `ClassSessions` | 1:N | `class_id` |
| 9 | `TrainerProfiles` | `ClassSessions` | 1:N | `trainer_id` |
| 10 | `Rooms` | `ClassSessions` | 1:N | `room_id` |
| 11 | `MemberProfiles` | `Reservations` | 1:N | `member_id` |
| 12 | `ClassSessions` | `Reservations` | 1:N | `session_id` |
| 13 | `Reservations` | `AttendanceRecords` | 1:0..1 | `reservation_id` |
| 14 | `Users` | `AttendanceRecords` | 1:N | `recorded_by` |

The conceptual **Users ↔ Roles N:M** association is represented by `UserRoles` with composite PK `(user_id, role_id)`.  
The conceptual **MemberProfiles ↔ ClassSessions N:M** association is represented by `Reservations` with `UNIQUE(member_id, session_id)`.

## 2.3 Keys, constraints, and business rules

- **PK:** All entities have unique identifiers; `UserRoles` uses a composite primary key.
- **FK:** 14 foreign keys connect the 13 entities; deletion is restricted while referenced.
- **NOT NULL / DEFAULT:** Mandatory values and default timestamps/states are documented in the dictionary.
- **UNIQUE:** E-mail, role, package, room/class names, member number, composite reservation identity and attendance reservation.
- **CHECK:** Positive fees/capacities, membership/session ordering, permitted status and payment-method values.
- **PostgreSQL exclusion constraints:** prohibit overlapping active memberships and overlapping trainer/room schedule intervals.
- **Triggers:** validate capacity and reservation eligibility, and enforce attendance constraints.
- **Authorization:** must additionally be implemented by an authenticated application/API; database relationship structure alone does not enforce all user-operation permissions.

| Rule | Design enforcement |
|---|---|
| BR-01 | `Users.email` unique, plus case-insensitive unique expression index |
| BR-02 | `Memberships.end_date > start_date` CHECK |
| BR-03 | `Memberships` GiST exclusion over member ID and active date range |
| BR-04 | `Payments.amount > 0` CHECK |
| BR-05 | Reservation trigger checks membership valid **on booking date** (as originally specified) |
| BR-06 | `Reservations UNIQUE(member_id,session_id)`; cancelled row can be reactivated |
| BR-07 | Session capacity CHECK + room/session and reservation-count triggers |
| BR-08 | Trainer/room GiST time-range exclusion constraints |

**Important:** BR-05 intentionally follows Section 1: booking date, not the session date. Checking the session date would be a *change of requirement* requiring updates to both documents.

## 2.4 Data dictionary

For all 13 tables: field name, type, length, constraint, and meaning.

### 2.4.1 Users

Identity module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `user_id` | BIGINT | — | PK | Unique user ID |
| `full_name` | VARCHAR | 100 | NOT NULL | Member or staff full name |
| `email` | VARCHAR | 255 | UNIQUE, NOT NULL | Account email |
| `password_hash` | VARCHAR | 255 | NOT NULL | Secure password digest |
| `phone` | VARCHAR | 20 | NULL | Contact phone |
| `is_active` | BOOLEAN | — | DEFAULT TRUE, NOT NULL | Account enabled |
| `created_at` | TIMESTAMP | — | DEFAULT CURRENT_TIMESTAMP, NOT NULL | Account creation time |

### 2.4.2 Roles

Identity module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `role_id` | BIGINT | — | PK | Role ID |
| `role_name` | VARCHAR | 30 | UNIQUE, NOT NULL | Member/trainer/reception/admin |
| `description` | VARCHAR | 255 | NULL | Role meaning |

### 2.4.3 UserRoles

Identity module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `user_id` | BIGINT | — | PK (composite), FK | Users reference |
| `role_id` | BIGINT | — | PK (composite), FK | Roles reference |
| `assigned_at` | TIMESTAMP | — | DEFAULT CURRENT_TIMESTAMP, NOT NULL | Assignment time |

### 2.4.4 MemberProfiles

Identity module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `member_id` | BIGINT | — | PK, FK | Users reference; max one profile |
| `member_number` | VARCHAR | 30 | UNIQUE, NOT NULL | Unique gym membership number |
| `joined_at` | DATE | — | DEFAULT CURRENT_DATE, NOT NULL | First enrollment date |
| `emergency_contact_phone` | VARCHAR | 20 | NULL | Emergency contact |

### 2.4.5 TrainerProfiles

Identity module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `trainer_id` | BIGINT | — | PK, FK | Users reference; max one profile |
| `specialty` | VARCHAR | 100 | NOT NULL | Professional specialty |
| `hire_date` | DATE | — | NOT NULL | Employment start |
| `experience_years` | SMALLINT | — | CHECK >= 0, DEFAULT 0, NOT NULL | Experience in years |

### 2.4.6 MembershipPackages

Membership module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `package_id` | BIGINT | — | PK | Package ID |
| `package_name` | VARCHAR | 80 | UNIQUE, NOT NULL | Package name |
| `duration_months` | SMALLINT | — | CHECK > 0, NOT NULL | Duration months |
| `price` | DECIMAL | 10,2 | CHECK > 0, NOT NULL | Current price |
| `description` | TEXT | — | NULL | Package description |
| `is_active` | BOOLEAN | — | DEFAULT TRUE, NOT NULL | Available for sale |

### 2.4.7 Memberships

Membership module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `membership_id` | BIGINT | — | PK | Membership ID |
| `member_id` | BIGINT | — | FK, NOT NULL | MemberProfiles reference |
| `package_id` | BIGINT | — | FK, NOT NULL | MembershipPackages reference |
| `agreed_price` | DECIMAL | 10,2 | CHECK > 0, NOT NULL | Snapshot of agreed charge |
| `start_date` | DATE | — | NOT NULL | Membership valid from |
| `end_date` | DATE | — | CHECK > start_date, NOT NULL | Membership valid until (inclusive) |
| `status` | VARCHAR | 20 | DEFAULT 'active', CHECK, NOT NULL | active/expired/cancelled |
| `created_at` | TIMESTAMP | — | DEFAULT CURRENT_TIMESTAMP, NOT NULL | Creation timestamp |

### 2.4.8 Payments

Membership module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `payment_id` | BIGINT | — | PK | Payment ID |
| `membership_id` | BIGINT | — | FK, NOT NULL | Memberships reference |
| `amount` | DECIMAL | 10,2 | CHECK > 0, NOT NULL | Paid amount |
| `payment_date` | TIMESTAMP | — | DEFAULT CURRENT_TIMESTAMP, NOT NULL | Payment date |
| `payment_method` | VARCHAR | 20 | CHECK, NOT NULL | cash/card/bank_transfer |
| `receipt_no` | VARCHAR | 40 | UNIQUE, NULL | Optional receipt number |

### 2.4.9 GroupClasses

Classes module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `class_id` | BIGINT | — | PK | Class type ID |
| `class_name` | VARCHAR | 80 | UNIQUE, NOT NULL | Yoga, Pilates, etc. |
| `description` | TEXT | — | NULL | Class details |
| `is_active` | BOOLEAN | — | DEFAULT TRUE, NOT NULL | Available class type |

### 2.4.10 Rooms

Classes module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `room_id` | BIGINT | — | PK | Room ID |
| `room_name` | VARCHAR | 60 | UNIQUE, NOT NULL | Room name |
| `capacity` | SMALLINT | — | CHECK > 0, NOT NULL | Maximum occupancy |
| `is_active` | BOOLEAN | — | DEFAULT TRUE, NOT NULL | Room available |

### 2.4.11 ClassSessions

Classes module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `session_id` | BIGINT | — | PK | Scheduled session ID |
| `class_id` | BIGINT | — | FK, NOT NULL | GroupClasses reference |
| `trainer_id` | BIGINT | — | FK, NOT NULL | TrainerProfiles reference |
| `room_id` | BIGINT | — | FK, NOT NULL | Rooms reference |
| `start_time` | TIMESTAMP | — | NOT NULL | Session start |
| `end_time` | TIMESTAMP | — | CHECK > start_time, NOT NULL | Session end |
| `capacity` | SMALLINT | — | CHECK > 0, NOT NULL | Session reservation limit |
| `status` | VARCHAR | 20 | DEFAULT 'scheduled', CHECK, NOT NULL | scheduled/completed/cancelled |

### 2.4.12 Reservations

Reservations module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `reservation_id` | BIGINT | — | PK | Reservation ID |
| `member_id` | BIGINT | — | FK, NOT NULL | MemberProfiles reference |
| `session_id` | BIGINT | — | FK, NOT NULL | ClassSessions reference |
| `reserved_at` | TIMESTAMP | — | DEFAULT CURRENT_TIMESTAMP, NOT NULL | Reservation created time |
| `status` | VARCHAR | 20 | DEFAULT 'active', CHECK, NOT NULL | active/cancelled |

### 2.4.13 AttendanceRecords

Reservations module.

| Field | Type | Length | Constraint | Description |
|---|---|---|---|---|
| `attendance_id` | BIGINT | — | PK | Attendance ID |
| `reservation_id` | BIGINT | — | UNIQUE, FK, NOT NULL | Reservations reference |
| `attendance_status` | VARCHAR | 15 | CHECK, NOT NULL | present/absent |
| `recorded_by` | BIGINT | — | FK, NOT NULL | Users reference |
| `recorded_at` | TIMESTAMP | — | DEFAULT CURRENT_TIMESTAMP, NOT NULL | Recorded time |


## 2.5 ER diagram

The editable Crow's Foot diagram is [Iron_Gym_ER.drawio](Iron_Gym_ER.drawio), and the [XML export](Iron_Gym_ER.xml) is kept for submission.

The diagram includes 13 tables, 67 fields and 14 foreign-key relationships.

## Implementation notes

- The PostgreSQL scripts are in `database/`; run them in numeric order against an **empty test database**.
- Price snapshots in `Memberships.agreed_price` preserve historical contract prices even if `MembershipPackages.price` changes.
- `Memberships.end_date` is inclusive; scheduled session times use half-open `[start, end)` ranges.
- Payment `card` denotes an **offline POS** transaction; online processing remains out of scope.
- The current frontend is a Next.js scaffold and is not yet connected to PostgreSQL.
