FROM debian:latest

# Install necessary tools and Python
RUN apt-get update && apt-get install -y \
    wipe \
    python3 \
    python3-venv \
    python3-pip \
    sudo \
    curl \
    && apt-get clean

# Ensure the upload directory exists
RUN mkdir -p /tmp/uploads

# Now, apply permissions to the upload folder
RUN chmod -R 777 /tmp/uploads

# Create a virtual environment for Python packages
RUN python3 -m venv /venv

# Install Flask and requests in the virtual environment
RUN /venv/bin/pip install flask requests

# Create and write the Flask application
RUN echo "\
from flask import Flask, request, render_template\n\
import subprocess\n\
import os\n\
import shutil\n\
import requests\n\
\n\
app = Flask(__name__)\n\
\n\
# Define upload folder\n\
UPLOAD_FOLDER = '/tmp/uploads'\n\
os.makedirs(UPLOAD_FOLDER, exist_ok=True)\n\
\n\
@app.route('/')\n\
def home():\n\
    return render_template('index.html')\n\
\n\
@app.route('/upload', methods=['POST'])\n\
def upload_file():\n\
    uploaded_files = request.files.getlist('directory_picker')  # Get uploaded files from the form\n\
    if not uploaded_files:\n\
        return 'Error: No files uploaded.', 400\n\
    \n\
    # Save files to the upload folder\n\
    for file in uploaded_files:\n\
        file_path = os.path.join(UPLOAD_FOLDER, file.filename)\n\
        # Ensure the directory exists before saving the file\n\
        file_dir = os.path.dirname(file_path)\n\
        os.makedirs(file_dir, exist_ok=True)\n\
        file.save(file_path)\n\
    \n\
    # After saving, upload to the remote server\n\
    upload_to_server(UPLOAD_FOLDER)\n\
    \n\
    # Now wipe the uploaded files and local copy\n\
    wipe(UPLOAD_FOLDER)\n\
    return 'Files uploaded and wiped successfully!', 200\n\
\n\
def upload_to_server(upload_folder):\n\
    # Define the server URL for uploading files\n\
    server_url = 'https://your-server.com/upload'  # Replace with the actual URL of the server\n\
    for filename in os.listdir(upload_folder):\n\
        file_path = os.path.join(upload_folder, filename)\n\
        # Skip directories and process only files\n\
        if os.path.isdir(file_path):\n\
            continue\n\
        with open(file_path, 'rb') as f:\n\
            response = requests.post(server_url, files={'file': f})\n\
            if response.status_code != 200:\n\
                print(f'Failed to upload {filename} to server. Status code: {response.status_code}')\n\
\n\
def wipe(directory):\n\
    # Perform wipe securely using the 'wipe' tool\n\
    try:\n\
        subprocess.run(['sudo', 'wipe', '-r', '-f', directory], check=True)\n\
        print(f'Successfully wiped: {directory}')\n\
    except subprocess.CalledProcessError:\n\
        print(f'Error: Failed to wipe {directory}. Check permissions or path validity.')\n\
    except Exception as e:\n\
        print(f'Error during wipe: {str(e)}')\n\
\n\
if __name__ == '__main__':\n\
    app.run(host='0.0.0.0', port=5000)\n" > app.py

# Create and write the hacker-themed HTML template with a directory picker
RUN mkdir -p templates && echo "\
<!DOCTYPE html>\n\
<html lang=\"en\">\n\
<head>\n\
    <meta charset=\"UTF-8\">\n\
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\
    <title>Secure File/Directory Uploader & Wiper</title>\n\
    <style>\n\
        body {\n\
            background-color: #1a1a1a;\n\
            color: #66ff66;\n\
            font-family: 'Courier New', Courier, monospace;\n\
            text-align: center;\n\
            margin-top: 50px;\n\
        }\n\
        h1 {\n\
            font-size: 3em;\n\
            margin-bottom: 20px;\n\
        }\n\
        form {\n\
            background-color: #333;\n\
            padding: 20px;\n\
            border-radius: 10px;\n\
            display: inline-block;\n\
            width: 300px;\n\
            box-shadow: 0 0 20px rgba(0, 255, 0, 0.6);\n\
        }\n\
        label {\n\
            font-size: 1.2em;\n\
        }\n\
        input[type=\"file\"] {\n\
            width: 100%;\n\
            padding: 10px;\n\
            margin: 15px 0;\n\
            border: 1px solid #66ff66;\n\
            background-color: #222;\n\
            color: #66ff66;\n\
            font-size: 1.2em;\n\
        }\n\
        button {\n\
            background-color: #66ff66;\n\
            color: #1a1a1a;\n\
            font-size: 1.5em;\n\
            padding: 10px;\n\
            border: none;\n\
            border-radius: 5px;\n\
            width: 100%;\n\
            cursor: pointer;\n\
            box-shadow: 0 0 15px rgba(0, 255, 0, 0.7);\n\
        }\n\
        button:hover {\n\
            background-color: #00ff00;\n\
        }\n\
        footer {\n\
            font-size: 0.8em;\n\
            margin-top: 30px;\n\
            color: #888;\n\
        }\n\
    </style>\n\
</head>\n\
<body>\n\
    <h1>Secure File/Directory Uploader & Wiper</h1>\n\
    <form action=\"/upload\" method=\"POST\" enctype=\"multipart/form-data\">\n\
        <label for=\"directory_picker\">Select Directory to Upload & Wipe:</label>\n\
        <input type=\"file\" id=\"directory_picker\" name=\"directory_picker\" webkitdirectory directory multiple required>\n\
        <button type=\"submit\">Upload & Wipe</button>\n\
    </form>\n\
    <footer>\n\
        <p>Warning: Use with caution. Wiping data is irreversible!</p>\n\
    </footer>\n\
</body>\n\
</html>\n" > templates/index.html

# Expose the port and run the Flask app
EXPOSE 5000
CMD [ "/venv/bin/python3", "app.py" ]
