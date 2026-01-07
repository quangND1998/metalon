#!/bin/bash
# Bash script để chạy Meltano commands trong Docker
# Usage: ./docker-run.sh [command] [args...]
# Examples:
#   ./docker-run.sh meltano run tap-mysql target-postgres
#   ./docker-run.sh meltano invoke tap-mysql --discover
#   ./docker-run.sh meltano select tap-mysql "*.*"

if [ $# -eq 0 ]; then
    echo "Usage: ./docker-run.sh [meltano command] [args...]"
    echo "Examples:"
    echo "  ./docker-run.sh meltano run tap-mysql target-postgres"
    echo "  ./docker-run.sh meltano invoke tap-mysql --discover"
    echo "  ./docker-run.sh meltano select tap-mysql \"*.*\""
    exit 1
fi

echo "Running: docker-compose run --rm meltano $@"
docker-compose run --rm meltano "$@"

exit $?





