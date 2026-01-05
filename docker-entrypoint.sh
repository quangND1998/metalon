#!/bin/bash
set -e

# Always run meltano install to ensure plugins are installed
# This is safe because meltano install is idempotent
echo "Ensuring Meltano plugins are installed..."
meltano install || echo "Warning: Some plugins may not have installed correctly"

# Execute command
exec "$@"

