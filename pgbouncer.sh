#!/bin/bash
# Install together with the corrected Zabbix 6.0 template.
set -euo pipefail
config=${PGBOUNCER_CONFIG:-${HOME}/.pgbouncer.env}
if [[ -r "$config" ]]; then
    # Local administrator-owned Bash assignments.
    source "$config"
fi
export PGHOST=${PGHOST:-127.0.0.1}
export PGPORT=${PGPORT:-6432}
export PGUSER=${PGUSER:-zabbix}
export PGDATABASE=pgbouncer
export PGCONNECT_TIMEOUT=${PGCONNECT_TIMEOUT:-3}
case "${1:-}" in
    discover|pools) query='SHOW POOLS;' ;;
    totals) query='SHOW TOTALS;' ;;
    stats) query='SHOW STATS;' ;;
    lists) query='SHOW LISTS;' ;;
    databases) query='SHOW DATABASES;' ;;
    state) query='SHOW STATE;' ;;
    *) printf 'Usage: %s {pools|stats|totals|lists|databases|state|discover}\n' "$0" >&2; exit 2 ;;
esac
# Buffer first: never publish partial tables or empty discovery after psql fails.
# -X ignores .psqlrc, -w prevents password prompts; CSV preserves names and headers.
if data=$(psql -X -w --csv --set=ON_ERROR_STOP=1 --command="$query"); then
    if [[ -z "$data" ]]; then
        printf 'PgBouncer: psql returned no CSV header\n' >&2
        exit 1
    fi
    printf '%s\n' "$data"
else
    exit "$?"
fi
