# IRON GYM

Gym membership & management system — database course project.

## Current status

- **Requirements:** complete ([Section 1](docs/Project%20Requirements.md)).
- **ER / relational design:** 13 entities, 67 fields, 14 foreign-key relationships ([Section 2](docs/Database%20Design.md)).
- **Editable ER diagram:** [Draw.io](docs/Iron_Gym_ER.drawio) / [XML](docs/Iron_Gym_ER.xml).
- **PostgreSQL SQL implementation:** [database](database/README.md).
- **Frontend:** `frontend/` is an existing **Next.js 16** scaffold, not a finished product or authenticated dashboard.
- **Backend and deployment:** not implemented.

## Database setup

Requires PostgreSQL 16+ and permission to enable `btree_gist`.
In a new/empty database named `iron_gym`, run:

```bash
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/01_schema.sql
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/02_business_rules.sql
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/03_seed.sql
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/04_tests.sql
```

Do not execute the scripts on an existing production database; there is no data migration plan. The test script runs in a transaction and rolls back all test records.

## Project scope

Member/staff records, roles, membership packages and validity, recorded payments, trainers, group classes, rooms, sessions, reservations and attendance.

Out of scope: online payment processing, biometrics, nutrition plans and equipment-maintenance management.

## Documentation / academic submission

- [Project Requirements](docs/Project%20Requirements.md)
- [Database Design + complete data dictionary](docs/Database%20Design.md)
- [ER Diagram (editable)](docs/Iron_Gym_ER.drawio)
- [ER Diagram (XML)](docs/Iron_Gym_ER.xml)

The university Vize hand-in requires a PDF report and editable/XML ER diagram. This repository contains the source documents and ER XML; an exported PDF can be packaged separately for LMS.

## Frontend (not connected to the database)

```bash
cd frontend
npm ci
npm run dev
```

The frontend remains unmodified by the database-design work.
