FROM debian:latest

# Install necessary tools and Python
RUN apt-get update && apt-get install -y \
    wipe \
    python3 \
    python3-pip \
    && apt-get clean

# Install Flask
RUN pip3 install flask

# Set working directory
WORKDIR /app

# Add Flask application code
RUN echo "\
from flask import Flask, request, render_template\n\
import subprocess\n\
\n\
app = Flask(__name__)\n\
\n\
@app.route('/')\n\
def home():\n\
    return render_template('index.html')\n\
\n\
@app.route('/wipe', methods=['POST'])\n\
def wipe():\n\
    target_path = request.form.get('target_path')\n\
    \n\
    # Validate input\n\
    if not target_path:\n\
        return 'Error: No path specified.', 400\n\
    \n\
    try:\n\
        # Perform wipe securely using the 'wipe' tool\n\
        subprocess.run(['wipe', '-r', target_path], check=True)\n\
        return f'Successfully wiped: {target_path}'\n\
    except subprocess.CalledProcessError:\n\
        return f'Error: Failed to wipe {target_path}. Check permissions or path validity.', 500\n\
    except Exception as e:\n\
        return f'Error during wipe: {str(e)}', 500\n\
\n\
if __name__ == '__main__':\n\
    app.run(host='0.0.0.0', port=5000)\n" > app.py

# Add HTML template code
RUN mkdir templates && echo "\
<!DOCTYPE html>\n\
<html lang=\"en\">\n\
<head>\n\
    <meta charset=\"UTF-8\">\n\
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\
    <title>Secure File/Directory Wiper</title>\n\
</head>\n\
<body>\n\
    <h1>Secure File/Directory Wiper</h1>\n\
    <form action=\"/wipe\" method=\"POST\">\n\
        <label for=\"target_path\">Path to Wipe:</label>\n\
        <input type=\"text\" id=\"target_path\" name=\"target_path\" placeholder=\"e.g., /dev/sda or /path/to/directory\" required>\n\
        <button type=\"submit\">Wipe</button>\n\
    </form>\n\
</body>\n\
</html>\n" > templates/index.html

# Expose Flask port
EXPOSE 5000

# Run the Flask app
CMD ["python3", "app.py"]
