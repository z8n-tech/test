# MISP Installation Instructions for Ubuntu 24.04 LTS (Noble Numbat)

**Last Updated:** 2025-10-31
**MISP Version:** 2.4 (Latest)
**Ubuntu Version:** 24.04 LTS
**PHP Version:** 8.3
**Python Version:** 3.12

## 0/ MISP Ubuntu 24.04 Server Installation Status

✅ **Tested and working** - Updated for Ubuntu 24.04 LTS
✅ **Maintained by the community**
✅ **Includes latest MISP updates and security patches**

## 1/ Minimal Ubuntu Install

Install a minimal Ubuntu 24.04 server system with:
- OpenSSH server
- Basic system utilities

This guide assumes a user named `misp` with sudo privileges.

### Update Your System

```bash
# Update package lists and upgrade system
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

### Install Essential Tools

```bash
# Install sudo and etckeeper (optional but recommended)
sudo apt install -y etckeeper sudo curl git
```

### Create MISP User

```bash
# Add MISP user to required groups
sudo adduser misp --disabled-password --gecos ""
sudo usermod -aG sudo,staff,www-data misp

# Set password for misp user
sudo passwd misp

# Make /usr/local/src writable
sudo chmod 2775 /usr/local/src
sudo chown root:staff /usr/local/src
```

### Network Configuration (Optional)

If you want to use traditional network interface names (eth0 instead of enp0s3):

```bash
# Edit GRUB configuration
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/' /etc/default/grub
sudo update-grub
```

### Install Postfix

```bash
# Install postfix for email functionality
sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix

# Configure relay host (optional)
sudo postconf -e 'relayhost = your-smtp-server.com'
sudo systemctl reload postfix
```

## 2/ Install Core Dependencies

### Install System Packages

```bash
# Core dependencies
sudo apt install -y \
    curl gcc git gpg-agent make python3 python3-dev python3-pip \
    openssl redis-server sudo vim zip unzip virtualenv \
    libfuzzy-dev sqlite3 moreutils \
    libxml2-dev libxslt1-dev zlib1g-dev python3-setuptools \
    libpq5 libjpeg-dev libfuzzy-dev

# Install MariaDB (MySQL fork)
sudo apt install -y mariadb-client mariadb-server

# Install Apache web server
sudo apt install -y apache2 apache2-doc apache2-utils

# Install build tools for Python packages
sudo apt install -y build-essential libssl-dev libffi-dev

# Install RNG tools for better entropy
sudo apt install -y rng-tools haveged
sudo systemctl enable --now haveged
```

## 3/ Install PHP 8.3 and Extensions

Ubuntu 24.04 comes with PHP 8.3 by default, which is perfect for the latest MISP version.

```bash
# Install PHP 8.3 and required extensions
sudo apt install -y \
    php8.3 \
    php8.3-cli \
    php8.3-dev \
    php8.3-fpm \
    libapache2-mod-php8.3 \
    php8.3-mysql \
    php8.3-xml \
    php8.3-mbstring \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-intl \
    php8.3-gd \
    php8.3-curl \
    php8.3-opcache \
    php8.3-readline

# Install PECL for additional PHP extensions
sudo apt install -y php-pear php8.3-dev

# Install Redis extension
sudo pecl channel-update pecl.php.net
sudo pecl install redis
echo "extension=redis.so" | sudo tee /etc/php/8.3/mods-available/redis.ini
sudo phpenmod redis

# Install GnuPG extension
sudo apt install -y libgpgme-dev
sudo pecl install gnupg
echo "extension=gnupg.so" | sudo tee /etc/php/8.3/mods-available/gnupg.ini
sudo phpenmod gnupg
```

### Configure PHP

```bash
# Edit PHP configuration for Apache
PHP_INI="/etc/php/8.3/apache2/php.ini"

sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 50M/' $PHP_INI
sudo sed -i 's/post_max_size = .*/post_max_size = 50M/' $PHP_INI
sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' $PHP_INI
sudo sed -i 's/memory_limit = .*/memory_limit = 2048M/' $PHP_INI
sudo sed -i 's/;session.sid_length = .*/session.sid_length = 32/' $PHP_INI
sudo sed -i 's/session.use_strict_mode = .*/session.use_strict_mode = 1/' $PHP_INI

# Also configure PHP CLI
PHP_CLI_INI="/etc/php/8.3/cli/php.ini"
sudo sed -i 's/memory_limit = .*/memory_limit = 2048M/' $PHP_CLI_INI
```

## 4/ Download and Install MISP

### Clone MISP Repository

```bash
# Set variables
export PATH_TO_MISP='/var/www/MISP'
export WWW_USER='www-data'

# Create MISP directory
sudo mkdir -p $PATH_TO_MISP
sudo chown $WWW_USER:$WWW_USER $PATH_TO_MISP

# Clone MISP
cd /var/www
sudo -u $WWW_USER git clone https://github.com/MISP/MISP.git
cd $PATH_TO_MISP

# Initialize and update submodules
sudo -u $WWW_USER git submodule update --init --recursive

# Make git ignore file permissions
sudo -u $WWW_USER git config core.filemode false
sudo -u $WWW_USER git submodule foreach --recursive git config core.filemode false
```

### Create Python Virtual Environment

```bash
# Create Python 3.12 virtual environment
sudo -u $WWW_USER python3 -m venv $PATH_TO_MISP/venv

# Create cache directory
sudo mkdir /var/www/.cache
sudo chown $WWW_USER:$WWW_USER /var/www/.cache

# Install Python dependencies
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install --upgrade pip setuptools wheel

# Install MISP Python dependencies
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install \
    ordered-set python-dateutil six weakrefmethod

# Install misp-stix
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install \
    $PATH_TO_MISP/app/files/scripts/misp-stix

# Install PyMISP
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install $PATH_TO_MISP/PyMISP

# Install additional Python libraries
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install \
    lief zmq redis python-magic plyara pydeep
```

### Install faup and gtcaca

```bash
# Install dependencies
sudo apt install -y cmake libcaca-dev liblua5.3-dev

cd /tmp

# Clone repositories
git clone https://github.com/stricaud/gtcaca.git
git clone https://github.com/stricaud/faup.git

# Build and install gtcaca
cd gtcaca
mkdir -p build
cd build
cmake .. && make
sudo make install

# Build and install faup
cd /tmp/faup
mkdir -p build
cd build
cmake .. && make
sudo make install

# Update library cache
sudo ldconfig
```

## 5/ Install CakePHP

```bash
# Create composer cache directory
sudo mkdir -p /var/www/.composer
sudo chown $WWW_USER:$WWW_USER /var/www/.composer

# Install Composer dependencies
cd $PATH_TO_MISP/app
sudo -u $WWW_USER php composer.phar install --no-dev

# Enable PHP extensions
sudo phpenmod redis
sudo phpenmod gnupg

# Copy CakeResque config
sudo -u $WWW_USER cp -a $PATH_TO_MISP/INSTALL/setup/config.php \
    $PATH_TO_MISP/app/Plugin/CakeResque/Config/config.php
```

## 6/ Set File Permissions

```bash
# Set ownership
sudo chown -R $WWW_USER:$WWW_USER $PATH_TO_MISP

# Set directory permissions
sudo chmod -R 750 $PATH_TO_MISP
sudo chmod -R g+ws $PATH_TO_MISP/app/tmp
sudo chmod -R g+ws $PATH_TO_MISP/app/files
sudo chmod -R g+ws $PATH_TO_MISP/app/files/scripts/tmp
```

## 7/ Create Database and User

```bash
# Secure MariaDB installation
sudo mysql_secure_installation

# Create database and user
sudo mysql -u root -p << EOF
CREATE DATABASE misp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'misp'@'localhost' IDENTIFIED BY 'YOUR_STRONG_PASSWORD_HERE';
GRANT USAGE ON *.* TO 'misp'@'localhost';
GRANT ALL PRIVILEGES ON misp.* TO 'misp'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import MISP database schema
sudo -u $WWW_USER cat $PATH_TO_MISP/INSTALL/MYSQL.sql | \
    mysql -u misp -p misp
```

## 8/ Apache Configuration

### Generate SSL Certificate

```bash
# Create self-signed SSL certificate (use Let's Encrypt for production!)
sudo openssl req -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=LU/ST=State/L=Location/O=Organization/OU=Unit/CN=misp.local/emailAddress=admin@misp.local" \
    -keyout /etc/ssl/private/misp.local.key \
    -out /etc/ssl/private/misp.local.crt

# Set proper permissions
sudo chmod 600 /etc/ssl/private/misp.local.key
```

### Configure Apache

```bash
# Copy MISP Apache configuration
sudo cp $PATH_TO_MISP/INSTALL/apache.24.misp.ssl /etc/apache2/sites-available/misp-ssl.conf

# Update ServerName if needed
sudo sed -i 's/ServerName misp.local/ServerName your-domain.com/' /etc/apache2/sites-available/misp-ssl.conf

# Enable Apache modules
sudo a2dismod status
sudo a2enmod ssl rewrite headers
sudo a2dissite 000-default default-ssl
sudo a2ensite misp-ssl

# Restart Apache
sudo systemctl restart apache2
```

## 9/ Configure MISP

### Copy Configuration Files

```bash
cd $PATH_TO_MISP/app/Config

# Copy configuration files
sudo -u $WWW_USER cp -a bootstrap.default.php bootstrap.php
sudo -u $WWW_USER cp -a database.default.php database.php
sudo -u $WWW_USER cp -a core.default.php core.php
sudo -u $WWW_USER cp -a config.default.php config.php
```

### Configure Database Connection

```bash
# Edit database.php with your credentials
sudo -u $WWW_USER nano $PATH_TO_MISP/app/Config/database.php
```

Update the database configuration:
```php
public $default = array(
    'datasource' => 'Database/Mysql',
    'persistent' => false,
    'host' => 'localhost',
    'login' => 'misp',
    'port' => 3306,
    'password' => 'YOUR_STRONG_PASSWORD_HERE',
    'database' => 'misp',
    'prefix' => '',
    'encoding' => 'utf8mb4',
);
```

### Generate GnuPG Key

```bash
# Create GPG directory
sudo -u $WWW_USER mkdir $PATH_TO_MISP/.gnupg
sudo chmod 700 $PATH_TO_MISP/.gnupg

# Generate GPG key
sudo -u $WWW_USER gpg --homedir $PATH_TO_MISP/.gnupg --batch --gen-key << EOF
%echo Generating MISP GPG key
Key-Type: RSA
Key-Length: 3072
Subkey-Type: RSA
Subkey-Length: 3072
Name-Real: MISP Admin
Name-Email: admin@misp.local
Expire-Date: 0
Passphrase: YOUR_GPG_PASSPHRASE
%commit
%echo Done
EOF

# Export public key
sudo -u $WWW_USER gpg --homedir $PATH_TO_MISP/.gnupg \
    --export --armor admin@misp.local > $PATH_TO_MISP/app/webroot/gpg.asc
```

## 10/ Configure Background Workers

```bash
# Make worker script executable
sudo chmod +x $PATH_TO_MISP/app/Console/worker/start.sh

# Create systemd service
sudo cp $PATH_TO_MISP/INSTALL/misp-workers.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now misp-workers
```

## 11/ Log Rotation

```bash
# Install log rotation
sudo cp $PATH_TO_MISP/INSTALL/misp.logrotate /etc/logrotate.d/misp
sudo chmod 0640 /etc/logrotate.d/misp
```

## 12/ Initialize MISP

```bash
# Set CAKE variable
CAKE="$PATH_TO_MISP/app/Console/cake"

# Initialize user
sudo -u $WWW_USER $CAKE userInit -q

# Run database updates
sudo -u $WWW_USER $CAKE Admin runUpdates

# Configure MISP settings
sudo -u $WWW_USER $CAKE Admin setSetting "MISP.python_bin" "$PATH_TO_MISP/venv/bin/python"
sudo -u $WWW_USER $CAKE Admin setSetting "MISP.baseurl" "https://your-misp-domain.com"
sudo -u $WWW_USER $CAKE Admin setSetting "MISP.external_baseurl" "https://your-misp-domain.com"

# Configure GnuPG
sudo -u $WWW_USER $CAKE Admin setSetting "GnuPG.email" "admin@misp.local"
sudo -u $WWW_USER $CAKE Admin setSetting "GnuPG.homedir" "$PATH_TO_MISP/.gnupg"
sudo -u $WWW_USER $CAKE Admin setSetting "GnuPG.password" "YOUR_GPG_PASSPHRASE"

# Update taxonomies, galaxies, etc.
sudo -u $WWW_USER $CAKE Admin updateGalaxies
sudo -u $WWW_USER $CAKE Admin updateTaxonomies
sudo -u $WWW_USER $CAKE Admin updateWarningLists
sudo -u $WWW_USER $CAKE Admin updateNoticeLists
sudo -u $WWW_USER $CAKE Admin updateObjectTemplates
```

## 13/ Install MISP Modules (Optional but Recommended)

```bash
# Install system dependencies
sudo apt install -y \
    libpq5 libjpeg-dev tesseract-ocr libpoppler-cpp-dev \
    imagemagick libopencv-dev zbar-tools libzbar0 libzbar-dev

# Clone misp-modules
cd /usr/local/src
sudo git clone https://github.com/MISP/misp-modules.git
sudo chown -R $WWW_USER:$WWW_USER misp-modules

# Install Python dependencies
cd misp-modules
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install -I -r REQUIREMENTS
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install .

# Create systemd service
sudo cp /usr/local/src/misp-modules/etc/systemd/system/misp-modules.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now misp-modules

# Configure MISP to use modules
sudo -u $WWW_USER $CAKE Admin setSetting "Plugin.Enrichment_services_enable" true
sudo -u $WWW_USER $CAKE Admin setSetting "Plugin.Enrichment_services_url" "http://127.0.0.1"
sudo -u $WWW_USER $CAKE Admin setSetting "Plugin.Enrichment_services_port" 6666
```

## 14/ First Login

1. Navigate to: `https://your-misp-domain.com`
2. Login with default credentials:
   - **Username:** admin@admin.test
   - **Password:** admin
3. **⚠️ IMMEDIATELY change the password!**
4. Configure your organization details
5. Review and fix any diagnostic issues in Administration → Server Settings & Maintenance → Diagnostics

## 15/ Security Hardening

### Firewall Configuration

```bash
# Install and configure UFW
sudo apt install -y ufw

# Allow SSH, HTTP, HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw --force enable
```

### Additional Security Steps

1. Install Let's Encrypt SSL certificates
2. Configure fail2ban for brute force protection
3. Disable directory listing in Apache
4. Set secure session cookie flags
5. Enable security headers in Apache
6. Regular security updates

```bash
# Install certbot for Let's Encrypt
sudo apt install -y certbot python3-certbot-apache

# Get SSL certificate
sudo certbot --apache -d your-misp-domain.com
```

## 16/ Troubleshooting

### Check Service Status

```bash
sudo systemctl status apache2
sudo systemctl status mariadb
sudo systemctl status redis-server
sudo systemctl status misp-workers
sudo systemctl status misp-modules
```

### Check Logs

```bash
# Apache logs
sudo tail -f /var/log/apache2/misp.local_error.log

# MISP logs
sudo -u $WWW_USER tail -f $PATH_TO_MISP/app/tmp/logs/error.log
sudo -u $WWW_USER tail -f $PATH_TO_MISP/app/tmp/logs/resque-worker-error.log
```

### Common Issues

**Workers not running:**
```bash
sudo systemctl restart misp-workers
sudo systemctl status misp-workers
```

**Permission errors:**
```bash
sudo chown -R www-data:www-data /var/www/MISP
sudo chmod -R 750 /var/www/MISP
sudo chmod -R g+ws /var/www/MISP/app/tmp
sudo chmod -R g+ws /var/www/MISP/app/files
```

## 17/ Maintenance

### Update MISP

```bash
cd $PATH_TO_MISP
sudo -u $WWW_USER git pull origin 2.4
sudo -u $WWW_USER git submodule update --init --recursive

# Update dependencies
cd $PATH_TO_MISP/app
sudo -u $WWW_USER php composer.phar update

# Update Python packages
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install --upgrade pip
sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install --upgrade -r $PATH_TO_MISP/INSTALL/REQUIREMENTS.txt

# Restart services
sudo systemctl restart apache2
sudo systemctl restart misp-workers
```

### Database Backup

```bash
# Backup MISP database
mysqldump -u misp -p misp > misp_backup_$(date +%Y%m%d).sql

# Backup MISP files
sudo tar -czf misp_files_backup_$(date +%Y%m%d).tar.gz /var/www/MISP
```

---

**Installation Complete!**

Your MISP instance is now ready to use on Ubuntu 24.04 LTS with PHP 8.3 and the latest updates.

For support, visit:
- https://www.misp-project.org
- https://github.com/MISP/MISP/issues
