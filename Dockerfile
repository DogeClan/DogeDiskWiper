# Use Debian as the base image
FROM debian:latest

# Set environment variables to reduce interaction during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: Git, Python, and required tools for ShredOS
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-flask \
    build-essential \
    coreutils \
    wget \
    make \
    gcc \
    && apt-get clean

# Clone ShredOS repository
RUN git clone https://github.com/PartialVolume/shredos.x86_64.git /shredos

# Install additional dependencies required by ShredOS
WORKDIR /shredos
RUN make

# Set up the Flask web application in the /app directory
WORKDIR /app

# Create Flask app script (app.py) with default path for wiping
RUN echo "\
from flask import Flask, request, jsonify\n\
import subprocess\n\
import os\n\
\n\
app = Flask(__name__)\n\
\n\
# Helper function to run ShredOS (shred command)\n\
def wipe_file(file_path):\n\
    try:\n\
        if os.path.exists(file_path):\n\
            result = subprocess.run(['shred', '-v', '-n', '3', file_path], check=True, capture_output=True)\n\
            return True\n\
        else:\n\
            return False\n\
    except subprocess.CalledProcessError as e:\n\
        return str(e)\n\
\n\
@app.route('/')\n\
def home():\n\
    return \"Welcome to ShredOS Wiper. The default path for wiping is /home/chronos/user/Downloads.\"\n\
\n\
@app.route('/wipe', methods=['POST'])\n\
def wipe():\n\
    # Hardcoded path for ChromeOS download folder\n\
    file_path = '/mnt/hostdir/Downloads'\n\
\n\
    success = wipe_file(file_path)\n\
    if success:\n\
        return jsonify({'message': f'File {file_path} wiped successfully!'}), 200\n\
    else:\n\
        return jsonify({'message': f'Failed to wipe {file_path}. File may not exist or be inaccessible.'}), 400\n\
\n\
if __name__ == '__main__':\n\
    app.run(debug=True, host='0.0.0.0', port=5000)\n" > /app/app.py

# Install Flask dependencies
RUN echo "Flask==2.1.2" > /app/requirements.txt
RUN pip3 install -r /app/requirements.txt

# Expose Flask port (default 5000)
EXPOSE 5000

# Command to run the Flask app
CMD ["python3", "app.py"]
