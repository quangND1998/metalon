#!/bin/bash
# Wrapper script to run sync with datetime transform
# This script will be copied to container and can be used as a simple command

meltano invoke tap-mysql | python3 /app/transform_datetime.py | meltano invoke target-postgres

