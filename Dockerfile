# Use Debian as the base image
FROM debian:latest

# Set environment variables to reduce interaction during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: Git, Python, required tools for ShredOS, and additional missing dependencies
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
    file \
    cpio \      
    unzip \       
    rsync \      
    bc \         
    && apt-get clean

# Clone ShredOS repository
RUN git clone https://github.com/PartialVolume/shredos.x86_64.git /shredos

# Install additional dependencies required by ShredOS
WORKDIR /shredos

# If there is a default configuration file (e.g., defconfig), use it
# Ensure a defconfig file is present to automate the configuration process
RUN make defconfig

# Now that Buildroot is configured, build the project
RUN make

# Set up the Flask web application in the /app directory
WORKDIR /app

# Create the HTML code (index.html)
RUN echo "\
<!DOCTYPE html>\n\
<html lang=\"en\">\n\
<head>\n\
    <meta charset=\"UTF-8\">\n\
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\
    <title>ShredOS Wiper</title>\n\
    <style>\n\
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px; }\n\
        h1 { color: #2c3e50; }\n\
        input[type='text'] { padding: 10px; width: 300px; }\n\
        button { padding: 10px 20px; background-color: #2ecc71; color: white; border: none; cursor: pointer; }\n\
        button:hover { background-color: #27ae60; }\n\
        .message { margin-top: 20px; font-size: 1.2em; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <h1>ShredOS Wiper</h1>\n\
    <p>Enter the directory you want to wipe:</p>\n\
    <input type=\"text\" id=\"dirInput\" placeholder=\"e.g., /path/to/directory\">\n\
    <button onclick=\"wipeNow()\">Wipe Now</button>\n\
    <div id=\"message\" class=\"message\"></div>\n\
    <script>\n\
        function wipeNow() {\n\
            const dir = document.getElementById('dirInput').value;\n\
            if (dir) {\n\
                fetch('/wipe', {\n\
                    method: 'POST',\n\
                    headers: {\n\
                        'Content-Type': 'application/json'\n\
                    },\n\
                    body: JSON.stringify({ dir: dir })\n\
                })\n\
                .then(response => response.json())\n\
                .then(data => {\n\
                    document.getElementById('message').textContent = data.message;\n\
                    document.getElementById('message').style.color = data.status === 'success' ? 'green' : 'red';\n\
                })\n\
                .catch(error => {\n\
                    document.getElementById('message').textContent = 'Error: ' + error;\n\
                    document.getElementById('message').style.color = 'red';\n\
                });\n\
            } else {\n\
                alert('Please enter a directory path!');\n\
            }\n\
        }\n\
    </script>\n\
</body>\n\
</html>\n" > /app/index.html

# Create Flask app script (app.py) with default path for wiping
RUN echo "\
from flask import Flask, request, jsonify, send_from_directory\n\
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
    return send_from_directory('/app', 'index.html')  # Serve the HTML file\n\
\n\
@app.route('/wipe', methods=['POST'])\n\
def wipe():\n\
    data = request.get_json()\n\
    file_path = data.get('dir')\n\
\n\
    success = wipe_file(file_path)\n\
    if success:\n\
        return jsonify({'message': f'File {file_path} wiped successfully!', 'status': 'success'}), 200\n\
    else:\n\
        return jsonify({'message': f'Failed to wipe {file_path}. File may not exist or be inaccessible.', 'status': 'error'}), 400\n\
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
