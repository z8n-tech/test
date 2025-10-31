#!/bin/bash
# Install PHP 8.3 and required extensions for MISP on Ubuntu 24.04
# Author: MISP Community
# Date: 2025-10-31

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing PHP 8.3 and extensions for MISP...${NC}"

# Update package lists
echo -e "${YELLOW}Updating package lists...${NC}"
sudo apt update

# Install PHP 8.3 and core extensions
echo -e "${YELLOW}Installing PHP 8.3 core packages...${NC}"
sudo apt install -y \
    php8.3 \
    php8.3-cli \
    php8.3-dev \
    php8.3-fpm \
    libapache2-mod-php8.3 \
    php-pear

# Install PHP extensions required by MISP
echo -e "${YELLOW}Installing PHP 8.3 extensions...${NC}"
sudo apt install -y \
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

# Install PECL for additional extensions
echo -e "${YELLOW}Installing PECL extensions...${NC}"

# Update PECL channel
sudo pecl channel-update pecl.php.net

# Install Redis extension
echo -e "${YELLOW}Installing Redis extension...${NC}"
if ! php -m | grep -q redis; then
    printf "\n" | sudo pecl install redis
    echo "extension=redis.so" | sudo tee /etc/php/8.3/mods-available/redis.ini
    sudo phpenmod redis
else
    echo -e "${GREEN}Redis extension already installed${NC}"
fi

# Install GnuPG extension
echo -e "${YELLOW}Installing GnuPG extension...${NC}"
if ! php -m | grep -q gnupg; then
    sudo apt install -y libgpgme-dev
    printf "\n" | sudo pecl install gnupg
    echo "extension=gnupg.so" | sudo tee /etc/php/8.3/mods-available/gnupg.ini
    sudo phpenmod gnupg
else
    echo -e "${GREEN}GnuPG extension already installed${NC}"
fi

# Configure PHP
echo -e "${YELLOW}Configuring PHP...${NC}"
PHP_INI="/etc/php/8.3/apache2/php.ini"

if [ -f "$PHP_INI" ]; then
    sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 50M/' "$PHP_INI"
    sudo sed -i 's/post_max_size = .*/post_max_size = 50M/' "$PHP_INI"
    sudo sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
    sudo sed -i 's/memory_limit = .*/memory_limit = 2048M/' "$PHP_INI"
    sudo sed -i 's/;date.timezone =.*/date.timezone = UTC/' "$PHP_INI"
    sudo sed -i 's/expose_php = .*/expose_php = Off/' "$PHP_INI"

    echo -e "${GREEN}PHP configuration updated${NC}"
fi

# Verify PHP installation
echo -e "${YELLOW}Verifying PHP installation...${NC}"
php -v

echo -e "${YELLOW}Installed PHP modules:${NC}"
php -m | grep -E "redis|gnupg|mysql|gd|intl|bcmath|mbstring|xml|zip"

# Restart Apache if it's running
if systemctl is-active --quiet apache2; then
    echo -e "${YELLOW}Restarting Apache...${NC}"
    sudo systemctl restart apache2
fi

echo -e "${GREEN}PHP 8.3 installation complete!${NC}"
echo -e "${YELLOW}Important extensions installed:${NC}"
echo "  - redis"
echo "  - gnupg"
echo "  - mysql"
echo "  - gd"
echo "  - intl"
echo "  - bcmath"
echo "  - mbstring"
echo "  - xml"
echo "  - zip"

echo -e "${GREEN}Done!${NC}"
