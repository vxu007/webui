#!/bin/bash
clear

install_dependencies() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [ "$ID" == "ubuntu" ] && [ "$VERSION_ID" == "20.04" ]; then
                # Ubuntu 20.04
                echo "Please wait ..."
                echo " . * . * . * ."
                sudo apt update >/dev/null 2>&1
                sudo apt install -y lighttpd iptables wget curl >/dev/null 2>&1
            elif [ "$ID" == "debian" ]; then
                # Debian
                echo "Please wait ..."
                echo " . * . * . * ."
                sudo apt update >/dev/null 2>&1
                sudo apt install -y lighttpd iptables wget curl >/dev/null 2>&1
            else
                echo "Unsupported OS: $ID $VERSION_ID"
                exit 1
            fi
        else
            echo "Unsupported OS: $OSTYPE"
            exit 1
        fi
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

setup_firewall() {
    if ! command -v iptables &>/dev/null; then
        sudo apt update >/dev/null 2>&1
        sudo apt install -y iptables >/dev/null 2>&1
    fi

    # Create iptables rules file if it doesn't exist
    sudo touch /etc/iptables/rules.v4

    # Add rule to open port 5000 for TCP
    echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 5000 -j ACCEPT" | sudo tee -a /etc/iptables/rules.v4 > /dev/null

    # Check if the reject rule exists
    if grep -q "REJECT --reject-with icmp-host-prohibited" /etc/iptables/rules.v4; then
        # Insert the rule before the reject rule
        sudo sed -i '/REJECT --reject-with icmp-host-prohibited/i -A INPUT -p tcp -m state --state NEW -m tcp --dport 5000 -j ACCEPT' /etc/iptables/rules.v4
    else
        # Append the rule at the end
        echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 5000 -j ACCEPT" | sudo tee -a /etc/iptables/rules.v4 > /dev/null
    fi

    # Apply the iptables rules
    sudo iptables-restore < /etc/iptables/rules.v4
}

setup_server() {
    sudo mkdir -p /root
    sudo chown -R www-data:www-data /root

    # Create upload script
    cat << 'EOF' | sudo tee /var/www/html/upload.sh > /dev/null
#!/bin/bash

UPLOAD_FOLDER="/root"
ALLOWED_EXTENSIONS=".volt"

if [ ! -d "$UPLOAD_FOLDER" ]; then
    echo "Upload folder does not exist or is not accessible."
    exit 1
fi

FILENAME=$(basename "$1")
EXTENSION="${FILENAME##*.}"

if [[ "$FILENAME" == "users_backup" && ".$EXTENSION" == "$ALLOWED_EXTENSIONS" ]]; then
    mv "$1" "$UPLOAD_FOLDER"
    echo "Content-type: text/html"
    echo ""
    echo "File successfully uploaded!"
else
    echo "Content-type: text/html"
    echo ""
    echo "Invalid file. Please upload a .volt file named users_backup.volt"
fi
EOF

    sudo chmod +x /var/www/html/upload.sh
    sudo chown -R www-data:www-data /root
    sudo chmod -R 755 /root


    # Configure lighttpd
    sudo tee /etc/lighttpd/lighttpd.conf > /dev/null << EOF
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_compress",
    "mod_redirect",
    "mod_fastcgi",
    "mod_rewrite",
    "mod_cgi"
)

cgi.assign = (
    ".sh" => "/bin/sh"
)

server.document-root = "/var/www/html"
server.upload-dirs = ("/var/cache/lighttpd/uploads")
server.errorlog = "/var/log/lighttpd/error.log"
server.pid-file = "/var/run/lighttpd.pid"
server.username = "www-data"
server.groupname = "www-data"
server.port = 5000

index-file.names = ("index.html")

mimetype.assign = (
    ".html" => "text/html",
    ".txt" => "text/plain",
    ".css" => "text/css",
    ".js" => "application/javascript",
    ".json" => "application/json",
    ".png" => "image/png",
    ".jpg" => "image/jpeg",
    ".jpeg" => "image/jpeg",
    ".gif" => "image/gif",
    ".pdf" => "application/pdf",
    ".svg" => "image/svg+xml"
)

url.rewrite-once = (
    "^/upload$" => "/upload.sh",
    "^/upload/(.*)" => "/upload.sh?$1"
)

static-file.exclude-extensions = (".sh")
EOF

    sudo service lighttpd restart
}

setup_web_interface() {
    # Function to insert flash message into HTML
    generate_html() {
        local file=$1
        local flash_message=$2

        sed -e "s/{{ flash_message }}/$flash_message/g" \
            $file > /var/www/html/$(basename $file)
    }

    # Generate index.html
    cat << 'EOF' > /tmp/index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>voltsshX-Ultimate</title>
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
  <script>
    function updateTime() {
        var now = new Date();
        document.getElementById('time').textContent = now.toLocaleTimeString();
    }
    setInterval(updateTime, 1000);
  </script>
</head>
<body onload="updateTime()">
    <header>
        <h2>voltsshX-Ultimate</h2>
        <p><i>an easy to use script!</i></p>
        <p class="headtime" id="time"></p>
    </header>
    <main>
        <div class="note">
            Please make sure that the file name is <code>users_backup.volt</code>
        </div>
        <div class="buttons">
            <a href="/root/users_backup.volt" download>Download Backup</a>
            <a href="/upload.html">Upload Backup</a>
        </div>
        <hr>
        <p class="stl">made with 🤍 from Boomerang Nebula</p>
    </main>
</body>
</html>
EOF

    # Generate upload.html
    cat << 'EOF' > /tmp/upload.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>voltsshX-Ultimate</title>
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
  <script>
    function updateTime() {
        var now = new Date();
        document.getElementById('time').textContent = now.toLocaleTimeString();
    }
    setInterval(updateTime, 1000);
  </script>
</head>
<body onload="updateTime()">
    <header>
        <h2>voltsshX-Ultimate</h2>
        <p><i>an easy to use script!</i></p>
        <p class="headtime" id="time"></p>
    </header>
    <main>
        <div class="note">
            Please make sure that the file name is <code>users_backup.volt</code>
        </div>
        <div class="flash danger">
            {{ flash_message }}
        </div>
        <form action="/upload.sh" method="post" enctype="multipart/form-data">
            <input type="file" name="file">
            <input type="submit" value="Upload">
        </form>
        <hr>
        <p class="stl">made with 🤍 from Boomerang Nebula</p>
    </main>
</body>
</html>
EOF

    # Generate final HTML files with dynamic content
    generate_html /tmp/index.html ""
    generate_html /tmp/upload.html "Please upload a valid file."

    # Set correct permissions
    sudo chown www-data:www-data /var/www/html/index.html
    sudo chown www-data:www-data /var/www/html/upload.html
}

# Main script execution starts here
install_dependencies
setup_firewall
setup_server
setup_web_interface

clear
# Display success message with server IP
# server_ip=$(hostname -I | cut -d' ' -f1)
server_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<<"$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
echo ""
echo "   voltsshX-Ultimate"
echo ""
echo " Backup server app running."
echo " - - - - - - - - - - - - - - - - - - - - - - - -"
echo "|                                           "
echo " > Access WebUI on http://$server_ip:5000"
echo "|                                           "
echo " - - - - - - - - - - - - - - - - - - - - - - - -"
echo "    @voltsshx"
echo ""
