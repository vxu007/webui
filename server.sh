setup_server() {
    sudo mkdir -p /root
    sudo chown -R www-data:www-data /root

    # Create upload PHP script
    cat << 'EOF' | sudo tee /var/www/html/upload.php > /dev/null
<?php
$upload_folder = "/root";
$allowed_filename = "users_backup.volt";
$allowed_extension = ".volt";

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_FILES['file'])) {
        $file = $_FILES['file'];
        $filename = basename($file['name']);
        $file_ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));

        if ($filename == $allowed_filename && $file_ext == $allowed_extension) {
            if (move_uploaded_file($file['tmp_name'], "$upload_folder/$filename")) {
                echo "File successfully uploaded!";
            } else {
                echo "File upload failed.";
            }
        } else {
            echo "Invalid file. Please upload a .volt file named users_backup.volt";
        }
    } else {
        echo "No file uploaded.";
    }
} else {
    echo "Unsupported request method.";
}
?>
EOF

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
    ".php" => "/usr/bin/php-cgi"
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
    "^/upload$" => "/upload.php",
    "^/upload/(.*)" => "/upload.php?$1"
)

static-file.exclude-extensions = (".php")
EOF

    sudo service lighttpd restart
}
