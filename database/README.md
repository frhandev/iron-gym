# Iron Gym — PostgreSQL database

Run against a **new empty** PostgreSQL 16+ database with permissions to create the `btree_gist` extension.

```bash
createdb -U postgres iron_gym
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/01_schema.sql
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/02_business_rules.sql
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/03_seed.sql
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/04_tests.sql
psql -U postgres -d iron_gym -v ON_ERROR_STOP=1 -f database/05_inspect.sql
```

To avoid inconsistent timestamps, use the same intended time zone for the database/application. Scripts use local `TIMESTAMP`/ `LOCALTIMESTAMP`; the system's chosen time zone should be explicit in deployment.

**Do not run on an existing DB.** These are initial-creation scripts, not migrations. The test file creates temporary test rows inside a transaction then rolls them back. It includes one negative test for each BR-01..08; it is **not** a full concurrency, authorization or production test suite.

Caveats:
- BR-05 is checked on reservation date, matching the original requirements. Session-date validity would be a requirements change.
- Member profiles and trainer profiles are checked for the correct role on insert/update; no API or authentication layer exists yet.
- Deactivating membership/user after existing reservations requires explicit lifecycle behavior in a future application.
- Attendance `recorded_by` is not independently authenticated; an API must enforce authenticated identity.
- A production app should employ controlled DB roles, least privilege, audit trails, race-condition tests, and migration tooling.
- Offline `card` payments represent POS records only. No online payment processing is included.
