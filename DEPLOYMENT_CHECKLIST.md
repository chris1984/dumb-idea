# Deployment Checklist

Use this checklist when deploying to a new AlmaLinux server.

## Pre-Deployment

- [ ] AlmaLinux server is accessible via SSH
- [ ] You have sudo privileges on the server
- [ ] Ruby 3.0+ is installed (`ruby -v`)
- [ ] Build tools are installed (`sudo dnf install gcc make redhat-rpm-config sqlite-devel`)
- [ ] SSL certificate and key files are ready and accessible
- [ ] Domain DNS is pointing to your server's IP address

## Deployment Steps

- [ ] Copy application files to server (e.g., `/var/www/dumb-idea`)
- [ ] Navigate to application directory
- [ ] Run `./setup.sh`
- [ ] Provide domain name when prompted
- [ ] Provide SSL certificate path when prompted
- [ ] Provide SSL key path when prompted
- [ ] Provide SSL CA certificate path (or skip)
- [ ] Wait for setup to complete

## Post-Deployment Configuration

- [ ] Edit `.env` file with your settings:
  ```bash
  nano .env
  ```
- [ ] Update `ADMIN_USERNAME` (change from 'admin')
- [ ] Update `ADMIN_PASSWORD` (change from 'changeme')
- [ ] Update `ADMIN_EMAIL`
- [ ] Configure SMTP settings if using email notifications

## Service Startup

- [ ] Start the application:
  ```bash
  sudo systemctl start dumb-idea
  ```
- [ ] Check application status:
  ```bash
  sudo systemctl status dumb-idea
  ```
- [ ] Verify no errors in logs:
  ```bash
  sudo journalctl -u dumb-idea -n 20
  ```
- [ ] Restart Apache:
  ```bash
  sudo systemctl restart httpd
  ```
- [ ] Check Apache status:
  ```bash
  sudo systemctl status httpd
  ```

## Testing

- [ ] Test HTTP to HTTPS redirect:
  ```bash
  curl -I http://your-domain.com
  ```
- [ ] Test HTTPS access:
  ```bash
  curl -I https://your-domain.com
  ```
- [ ] Visit site in browser: `https://your-domain.com`
- [ ] Generate a few ideas (click "Generate Stupid Idea")
- [ ] Test favoriting an idea
- [ ] Test viewing favorites
- [ ] Test idea history navigation (left/right arrows)
- [ ] Test dark mode toggle
- [ ] Submit a test idea
- [ ] Log into admin panel: `https://your-domain.com/admin`
  - Username: (from .env)
  - Password: (from .env)
- [ ] Verify test submission appears in admin panel
- [ ] Test approving/rejecting a submission

## Security Hardening

- [ ] Admin credentials changed from defaults
- [ ] `.env` file permissions are restrictive:
  ```bash
  chmod 600 .env
  ```
- [ ] Database file permissions are appropriate:
  ```bash
  ls -la ideas.db
  ```
- [ ] Firewall is configured (ports 80, 443 open)
- [ ] SELinux is configured (if enabled):
  ```bash
  getsebool httpd_can_network_connect
  # Should show "on"
  ```
- [ ] Consider restricting admin panel by IP in Apache config

## Monitoring Setup

- [ ] Application logs are being written:
  ```bash
  sudo journalctl -u dumb-idea --since today
  ```
- [ ] Apache logs are accessible:
  ```bash
  sudo tail /var/log/httpd/dumb-idea-access.log
  sudo tail /var/log/httpd/dumb-idea-error.log
  ```
- [ ] Set up log rotation (if needed)
- [ ] Configure external uptime monitoring (optional)

## Backup Setup

- [ ] Create backups directory:
  ```bash
  mkdir -p backups
  ```
- [ ] Test manual backup:
  ```bash
  cp ideas.db backups/ideas-test.db
  ```
- [ ] Set up automated backups with cron (optional):
  ```bash
  crontab -e
  # Add: 0 2 * * * cd /var/www/dumb-idea && cp ideas.db backups/ideas-$(date +\%Y\%m\%d).db
  ```
- [ ] Configure off-site backups (optional)

## Documentation

- [ ] Document server details (IP, credentials, etc.) in secure location
- [ ] Document SSL certificate renewal process
- [ ] Note any custom configurations made
- [ ] Save this checklist with completion date

## Post-Deployment Verification (24 hours later)

- [ ] Services still running:
  ```bash
  sudo systemctl status dumb-idea httpd
  ```
- [ ] No errors in logs
- [ ] Site is accessible
- [ ] No performance issues
- [ ] Email notifications working (if configured)

---

## Deployment Info

- **Deployment Date:** _______________
- **Server IP:** _______________
- **Domain:** _______________
- **SSL Certificate Expiry:** _______________
- **Deployed By:** _______________
- **Notes:** _______________________________________________
  _______________________________________________
  _______________________________________________
