# Dockerfile
FROM debian:latest

# Install Python, Pip, venv, and necessary utilities
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    secure-delete \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Write the HTML upload form directly into Dockerfile
RUN mkdir -p /app/templates && \
    echo '<!doctype html>' > /app/templates/upload.html && \
    echo '<html>' >> /app/templates/upload.html && \
    echo '<head>' >> /app/templates/upload.html && \
    echo '    <meta charset="UTF-8">' >> /app/templates/upload.html && \
    echo '    <title>Upload Directory</title>' >> /app/templates/upload.html && \
    echo '    <style>' >> /app/templates/upload.html && \
    echo '        body {' >> /app/templates/upload.html && \
    echo '            background-color: black;' >> /app/templates/upload.html && \
    echo '            color: armygreen;' >> /app/templates/upload.html && \
    echo '            font-family: "Courier New", Courier, monospace;' >> /app/templates/upload.html && \
    echo '            text-align: center;' >> /app/templates/upload.html && \
    echo '        }' >> /app/templates/upload.html && \
    echo '        h1 {' >> /app/templates/upload.html && \
    echo '            margin-top: 50px;' >> /app/templates/upload.html && \
    echo '        }' >> /app/templates/upload.html && \
    echo '        form {' >> /app/templates/upload.html && \
    echo '            margin: 20px auto;' >> /app/templates/upload.html && \
    echo '            padding: 20px;' >> /app/templates/upload.html && \
    echo '            border: 2px solid armygreen;' >> /app/templates/upload.html && \
    echo '            border-radius: 10px;' >> /app/templates/upload.html && \
    echo '            display: inline-block;' >> /app/templates/upload.html && \
    echo '        }' >> /app/templates/upload.html && \
    echo '        input[type="file"], input[type="submit"] {' >> /app/templates/upload.html && \
    echo '            background-color: armygreen;' >> /app/templates/upload.html && \
    echo '            color: black;' >> /app/templates/upload.html && \
    echo '            border: none;' >> /app/templates/upload.html && \
    echo '            padding: 10px 20px;' >> /app/templates/upload.html && \
    echo '            border-radius: 5px;' >> /app/templates/upload.html && \
    echo '            font-size: 16px;' >> /app/templates/upload.html && \
    echo '            cursor: pointer;' >> /app/templates/upload.html && \
    echo '        }' >> /app/templates/upload.html && \
    echo '        input[type="file"]:hover, input[type="submit"]:hover {' >> /app/templates/upload.html && \
    echo '            background-color: darkgreen;' >> /app/templates/upload.html && \
    echo '        }' >> /app/templates/upload.html && \
    echo '    </style>' >> /app/templates/upload.html && \
    echo '</head>' >> /app/templates/upload.html && \
    echo '<body>' >> /app/templates/upload.html && \
    echo '    <h1>Upload Directory to Wipe</h1>' >> /app/templates/upload.html && \
    echo '    <form method="post" enctype="multipart/form-data">' >> /app/templates/upload.html && \
    echo '        <input type="file" name="directory" accept=".zip"><br><br>' >> /app/templates/upload.html && \
    echo '        <input type="submit" value="Upload">' >> /app/templates/upload.html && \
    echo '    </form>' >> /app/templates/upload.html && \
    echo '</body>' >> /app/templates/upload.html && \
    echo '</html>' >> /app/templates/upload.html

# Create a virtual environment
RUN python3 -m venv /app/venv

# Activate the virtual environment and install Flask
RUN . /app/venv/bin/activate && pip install --no-cache-dir Flask

# Write the Flask application directly into the Dockerfile
RUN echo 'from flask import Flask, request, render_template' > /app/app.py && \
    echo 'import os' >> /app/app.py && \
    echo 'import shutil' >> /app/app.py && \
    echo 'import subprocess' >> /app/app.py && \
    echo '' >> /app/app.py && \
    echo 'app = Flask(__name__)' >> /app/app.py && \
    echo '' >> /app/app.py && \
    echo '# Ensure the upload directory exists' >> /app/app.py && \
    echo 'UPLOAD_FOLDER = "/app/uploads"' >> /app/app.py && \
    echo 'os.makedirs(UPLOAD_FOLDER, exist_ok=True)' >> /app/app.py && \
    echo '' >> /app/app.py && \
    echo '@app.route("/")' >> /app/app.py && \
    echo 'def upload_form():' >> /app/app.py && \
    echo '    return render_template("upload.html")' >> /app/app.py && \
    echo '' >> /app/app.py && \
    echo '@app.route("/", methods=["POST"])' >> /app/app.py && \
    echo 'def upload_file():' >> /app/app.py && \
    echo '    if "directory" not in request.files:' >> /app/app.py && \
    echo '        return "No directory part"' >> /app/app.py && \
    echo '    directory = request.files["directory"]' >> /app/app.py && \
    echo '    if directory.filename == "":' >> /app/app.py && \
    echo '        return "No selected file"' >> /app/app.py && \
    echo '    temp_file_path = os.path.join(UPLOAD_FOLDER, directory.filename)' >> /app/app.py && \
    echo '    directory.save(temp_file_path)' >> /app/app.py && \
    echo '' >> /app/app.py && \
    echo '    extract_path = os.path.join(UPLOAD_FOLDER, "tempdir")' >> /app/app.py && \
    echo '    os.makedirs(extract_path, exist_ok=True)' >> /app/app.py && \
    echo '    subprocess.run(["unzip", temp_file_path, "-d", extract_path], check=True)' >> /app/app.py && \
    echo '    subprocess.run(["sfill", "-f", "-l", "-n", "--", extract_path], check=True)' >> /app/app.py && \
    echo '    os.remove(temp_file_path)' >> /app/app.py && \
    echo '    shutil.rmtree(extract_path)' >> /app/app.py && \
    echo '    return "Directory has been wiped successfully!"' >> /app/app.py && \
    echo '' >> /app/app.py && \
    echo 'if __name__ == "__main__":' >> /app/app.py && \
    echo '    app.run(host="0.0.0.0", port=5000)' >> /app/app.py

# Expose port 5000
EXPOSE 5000

# Define the command to run the application using the virtual environment
CMD ["/app/venv/bin/python", "app.py"]
