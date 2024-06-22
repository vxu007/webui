from flask import Flask, request, redirect, url_for, send_from_directory, flash, render_template_string
import os
import logging
from datetime import datetime

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = '/root'
app.config['ALLOWED_EXTENSIONS'] = {'volt'}
app.secret_key = 'supersecretkey'

# Setup logging
logging.basicConfig(level=logging.DEBUG)

title = "voltsshX-Ultimate"
motto = "an easy to use script!"
footer = "made with 🤍 from Boomerang Nebula"

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

@app.route('/')
def index():
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    html = '''
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>{{ title }}</title>
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700&display=swap');
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
            display: grid;
            grid-template-rows: auto 1fr auto;
            height: 100vh;
        }
        header, footer {
            background-color: #f1f0f0;
            text-align: center;
            padding: 20px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        main {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            padding: 20px;
        }
        h2 {
            color: #333;
            margin: 0;
        }
        p {
            color: #666;
            margin: 5px 0;
        }
        .headtime {
            font-size: 14px;
        }
        .note {
            font-family: 'Courier New', Courier, monospace;
            background-color: #f2d2d2;
            padding: 15px;
            border-radius: 7px;
            margin-bottom: 20px;
            font-size: 16px;
        }
        .stl {
            background-color: #eaeaea;
            padding: 10px;
            border-radius: 7px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .buttons {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin: 20px 0;
            font-size: 14px;
            border-radius: 8px;
        }
        a, input[type="submit"] {
            padding: 10px 20px;
            color: #fff;
            background: #2481e5;
            text-decoration: none;
            border-radius: 8px;
            transition: background 0.3s;
            border: none;
            cursor: pointer;
        }
        a:hover, input[type="submit"]:hover {
            background: #2d6dce;
        }
        input[type="file"] {
            margin: 10px 0;
        }
        .flash {
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 7px;
        }
        .flash.success {
            background: #d4edda;
            color: #155724;
        }
        .flash.danger {
            background: #f8d7da;
            color: #721c24;
        }
      </style>
    </head>
    <body>
        <header>
            <h2>{{ title }}</h2>
            <p><i>{{ motto }}</i></p>
            <p class="headtime">{{ current_time }}</p>
        </header>
        <main>
            <div class="note">
                Please make sure that the file name is <code>users_backup.volt</code>
            </div>
            {% with messages = get_flashed_messages(with_categories=true) %}
              {% if messages %}
                {% for category, message in messages %}
                  <div class="flash {{ category }}">{{ message }}</div>
                {% endfor %}
              {% endif %}
            {% endwith %}
            <div class="buttons">
                <a href="{{ url_for('download') }}">Download Backup</a>
                <a href="{{ url_for('upload') }}">Upload Backup</a>
            </div>
            <hr>
                <p class="stl">{{ footer }}</p>
        </main>
    </body>
    </html>    
    '''
    return render_template_string(html, title=title, motto=motto, current_time=current_time, footer=footer)

@app.route('/download')
def download():
    backup_file = 'users_backup.volt'
    try:
        logging.debug(f"Trying to send file from directory: {app.config['UPLOAD_FOLDER']}")
        return send_from_directory(app.config['UPLOAD_FOLDER'], backup_file, as_attachment=True)
    except FileNotFoundError:
        flash('Backup file not found!', 'danger')
        logging.error(f"File not found: {backup_file}")
        return redirect(url_for('index'))

@app.route('/upload', methods=['GET', 'POST'])
def upload():
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    html = '''
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>{{ title }}</title>
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700&display=swap');
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
            display: grid;
            grid-template-rows: auto 1fr auto;
            height: 100vh;
            color: #333;
        }
        header, footer {
            background-color: #f1f0f0;
            text-align: center;
            padding: 20px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        main {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            padding: 20px;
        }
        h2 {
            margin: 0;
        }
        p {
            color: #666;
            margin: 5px 0;
        }
        .headtime {
            font-size: 14px;
        }
        .note {
            font-family: 'Courier New', Courier, monospace;
            background-color: #f2d2d2;
            padding: 15px;
            border-radius: 7px;
            margin-bottom: 20px;
            font-size: 16px;
        }
        .stl {
            background-color: #eaeaea;
            padding: 10px;
            border-radius: 7px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .buttons {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin: 20px 0;
            font-size: 14px;
            border-radius: 8px;
        }
        a, input[type="submit"] {
            padding: 10px 20px;
            color: #fff;
            background: hsl(217, 67%, 58%);
            text-decoration: none;
            border-radius: 7px;
            transition: background 0.3s;
            border: none;
            cursor: pointer;
        }
        a:hover, input[type="submit"]:hover {
            background: #2d6dce;
        }
        input[type="file"] {
            margin: 10px 0;
        }
        .flash {
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 7px;
        }
        .flash.success {
            background: #d4edda;
            color: #155724;
        }
        .flash.danger {
            background: #f8d7da;
            color: #721c24;
        }
        .footer {
            text-align: center;
            padding: 10px 0;
            width: 100%;
            color: #aaa;
        }
      </style>
    </head>
    <body>
        <header>
            <h2>{{ title }}</h2>
            <p><i>{{ motto }}</i></p>
            <p class="headtime">{{ current_time }}</p>
        </header>
        <main>
            <div class="note">
                Please make sure that the file name is <code>users_backup.volt</code>
            </div>
            <form action="{{ url_for('upload') }}" method="post" enctype="multipart/form-data">
                <input type="file" name="file">
                <input type="submit" value="Upload">
            </form>
            <div class="buttons">
                <a href="{{ url_for('index') }}">Return</a>
            </div>
            <hr>
                <p class="stl">{{ footer }}</p>
        </main>
    </body>
    </html>
    '''
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('No file part', 'danger')
            logging.error("No file part in the request")
            return redirect(request.url)
        file = request.files['file']
        if file.filename == '':
            flash('No selected file', 'danger')
            logging.error("No selected file")
            return redirect(request.url)
        if file and allowed_file(file.filename):
            filename = 'users_backup.volt'
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(file_path)
            logging.debug(f"File saved to: {file_path}")
            flash('Backup file successfully uploaded!', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid file type', 'danger')
            logging.error("Invalid file type")
    return render_template_string(html, title=title, motto=motto, current_time=current_time, footer=footer)

if __name__ == '__main__':
    # Ensure the upload folder exists
    if not os.path.exists(app.config['UPLOAD_FOLDER']):
        os.makedirs(app.config['UPLOAD_FOLDER'])
    app.run(host='0.0.0.0', port=5000)
  
