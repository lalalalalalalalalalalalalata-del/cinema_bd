\set ON_ERROR_STOP on

\i sql/00_init.sql
\i sql/01_schema/01_core_tables.sql
\i sql/01_schema/02_business_tables.sql
\i sql/02_functions/01_session_functions.sql
\i sql/02_functions/02_ticket_functions.sql
\i sql/03_data/01_reference_data.sql
\i sql/03_data/02_business_data.sql
\i sql/04_constraints/01_primary_unique_constraints.sql
\i sql/04_constraints/02_foreign_keys.sql
\i sql/05_indexes/01_indexes.sql
\i sql/06_triggers/01_session_triggers.sql
\i sql/06_triggers/02_ticket_triggers.sql

-- Quick check after restore.
SELECT 'genres' AS table_name, COUNT(*) AS rows_count FROM genres
UNION ALL SELECT 'films', COUNT(*) FROM films
UNION ALL SELECT 'halls', COUNT(*) FROM halls
UNION ALL SELECT 'seats', COUNT(*) FROM seats
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL SELECT 'tickets', COUNT(*) FROM tickets
UNION ALL SELECT 'ticket_status_log', COUNT(*) FROM ticket_status_log;
