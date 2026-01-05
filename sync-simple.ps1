# Simple sync script with datetime transform
# Usage: .\sync-simple.ps1

docker-compose run --rm meltano bash -c "meltano invoke tap-mysql | python3 /app/transform_datetime.py | meltano invoke target-postgres"

