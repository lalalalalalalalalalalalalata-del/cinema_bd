DB_NAME ?= cinema_db

restore:
	psql -d $(DB_NAME) -f scripts/restore_split.sql

backup-custom:
	pg_dump -Fc $(DB_NAME) > backups/cinema_db_custom.backup

backup-sql:
	pg_dump -Fp $(DB_NAME) > backups/cinema_db_plain.sql
