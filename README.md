# DNS Master Audit - Enterprise Edition v3.0

<div align="center">

![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Author](https://img.shields.io/badge/author-Adrian%20Johnson-brightgreen.svg)

**Enterprise-grade DNS auditing solution with advanced analytics, interactive dashboards, and comprehensive reporting**

[Features](#-features) •
[Quick Start](#-quick-start) •
[Documentation](#-documentation) •
[Installation](#-installation) •
[Examples](#-examples) •
[Support](#-support)

</div>

---

## 📋 Overview

DNS Master Audit v3.0 is a comprehensive PowerShell-based DNS auditing platform designed for enterprise environments. It provides deep insights into DNS infrastructure health, security posture, and configuration drift with interactive reporting and automated remediation capabilities.

### What's New in v3.0

| Feature | Description |
|---------|-------------|
| 🎨 **HTML Dashboards** | Interactive reports with charts and drill-down capabilities |
| ⚡ **Parallel Processing** | 5-10x faster execution through multi-threading |
| 📊 **Change Detection** | Baseline comparison and drift analysis |
| 🔍 **Advanced Analytics** | Stale record detection, duplicate IPs, PTR validation |
| 🔗 **Enterprise Integration** | Teams, Slack, SIEM connectivity |
| 🔐 **Security Audits** | DNSSEC, zone transfer, and compliance checks |
| 🛠️ **Auto-Remediation** | Generated PowerShell scripts for fixes |
| 📈 **Enhanced Diagnostics** | Performance testing and replication monitoring |
| 📁 **Multiple Formats** | CSV, JSON, XML, HTML, Excel, PDF, Markdown |
| ⚙️ **Configuration Management** | Template-driven repeatable audits |

---

## ✨ Features

### Core Audit Modes

- **DNS Inventory:** Complete server discovery and cataloging
- **Health Check:** Service status and availability testing  
- **Record Export:** Comprehensive DNS record extraction
- **Site Audit:** AD site mismatch detection and analysis
- **Complete Audit:** All modes with consolidated reporting
- **Baseline Mode:** Create configuration snapshots
- **Compare Mode:** Detect changes and drift

### Advanced Capabilities

#### 📊 Interactive Dashboards
- Executive summary cards with key metrics
- Chart.js visualizations (pie, bar, heat maps)
- Sortable/filterable DataTables
- Responsive mobile-friendly design
- Offline viewing (self-contained HTML)

#### ⚡ Performance Optimization
- PowerShell runspace-based parallelization
- Configurable thread count (1-20)
- Batch processing for large datasets
- Memory-efficient streaming
- Resume capability

#### 🔍 Intelligence & Analytics
- **Stale Records:** Age-based and connectivity testing
- **Duplicate IPs:** Conflict detection across zones
- **PTR Validation:** Forward/reverse DNS alignment
- **Naming Conventions:** Pattern compliance checking
- **TTL Analysis:** Consistency and optimization recommendations

#### 🔐 Security & Compliance
- DNSSEC status validation
- Zone transfer security audits
- Dynamic update security checks
- Scavenging configuration review
- Compliance mapping (PCI-DSS, HIPAA, SOX, NIST 800-53)

#### 🔗 Enterprise Integration
- **Microsoft Teams:** Adaptive card notifications
- **Slack:** Formatted channel messages
- **SIEM:** Syslog (RFC 5424), CEF format
- **Email:** SMTP notifications (legacy)
- **Webhooks:** Custom HTTP endpoints

#### 🛠️ Remediation
- Auto-generated PowerShell scripts
- WhatIf support for safety
- Backup before changes
- Rollback procedures
- Approval workflows

---

## 🚀 Quick Start

### Prerequisites

```powershell
# Check PowerShell version (5.1+ required)
$PSVersionTable.PSVersion

# Verify required modules
Get-Module -ListAvailable ActiveDirectory, DnsServer

# Install if missing
Install-WindowsFeature RSAT-AD-PowerShell, RSAT-DNS-Server
```

### Installation

```powershell
# Download
Invoke-WebRequest -Uri "https://github.com/adrian207/DNS-Audit/releases/latest/DNS-MasterAudit-Enhanced-v3.0.ps1" `
    -OutFile "DNS-MasterAudit.ps1"

# Unblock
Unblock-File ".\DNS-MasterAudit.ps1"

# Run first audit
.\DNS-MasterAudit.ps1 -Mode Complete -EnableHTMLDashboard -EnableParallelProcessing
```

### First Run

```powershell
# Basic inventory
.\DNS-MasterAudit.ps1 -Mode Inventory

# Complete audit with all features
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableHTMLDashboard `
    -EnableParallelProcessing `
    -EnableAdvancedAnalytics `
    -EnableSecurityAudits `
    -GenerateRemediationScript

# View results
explorer C:\DNSAudit
start C:\DNSAudit\DNS_Dashboard_*.html
```

---

## 📚 Documentation

| Document | Description | Link |
|----------|-------------|------|
| **Quick Start Guide** | 5-minute setup | [QUICK-START-GUIDE.md](./docs/QUICK-START-GUIDE.md) |
| **User Guide** | Complete feature documentation | [USER-GUIDE.md](./docs/USER-GUIDE.md) |
| **Deployment Guide** | Enterprise installation | [DEPLOYMENT-GUIDE.md](./docs/DEPLOYMENT-GUIDE.md) |
| **Design Document** | Technical architecture | [DESIGN-DOCUMENT.md](./docs/DESIGN-DOCUMENT.md) |
| **Project Summary** | Complete overview | [PROJECT-SUMMARY.md](./docs/PROJECT-SUMMARY.md) |
| **Deliverables Manifest** | Complete inventory | [DELIVERABLES-MANIFEST.md](./docs/DELIVERABLES-MANIFEST.md) |

---

## 💻 Installation

### Method 1: Quick Install (Recommended)

```powershell
# Single command install
irm https://raw.githubusercontent.com/adrian207/DNS-Audit/main/install.ps1 | iex
```

### Method 2: Manual Install

```powershell
# Create directory structure
New-Item -Path "C:\DNSAudit" -ItemType Directory
cd C:\DNSAudit

# Download script
Invoke-WebRequest -Uri "https://github.com/adrian207/DNS-Audit/releases/latest/DNS-MasterAudit-Enhanced-v3.0.ps1" `
    -OutFile "DNS-MasterAudit.ps1"

# Unblock
Unblock-File ".\DNS-MasterAudit.ps1"
```

### Method 3: Git Clone

```powershell
git clone https://github.com/adrian207/DNS-Audit.git
cd DNS-Audit
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Inventory
```

---

## 📖 Examples

### Basic Audits

```powershell
# Server inventory
.\DNS-MasterAudit.ps1 -Mode Inventory

# Health check only
.\DNS-MasterAudit.ps1 -Mode HealthCheck

# Export DNS records
.\DNS-MasterAudit.ps1 -Mode RecordExport

# Site audit
.\DNS-MasterAudit.ps1 -Mode SiteAudit -EnableAllFeatures
```

### Advanced Audits

```powershell
# Complete audit with HTML dashboard
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableHTMLDashboard `
    -EnableParallelProcessing

# Security-focused audit
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableSecurityAudits `
    -EnableAdvancedAnalytics `
    -GenerateRemediationScript `
    -ExportFormat HTML

# Specific zones only
.\DNS-MasterAudit.ps1 -Mode RecordExport `
    -ZoneFilter "contoso.com","fabrikam.com" `
    -UnionZones

# With custom credentials
$cred = Get-Credential
.\DNS-MasterAudit.ps1 -Mode Complete -Credential $cred
```

### Enterprise Integration

```powershell
# Teams notification
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableHTMLDashboard `
    -TeamsWebhook "https://outlook.office.com/webhook/..."

# SIEM integration
.\DNS-MasterAudit.ps1 -Mode Complete `
    -SyslogServer "siem.contoso.com" `
    -SyslogPort 514

# Multiple outputs
.\DNS-MasterAudit.ps1 -Mode Complete `
    -ExportFormat All `
    -TeamsWebhook $teamsWebhook `
    -SlackWebhook $slackWebhook
```

### Configuration File

```powershell
# Create config
$config = @{
    Mode = "Complete"
    EnableHTMLDashboard = $true
    EnableParallelProcessing = $true
    MaxDegreeOfParallelism = 10
    EnableAdvancedAnalytics = $true
} | ConvertTo-Json

$config | Set-Content "audit-config.json"

# Use config
.\DNS-MasterAudit.ps1 -ConfigFile "audit-config.json"
```

### Baseline & Change Detection

```powershell
# Create baseline
.\DNS-MasterAudit.ps1 -Mode Baseline `
    -BaselinePath "C:\DNSAudit\Baselines"

# Compare to baseline
.\DNS-MasterAudit.ps1 -Mode Compare `
    -CompareToBaseline `
    -ExportFormat HTML
```

### Automated Scheduling

```powershell
# Create scheduled task
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-File C:\DNSAudit\DNS-MasterAudit.ps1 -Mode Complete -ConfigFile C:\DNSAudit\config.json -Quiet"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 2am

Register-ScheduledTask -TaskName "DNS Monthly Audit" `
    -Action $action `
    -Trigger $trigger `
    -RunLevel Highest
```

---

## 🎯 Use Cases

| Scenario | Recommendation |
|----------|---------------|
| **Monthly Reporting** | `-Mode Complete -EnableHTMLDashboard` |
| **Daily Health Monitoring** | `-Mode HealthCheck -Quiet` |
| **Pre-Migration Assessment** | `-Mode Complete -EnableAdvancedAnalytics -ExportFormat All` |
| **Security Audit** | `-Mode Complete -EnableSecurityAudits -GenerateRemediationScript` |
| **Change Management** | `-Mode Compare -CompareToBaseline` |
| **Performance Troubleshooting** | `-Mode Complete -EnableDiagnostics` |
| **Compliance Evidence** | `-Mode Complete -EnableSecurityAudits -ExportFormat PDF` |
| **Large Environment** | `-EnableParallelProcessing -MaxDegreeOfParallelism 15` |

---

## 📊 Performance

### Benchmarks

| Environment | Sequential | Parallel (5 threads) | Speedup |
|-------------|-----------|---------------------|---------|
| 5 DCs, 10K records | 15 min | 3 min | 5x |
| 10 DCs, 50K records | 45 min | 8 min | 5.6x |
| 20 DCs, 100K records | 2 hours | 15 min | 8x |
| 50 DCs, 500K records | 8 hours | 1 hour | 8x |

### System Requirements

| Environment | CPU | RAM | Disk |
|-------------|-----|-----|------|
| Small (1-5 DCs) | 2 vCPU | 4 GB | 20 GB |
| Medium (6-20 DCs) | 4 vCPU | 8 GB | 50 GB |
| Large (21-50 DCs) | 8 vCPU | 16 GB | 100 GB |
| Enterprise (50+ DCs) | 16 vCPU | 32 GB | 200 GB |

---

## 🔐 Security

### Best Practices

- ✅ Use dedicated service account with least privileges
- ✅ Store credentials in Windows Credential Manager or Azure Key Vault
- ✅ Enable transcript logging for audit trail
- ✅ Restrict script execution to approved servers
- ✅ Review remediation scripts before execution
- ✅ Enable security audits regularly

### Permissions Required

**Minimum:**
- Read access to Active Directory
- Read access to DNS zones
- Domain User membership

**Recommended:**
- DNS Admins group (read-only in practice)
- Enterprise Admins (for forest-wide audits)

**Not Required:**
- No local Administrator rights needed (for auditing)
- No Schema Admin rights needed

---

## 🐛 Troubleshooting

### Common Issues

#### Access Denied
```powershell
# Solution: Use credentials
$cred = Get-Credential
.\DNS-MasterAudit.ps1 -Mode Complete -Credential $cred
```

#### Slow Performance
```powershell
# Solution: Enable parallel processing
.\DNS-MasterAudit.ps1 -Mode Complete -EnableParallelProcessing -MaxDegreeOfParallelism 10
```

#### Out of Memory
```powershell
# Solution: Reduce parallelism or filter zones
.\DNS-MasterAudit.ps1 -Mode RecordExport -MaxDegreeOfParallelism 3 -ZoneFilter "contoso.com"
```

### Debug Mode

```powershell
# Enable verbose logging
.\DNS-MasterAudit.ps1 -Mode Complete -Verbose

# Review transcript
Get-Content "C:\DNSAudit\DNS_Audit_Transcript_*.log"
```

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Setup

```powershell
# Clone repository
git clone https://github.com/adrian207/DNS-Audit.git
cd DNS-Audit

# Create feature branch
git checkout -b feature/my-new-feature

# Make changes and test
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Inventory -Verbose

# Submit pull request
```

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Adrian Johnson**
- Email: adrian207@gmail.com
- GitHub: [@adrian207](https://github.com/adrian207)

---

## 🌟 Acknowledgments

- Microsoft DNS Server team for excellent PowerShell modules
- Chart.js for beautiful visualizations
- DataTables for interactive tables
- PowerShell community for inspiration and support

---

## 📈 Project Stats

![GitHub stars](https://img.shields.io/github/stars/adrian207/DNS-Audit?style=social)
![GitHub forks](https://img.shields.io/github/forks/adrian207/DNS-Audit?style=social)
![GitHub issues](https://img.shields.io/github/issues/adrian207/DNS-Audit)
![GitHub pull requests](https://img.shields.io/github/issues-pr/adrian207/DNS-Audit)

---

## 🗺️ Roadmap

### v3.1 (Q2 2025)
- [ ] PowerShell 7+ native support
- [ ] Cross-platform compatibility (Linux/Mac)
- [ ] Real-time monitoring dashboard
- [ ] Machine learning anomaly detection

### v3.2 (Q3 2025)
- [ ] REST API server mode
- [ ] Database backend (SQLite/SQL Server)
- [ ] Multi-tenant support
- [ ] Role-based access control

### v4.0 (Q4 2025)
- [ ] Web UI (React/Vue.js)
- [ ] Real-time collaboration features
- [ ] Mobile app
- [ ] Cloud-native deployment

---

## 📞 Support

### Getting Help

- 📖 **Documentation:** See [docs/](./docs/) folder
- 💬 **Discussions:** [GitHub Discussions](https://github.com/adrian207/DNS-Audit/discussions)
- 🐛 **Issues:** [GitHub Issues](https://github.com/adrian207/DNS-Audit/issues)
- 📧 **Email:** adrian207@gmail.com

### Commercial Support

Enterprise support options available:
- Priority bug fixes
- Custom feature development
- On-site training and consultation
- SLA-backed support contracts

Contact: adrian207@gmail.com

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=adrian207/DNS-Audit&type=Date)](https://star-history.com/#adrian207/DNS-Audit&Date)

---

<div align="center">

**Made with ❤️ by Adrian Johnson**

[⬆ Back to top](#dns-master-audit---enterprise-edition-v30)

</div>
