# MISP Installation Guide for Ubuntu 24.04 LTS

This project contains updated installation instructions and scripts for installing MISP (Malware Information Sharing Platform) on **Ubuntu 24.04 LTS (Noble Numbat)**.

## 🆕 What's New in Ubuntu 24.04 Version

### Major Updates from Ubuntu 22.04:
- **PHP 8.3** (upgraded from PHP 7.4)
- **Python 3.12** (upgraded from Python 3.10)
- **MariaDB 10.11** (upgraded from MariaDB 10.6)
- **Apache 2.4.58+** with improved security defaults
- **Updated system libraries** and improved performance
- **Latest MISP version** with all security patches

## 📋 Prerequisites

- Fresh Ubuntu 24.04 Server installation
- Minimum 4GB RAM (8GB recommended)
- 50GB disk space minimum
- Internet connection for package installation
- sudo privileges

## 🚀 Quick Installation

### Option 1: Automated Installation (Recommended)

```bash
# Download the installer
wget --no-cache -O /tmp/INSTALL-ubuntu-24.04.sh https://raw.githubusercontent.com/YOUR-REPO/MISP/2.4/INSTALL/INSTALL-ubuntu-24.04.sh

# Run the installer
bash /tmp/INSTALL-ubuntu-24.04.sh -c
```

### Option 2: Manual Installation

Follow the detailed instructions in [INSTALL-ubuntu-24.04.md](./INSTALL-ubuntu-24.04.md)

## 📦 What Gets Installed

- **MISP Core** - Main MISP application
- **PHP 8.3** - With all required extensions
- **MariaDB** - Database backend
- **Apache 2** - Web server with SSL
- **Redis** - Caching and background jobs
- **Python 3.12 virtualenv** - For MISP modules
- **Background workers** - For asynchronous processing

## 🔄 Migration from Ubuntu 22.04

If you're upgrading from Ubuntu 22.04, see the [MIGRATION-22.04-to-24.04.md](./MIGRATION-22.04-to-24.04.md) guide.

**⚠️ Important:** Always backup your data before migrating!

## 📂 Project Structure

```
.
├── README.md                           # This file
├── INSTALL-ubuntu-24.04.md            # Detailed installation guide
├── INSTALL-ubuntu-24.04.sh            # Installation script
├── MIGRATION-22.04-to-24.04.md        # Migration guide
├── configs/
│   ├── apache-misp-ssl-24.04.conf     # Apache SSL configuration
│   ├── php-8.3-misp.ini               # PHP configuration
│   └── misp-workers.service           # Systemd service file
└── scripts/
    ├── install-php83-deps.sh          # PHP 8.3 dependencies
    ├── install-core-deps.sh           # Core system dependencies
    └── configure-misp.sh              # MISP configuration

```

## 🔐 Security Hardening

After installation, follow these security best practices:

1. Change default passwords immediately
2. Configure firewall (ufw)
3. Set up SSL certificates (Let's Encrypt recommended)
4. Configure proper file permissions
5. Enable SELinux/AppArmor if needed
6. Regular system updates

## 🐛 Troubleshooting

### Common Issues

**PHP Extension Missing:**
```bash
sudo apt install php8.3-{redis,gnupg,gd,mysql,xml,mbstring,zip,bcmath,intl}
sudo systemctl restart apache2
```

**Permission Issues:**
```bash
sudo chown -R www-data:www-data /var/www/MISP
sudo chmod -R 750 /var/www/MISP
```

**Database Connection Failed:**
```bash
sudo systemctl status mariadb
sudo mysql_secure_installation
```

## 📚 Additional Resources

- [Official MISP Documentation](https://www.misp-project.org/documentation/)
- [MISP GitHub Repository](https://github.com/MISP/MISP)
- [MISP Training Materials](https://www.misp-project.org/training/)
- [Ubuntu 24.04 Release Notes](https://discourse.ubuntu.com/t/noble-numbat-release-notes/)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes on a clean Ubuntu 24.04 installation
4. Submit a pull request

## 📝 License

This installation guide follows the same license as MISP: AGPL-3.0

## ⚠️ Disclaimer

This installation is provided as-is. Always test in a development environment before deploying to production.

## 📧 Support

- MISP Community: https://www.misp-project.org/community/
- GitHub Issues: https://github.com/MISP/MISP/issues
- Gitter Chat: https://gitter.im/MISP/MISP

---

**Last Updated:** 2025-10-31
**MISP Version:** 2.4 (Latest)
**Ubuntu Version:** 24.04 LTS (Noble Numbat)
