# 1. Use an official Python runtime as a parent image
FROM python:3.11-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy the requirements file first to leverage Docker's cache
COPY requirements.txt .

# 4. Install the specified Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the rest of your application code into the container
COPY . .

# 6. Specify the command to run your app (replace main.py with your entry file)
CMD ["python", "main.py"]
