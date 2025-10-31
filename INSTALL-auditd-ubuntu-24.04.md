# Auditd Installation Guide for Ubuntu 24.04 LTS

This guide provides instructions for installing and configuring **auditd** (Linux Audit Framework) on Ubuntu 24.04 LTS.

## 📋 What is auditd?

The Linux Audit system (auditd) is a security-relevant information logging system that provides:
- System call monitoring and logging
- File and directory access tracking
- User activity monitoring
- Security event detection
- Compliance auditing (PCI-DSS, HIPAA, etc.)

## 🆕 Features in Ubuntu 24.04

- **Latest auditd version** with improved performance
- **Enhanced audit rules** for modern threat detection
- **Better integration** with systemd
- **Improved reporting** capabilities
- **Advanced filtering** and search options

## 📋 Prerequisites

- Ubuntu 24.04 LTS Server or Desktop
- Minimum 2GB RAM
- At least 10GB free disk space for logs
- Root or sudo privileges
- Internet connection

## 🚀 Quick Installation

### Automated Installation (Recommended)

```bash
# Download the script
wget -O /tmp/install-auditd-ubuntu-24.04.sh https://raw.githubusercontent.com/YOUR-REPO/Security-Enhancement/main/scripts/install-auditd-ubuntu-24.04.sh

# Make it executable
chmod +x /tmp/install-auditd-ubuntu-24.04.sh

# Run the installation
sudo /tmp/install-auditd-ubuntu-24.04.sh
```

Or if you have the script locally:

```bash
cd /path/to/Security-Enhancement
sudo bash scripts/install-auditd-ubuntu-24.04.sh
```

### Manual Installation

```bash
# Update package lists
sudo apt update

# Install auditd and plugins
sudo apt install -y auditd audispd-plugins

# Enable the service
sudo systemctl enable auditd
sudo systemctl start auditd

# Verify installation
sudo systemctl status auditd
```

## 🔧 What Gets Configured

The automated script configures the following:

### 1. System Monitoring
- ✅ System time changes
- ✅ User/group modifications
- ✅ Network configuration changes
- ✅ Login/logout events
- ✅ Failed login attempts

### 2. Security Events
- ✅ File permission changes
- ✅ Unauthorized access attempts
- ✅ Privileged command execution (sudo, su, passwd)
- ✅ File deletion events
- ✅ Kernel module operations

### 3. Configuration Monitoring
- ✅ SSH configuration changes
- ✅ Sudoers file modifications
- ✅ Cron job changes
- ✅ System startup scripts
- ✅ AppArmor/SELinux policy changes

### 4. Log Management
- **Location**: `/var/log/audit/audit.log`
- **Format**: ENRICHED (includes hostname and context)
- **Rotation**: Automatic rotation after 8MB
- **Retention**: Keeps 5 rotated logs
- **Space management**: Alerts when 75MB remaining

## 📊 Using auditd

### Basic Commands

```bash
# View audit service status
sudo systemctl status auditd

# View current audit rules
sudo auditctl -l

# Search audit logs (interactive mode)
sudo ausearch -i

# Generate summary report
sudo aureport

# Search for specific events (e.g., failed logins)
sudo ausearch -m USER_LOGIN --failed

# Search by user
sudo ausearch -ui 1000

# Search by time range
sudo ausearch -ts today -te now
```

### Using the Audit Monitor Helper

The installation creates a convenient monitoring script:

```bash
# Show audit summary
sudo audit-monitor summary

# Show failed login attempts
sudo audit-monitor logins

# Show file access events
sudo audit-monitor files

# Show user actions
sudo audit-monitor users

# Show privileged commands
sudo audit-monitor commands

# Show system modifications
sudo audit-monitor modifications
```

## 🔍 Common Use Cases

### 1. Track Who Accessed a File

```bash
# Monitor a specific file
sudo auditctl -w /etc/passwd -p rwxa -k password_file

# View access logs
sudo ausearch -k password_file -i
```

### 2. Monitor User Activity

```bash
# Track all commands run by a specific user (UID 1000)
sudo ausearch -ui 1000 -i | tail -50
```

### 3. Detect Failed Login Attempts

```bash
# Show all failed login attempts
sudo aureport -l --failed --summary

# Detailed view
sudo ausearch -m USER_LOGIN --failed -i
```

### 4. Track Privileged Operations

```bash
# View all sudo usage
sudo ausearch -k privileged-sudo -i

# View password changes
sudo ausearch -k privileged-passwd -i
```

### 5. Monitor File Deletions

```bash
# View deleted files
sudo ausearch -k delete -i | tail -30
```

### 6. Generate Compliance Reports

```bash
# Summary of all events
sudo aureport -summary

# Authentication report
sudo aureport -au

# File access report
sudo aureport -f

# Executable report
sudo aureport -x
```

## ⚙️ Configuration Files

### Main Configuration
- **File**: `/etc/audit/auditd.conf`
- **Purpose**: Controls audit daemon behavior
- **Backup**: Created automatically as `auditd.conf.backup-YYYYMMDD-HHMMSS`

### Audit Rules
- **File**: `/etc/audit/rules.d/audit.rules`
- **Purpose**: Defines what to audit
- **Backup**: Created automatically as `audit.rules.backup-YYYYMMDD-HHMMSS`

### Key Settings in auditd.conf

```bash
log_file = /var/log/audit/audit.log    # Main log file
log_format = ENRICHED                   # Include hostname
max_log_file = 8                        # 8MB per file
num_logs = 5                            # Keep 5 rotated logs
space_left = 75                         # Alert at 75MB
flush = INCREMENTAL_ASYNC               # Performance setting
```

## 🔒 Security Best Practices

### 1. Protect Audit Logs

```bash
# Set proper permissions
sudo chmod 600 /var/log/audit/audit.log
sudo chown root:root /var/log/audit/audit.log

# Prevent unauthorized deletion
sudo chattr +a /var/log/audit/audit.log
```

### 2. Monitor Critical Directories

Add custom rules to `/etc/audit/rules.d/custom.rules`:

```bash
# Monitor /etc for changes
-w /etc/ -p wa -k etc_changes

# Monitor sensitive application directories
-w /var/www/ -p wa -k web_changes
-w /opt/myapp/ -p wa -k app_changes

# Then reload rules
sudo augenrules --load
sudo systemctl restart auditd
```

### 3. Set Up Remote Logging

For centralized logging, configure audisp:

```bash
sudo apt install -y audispd-plugins

# Edit /etc/audit/plugins.d/syslog.conf
active = yes
direction = out
path = builtin_syslog
type = builtin
args = LOG_INFO
format = string

sudo systemctl restart auditd
```

### 4. Regular Maintenance

```bash
# Create a daily audit report script
cat > /etc/cron.daily/audit-report <<'EOF'
#!/bin/bash
aureport -summary > /var/log/audit/daily-report-$(date +\%Y\%m\%d).txt
EOF

chmod +x /etc/cron.daily/audit-report
```

## 🐛 Troubleshooting

### Issue: auditd won't start

```bash
# Check for configuration errors
sudo auditctl -l

# Check system logs
sudo journalctl -u auditd -n 50

# Verify configuration syntax
sudo auditd -v
```

### Issue: Disk space filling up

```bash
# Check current disk usage
df -h /var/log/audit/

# Reduce retention
sudo nano /etc/audit/auditd.conf
# Modify: num_logs = 3 (instead of 5)

# Manual cleanup (be careful!)
sudo rm /var/log/audit/audit.log.* (older logs)
```

### Issue: Too many audit messages

```bash
# Temporarily disable rules
sudo auditctl -D

# Review and optimize rules
sudo nano /etc/audit/rules.d/audit.rules

# Reload specific rules
sudo augenrules --load
```

### Issue: Rules not loading

```bash
# Check for rule errors
sudo augenrules --check

# Load rules manually
sudo augenrules --load

# If immutable mode is set (-e 2), reboot required
sudo reboot
```

## 📈 Performance Tuning

### Reduce Audit Overhead

```bash
# Edit /etc/audit/auditd.conf
# Increase buffer size
-b 8192 (default) to -b 16384

# Adjust flush frequency
freq = 50 (default) to freq = 100

# Use async mode
flush = INCREMENTAL_ASYNC
```

### Filter Noisy Events

```bash
# Exclude specific users (e.g., system users)
-a exit,never -F auid=0

# Exclude specific processes
-a exit,never -F exe=/usr/bin/noisy-app
```

## 📚 Additional Resources

- [Linux Audit Documentation](https://github.com/linux-audit/audit-documentation)
- [auditd Man Pages](https://man7.org/linux/man-pages/man8/auditd.8.html)
- [CIS Ubuntu 24.04 Benchmark](https://www.cisecurity.org/benchmark/ubuntu_linux)
- [NIST Audit Guidelines](https://csrc.nist.gov/)

## 🔄 Uninstallation

If you need to remove auditd:

```bash
# Stop and disable service
sudo systemctl stop auditd
sudo systemctl disable auditd

# Remove packages
sudo apt remove --purge auditd audispd-plugins

# Remove configuration (optional)
sudo rm -rf /etc/audit/
sudo rm -rf /var/log/audit/
```

## 📝 Compliance Mapping

### PCI-DSS Requirements
- **10.2** - Automated audit trails for all users
- **10.3** - Audit trail entries for each event
- **10.5** - Secure audit trails

### HIPAA Requirements
- **164.312(b)** - Audit controls
- **164.308(a)(1)(ii)(D)** - Information system activity review

### CIS Benchmark
- **4.1.1.1** - Ensure auditd is installed
- **4.1.1.2** - Ensure auditd service is enabled
- **4.1.1.3** - Ensure audit log storage size is configured

## 🤝 Contributing

Found an issue or want to improve the rules? Contributions are welcome!

1. Test changes on a clean Ubuntu 24.04 system
2. Verify rules don't cause performance issues
3. Submit a pull request with description

## 📧 Support

- GitHub Issues: https://github.com/YOUR-REPO/Security-Enhancement/issues
- Ubuntu Community: https://ubuntu.com/support/community-support

---

**Last Updated**: 2025-10-31
**auditd Version**: Latest (Ubuntu 24.04 repository)
**Ubuntu Version**: 24.04 LTS (Noble Numbat)
**Status**: Production Ready
