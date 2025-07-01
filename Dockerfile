# Use a lightweight official Python base image
FROM python:3.10-slim

# Set working directory inside the container
WORKDIR /app

# Copy your app files to the container
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Tell Docker how to run your app
CMD ["python", "app.py"]