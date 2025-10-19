# DNS Master Audit - Enterprise Edition v3.2

<div align="center">

![Version](https://img.shields.io/badge/version-3.2.0-blue.svg)
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

> **🎉 NEW: v2.2 Production Release Available!**  
> Parallel processing is NOW LIVE in the production script (`DNS-MasterAudit.ps1` v2.2)!  
> Get **5-10x faster execution** in large environments today. See [Parallel Processing Examples](#parallel-processing) below.

### What's New in v3.2 (Latest)

| Feature | Description |
|---------|-------------|
| 🛡️ **CIS Compliance** | CIS Benchmark v3.0.0 security auditing (9 critical checks) |
| 🔐 **DNSSEC Inventory** | Migration preparation and key documentation |
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
- **CIS Compliance:** Security baseline auditing (CIS v3.0.0)
- **DNSSEC Inventory:** Migration preparation and key documentation

### 🆕 DNS Scavenging Manager

**NEW!** Comprehensive DNS scavenging analysis and configuration tool:
- **Analyze Mode:** Audit current scavenging configuration
- **Configure Mode:** Apply scavenging settings across all DNS servers
- **Report Mode:** Generate detailed CSV reports
- **3-Day Aggressive Cleanup:** Or any custom interval (7+7 Microsoft default)
- **Safety Features:** WhatIf, confirmations, zone exclusions, detailed logging

See: [`DNS-SCAVENGING-README.md`](./DNS-SCAVENGING-README.md)

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
Invoke-WebRequest -Uri "https://github.com/adrian207/DNS-Audit/releases/latest/DNS-MasterAudit-Enhanced-v3.2.ps1" `
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
Invoke-WebRequest -Uri "https://github.com/adrian207/DNS-Audit/releases/latest/DNS-MasterAudit-Enhanced-v3.2.ps1" `
    -OutFile "DNS-MasterAudit.ps1"

# Unblock
Unblock-File ".\DNS-MasterAudit.ps1"
```

### Method 3: Git Clone

```powershell
git clone https://github.com/adrian207/DNS-Audit.git
cd DNS-Audit
.\DNS-MasterAudit-Enhanced-v3.2.ps1 -Mode Inventory
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

### Parallel Processing (v2.2 - Available Now!)

```powershell
# Inventory with parallel processing (5-10x faster)
.\DNS-MasterAudit.ps1 -Mode Inventory -EnableParallelProcessing

# Health check with custom throttle
.\DNS-MasterAudit.ps1 -Mode HealthCheck `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 10

# Complete audit with parallel processing
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -ExportFormat HTML
```

### Advanced Audits

```powershell
# Complete audit with HTML dashboard (v3.0 - In Development)
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableHTMLDashboard `
    -EnableParallelProcessing

# Security-focused audit (v3.0 - In Development)
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

## 🛡️ CIS Compliance Auditing

### Overview

**NEW in v3.2:** Automated CIS Benchmark compliance checking for Windows DNS Server.

```powershell
# Run CIS compliance audit
.\DNS-MasterAudit-Enhanced-v3.2.ps1 -Mode CISCompliance
```

### CIS Benchmark Version

**Current Implementation:**
- **Benchmark:** CIS Microsoft Windows Server 2019/2022 Benchmark
- **Version:** 3.0.0
- **Release Date:** December 2023
- **Last Verified:** January 2025
- **Checks Implemented:** 9 critical controls

### Implemented CIS Controls

| Check ID | Category | Description | Severity |
|----------|----------|-------------|----------|
| **CIS-1.1** | Service Hardening | Recursion disabled on authoritative servers | HIGH |
| **CIS-1.2** | Service Hardening | DNS Socket Pool ≥2500 (DoS protection) | MEDIUM |
| **CIS-1.3** | Logging | Event logging enabled (level ≥2) | MEDIUM |
| **CIS-2.1** | Zone Security | Zone transfers restricted | CRITICAL |
| **CIS-2.2** | Zone Security | Secure dynamic updates only | HIGH |
| **CIS-2.3** | Zone Security | DNSSEC validation enabled | MEDIUM |
| **CIS-3.1** | Network Security | Listen on specific interfaces only | MEDIUM |
| **CIS-3.2** | Network Security | Response Rate Limiting (RRL) enabled | HIGH |
| **CIS-3.3** | Network Security | Cache locking ≥80% | MEDIUM |

### Compliance Scoring

The script generates a **compliance score** based on:
- ✅ **Passed:** Fully compliant with CIS recommendation
- ❌ **Failed:** Non-compliant (remediation required)
- ⚠️ **Manual Review:** Requires administrator judgment
- ○ **Not Applicable:** Check doesn't apply to environment

**Example Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║              CIS Compliance Summary                           ║
╚═══════════════════════════════════════════════════════════════╝

  Compliance Score:      87.5%

  Total Checks:          24
  ✓ Passed:              21
  ✗ Failed:              2
  ⚠ Manual Review:       1
  ○ Not Applicable:      0

  Critical Findings:     2
```

### Auto-Update Limitations

⚠️ **IMPORTANT: CIS Benchmarks CANNOT be automatically updated**

**Why:**
- CIS Benchmarks are copyrighted documents requiring paid membership
- No public API exists for programmatic access
- Licensing restrictions prevent automated distribution

**Current Approach:**
- Script contains hardcoded checks based on CIS v3.0.0 (December 2023)
- Version information clearly displayed in script constants
- Manual updates required when new CIS versions are released

### How to Update CIS Checks

When a new CIS Benchmark version is released:

**Step 1: Obtain Latest Benchmark**
```text
1. Visit: https://www.cisecurity.org/benchmark/microsoft_windows_server
2. Download the latest PDF (CIS membership may be required)
3. Review changes in DNS Server section
```

**Step 2: Update Script Constants**

Edit `DNS-MasterAudit-Enhanced-v3.2.ps1` lines 282-297:

```powershell
# Update these constants
$script:CIS_BenchmarkName = "CIS Microsoft Windows Server 2022 Benchmark"
$script:CIS_Version = "3.1.0"  # <-- Change version
$script:CIS_ReleaseDate = "June 2025"  # <-- Update date
$script:CIS_LastVerified = "June 2025"  # <-- Update verification date
```

**Step 3: Add/Modify Checks**

If the new CIS version adds or changes recommendations:
1. Locate the `Start-CISComplianceCheck` function (line ~1550)
2. Add new check blocks following existing patterns
3. Update `$script:CIS_ChecksImplemented` array with new checks
4. Test thoroughly before deployment

**Step 4: Update Documentation**

Update this README section with new:
- Benchmark version
- Check counts
- New/modified controls

**Step 5: Commit Changes**

```powershell
git add DNS-MasterAudit-Enhanced-v3.2.ps1 README.md
git commit -m "Update CIS Benchmark to v3.1.0"
git push origin main
```

### Maintenance Schedule

**Recommended:**
- Review CIS website quarterly for new benchmark releases
- Update script within 30 days of new release
- Document changes in CHANGELOG.md
- Test in non-production environment first

### Version History

| Script Version | CIS Version | Updated | Notes |
|----------------|-------------|---------|-------|
| v3.2 | 3.0.0 | January 2025 | Initial CIS implementation |
| Future | TBD | TBD | Awaiting CIS v3.1.0 release |

### Export & Reporting

CIS compliance results are exported to:
- **CSV:** `CISCompliance_<timestamp>.csv` - All check details
- **HTML:** `CISCompliance_Dashboard_<timestamp>.html` - Interactive report
- **JSON:** `CISCompliance_<timestamp>.json` - Machine-readable format

### Remediation

The script provides **ready-to-run PowerShell commands** for each failed check:

```powershell
# Example remediation commands shown in output
Set-DnsServerRecursion -ComputerName DC01 -Enable $false
Set-DnsServerCache -ComputerName DC01 -LockingPercent 80
Set-DnsServerResponseRateLimiting -ComputerName DC01 -Mode Enable
```

⚠️ **Always review and test remediation scripts before executing in production**

### Integration Examples

```powershell
# CIS compliance with Teams notification
.\DNS-MasterAudit-Enhanced-v3.2.ps1 -Mode CISCompliance `
    -TeamsWebhook "https://outlook.office.com/webhook/..."

# Monthly compliance report
.\DNS-MasterAudit-Enhanced-v3.2.ps1 -Mode CISCompliance `
    -ExportFormat HTML `
    -ExportPath "\\fileserver\compliance\DNS"

# Automated compliance check
$task = {
    .\DNS-MasterAudit-Enhanced-v3.2.ps1 -Mode CISCompliance -NonInteractive
    if ($LASTEXITCODE -ne 0) {
        Send-MailMessage -To "security@contoso.com" `
            -Subject "DNS CIS Compliance Failures" `
            -Body "Review: \\fileserver\compliance\DNS"
    }
}

Register-ScheduledTask -TaskName "DNS-CIS-Monthly" `
    -Action (New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File $task") `
    -Trigger (New-ScheduledTaskTrigger -Monthly -At 9am)
```

### Related Documentation

- **Official CIS Benchmarks:** https://www.cisecurity.org/cis-benchmarks
- **CIS Controls:** https://www.cisecurity.org/controls
- **Microsoft DNS Security:** https://docs.microsoft.com/en-us/windows-server/networking/dns/dns-top

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
.\DNS-MasterAudit-Enhanced-v3.2.ps1 -Mode Inventory -Verbose

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
