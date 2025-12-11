#!/bin/bash
set -e

echo "========================================="
echo "Dumb Idea App - AlmaLinux Setup Script"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root${NC}"
    echo "Run as a regular user with sudo privileges"
    exit 1
fi

# Get the directory where the script is located
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_USER=$(whoami)

echo -e "${GREEN}App directory: $APP_DIR${NC}"
echo -e "${GREEN}App user: $APP_USER${NC}"
echo ""

# Step 1: Check for Ruby
echo "Step 1: Checking Ruby installation..."
if ! command -v ruby &> /dev/null; then
    echo -e "${RED}Ruby is not installed!${NC}"
    echo "Please install Ruby first:"
    echo "  sudo dnf install ruby ruby-devel"
    exit 1
fi
RUBY_VERSION=$(ruby -v)
echo -e "${GREEN}Found: $RUBY_VERSION${NC}"
echo ""

# Step 2: Check for bundler
echo "Step 2: Checking for bundler..."
if ! command -v bundle &> /dev/null; then
    echo "Installing bundler..."
    gem install bundler --user-install
    # Add gem bin to PATH if not already there
    export PATH="$HOME/.local/share/gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"
fi
echo -e "${GREEN}Bundler is available${NC}"
echo ""

# Step 3: Install Ruby gems
echo "Step 3: Installing Ruby dependencies..."
cd "$APP_DIR"
bundle install --path vendor/bundle
echo -e "${GREEN}Dependencies installed${NC}"
echo ""

# Step 4: Set up environment file
echo "Step 4: Setting up environment file..."
if [ ! -f "$APP_DIR/.env" ]; then
    cp "$APP_DIR/.env.example" "$APP_DIR/.env"
    echo -e "${YELLOW}Created .env file from template${NC}"
    echo -e "${YELLOW}IMPORTANT: Edit .env and configure your settings!${NC}"
else
    echo -e "${GREEN}.env file already exists${NC}"
fi
echo ""

# Step 5: Initialize database
echo "Step 5: Initializing database..."
cd "$APP_DIR"

# Run main database setup
if [ ! -f "$APP_DIR/ideas.db" ]; then
    bundle exec ruby setup_db.rb
    echo -e "${GREEN}Database created${NC}"
else
    echo -e "${YELLOW}Database already exists, running setup to ensure tables exist...${NC}"
    bundle exec ruby setup_db.rb
fi

# Run migration scripts
echo "Running migration scripts..."
for migration in add_submissions_table.rb add_submission_status.rb add_rate_limiting.rb add_profanity_flag.rb; do
    if [ -f "$APP_DIR/$migration" ]; then
        echo "  - Running $migration..."
        bundle exec ruby "$migration" 2>/dev/null || true
    fi
done

# Seed database if empty
IDEA_COUNT=$(bundle exec ruby -e "require 'sqlite3'; db = SQLite3::Database.new('ideas.db'); puts db.execute('SELECT COUNT(*) FROM ideas')[0][0]")
if [ "$IDEA_COUNT" -eq 0 ]; then
    echo "Seeding database with initial ideas..."
    bundle exec ruby seed.rb
    echo -e "${GREEN}Database seeded${NC}"
else
    echo -e "${GREEN}Database already has $IDEA_COUNT ideas${NC}"
fi
echo ""

# Step 6: Make start script executable
echo "Step 6: Making start script executable..."
chmod +x "$APP_DIR/start.sh"
echo -e "${GREEN}start.sh is now executable${NC}"
echo ""

# Step 7: Install and configure Apache (httpd)
echo "Step 7: Setting up Apache (httpd)..."
echo -e "${YELLOW}This step requires sudo privileges${NC}"

# Check if httpd is installed
if ! command -v httpd &> /dev/null; then
    echo "Installing httpd and mod_ssl..."
    sudo dnf install -y httpd mod_ssl
else
    echo -e "${GREEN}httpd is already installed${NC}"
fi

# Enable and start httpd
sudo systemctl enable httpd
echo ""

# Step 8: Create systemd service for the app
echo "Step 8: Creating systemd service..."
sudo tee /etc/systemd/system/dumb-idea.service > /dev/null <<EOF
[Unit]
Description=Dumb Idea Generator App
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment="PATH=/usr/local/bin:/usr/bin:/bin:$HOME/.local/share/gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin"
ExecStart=/bin/bash $APP_DIR/start.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable dumb-idea.service
echo -e "${GREEN}Systemd service created and enabled${NC}"
echo ""

# Step 9: Create Apache configuration
echo "Step 9: Creating Apache configuration..."
echo ""
echo -e "${YELLOW}Please provide the following information:${NC}"
read -p "Domain name (e.g., example.com): " DOMAIN_NAME
read -p "SSL Certificate path (e.g., /etc/pki/tls/certs/your-cert.crt): " SSL_CERT
read -p "SSL Certificate Key path (e.g., /etc/pki/tls/private/your-key.key): " SSL_KEY

# Optional: SSL CA Certificate
read -p "SSL CA Certificate path (optional, press Enter to skip): " SSL_CA

sudo tee /etc/httpd/conf.d/dumb-idea.conf > /dev/null <<EOF
# HTTP to HTTPS redirect
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    Redirect permanent / https://$DOMAIN_NAME/
</VirtualHost>

# HTTPS configuration
<VirtualHost *:443>
    ServerName $DOMAIN_NAME

    # SSL Configuration
    SSLEngine on
    SSLCertificateFile $SSL_CERT
    SSLCertificateKeyFile $SSL_KEY
EOF

# Add CA certificate if provided
if [ -n "$SSL_CA" ]; then
    sudo bash -c "cat >> /etc/httpd/conf.d/dumb-idea.conf" <<EOF
    SSLCertificateChainFile $SSL_CA
EOF
fi

sudo bash -c "cat >> /etc/httpd/conf.d/dumb-idea.conf" <<'EOF'

    # Security headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    # Compression
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
    </IfModule>

    # Caching headers for static content (if served directly)
    <FilesMatch "\.(ico|jpg|jpeg|png|gif|js|css|svg|woff|woff2|ttf|eot)$">
        Header set Cache-Control "max-age=2592000, public"
    </FilesMatch>

    # Cache-control for HTML (shorter cache)
    <FilesMatch "\.(html|htm)$">
        Header set Cache-Control "max-age=3600, public, must-revalidate"
    </FilesMatch>

    # Proxy configuration
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:9292/
    ProxyPassReverse / http://127.0.0.1:9292/

    # WebSocket support (if needed in the future)
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "ws://127.0.0.1:9292/$1" [P,L]

    # Logging
    ErrorLog /var/log/httpd/dumb-idea-error.log
    CustomLog /var/log/httpd/dumb-idea-access.log combined
</VirtualHost>
EOF

echo -e "${GREEN}Apache configuration created${NC}"
echo ""

# Step 10: Configure SELinux (if enabled)
echo "Step 10: Configuring SELinux..."
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    echo "Allowing httpd to make network connections..."
    sudo setsebool -P httpd_can_network_connect 1
    echo -e "${GREEN}SELinux configured${NC}"
else
    echo -e "${YELLOW}SELinux is not enabled or not installed${NC}"
fi
echo ""

# Step 11: Configure firewall
echo "Step 11: Configuring firewall..."
if command -v firewall-cmd &> /dev/null && sudo systemctl is-active --quiet firewalld; then
    echo "Opening HTTP and HTTPS ports..."
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
    echo -e "${GREEN}Firewall configured${NC}"
else
    echo -e "${YELLOW}firewalld is not running${NC}"
fi
echo ""

# Step 12: Test Apache configuration
echo "Step 12: Testing Apache configuration..."
if sudo apachectl configtest; then
    echo -e "${GREEN}Apache configuration is valid${NC}"
else
    echo -e "${RED}Apache configuration has errors. Please fix them before continuing.${NC}"
    exit 1
fi
echo ""

# Final summary
echo ""
echo "========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Edit the .env file with your configuration:"
echo "   nano $APP_DIR/.env"
echo ""
echo "2. Start the application service:"
echo "   sudo systemctl start dumb-idea"
echo ""
echo "3. Check the application status:"
echo "   sudo systemctl status dumb-idea"
echo ""
echo "4. Start Apache:"
echo "   sudo systemctl restart httpd"
echo ""
echo "5. View application logs:"
echo "   sudo journalctl -u dumb-idea -f"
echo ""
echo "6. View Apache logs:"
echo "   sudo tail -f /var/log/httpd/dumb-idea-access.log"
echo "   sudo tail -f /var/log/httpd/dumb-idea-error.log"
echo ""
echo "Your app will be available at:"
echo "  https://$DOMAIN_NAME"
echo ""
echo -e "${YELLOW}IMPORTANT: Don't forget to configure your .env file!${NC}"
echo ""
