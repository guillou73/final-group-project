#!/bin/bash

echo "Waiting for MySQL to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker-compose exec -T mysql-service mysql -h mysql-service -u guillou73 -padmin -e "SELECT 1;" &>/dev/null; then
        echo "MySQL is ready!"
        exit 0
    fi
    
    attempt=$((attempt + 1))
    echo "Attempt $attempt of $max_attempts. Waiting..."
    sleep 2
done

echo "MySQL failed to become ready in time"
exit 1
