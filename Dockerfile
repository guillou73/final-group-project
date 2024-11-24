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

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

COPY wait.sh /wait.sh
RUN chmod +x /wait.sh

# Copy the rest of the application code into the container
COPY main.py .
RUN ls -l /app

# Set environment variables for Flask
ENV FLASK_APP=main.py
ENV FLASK_ENV=development

# Expose the port Flask will run on
EXPOSE 5000

# Run the application
#CMD ["flask", "run", "--host=0.0.0.0"]

CMD ["/wait.sh", "mysql-service:3306", "--", "flask", "run", "--host=0.0.0.0", "--port=5000"]
