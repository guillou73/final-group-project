# Use an official Python image as the base
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .
COPY --from=docker/buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# Install dependencies for mysqlclient
RUN apt-get update && \
    apt-get install -y default-libmysqlclient-dev build-essential default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies and pytest
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir pytest pytest-flask

COPY wait.sh /wait.sh
RUN chmod +x /wait.sh

# Copy the application code and test files into the container
COPY main.py .
COPY tests/ ./tests/
RUN ls -l /app

# Create a simple test if it doesn't exist
RUN mkdir -p tests && \
    if [ ! -f tests/test_main.py ]; then \
    echo 'from main import app\n\
def test_home():\n\
    client = app.test_client()\n\
    response = client.get("/")\n\
    assert response.status_code == 200' > tests/test_main.py; \
    fi

# Set environment variables for Flask
ENV FLASK_APP=main.py
ENV FLASK_ENV=development

# Expose the port Flask will run on
EXPOSE 5000

# Run the application
CMD ["/wait.sh", "mysql-service:3306", "--", "flask", "run", "--host=0.0.0.0", "--port=5000"]
