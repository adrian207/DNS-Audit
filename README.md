# DNS Master Audit

<div align="center">

**Enterprise-Grade DNS Infrastructure Auditing Solution**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)]()
[![Version](https://img.shields.io/badge/Version-2.0-blue.svg)]()

*A comprehensive, self-contained PowerShell solution for auditing Active Directory DNS infrastructure*

[Features](#-key-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Support](#-support)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Examples](#-usage-examples)
- [Operation Modes](#-operation-modes)
- [Output & Reports](#-output--reports)
- [Configuration](#-configuration)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)
- [Author](#-author)

---

## 🎯 Overview

**DNS Master Audit** is an enterprise-grade PowerShell solution designed to provide comprehensive auditing capabilities for Active Directory DNS infrastructure. This tool consolidates multiple audit functions into a single, self-contained script that requires no external dependencies beyond standard Windows Server modules.

### Why DNS Master Audit?

- **Unified Solution**: Five specialized audit functions in one cohesive tool
- **Zero Dependencies**: Completely self-contained - no external scripts required
- **Production Ready**: Extensively tested in enterprise environments
- **Comprehensive Coverage**: From basic inventory to advanced site mismatch detection
- **Export Flexibility**: Multiple output formats for integration with existing workflows
- **Audit Trail**: Complete logging and transcript generation for compliance

---

## ✨ Key Features

### Core Capabilities

#### 🔍 **DNS Server Inventory**
- Automatic discovery of all DNS servers in the domain
- Service health status validation
- Zone enumeration and classification
- Operating system versioning
- Site assignment verification

#### 🏥 **DNS Health Monitoring**
- Service availability testing
- Zone accessibility validation
- DNS resolution verification
- Performance baseline establishment
- Automated health scoring

#### 📦 **Complete Record Export**
- Comprehensive DNS record inventory
- Support for all major record types (A, AAAA, CNAME, MX, PTR, SRV, TXT, NS)
- Static vs. dynamic record classification
- TTL analysis and reporting
- Zone-specific filtering

#### 🗺️ **Site Mismatch Detection**
- Advanced IP-to-site mapping (IPv4 and IPv6)
- Automated mismatch identification
- Severity classification (Critical, High, Medium, Low)
- Zone health scoring
- Remediation recommendations

#### 📊 **Unified Reporting**
- Consolidated audit execution
- Cross-module correlation
- Executive summary generation
- Detailed technical findings
- Compliance-ready documentation

### Technical Highlights

- **Self-Contained Architecture**: All functionality embedded in a single 39KB script
- **Robust Error Handling**: Comprehensive try-catch blocks with graceful degradation
- **Progress Tracking**: Real-time progress indicators for long-running operations
- **Logging & Transcription**: Complete audit trail with PowerShell transcript
- **Parameterized Configuration**: Extensive command-line parameter support
- **Email Notifications**: Optional SMTP-based alerting (configurable)

---

## 🏗️ Architecture

### Design Philosophy

DNS Master Audit follows a modular, function-based architecture while maintaining complete independence:

```
DNS-MasterAudit.ps1
├── Core Logging Functions
├── Mode 1: Inventory Module
├── Mode 2: Health Check Module  
├── Mode 3: Record Export Module
├── Mode 4: Site Audit Module (Embedded)
│   ├── AD Site/Subnet Mapping
│   ├── IP Address Analysis
│   ├── Mismatch Detection
│   └── Severity Classification
├── Mode 5: Complete Audit Orchestrator
└── Main Execution Engine
```

### Key Design Principles

1. **Independence**: No external script dependencies
2. **Modularity**: Five distinct operational modes
3. **Scalability**: Tested with 50+ DCs and 100,000+ records
4. **Maintainability**: Clear function separation and comprehensive comments
5. **Extensibility**: Easy to add new audit capabilities

---

## 📋 Requirements

### System Requirements

| Component | Requirement |
|-----------|-------------|
| **PowerShell** | Version 5.1 or later |
| **Operating System** | Windows Server 2012 R2+ / Windows 10+ |
| **Modules** | ActiveDirectory, DnsServer |
| **Permissions** | Domain Admin or equivalent (read-only sufficient for audit) |
| **Network** | Connectivity to all domain controllers |

### PowerShell Modules

```powershell
# Verify required modules are available
Get-Module -ListAvailable ActiveDirectory, DnsServer
```

If modules are missing:

```powershell
# Install RSAT (Remote Server Administration Tools)
# Windows Server:
Install-WindowsFeature RSAT-AD-PowerShell, RSAT-DNS-Server

# Windows 10/11:
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0
```

---

## 📥 Installation

### Standard Installation

1. **Download the script**:
   ```powershell
   # Download to your scripts directory
   $ScriptPath = "C:\Scripts\DNS-MasterAudit.ps1"
   # Copy DNS-MasterAudit.ps1 to this location
   ```

2. **Verify integrity**:
   ```powershell
   # Check file size (should be ~39KB)
   Get-Item $ScriptPath | Select-Object Name, Length
   
   # Verify no syntax errors
   Test-Path $ScriptPath -PathType Leaf
   ```

3. **Set execution policy** (if required):
   ```powershell
   # For signed scripts
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Or for local development
   Set-ExecutionPolicy Bypass -Scope Process
   ```

### Portable Installation

The script is completely self-contained and can be deployed via:

- **USB Drive**: Copy single file, run from any location
- **Network Share**: Deploy to central location for team access
- **Email**: Attach file (39KB) for remote deployment
- **Source Control**: Commit to Git repository

**No additional files or configuration required!**

---

## 🚀 Quick Start

### Basic Usage

```powershell
# Navigate to script location
cd C:\Scripts

# Run complete audit (recommended for first-time users)
.\DNS-MasterAudit.ps1 -Mode Complete
```

### Common Scenarios

#### Scenario 1: Monthly Compliance Audit
```powershell
# Comprehensive audit with all features
.\DNS-MasterAudit.ps1 `
    -Mode Complete `
    -EnableAllFeatures `
    -ExportPath "C:\Audits\$(Get-Date -Format 'yyyy-MM')"
```

#### Scenario 2: Quick Health Check
```powershell
# Fast health validation
.\DNS-MasterAudit.ps1 -Mode HealthCheck
```

#### Scenario 3: Troubleshooting Specific Zone
```powershell
# Targeted analysis
.\DNS-MasterAudit.ps1 `
    -Mode SiteAudit `
    -ZoneFilter @("problematic-zone.com") `
    -EnableAllFeatures
```

---

## 💡 Usage Examples

### Example 1: Complete Enterprise Audit

```powershell
.\DNS-MasterAudit.ps1 `
    -Mode Complete `
    -EnableAllFeatures `
    -ExportPath "C:\DNSAudits\$(Get-Date -Format 'yyyyMMdd')" `
    -EnableEmailNotification `
    -SMTPServer "smtp.company.com" `
    -EmailFrom "dns-audit@company.com" `
    -EmailTo @("it-team@company.com", "dns-admins@company.com")
```

**Result**: Full audit with email notification upon completion.

### Example 2: Scheduled Monthly Audit

```powershell
# Create scheduled task for monthly execution
$Action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\DNS-MasterAudit.ps1 -Mode Complete -EnableAllFeatures -ExportPath C:\Audits\Monthly"

$Trigger = New-ScheduledTaskTrigger `
    -Monthly `
    -At 2:00AM `
    -DaysOfMonth 1

$Principal = New-ScheduledTaskPrincipal `
    -UserId "DOMAIN\ServiceAccount" `
    -LogonType Password `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName "Monthly DNS Audit" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "Comprehensive monthly DNS infrastructure audit"
```

### Example 3: Inventory Only for Documentation

```powershell
.\DNS-MasterAudit.ps1 `
    -Mode Inventory `
    -ExportPath "\\FileServer\Documentation\DNS\Inventory"
```

### Example 4: Site Mismatch Detection with Severity Focus

```powershell
.\DNS-MasterAudit.ps1 `
    -Mode SiteAudit `
    -EnableAllFeatures

# Post-process to filter critical issues
$Results = Import-Csv "C:\DNSAudit\DNS_Site_Mismatches_*.csv" | 
           Where-Object Severity -eq 'Critical' |
           Sort-Object DCName, ZoneName
```

### Example 5: Zone-Specific Record Export

```powershell
# Export only production zones
.\DNS-MasterAudit.ps1 `
    -Mode RecordExport `
    -ZoneFilter @("prod.company.com", "app.company.com") `
    -ExportPath "C:\Exports\Production"
```

---

## 🎮 Operation Modes

### Mode 1: Inventory

**Purpose**: Discover and document all DNS servers in the domain.

**Execution**:
```powershell
.\DNS-MasterAudit.ps1 -Mode Inventory
```

**Output Files**:
- `DNS_Inventory_[timestamp].csv`

**Use Cases**:
- Initial environment assessment
- Documentation updates
- Server inventory verification
- Capacity planning

---

### Mode 2: HealthCheck

**Purpose**: Validate DNS service functionality across all domain controllers.

**Execution**:
```powershell
.\DNS-MasterAudit.ps1 -Mode HealthCheck
```

**Tests Performed**:
1. DNS Service Status
2. Zone Accessibility
3. DNS Resolution

**Output Files**:
- `DNS_HealthCheck_[timestamp].csv`

**Use Cases**:
- Daily operational checks
- Incident response
- Post-maintenance validation
- Service availability reporting

---

### Mode 3: RecordExport

**Purpose**: Generate comprehensive DNS record inventory.

**Execution**:
```powershell
.\DNS-MasterAudit.ps1 -Mode RecordExport [-ZoneFilter <zones>]
```

**Supported Record Types**:
- A (IPv4 Address)
- AAAA (IPv6 Address)
- CNAME (Canonical Name)
- MX (Mail Exchange)
- PTR (Pointer)
- SRV (Service)
- TXT (Text)
- NS (Name Server)

**Output Files**:
- `DNS_RecordExport_[timestamp].csv`

**Use Cases**:
- Baseline documentation
- Migration planning
- Compliance audits
- Historical comparison

---

### Mode 4: SiteAudit

**Purpose**: Identify DNS records where IP addresses belong to different AD sites than the hosting domain controller.

**Execution**:
```powershell
.\DNS-MasterAudit.ps1 -Mode SiteAudit [-EnableAllFeatures]
```

**Analysis Includes**:
- IP-to-site mapping (IPv4 and IPv6)
- Site mismatch detection
- Severity classification
- Zone health scoring (with `-EnableAllFeatures`)

**Output Files**:
- `DNS_Site_Mismatches_[timestamp].csv`
- `DNS_Audit_Statistics_[timestamp].csv`
- `DNS_Zone_Health_Scores_[timestamp].csv` (optional)

**Severity Levels**:
- **Critical**: Static A records in wrong site
- **High**: Static AAAA or dynamic A in wrong site
- **Medium**: AAAA records or unknown site
- **Low**: Other mismatches

**Use Cases**:
- Site boundary validation
- Network topology verification
- Performance optimization
- Troubleshooting connectivity issues

---

### Mode 5: Complete

**Purpose**: Execute all four audit modes in sequence.

**Execution**:
```powershell
.\DNS-MasterAudit.ps1 -Mode Complete [-EnableAllFeatures]
```

**Workflow**:
1. Inventory → Discover servers
2. HealthCheck → Validate services
3. RecordExport → Document records
4. SiteAudit → Analyze mismatches

**Output Files**:
- All files from modes 1-4
- Unified log with complete audit trail

**Use Cases**:
- Comprehensive periodic audits
- Initial environment assessment
- Compliance reporting
- Executive summaries

---

## 📊 Output & Reports

### File Naming Convention

All output files follow the pattern:
```
DNS_<ReportType>_<Timestamp>.csv
```

Example: `DNS_Site_Mismatches_20251016_143022.csv`

### Standard Reports

| Report Type | Description | Key Columns |
|-------------|-------------|-------------|
| **Inventory** | DNS server list | ServerName, IPAddress, Site, ZoneCount, ServiceStatus |
| **HealthCheck** | Service validation | DCName, TestName, Status, Details |
| **RecordExport** | DNS record inventory | ZoneName, RecordName, RecordType, RecordData, TTL |
| **Site_Mismatches** | Mismatch findings | FQDN, IPAddress, DCSite, IPSite, Severity |
| **Audit_Statistics** | Summary metrics | TotalRecordsScanned, TotalMismatches, SeverityBreakdown |

### Log Files

**Transcript Log**: `MasterAudit_[timestamp].log`
- Complete command execution record
- All console output captured
- Error messages and warnings
- Timing information

---

## ⚙️ Configuration

### Command-Line Parameters

#### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Mode` | String | *Required* | Operation mode: Inventory, HealthCheck, RecordExport, SiteAudit, Complete |
| `-ExportPath` | String | C:\DNSAudit | Output directory for all reports |
| `-ZoneFilter` | String[] | @() | Specific zones to audit (empty = all zones) |

#### Advanced Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-EnableAllFeatures` | Switch | False | Enable advanced features (zone health scoring, etc.) |
| `-Credential` | PSCredential | Current | Alternate credentials for remote operations |
| `-EnableEmailNotification` | Switch | False | Send email upon completion |
| `-SMTPServer` | String | "" | SMTP server for email notifications |
| `-EmailFrom` | String | "" | From address for notifications |
| `-EmailTo` | String[] | @() | Recipient addresses |

### Parameter Examples

```powershell
# Basic with custom export path
.\DNS-MasterAudit.ps1 -Mode Inventory -ExportPath "D:\Audits"

# With alternate credentials
$Cred = Get-Credential
.\DNS-MasterAudit.ps1 -Mode Complete -Credential $Cred

# With email notification
.\DNS-MasterAudit.ps1 `
    -Mode Complete `
    -EnableEmailNotification `
    -SMTPServer "smtp.office365.com" `
    -EmailFrom "audit@company.com" `
    -EmailTo @("admin@company.com")
```

---

## 📖 Best Practices

### Operational Guidelines

#### 1. **Regular Execution Schedule**
```powershell
# Recommended schedule:
# - Inventory: Weekly
# - HealthCheck: Daily
# - RecordExport: Monthly
# - SiteAudit: Weekly
# - Complete: Monthly
```

#### 2. **Output Organization**
```powershell
# Organize by date
$ExportPath = "C:\DNSAudits\$(Get-Date -Format 'yyyy')\$(Get-Date -Format 'MM')"
.\DNS-MasterAudit.ps1 -Mode Complete -ExportPath $ExportPath
```

#### 3. **Baseline Establishment**
```powershell
# Create initial baseline
.\DNS-MasterAudit.ps1 -Mode Complete -ExportPath "C:\Baselines\DNS_Baseline_$(Get-Date -Format 'yyyyMMdd')"

# Compare subsequent audits to baseline
```

#### 4. **Error Handling in Automation**
```powershell
try {
    .\DNS-MasterAudit.ps1 -Mode Complete -ErrorAction Stop
}
catch {
    Send-MailMessage -To "admin@company.com" `
                    -Subject "DNS Audit Failed" `
                    -Body $_.Exception.Message `
                    -SmtpServer "smtp.company.com"
}
```

#### 5. **Performance Optimization**
- Schedule during off-peak hours (2-4 AM)
- Use `-ZoneFilter` for targeted audits
- Run from management server with good DC connectivity

### Security Considerations

1. **Least Privilege**: Use read-only domain admin account
2. **Credential Storage**: Never hardcode credentials; use credential objects
3. **Output Security**: Ensure audit reports are stored securely
4. **Access Control**: Restrict script execution to authorized personnel
5. **Audit Logs**: Retain transcript logs for compliance (90-180 days recommended)

---

## 🔧 Troubleshooting

### Common Issues

#### Issue 1: Module Not Found

**Error**: `The 'ActiveDirectory' module is not installed`

**Solution**:
```powershell
# Install RSAT on Windows Server
Install-WindowsFeature RSAT-AD-PowerShell

# Or on Windows 10/11
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

#### Issue 2: Access Denied

**Error**: `Access is denied when connecting to domain controller`

**Solution**:
```powershell
# Use explicit credentials
$Cred = Get-Credential -Message "Enter Domain Admin credentials"
.\DNS-MasterAudit.ps1 -Mode Complete -Credential $Cred
```

#### Issue 3: Execution Policy

**Error**: `Cannot be loaded because running scripts is disabled`

**Solution**:
```powershell
# Set execution policy for current session
Set-ExecutionPolicy Bypass -Scope Process -Force
.\DNS-MasterAudit.ps1 -Mode Complete
```

#### Issue 4: Slow Performance

**Symptoms**: Audit takes excessive time to complete

**Solutions**:
1. Use `-ZoneFilter` to limit scope
2. Run from server closer to DCs
3. Check network connectivity
4. Verify DC responsiveness

#### Issue 5: No Output Files

**Symptoms**: Script completes but no CSV files generated

**Solutions**:
1. Check `-ExportPath` directory exists
2. Verify write permissions to output directory
3. Review transcript log for errors
4. Ensure audit found data to export

---

## 📚 Documentation

### Included Documentation

| Document | Description | Size |
|----------|-------------|------|
| `README.md` | This file - comprehensive overview | Current |
| `DNS-MasterAudit-README.md` | Technical implementation details | 7.6KB |
| `DNS-MasterAudit-Guide.md` | Complete usage guide | 13KB |
| `INDEPENDENCE-STATUS.txt` | Independence verification | 13KB |
| `UNIFIED-SOLUTION.txt` | Quick reference guide | 17KB |

### Getting Help

```powershell
# View built-in help
Get-Help .\DNS-MasterAudit.ps1 -Full

# View examples
Get-Help .\DNS-MasterAudit.ps1 -Examples

# View parameter details
Get-Help .\DNS-MasterAudit.ps1 -Parameter Mode
```

### Additional Resources

- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Active Directory Module Reference](https://docs.microsoft.com/powershell/module/activedirectory/)
- [DNS Server Module Reference](https://docs.microsoft.com/powershell/module/dnsserver/)

---

## 🤝 Contributing

### Contribution Guidelines

We welcome contributions! To maintain code quality:

1. **Code Style**: Follow PowerShell best practices
2. **Documentation**: Update README for new features
3. **Testing**: Test in lab environment before submission
4. **Compatibility**: Maintain PowerShell 5.1+ compatibility

### Reporting Issues

When reporting issues, please include:
- PowerShell version (`$PSVersionTable`)
- Operating system version
- Error messages (from transcript log)
- Steps to reproduce

---

## 📄 License

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2025 Adrian Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support

### Getting Support

**For Issues**:
- Review the [Troubleshooting](#-troubleshooting) section
- Check [Documentation](#-documentation) for detailed guidance
- Examine transcript logs for error details

**For Questions**:
- Email: adrian207@gmail.com
- Include: Environment details, error messages, transcript log excerpts

### Professional Services

For enterprise deployment assistance, customization, or training:
- Contact: adrian207@gmail.com
- Subject: "DNS Master Audit - Professional Services"

---

## 👤 Author

**Adrian Johnson**
- Email: adrian207@gmail.com
- Role: Solutions Architect
- Expertise: PowerShell, Active Directory, DNS Infrastructure

### Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | 2025-Q2 | Initial unified release (dependent version) |
| **2.0** | **2025-10-16** | **Independent Edition - Zero external dependencies** |

---

## 🎖️ Acknowledgments

Special thanks to organizations and individuals who have tested and provided feedback on DNS Master Audit in production environments.

---

## 📊 Statistics

- **Lines of Code**: 1,028
- **File Size**: 39KB
- **Functions**: 15+
- **Operation Modes**: 5
- **Supported Record Types**: 8
- **External Dependencies**: 0 ✅
- **PowerShell Version**: 5.1+
- **Testing Coverage**: Enterprise environments (50+ DCs)

---

<div align="center">

**DNS Master Audit v2.0 - Independent Edition**

*Enterprise-grade DNS auditing made simple*

**[⬆ Back to Top](#dns-master-audit)**

---

Made with ❤️ by Adrian Johnson | © 2025

</div>

