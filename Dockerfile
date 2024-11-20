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
    shred \
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

# Create Flask app script (app.py) with default path for wiping
RUN echo "\
from flask import Flask, request, jsonify, render_template\n\
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
    return render_template('index.html')\n\
\n\
@app.route('/wipe', methods=['POST'])\n\
def wipe():\n\
    # Get the file path specified by the user\n\
    file_path = request.form.get('file_path')\n\
\n\
    if file_path:\n\
        success = wipe_file(file_path)\n\
        if success:\n\
            return jsonify({'message': f'File {file_path} wiped successfully!'}), 200\n\
        else:\n\
            return jsonify({'message': f'Failed to wipe {file_path}. File may not exist or be inaccessible.'}), 400\n\
    else:\n\
        return jsonify({'message': 'No file path provided.'}), 400\n\
\n\
if __name__ == '__main__':\n\
    app.run(debug=True, host='0.0.0.0', port=5000)\n" > /app/app.py

# Create the HTML template for the interface (index.html)
RUN echo "\
<!DOCTYPE html>\n\
<html lang='en'>\n\
<head>\n\
    <meta charset='UTF-8'>\n\
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>\n\
    <title>ShredOS Wiper</title>\n\
    <style>\n\
        body {\n\
            font-family: Arial, sans-serif;\n\
            padding: 20px;\n\
            background-color: #f4f4f4;\n\
        }\n\
        .container {\n\
            max-width: 600px;\n\
            margin: 0 auto;\n\
            padding: 20px;\n\
            background-color: white;\n\
            border-radius: 8px;\n\
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);\n\
        }\n\
        h1 {\n\
            text-align: center;\n\
        }\n\
        .input-container {\n\
            margin-bottom: 20px;\n\
        }\n\
        input[type='text'] {\n\
            width: 100%;\n\
            padding: 10px;\n\
            font-size: 16px;\n\
            border-radius: 5px;\n\
            border: 1px solid #ddd;\n\
        }\n\
        button {\n\
            width: 100%;\n\
            padding: 10px;\n\
            background-color: green;\n\
            color: white;\n\
            font-size: 18px;\n\
            border: none;\n\
            border-radius: 5px;\n\
            cursor: pointer;\n\
        }\n\
        button:hover {\n\
            background-color: #45a049;\n\
        }\n\
        .message {\n\
            margin-top: 20px;\n\
            text-align: center;\n\
        }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class='container'>\n\
        <h1>ShredOS Wiper</h1>\n\
        <form action='/wipe' method='POST'>\n\
            <div class='input-container'>\n\
                <label for='file_path'>Enter Directory Path to Wipe:</label>\n\
                <input type='text' id='file_path' name='file_path' placeholder='/home/user/Downloads' required>\n\
            </div>\n\
            <button type='submit'>Wipe Now</button>\n\
        </form>\n\
        <div class='message' id='message'></div>\n\
    </div>\n\
</body>\n\
</html>\n" > /app/templates/index.html

# Install Flask dependencies
RUN echo "Flask==2.1.2" > /app/requirements.txt
RUN pip3 install -r /app/requirements.txt

# Expose Flask port (default 5000)
EXPOSE 5000

# Command to run the Flask app
CMD ["python3", "app.py"]
