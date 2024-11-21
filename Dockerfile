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

# Apply permissions to the upload folder
RUN chmod -R 777 /tmp/uploads

# Create a virtual environment for Python packages
RUN python3 -m venv /venv

# Install Flask and requests in the virtual environment
RUN /venv/bin/pip install flask requests

# Create and write the updated Flask application
RUN echo "\
from flask import Flask, request, render_template, redirect, url_for, flash\n\
import os\n\
import shutil\n\
\n\
app = Flask(__name__)\n\
app.secret_key = 'supersecretkey'  # Required for session management\n\
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
    # After saving, show confirmation page for deletion\n\
    return render_template('confirm_delete.html', files=uploaded_files)\n\
\n\
@app.route('/delete', methods=['POST'])\n\
def delete_files():\n\
    directory_to_delete = UPLOAD_FOLDER\n\
    if os.path.exists(directory_to_delete):\n\
        shutil.rmtree(directory_to_delete)  # Deletes the directory and its contents\n\
        flash('The uploaded directory has been deleted.', 'success')\n\
    else:\n\
        flash('Directory does not exist.', 'error')\n\
    return redirect(url_for('home'))\n\
\n\
if __name__ == '__main__':\n\
    app.run(host='0.0.0.0', port=5000)\n" > app.py

# Create and write the HTML template for file upload
RUN mkdir -p templates && echo "\
<!DOCTYPE html>\n\
<html lang=\"en\">\n\
<head>\n\
    <meta charset=\"UTF-8\">\n\
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\
    <title>Secure File Uploader</title>\n\
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
    <h1>Secure File Uploader</h1>\n\
    <form action=\"/upload\" method=\"POST\" enctype=\"multipart/form-data\">\n\
        <label for=\"directory_picker\">Select Directory to Upload:</label>\n\
        <input type=\"file\" id=\"directory_picker\" name=\"directory_picker\" webkitdirectory directory multiple required>\n\
        <button type=\"submit\">Upload</button>\n\
    </form>\n\
    {% with messages = get_flashed_messages(with_categories=true) %}\n\
      {% if messages %}\n\
        <ul>\n\
        {% for category, message in messages %}\n\
          <li class=\"{{ category }}\">{{ message }}</li>\n\
        {% endfor %}\n\
        </ul>\n\
      {% endif %}\n\
    {% endwith %}\n\
    <footer>\n\
        <p>Warning: Use with caution!</p>\n\
    </footer>\n\
</body>\n\
</html>\n" > templates/index.html

# Create and write the HTML template for deletion confirmation
RUN echo "\
<!DOCTYPE html>\n\
<html lang=\"en\">\n\
<head>\n\
    <meta charset=\"UTF-8\">\n\
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\
    <title>Confirm Deletion</title>\n\
</head>\n\
<body>\n\
    <h1>Confirm Deletion</h1>\n\
    <p>The following files have been uploaded:</p>\n\
    <ul>\n\
        {% for file in files %}\n\
            <li>{{ file.filename }}</li>\n\
        {% endfor %}\n\
    </ul>\n\
    <form action=\"/delete\" method=\"POST\">\n\
        <button type=\"submit\">Delete Uploaded Files</button>\n\
    </form>\n\
    <a href=\"/\">Cancel</a>\n\
</body>\n\
</html>\n" > templates/confirm_delete.html

# Expose the port and run the Flask app
EXPOSE 5000
CMD [ "/venv/bin/python3", "app.py" ]
