# Deployment Guide for AlmaLinux

This guide will help you deploy the Dumb Idea Generator app on an AlmaLinux server with Apache (httpd) and SSL.

## Prerequisites

Before running the setup script, ensure you have:

1. **AlmaLinux server** with sudo access
2. **Ruby installed** (version 3.0 or higher)
   ```bash
   sudo dnf install ruby ruby-devel
   ```

3. **Build tools** (required for compiling native gems)
   ```bash
   sudo dnf install gcc make redhat-rpm-config
   ```

4. **SQLite development libraries**
   ```bash
   sudo dnf install sqlite-devel
   ```

5. **SSL Certificate and Key** for your domain
   - Certificate file (e.g., `/etc/pki/tls/certs/your-domain.crt`)
   - Private key file (e.g., `/etc/pki/tls/private/your-domain.key`)
   - Optional: CA bundle file (e.g., `/etc/pki/tls/certs/ca-bundle.crt`)

## Quick Start

1. **Clone or copy the app to your server**
   ```bash
   # Example: copy to /var/www/dumb-idea
   sudo mkdir -p /var/www/dumb-idea
   sudo chown $USER:$USER /var/www/dumb-idea
   cd /var/www/dumb-idea
   # ... copy your files here ...
   ```

2. **Run the setup script**
   ```bash
   cd /var/www/dumb-idea
   ./setup.sh
   ```

   The script will:
   - Install Ruby dependencies
   - Create and seed the database
   - Set up systemd service
   - Configure Apache (httpd) with SSL
   - Configure firewall (if firewalld is active)
   - Configure SELinux (if enabled)

   During setup, you'll be prompted for:
   - Your domain name
   - SSL certificate path
   - SSL key path
   - SSL CA certificate path (optional)

3. **Configure your environment**
   ```bash
   nano .env
   ```

   Update these critical settings:
   - `ADMIN_USERNAME` - Change from default 'admin'
   - `ADMIN_PASSWORD` - Change from default 'changeme'
   - `ADMIN_EMAIL` - Your email for notifications
   - `SMTP_*` - Email server settings (if using email notifications)

4. **Start the services**
   ```bash
   # Start the app
   sudo systemctl start dumb-idea

   # Verify it's running
   sudo systemctl status dumb-idea

   # Start Apache
   sudo systemctl restart httpd
   ```

5. **Verify deployment**

   Visit your domain in a browser:
   ```
   https://your-domain.com
   ```

## Service Management

### Application Service

```bash
# Start the app
sudo systemctl start dumb-idea

# Stop the app
sudo systemctl stop dumb-idea

# Restart the app
sudo systemctl restart dumb-idea

# View app status
sudo systemctl status dumb-idea

# View app logs
sudo journalctl -u dumb-idea -f

# View app logs for the last hour
sudo journalctl -u dumb-idea --since "1 hour ago"
```

### Apache Service

```bash
# Restart Apache
sudo systemctl restart httpd

# Check Apache status
sudo systemctl status httpd

# Test Apache configuration
sudo apachectl configtest

# View Apache access logs
sudo tail -f /var/log/httpd/dumb-idea-access.log

# View Apache error logs
sudo tail -f /var/log/httpd/dumb-idea-error.log
```

## Directory Structure

```
/var/www/dumb-idea/
├── app.rb                      # Main application
├── config.ru                   # Rack configuration
├── Gemfile                     # Ruby dependencies
├── ideas.db                    # SQLite database
├── .env                        # Environment configuration (DO NOT commit)
├── start.sh                    # App startup script
├── setup.sh                    # Deployment setup script
├── views/                      # ERB templates
│   ├── index.erb
│   ├── admin.erb
│   └── ...
└── vendor/bundle/              # Ruby gems (created by bundler)
```

## Configuration Files

### Systemd Service
Location: `/etc/systemd/system/dumb-idea.service`

### Apache Configuration
Location: `/etc/httpd/conf.d/dumb-idea.conf`

## Troubleshooting

### App won't start

1. **Check service logs:**
   ```bash
   sudo journalctl -u dumb-idea -n 50
   ```

2. **Check if port 9292 is already in use:**
   ```bash
   sudo lsof -i :9292
   ```

3. **Test starting manually:**
   ```bash
   cd /var/www/dumb-idea
   ./start.sh
   ```

### Apache shows 502 Bad Gateway

1. **Verify app is running:**
   ```bash
   sudo systemctl status dumb-idea
   ```

2. **Test app directly:**
   ```bash
   curl http://localhost:9292
   ```

3. **Check SELinux:**
   ```bash
   sudo getsebool httpd_can_network_connect
   # Should be "on"
   ```

   If not:
   ```bash
   sudo setsebool -P httpd_can_network_connect 1
   ```

### SSL Certificate Errors

1. **Verify certificate paths in Apache config:**
   ```bash
   sudo cat /etc/httpd/conf.d/dumb-idea.conf | grep SSL
   ```

2. **Test certificate validity:**
   ```bash
   openssl x509 -in /path/to/cert.crt -text -noout
   ```

3. **Check Apache error logs:**
   ```bash
   sudo tail -f /var/log/httpd/error_log
   ```

### Database Issues

1. **Check database file permissions:**
   ```bash
   ls -la /var/www/dumb-idea/ideas.db
   ```

2. **Verify database schema:**
   ```bash
   cd /var/www/dumb-idea
   bundle exec ruby -e "require 'sqlite3'; db = SQLite3::Database.new('ideas.db'); db.execute('SELECT name FROM sqlite_master WHERE type=\"table\"').each {|t| puts t}"
   ```

3. **Rebuild database (WARNING: destroys data):**
   ```bash
   cd /var/www/dumb-idea
   rm ideas.db
   bundle exec ruby setup_db.rb
   bundle exec ruby seed.rb
   ```

## Updating the Application

1. **Stop the service:**
   ```bash
   sudo systemctl stop dumb-idea
   ```

2. **Backup the database:**
   ```bash
   cp ideas.db ideas.db.backup
   ```

3. **Pull updates or copy new files**

4. **Update dependencies if Gemfile changed:**
   ```bash
   bundle install --path vendor/bundle
   ```

5. **Restart the service:**
   ```bash
   sudo systemctl start dumb-idea
   sudo systemctl restart httpd
   ```

## Security Recommendations

1. **Change default admin credentials** in `.env`:
   ```
   ADMIN_USERNAME=your_secure_username
   ADMIN_PASSWORD=your_secure_password
   ```

2. **Restrict admin panel access** by IP (optional):

   Add to `/etc/httpd/conf.d/dumb-idea.conf`:
   ```apache
   <Location /admin>
       Require ip 1.2.3.4  # Your trusted IP
   </Location>
   ```

3. **Keep system updated:**
   ```bash
   sudo dnf update
   ```

4. **Monitor logs regularly:**
   ```bash
   sudo journalctl -u dumb-idea --since today
   ```

5. **Set up log rotation** (if not already configured):
   ```bash
   sudo nano /etc/logrotate.d/dumb-idea
   ```

   Add:
   ```
   /var/www/dumb-idea/submissions.log {
       daily
       rotate 7
       compress
       missingok
       notifempty
   }
   ```

## Performance Tuning

### For High Traffic

1. **Use Puma instead of WEBrick** (already in Gemfile)

   Edit `start.sh` to use puma:
   ```bash
   bundle exec puma -b tcp://0.0.0.0:9292 -w 4 -t 8:32
   ```

2. **Enable Apache caching** for static assets

3. **Set up a CDN** for static assets

### Database Optimization

For larger deployments, consider migrating to PostgreSQL or MySQL instead of SQLite.

## Monitoring

Set up monitoring with:
- System metrics: `htop`, `iotop`
- Log monitoring: `logwatch` or centralized logging
- Uptime monitoring: External service like UptimeRobot
- Application Performance Monitoring (APM): New Relic, DataDog, etc.

## Backup Strategy

1. **Database backups:**
   ```bash
   # Create backup
   cp ideas.db backups/ideas-$(date +%Y%m%d-%H%M%S).db
   ```

2. **Automated backups with cron:**
   ```bash
   crontab -e
   ```

   Add:
   ```
   0 2 * * * cd /var/www/dumb-idea && cp ideas.db backups/ideas-$(date +\%Y\%m\%d).db
   ```

3. **Off-site backups:** Use rsync, rclone, or cloud backup service

## Support

For issues or questions:
- Check application logs: `sudo journalctl -u dumb-idea -f`
- Check Apache logs: `/var/log/httpd/dumb-idea-*.log`
- Review this guide's troubleshooting section
- Check the main README.md for application features and usage
