# Migration Guide: MISP from Ubuntu 22.04 to Ubuntu 24.04

This guide covers migrating an existing MISP installation from Ubuntu 22.04 (with PHP 7.4) to Ubuntu 24.04 (with PHP 8.3).

## ⚠️ Important Warnings

- **ALWAYS backup your data before migration!**
- Test the migration process in a development environment first
- Plan for downtime during migration
- Verify all integrations work after migration
- Keep the old server available as fallback

## 📋 Pre-Migration Checklist

- [ ] Full database backup
- [ ] Full filesystem backup (/var/www/MISP)
- [ ] Document current PHP version and extensions
- [ ] List all custom configurations
- [ ] Note all MISP modules in use
- [ ] Export MISP configuration
- [ ] Document current MISP version
- [ ] Test backups can be restored

## 🔄 Migration Options

### Option 1: Fresh Install and Data Migration (Recommended)

This is the **safest** approach for production systems.

#### Step 1: Backup Current System (Ubuntu 22.04)

```bash
# On OLD server (Ubuntu 22.04)

# Stop MISP workers
sudo systemctl stop misp-workers

# Backup database
mysqldump -u misp -p misp > /tmp/misp_backup_$(date +%Y%m%d).sql

# Backup MISP directory
sudo tar -czf /tmp/misp_files_$(date +%Y%m%d).tar.gz /var/www/MISP

# Backup configurations
sudo tar -czf /tmp/misp_configs_$(date +%Y%m%d).tar.gz \
    /var/www/MISP/app/Config \
    /etc/apache2/sites-available/misp-ssl.conf \
    /etc/php/7.4/apache2/php.ini

# Copy backups to safe location
scp /tmp/misp_*.{sql,tar.gz} user@backup-server:/backups/
```

#### Step 2: Install Fresh Ubuntu 24.04 and MISP

On a new Ubuntu 24.04 server, follow the complete installation guide: [INSTALL-ubuntu-24.04.md](./INSTALL-ubuntu-24.04.md)

Stop before running the database import.

#### Step 3: Restore Data

```bash
# On NEW server (Ubuntu 24.04)

# Stop services
sudo systemctl stop misp-workers apache2

# Restore database
mysql -u misp -p misp < misp_backup_YYYYMMDD.sql

# Extract old MISP files (for reference)
mkdir /tmp/old_misp
tar -xzf misp_files_YYYYMMDD.tar.gz -C /tmp/old_misp

# Copy important files
sudo -u www-data cp /tmp/old_misp/var/www/MISP/app/files/* \
    /var/www/MISP/app/files/

sudo -u www-data cp -r /tmp/old_misp/var/www/MISP/.gnupg \
    /var/www/MISP/

# Restore custom configurations (review and adapt for PHP 8.3)
# Compare old and new config files manually

# Fix permissions
sudo chown -R www-data:www-data /var/www/MISP
sudo chmod -R 750 /var/www/MISP
sudo chmod -R g+ws /var/www/MISP/app/tmp
sudo chmod -R g+ws /var/www/MISP/app/files

# Run database updates
cd /var/www/MISP/app
sudo -u www-data Console/cake Admin runUpdates

# Start services
sudo systemctl start apache2 misp-workers

# Verify
sudo systemctl status apache2
sudo systemctl status misp-workers
```

#### Step 4: Post-Migration Verification

```bash
# Check MISP diagnostics
# Go to: https://your-misp.com/servers/serverSettings/diagnostics

# Test API access
curl -k -H "Authorization: YOUR_API_KEY" \
    -H "Accept: application/json" \
    https://your-misp.com/servers/getVersion

# Check workers
ps aux | grep workers

# Check logs
sudo -u www-data tail -f /var/www/MISP/app/tmp/logs/error.log
```

### Option 2: In-Place Upgrade (Advanced Users Only)

⚠️ **Risk Level: High** - Not recommended for production without extensive testing.

This involves upgrading Ubuntu 22.04 → 24.04 in place.

```bash
# Full backup first!
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y

# Upgrade to Ubuntu 24.04
sudo do-release-upgrade

# Follow prompts carefully
# After reboot, verify Ubuntu version
lsb_release -a

# Should show: Ubuntu 24.04 LTS
```

Then proceed with PHP upgrade (see Option 3).

### Option 3: PHP Upgrade Only (If Already on Ubuntu 24.04)

If you somehow have MISP on Ubuntu 24.04 but still using old PHP:

```bash
# Remove old PHP 7.4
sudo apt purge php7.4*
sudo apt autoremove -y

# Install PHP 8.3
sudo apt install -y \
    php8.3 php8.3-cli php8.3-dev libapache2-mod-php8.3 \
    php8.3-mysql php8.3-xml php8.3-mbstring php8.3-zip \
    php8.3-bcmath php8.3-intl php8.3-gd php8.3-curl \
    php8.3-opcache php8.3-readline

# Install PECL extensions
sudo pecl install redis
echo "extension=redis.so" | sudo tee /etc/php/8.3/mods-available/redis.ini
sudo phpenmod redis

sudo apt install -y libgpgme-dev
sudo pecl install gnupg
echo "extension=gnupg.so" | sudo tee /etc/php/8.3/mods-available/gnupg.ini
sudo phpenmod gnupg

# Update PHP configuration
PHP_INI="/etc/php/8.3/apache2/php.ini"
sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 50M/' $PHP_INI
sudo sed -i 's/post_max_size = .*/post_max_size = 50M/' $PHP_INI
sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' $PHP_INI
sudo sed -i 's/memory_limit = .*/memory_limit = 2048M/' $PHP_INI

# Update Composer dependencies
cd /var/www/MISP/app
sudo -u www-data php composer.phar update

# Restart services
sudo systemctl restart apache2
sudo systemctl restart misp-workers
```

## 🔍 PHP 7.4 vs PHP 8.3 Compatibility Issues

MISP is compatible with PHP 8.3, but be aware of these changes:

### Breaking Changes

1. **Nullsafe operator:** `null` handling is stricter
2. **Union types:** Type declarations may need updates
3. **Constructor property promotion:** New syntax available
4. **Named arguments:** Can be used in newer code
5. **Attributes:** Replace some old annotations

### MISP Specific Notes

- CakePHP has been updated to support PHP 8.3
- All core MISP modules work with PHP 8.3
- Custom modules may need testing

## 🗄️ Database Considerations

### MariaDB Upgrade

Ubuntu 24.04 uses MariaDB 10.11 (vs 10.6 in Ubuntu 22.04).

```bash
# After migration, optimize tables
sudo mysql -u root -p misp -e "OPTIMIZE TABLE attributes;"
sudo mysql -u root -p misp -e "OPTIMIZE TABLE events;"

# Check database status
sudo mysql -u root -p misp -e "SHOW TABLE STATUS;"
```

### UTF8MB4 Conversion (If Needed)

```bash
# Convert to utf8mb4 for better emoji/unicode support
sudo mysql -u root -p << EOF
ALTER DATABASE misp CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
USE misp;
ALTER TABLE attributes CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE events CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE organisations CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE users CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Repeat for other important tables
EOF
```

## 🔧 Configuration Migration

### Apache Configuration

The Apache configuration should work without changes, but review:

```bash
# Check Apache version
apache2 -v

# Test configuration
sudo apache2ctl configtest

# Review security settings
sudo nano /etc/apache2/sites-available/misp-ssl.conf
```

### Python Virtual Environment

Rebuild venv for Python 3.12:

```bash
# Backup old venv
sudo mv /var/www/MISP/venv /var/www/MISP/venv.old

# Create new venv with Python 3.12
sudo -u www-data python3 -m venv /var/www/MISP/venv

# Install dependencies
sudo -u www-data /var/www/MISP/venv/bin/pip install --upgrade pip
sudo -u www-data /var/www/MISP/venv/bin/pip install -r /var/www/MISP/INSTALL/REQUIREMENTS.txt
sudo -u www-data /var/www/MISP/venv/bin/pip install /var/www/MISP/PyMISP
sudo -u www-data /var/www/MISP/venv/bin/pip install /var/www/MISP/app/files/scripts/misp-stix

# Update MISP Python path
cd /var/www/MISP/app
sudo -u www-data Console/cake Admin setSetting "MISP.python_bin" "/var/www/MISP/venv/bin/python"
```

## ✅ Post-Migration Checklist

- [ ] All services running (Apache, MariaDB, Redis, Workers)
- [ ] Web interface accessible
- [ ] Login working
- [ ] API responding
- [ ] Background workers processing jobs
- [ ] MISP modules responding
- [ ] Email notifications working
- [ ] Synchronization with other MISP instances working
- [ ] Custom integrations tested
- [ ] Performance acceptable
- [ ] No errors in logs
- [ ] Diagnostics page green
- [ ] Backup old server (keep for 30 days)

## 🐛 Troubleshooting Migration Issues

### Issue: PHP Extensions Missing

```bash
# Check loaded extensions
php -m

# Install missing extensions
sudo apt install php8.3-{extension-name}
sudo systemctl restart apache2
```

### Issue: Database Connection Failed

```bash
# Check MariaDB status
sudo systemctl status mariadb

# Check credentials in database.php
sudo -u www-data nano /var/www/MISP/app/Config/database.php

# Test connection
mysql -u misp -p misp -e "SELECT 1;"
```

### Issue: Workers Not Running

```bash
# Check service status
sudo systemctl status misp-workers

# View logs
sudo journalctl -u misp-workers -f

# Restart workers
sudo systemctl restart misp-workers
```

### Issue: Permission Errors

```bash
# Reset all permissions
sudo chown -R www-data:www-data /var/www/MISP
sudo chmod -R 750 /var/www/MISP
sudo chmod -R g+ws /var/www/MISP/app/tmp
sudo chmod -R g+ws /var/www/MISP/app/files
sudo chmod -R g+ws /var/www/MISP/app/files/scripts/tmp
```

### Issue: Slow Performance

```bash
# Check Redis
redis-cli ping

# Optimize database
sudo mysqlcheck -u root -p --optimize --all-databases

# Check Apache workers
sudo apachectl status

# Review PHP-FPM settings if using FPM
sudo nano /etc/php/8.3/fpm/pool.d/www.conf
```

## 📊 Performance Comparison

Expected improvements on Ubuntu 24.04:

- **PHP 8.3:** 10-15% faster than PHP 7.4
- **MariaDB 10.11:** Better query optimization
- **Apache 2.4.58+:** Improved HTTP/2 support
- **Python 3.12:** Faster module execution
- **Overall:** 20-30% performance improvement

## 🔙 Rollback Plan

If migration fails:

1. Keep old Ubuntu 22.04 server running
2. Update DNS to point back to old server
3. Restore from backups if needed
4. Document what went wrong
5. Fix issues before retry

## 📞 Getting Help

If you encounter issues:

1. Check MISP diagnostics page
2. Review /var/www/MISP/app/tmp/logs/error.log
3. Search MISP GitHub issues
4. Ask on MISP Gitter chat
5. Post on MISP mailing list

## 🎯 Success Criteria

Migration is successful when:

- ✅ All MISP functionality works
- ✅ No errors in diagnostics
- ✅ Performance is equal or better
- ✅ All integrations functioning
- ✅ Team can use MISP normally
- ✅ Backups are in place
- ✅ Old server can be decommissioned

---

**Good luck with your migration!**

Remember: Take your time, test thoroughly, and keep backups!
