# Dockerfile cho Meltano MySQL to PostgreSQL Sync
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONUTF8=1 \
    PYTHONIOENCODING=utf-8 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Meltano
RUN pip install --upgrade pip && \
    pip install meltano

# Copy project files
COPY meltano.yml ./
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy remaining project files (excluding .meltano which will be a volume)
COPY . .

# Create volume for state persistence
VOLUME ["/app/.meltano"]

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["meltano", "run", "tap-mysql", "target-postgres"]

