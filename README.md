# Security Enhancement for Ubuntu 24.04 LTS

This project contains security tools and installation scripts for Ubuntu 24.04 LTS (Noble Numbat), including:
- **MISP** (Malware Information Sharing Platform) - Threat intelligence sharing
- **auditd** (Linux Audit Framework) - System auditing and compliance monitoring

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

## 🔍 auditd - Linux Audit Framework

### Quick Installation

```bash
# Run the auditd installation script
sudo bash scripts/install-auditd-ubuntu-24.04.sh
```

### What You Get

- **System Monitoring** - Track file access, user activities, and system changes
- **Security Auditing** - Detect unauthorized access and privilege escalation
- **Compliance Support** - PCI-DSS, HIPAA, and CIS Benchmark compliance
- **Automated Reports** - Daily summaries and security event tracking
- **Helper Tools** - Easy-to-use monitoring commands

### Quick Commands

```bash
# Monitor audit events
sudo audit-monitor summary

# View failed logins
sudo audit-monitor logins

# Check privileged commands
sudo audit-monitor commands
```

For detailed installation and configuration, see [INSTALL-auditd-ubuntu-24.04.md](./INSTALL-auditd-ubuntu-24.04.md)

## 🔄 Migration from Ubuntu 22.04

If you're upgrading from Ubuntu 22.04, see the [MIGRATION-22.04-to-24.04.md](./MIGRATION-22.04-to-24.04.md) guide.

**⚠️ Important:** Always backup your data before migrating!

## 📂 Project Structure

```
.
├── README.md                                # This file
├── INSTALL-ubuntu-24.04.md                 # MISP installation guide
├── INSTALL-ubuntu-24.04.sh                 # MISP installation script
├── INSTALL-auditd-ubuntu-24.04.md          # auditd installation guide
├── MIGRATION-22.04-to-24.04.md             # Migration guide
├── configs/
│   ├── apache-misp-ssl-24.04.conf          # Apache SSL configuration
│   ├── php-8.3-misp.ini                    # PHP configuration
│   └── misp-workers.service                # Systemd service file
└── scripts/
    ├── install-php83-deps.sh               # PHP 8.3 dependencies
    ├── install-core-deps.sh                # Core system dependencies
    ├── configure-misp.sh                   # MISP configuration
    └── install-auditd-ubuntu-24.04.sh      # auditd installation & config

```

## 🔐 Security Hardening

After installation, follow these security best practices:

1. **Install auditd** - Enable system auditing for security monitoring
2. Change default passwords immediately
3. Configure firewall (ufw)
4. Set up SSL certificates (Let's Encrypt recommended)
5. Configure proper file permissions
6. Enable SELinux/AppArmor if needed
7. Regular system updates
8. Review audit logs daily (`sudo audit-monitor summary`)

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
