#!/bin/bash
# Configure MISP settings via command line
# Author: MISP Community
# Date: 2025-10-31

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PATH_TO_MISP=${PATH_TO_MISP:-/var/www/MISP}
CAKE="$PATH_TO_MISP/app/Console/cake"
WWW_USER="www-data"
SUDO_WWW="sudo -u $WWW_USER"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  MISP Configuration Script${NC}"
echo -e "${BLUE}  Ubuntu 24.04 LTS${NC}"
echo -e "${BLUE}=============================================${NC}"

# Check if MISP is installed
if [ ! -d "$PATH_TO_MISP" ]; then
    echo -e "${RED}Error: MISP not found at $PATH_TO_MISP${NC}"
    exit 1
fi

if [ ! -f "$CAKE" ]; then
    echo -e "${RED}Error: Cake console not found at $CAKE${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuring MISP...${NC}"

# Initialize MISP user
echo -e "${YELLOW}[1/10] Initializing MISP admin user...${NC}"
$SUDO_WWW $CAKE userInit -q

# Run database updates
echo -e "${YELLOW}[2/10] Running database updates...${NC}"
$SUDO_WWW $CAKE Admin runUpdates

# Set Python binary path
echo -e "${YELLOW}[3/10] Setting Python binary path...${NC}"
$SUDO_WWW $CAKE Admin setSetting "MISP.python_bin" "$PATH_TO_MISP/venv/bin/python"

# Set base URL (prompt user)
echo -e "${YELLOW}[4/10] Setting base URL...${NC}"
read -p "Enter your MISP base URL (e.g., https://misp.example.com): " BASE_URL
if [ -n "$BASE_URL" ]; then
    $SUDO_WWW $CAKE Admin setSetting "MISP.baseurl" "$BASE_URL"
    $SUDO_WWW $CAKE Admin setSetting "MISP.external_baseurl" "$BASE_URL"
else
    echo -e "${YELLOW}Skipping base URL configuration${NC}"
fi

# Set temporary directory
echo -e "${YELLOW}[5/10] Setting temporary directory...${NC}"
$SUDO_WWW $CAKE Admin setSetting "MISP.tmpdir" "$PATH_TO_MISP/app/tmp"

# Configure GnuPG
echo -e "${YELLOW}[6/10] Configuring GnuPG...${NC}"
$SUDO_WWW $CAKE Admin setSetting "GnuPG.email" "admin@misp.local"
$SUDO_WWW $CAKE Admin setSetting "GnuPG.homedir" "$PATH_TO_MISP/.gnupg"
$SUDO_WWW $CAKE Admin setSetting "GnuPG.binary" "$(which gpg)"

# Configure session
echo -e "${YELLOW}[7/10] Configuring session settings...${NC}"
$SUDO_WWW $CAKE Admin setSetting "Session.autoRegenerate" 0
$SUDO_WWW $CAKE Admin setSetting "Session.timeout" 600
$SUDO_WWW $CAKE Admin setSetting "Session.cookieTimeout" 3600

# Configure Redis
echo -e "${YELLOW}[8/10] Configuring Redis...${NC}"
$SUDO_WWW $CAKE Admin setSetting "MISP.redis_host" "127.0.0.1"
$SUDO_WWW $CAKE Admin setSetting "MISP.redis_port" 6379
$SUDO_WWW $CAKE Admin setSetting "MISP.redis_database" 13
$SUDO_WWW $CAKE Admin setSetting "MISP.redis_password" ""

# Security settings
echo -e "${YELLOW}[9/10] Configuring security settings...${NC}"
$SUDO_WWW $CAKE Admin setSetting "Security.disable_browser_cache" true
$SUDO_WWW $CAKE Admin setSetting "Security.check_sec_fetch_site_header" true
$SUDO_WWW $CAKE Admin setSetting "Security.csp_enforce" true
$SUDO_WWW $CAKE Admin setSetting "Security.advanced_authkeys" true
$SUDO_WWW $CAKE Admin setSetting "Security.do_not_log_authkeys" true
$SUDO_WWW $CAKE Admin setSetting "Security.password_policy_length" 12
$SUDO_WWW $CAKE Admin setSetting "Security.password_policy_complexity" '/^((?=.*\d)|(?=.*\W+))(?![\n])(?=.*[A-Z])(?=.*[a-z]).*$|.{16,}/'

# Update taxonomies, galaxies, etc.
echo -e "${YELLOW}[10/10] Updating MISP data (taxonomies, galaxies, etc.)...${NC}"
$SUDO_WWW $CAKE Admin updateGalaxies
$SUDO_WWW $CAKE Admin updateTaxonomies
$SUDO_WWW $CAKE Admin updateWarningLists
$SUDO_WWW $CAKE Admin updateNoticeLists
$SUDO_WWW $CAKE Admin updateObjectTemplates

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}MISP configuration complete!${NC}"
echo -e "${GREEN}=============================================${NC}"

echo -e "${YELLOW}Important notes:${NC}"
echo "  1. Default login: ${GREEN}admin@admin.test${NC} / ${GREEN}admin${NC}"
echo "  2. ${RED}CHANGE THE PASSWORD IMMEDIATELY${NC}"
echo "  3. Review diagnostics at: ${BLUE}https://your-misp/servers/serverSettings/diagnostics${NC}"
echo "  4. Configure email settings in the admin panel"
echo "  5. Set up external authentication if needed"

echo -e "${YELLOW}To get your admin API key:${NC}"
echo "  ${GREEN}sudo mysql -u root -p misp -e \"SELECT authkey FROM users WHERE role_id=1 LIMIT 1;\"${NC}"

echo -e "${GREEN}Done!${NC}"
