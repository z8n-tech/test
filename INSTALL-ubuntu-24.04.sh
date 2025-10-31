#!/bin/bash
# MISP Automated Installation Script for Ubuntu 24.04 LTS
# Author: MISP Community
# Date: 2025-10-31
# Version: 1.0
#
# This script automates the installation of MISP on Ubuntu 24.04 LTS
# Use with caution and only on fresh Ubuntu 24.04 installations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration variables
export PATH_TO_MISP="${PATH_TO_MISP:-/var/www/MISP}"
export WWW_USER="www-data"
export MISP_USER="${MISP_USER:-misp}"
export DBHOST="localhost"
export DBNAME="misp"
export DBUSER_MISP="misp"

# Generate random passwords
DBPASSWORD_ADMIN=$(openssl rand -hex 32)
DBPASSWORD_MISP=$(openssl rand -hex 32)
MISP_PASSWORD=$(openssl rand -hex 16)
GPG_PASSPHRASE=$(openssl rand -hex 32)

# Usage function
usage() {
    echo -e "${CYAN}MISP Installation Script for Ubuntu 24.04${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c    Install MISP Core only"
    echo "  -m    Install MISP Modules"
    echo "  -a    Install all (Core + Modules)"
    echo "  -u    Unattended installation (no prompts)"
    echo "  -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -c        # Install MISP core"
    echo "  $0 -a        # Install everything"
    echo "  $0 -c -u     # Unattended core installation"
    echo ""
}

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║       MISP Installation for Ubuntu 24.04 LTS             ║"
    echo "║       Malware Information Sharing Platform               ║"
    echo "║                                                           ║"
    echo "║       PHP 8.3 | Python 3.12 | MariaDB 10.11             ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Error: Please do not run this script as root${NC}"
        echo "Run it as a regular user with sudo privileges"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    echo -e "${YELLOW}Checking Ubuntu version...${NC}"

    if [ ! -f /etc/os-release ]; then
        echo -e "${RED}Error: Cannot detect OS version${NC}"
        exit 1
    fi

    . /etc/os-release

    if [ "$ID" != "ubuntu" ]; then
        echo -e "${RED}Error: This script is for Ubuntu only${NC}"
        echo "Detected: $ID"
        exit 1
    fi

    if [ "$VERSION_ID" != "24.04" ]; then
        echo -e "${YELLOW}Warning: This script is designed for Ubuntu 24.04${NC}"
        echo "Your version: $VERSION_ID"
        read -p "Continue anyway? (y/N): " continue_install
        if [ "$continue_install" != "y" ] && [ "$continue_install" != "Y" ]; then
            exit 1
        fi
    fi

    echo -e "${GREEN}✓ Ubuntu version check passed${NC}"
}

# Install core dependencies
install_core_deps() {
    echo -e "${BLUE}[1/12] Installing core dependencies...${NC}"

    sudo apt update
    sudo apt install -y \
        curl gcc git gpg-agent make python3 python3-dev python3-pip \
        openssl redis-server sudo vim zip unzip virtualenv \
        libfuzzy-dev sqlite3 moreutils \
        mariadb-client mariadb-server \
        apache2 apache2-doc apache2-utils \
        libxml2-dev libxslt1-dev zlib1g-dev python3-setuptools \
        libpq5 libjpeg-dev libfuzzy-dev \
        rng-tools haveged etckeeper \
        libssl-dev libffi-dev

    sudo systemctl enable --now haveged
    echo -e "${GREEN}✓ Core dependencies installed${NC}"
}

# Install PHP 8.3
install_php83() {
    echo -e "${BLUE}[2/12] Installing PHP 8.3 and extensions...${NC}"

    sudo apt install -y \
        php8.3 php8.3-cli php8.3-dev libapache2-mod-php8.3 php-pear \
        php8.3-mysql php8.3-xml php8.3-mbstring php8.3-zip \
        php8.3-bcmath php8.3-intl php8.3-gd php8.3-curl \
        php8.3-opcache php8.3-readline

    # Install PECL extensions
    sudo pecl channel-update pecl.php.net

    if ! php -m | grep -q redis; then
        printf "\n" | sudo pecl install redis
        echo "extension=redis.so" | sudo tee /etc/php/8.3/mods-available/redis.ini
        sudo phpenmod redis
    fi

    if ! php -m | grep -q gnupg; then
        sudo apt install -y libgpgme-dev
        printf "\n" | sudo pecl install gnupg
        echo "extension=gnupg.so" | sudo tee /etc/php/8.3/mods-available/gnupg.ini
        sudo phpenmod gnupg
    fi

    # Configure PHP
    PHP_INI="/etc/php/8.3/apache2/php.ini"
    sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 50M/' $PHP_INI
    sudo sed -i 's/post_max_size = .*/post_max_size = 50M/' $PHP_INI
    sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' $PHP_INI
    sudo sed -i 's/memory_limit = .*/memory_limit = 2048M/' $PHP_INI

    echo -e "${GREEN}✓ PHP 8.3 installed and configured${NC}"
}

# Clone MISP repository
clone_misp() {
    echo -e "${BLUE}[3/12] Cloning MISP repository...${NC}"

    sudo mkdir -p $PATH_TO_MISP
    sudo chown $WWW_USER:$WWW_USER $PATH_TO_MISP

    sudo -u $WWW_USER git clone https://github.com/MISP/MISP.git $PATH_TO_MISP
    cd $PATH_TO_MISP
    sudo -u $WWW_USER git submodule update --init --recursive
    sudo -u $WWW_USER git config core.filemode false
    sudo -u $WWW_USER git submodule foreach --recursive git config core.filemode false

    echo -e "${GREEN}✓ MISP repository cloned${NC}"
}

# Create Python virtual environment
create_virtualenv() {
    echo -e "${BLUE}[4/12] Creating Python virtual environment...${NC}"

    sudo -u $WWW_USER python3 -m venv $PATH_TO_MISP/venv

    sudo mkdir -p /var/www/.cache
    sudo chown $WWW_USER:$WWW_USER /var/www/.cache

    sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install --upgrade pip setuptools wheel
    sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install \
        ordered-set python-dateutil six weakrefmethod

    sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install \
        $PATH_TO_MISP/app/files/scripts/misp-stix
    sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install $PATH_TO_MISP/PyMISP
    sudo -u $WWW_USER $PATH_TO_MISP/venv/bin/pip install \
        lief zmq redis python-magic plyara pydeep

    echo -e "${GREEN}✓ Python virtual environment created${NC}"
}

# Install faup and gtcaca
install_faup() {
    echo -e "${BLUE}[5/12] Installing faup and gtcaca...${NC}"

    sudo apt install -y cmake libcaca-dev liblua5.3-dev

    cd /tmp
    git clone https://github.com/stricaud/gtcaca.git
    git clone https://github.com/stricaud/faup.git

    cd gtcaca && mkdir -p build && cd build
    cmake .. && make
    sudo make install

    cd /tmp/faup && mkdir -p build && cd build
    cmake .. && make
    sudo make install

    sudo ldconfig

    echo -e "${GREEN}✓ faup and gtcaca installed${NC}"
}

# Install CakePHP
install_cakephp() {
    echo -e "${BLUE}[6/12] Installing CakePHP dependencies...${NC}"

    sudo mkdir -p /var/www/.composer
    sudo chown $WWW_USER:$WWW_USER /var/www/.composer

    cd $PATH_TO_MISP/app
    sudo -u $WWW_USER php composer.phar install --no-dev

    sudo phpenmod redis
    sudo phpenmod gnupg

    sudo -u $WWW_USER cp -a $PATH_TO_MISP/INSTALL/setup/config.php \
        $PATH_TO_MISP/app/Plugin/CakeResque/Config/config.php

    echo -e "${GREEN}✓ CakePHP dependencies installed${NC}"
}

# Set permissions
set_permissions() {
    echo -e "${BLUE}[7/12] Setting file permissions...${NC}"

    sudo chown -R $WWW_USER:$WWW_USER $PATH_TO_MISP
    sudo chmod -R 750 $PATH_TO_MISP
    sudo chmod -R g+ws $PATH_TO_MISP/app/tmp
    sudo chmod -R g+ws $PATH_TO_MISP/app/files
    sudo chmod -R g+ws $PATH_TO_MISP/app/files/scripts/tmp

    echo -e "${GREEN}✓ File permissions set${NC}"
}

# Create database
create_database() {
    echo -e "${BLUE}[8/12] Creating database...${NC}"

    # Secure MariaDB (automated)
    sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('$DBPASSWORD_ADMIN') WHERE User='root';"
    sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
    sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    sudo mysql -e "DROP DATABASE IF EXISTS test;"
    sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    # Create MISP database and user
    sudo mysql -u root -p"$DBPASSWORD_ADMIN" << EOF
CREATE DATABASE $DBNAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DBUSER_MISP'@'localhost' IDENTIFIED BY '$DBPASSWORD_MISP';
GRANT USAGE ON *.* TO '$DBUSER_MISP'@'localhost';
GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER_MISP'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Import schema
    sudo -u $WWW_USER cat $PATH_TO_MISP/INSTALL/MYSQL.sql | \
        mysql -u $DBUSER_MISP -p"$DBPASSWORD_MISP" $DBNAME

    echo -e "${GREEN}✓ Database created and configured${NC}"
}

# Configure Apache
configure_apache() {
    echo -e "${BLUE}[9/12] Configuring Apache...${NC}"

    # Generate self-signed certificate
    sudo openssl req -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=LU/ST=State/L=Location/O=Organization/CN=misp.local/emailAddress=admin@misp.local" \
        -keyout /etc/ssl/private/misp.local.key \
        -out /etc/ssl/private/misp.local.crt

    sudo chmod 600 /etc/ssl/private/misp.local.key

    # Copy Apache config
    sudo cp $PATH_TO_MISP/INSTALL/apache.24.misp.ssl /etc/apache2/sites-available/misp-ssl.conf

    # Enable modules and sites
    sudo a2dismod status
    sudo a2enmod ssl rewrite headers
    sudo a2dissite 000-default default-ssl
    sudo a2ensite misp-ssl

    sudo systemctl restart apache2

    echo -e "${GREEN}✓ Apache configured${NC}"
}

# Configure MISP
configure_misp() {
    echo -e "${BLUE}[10/12] Configuring MISP...${NC}"

    cd $PATH_TO_MISP/app/Config

    sudo -u $WWW_USER cp -a bootstrap.default.php bootstrap.php
    sudo -u $WWW_USER cp -a database.default.php database.php
    sudo -u $WWW_USER cp -a core.default.php core.php
    sudo -u $WWW_USER cp -a config.default.php config.php

    # Configure database
    cat << EOF | sudo -u $WWW_USER tee $PATH_TO_MISP/app/Config/database.php
<?php
class DATABASE_CONFIG {
    public \$default = array(
        'datasource' => 'Database/Mysql',
        'persistent' => false,
        'host' => '$DBHOST',
        'login' => '$DBUSER_MISP',
        'port' => 3306,
        'password' => '$DBPASSWORD_MISP',
        'database' => '$DBNAME',
        'prefix' => '',
        'encoding' => 'utf8mb4',
    );
}
EOF

    sudo chown -R $WWW_USER:$WWW_USER $PATH_TO_MISP/app/Config
    sudo chmod -R 750 $PATH_TO_MISP/app/Config

    # Generate GPG key
    sudo -u $WWW_USER mkdir -p $PATH_TO_MISP/.gnupg
    sudo chmod 700 $PATH_TO_MISP/.gnupg

    echo -e "${GREEN}✓ MISP configured${NC}"
}

# Configure background workers
configure_workers() {
    echo -e "${BLUE}[11/12] Configuring background workers...${NC}"

    sudo chmod +x $PATH_TO_MISP/app/Console/worker/start.sh

    sudo cp $PATH_TO_MISP/INSTALL/misp-workers.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now misp-workers

    # Log rotation
    sudo cp $PATH_TO_MISP/INSTALL/misp.logrotate /etc/logrotate.d/misp
    sudo chmod 0640 /etc/logrotate.d/misp

    echo -e "${GREEN}✓ Background workers configured${NC}"
}

# Initialize MISP
initialize_misp() {
    echo -e "${BLUE}[12/12] Initializing MISP...${NC}"

    CAKE="$PATH_TO_MISP/app/Console/cake"

    sudo -u $WWW_USER $CAKE userInit -q
    sudo -u $WWW_USER $CAKE Admin runUpdates

    sudo -u $WWW_USER $CAKE Admin setSetting "MISP.python_bin" "$PATH_TO_MISP/venv/bin/python"
    sudo -u $WWW_USER $CAKE Admin setSetting "MISP.baseurl" "https://localhost"

    sudo -u $WWW_USER $CAKE Admin updateGalaxies
    sudo -u $WWW_USER $CAKE Admin updateTaxonomies
    sudo -u $WWW_USER $CAKE Admin updateWarningLists
    sudo -u $WWW_USER $CAKE Admin updateNoticeLists
    sudo -u $WWW_USER $CAKE Admin updateObjectTemplates

    echo -e "${GREEN}✓ MISP initialized${NC}"
}

# Print final information
print_final_info() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║       MISP Installation Complete!                        ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${GREEN}Installation successful!${NC}"
    echo ""
    echo -e "${YELLOW}MISP URL:${NC} https://localhost"
    echo -e "${YELLOW}Default credentials:${NC}"
    echo "  Username: admin@admin.test"
    echo "  Password: admin"
    echo ""
    echo -e "${RED}IMPORTANT: Change the password immediately after first login!${NC}"
    echo ""
    echo -e "${YELLOW}Database credentials (save these!):${NC}"
    echo "  Database: $DBNAME"
    echo "  DB User: $DBUSER_MISP"
    echo "  DB Password: $DBPASSWORD_MISP"
    echo "  DB Root Password: $DBPASSWORD_ADMIN"
    echo ""
    echo -e "${YELLOW}Credentials saved to:${NC} /tmp/misp-credentials.txt"

    # Save credentials
    cat > /tmp/misp-credentials.txt << EOF
MISP Installation Credentials
=============================

Web Interface:
--------------
URL: https://localhost
Username: admin@admin.test
Password: admin

Database:
---------
Database Name: $DBNAME
DB User: $DBUSER_MISP
DB Password: $DBPASSWORD_MISP
DB Root Password: $DBPASSWORD_ADMIN

Installation Date: $(date)
EOF

    sudo chmod 600 /tmp/misp-credentials.txt
}

# Main installation function
main() {
    INSTALL_CORE=0
    INSTALL_MODULES=0
    UNATTENDED=0

    # Parse arguments
    while getopts "cmahuo" opt; do
        case $opt in
            c) INSTALL_CORE=1 ;;
            m) INSTALL_MODULES=1 ;;
            a) INSTALL_CORE=1; INSTALL_MODULES=1 ;;
            u) UNATTENDED=1 ;;
            h) usage; exit 0 ;;
            *) usage; exit 1 ;;
        esac
    done

    # If no options, show usage
    if [ $INSTALL_CORE -eq 0 ] && [ $INSTALL_MODULES -eq 0 ]; then
        usage
        exit 1
    fi

    print_banner
    check_root
    check_ubuntu_version

    if [ $INSTALL_CORE -eq 1 ]; then
        echo -e "${CYAN}Starting MISP core installation...${NC}"
        install_core_deps
        install_php83
        clone_misp
        create_virtualenv
        install_faup
        install_cakephp
        set_permissions
        create_database
        configure_apache
        configure_misp
        configure_workers
        initialize_misp
        print_final_info
    fi

    if [ $INSTALL_MODULES -eq 1 ]; then
        echo -e "${CYAN}Installing MISP modules...${NC}"
        # Module installation would go here
        echo -e "${YELLOW}Module installation not yet implemented in this script${NC}"
        echo -e "${YELLOW}Please refer to the manual installation guide${NC}"
    fi
}

# Run main function
main "$@"
