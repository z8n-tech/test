#!/bin/bash
# Install core system dependencies for MISP on Ubuntu 24.04
# Author: MISP Community
# Date: 2025-10-31

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  MISP Core Dependencies Installation${NC}"
echo -e "${BLUE}  Ubuntu 24.04 LTS${NC}"
echo -e "${BLUE}=============================================${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root${NC}"
    echo "Run it as a regular user with sudo privileges"
    exit 1
fi

# Update system
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

# Install basic tools
echo -e "${YELLOW}[2/8] Installing basic tools...${NC}"
sudo apt install -y \
    curl \
    git \
    sudo \
    vim \
    wget \
    gnupg-agent \
    make \
    gcc \
    g++ \
    unzip \
    zip \
    etckeeper

# Install Python and development tools
echo -e "${YELLOW}[3/8] Installing Python 3.12 and development tools...${NC}"
sudo apt install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-virtualenv

# Install database (MariaDB)
echo -e "${YELLOW}[4/8] Installing MariaDB...${NC}"
sudo apt install -y \
    mariadb-client \
    mariadb-server

# Enable and start MariaDB
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Install web server (Apache)
echo -e "${YELLOW}[5/8] Installing Apache web server...${NC}"
sudo apt install -y \
    apache2 \
    apache2-doc \
    apache2-utils

# Enable and start Apache
sudo systemctl enable apache2
sudo systemctl start apache2

# Install Redis
echo -e "${YELLOW}[6/8] Installing Redis...${NC}"
sudo apt install -y redis-server

# Configure Redis
sudo sed -i 's/^# maxmemory .*/maxmemory 256mb/' /etc/redis/redis.conf
sudo sed -i 's/^# maxmemory-policy .*/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf

# Enable and start Redis
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Install required libraries
echo -e "${YELLOW}[7/8] Installing required libraries...${NC}"
sudo apt install -y \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    libpq5 \
    libjpeg-dev \
    libfuzzy-dev \
    libgpgme-dev \
    libcaca-dev \
    liblua5.3-dev \
    sqlite3 \
    moreutils

# Install entropy tools
echo -e "${YELLOW}[8/8] Installing entropy tools...${NC}"
sudo apt install -y \
    rng-tools \
    haveged

# Enable and start haveged
sudo systemctl enable haveged
sudo systemctl start haveged

# Install mail server
echo -e "${YELLOW}Installing Postfix (mail server)...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix

# Verify installations
echo -e "${BLUE}Verifying installations...${NC}"

echo -e "${YELLOW}Python version:${NC}"
python3 --version

echo -e "${YELLOW}MariaDB status:${NC}"
sudo systemctl status mariadb --no-pager | grep "Active:"

echo -e "${YELLOW}Apache status:${NC}"
sudo systemctl status apache2 --no-pager | grep "Active:"

echo -e "${YELLOW}Redis status:${NC}"
sudo systemctl status redis-server --no-pager | grep "Active:"

echo -e "${YELLOW}Redis connectivity:${NC}"
redis-cli ping

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}Core dependencies installation complete!${NC}"
echo -e "${GREEN}=============================================${NC}"

echo -e "${YELLOW}Installed services:${NC}"
echo "  ✓ Python 3.12"
echo "  ✓ MariaDB (MySQL)"
echo "  ✓ Apache 2.4"
echo "  ✓ Redis"
echo "  ✓ Postfix"
echo "  ✓ Development tools"

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: ${GREEN}sudo mysql_secure_installation${NC}"
echo "  2. Install PHP 8.3: ${GREEN}./install-php83-deps.sh${NC}"
echo "  3. Continue with MISP installation"

echo -e "${GREEN}Done!${NC}"
