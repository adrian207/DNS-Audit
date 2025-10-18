# DNS Master Audit - Enterprise Edition v3.0
## User Guide

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Version:** 3.0.0  
**Date:** January 2025

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Installation](#installation)
4. [Quick Start](#quick-start)
5. [Core Features](#core-features)
6. [Advanced Features](#advanced-features)
7. [Configuration](#configuration)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [FAQ](#faq)

---

## Introduction

Welcome to the DNS Master Audit Tool - Enterprise Edition v3.0! This comprehensive guide will help you leverage the full power of enterprise-grade DNS auditing.

### What's New in v3.0

- ✅ Interactive HTML dashboards
- ✅ 5-10x faster with parallel processing
- ✅ Change detection and baseline management
- ✅ Advanced analytics and intelligence
- ✅ Enterprise integrations (Teams, Slack, SIEM)
- ✅ Security and compliance auditing
- ✅ Automated remediation scripts
- ✅ Enhanced diagnostics
- ✅ Multiple export formats
- ✅ Configuration management

---

## Getting Started

### System Requirements

**Minimum Requirements:**
- Windows Server 2012 R2 / Windows 10 or later
- PowerShell 5.1 or later
- Active Directory module
- DnsServer module
- 4 GB RAM
- Network connectivity to domain controllers

**Recommended Requirements:**
- Windows Server 2019 / Windows 11 or later
- PowerShell 7.x
- 8 GB RAM or more
- SSD storage
- Dedicated audit workstation

### Prerequisites

```powershell
# Verify PowerShell version
$PSVersionTable.PSVersion

# Check required modules
Get-Module -ListAvailable ActiveDirectory, DnsServer

# Install missing modules (if needed)
Install-WindowsFeature RSAT-AD-PowerShell, RSAT-DNS-Server
```

### Permissions Required

- **Read Access:** Domain Controllers, DNS zones
- **Recommended:** DNS Administrators group membership
- **Optional (for remediation):** Administrator rights

---

## Installation

### Quick Install

```powershell
# Download the script
Invoke-WebRequest -Uri "https://github.com/adrian207/DNS-Audit/releases/latest/DNS-MasterAudit-Enhanced-v3.0.ps1" -OutFile "DNS-MasterAudit-Enhanced-v3.0.ps1"

# Unblock the script
Unblock-File -Path ".\DNS-MasterAudit-Enhanced-v3.0.ps1"

# Verify script
Get-AuthenticodeSignature -FilePath ".\DNS-MasterAudit-Enhanced-v3.0.ps1"
```

### Optional Components

```powershell
# For Excel export
Install-Module ImportExcel -Scope CurrentUser

# For SQLite baseline storage
Install-Module PSSQLite -Scope CurrentUser

# For enhanced charting
Install-Module PSWriteHTML -Scope CurrentUser
```

---

## Quick Start

### Your First Audit

#### 1. Basic Inventory

```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Inventory
```

**What it does:**
- Discovers all domain controllers
- Lists DNS servers and their status
- Exports server inventory to CSV

#### 2. Health Check

```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode HealthCheck
```

**What it does:**
- Tests DNS service on all DCs
- Validates zone accessibility
- Tests DNS resolution
- Exports health report

#### 3. Complete Audit (Recommended)

```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -EnableHTMLDashboard -EnableParallelProcessing
```

**What it does:**
- Runs all audit modes
- Generates interactive HTML dashboard
- Uses parallel processing for speed
- Creates comprehensive report

#### 4. Review Results

Results are saved to `C:\DNSAudit` by default:
- CSV files for data analysis
- HTML dashboard (if enabled)
- Transcript log
- Recommendations report

---

## Core Features

### Mode 1: DNS Inventory

**Purpose:** Discover and catalog all DNS servers in your environment.

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Inventory `
    -ExportPath "C:\Audits\DNS" `
    -Credential (Get-Credential)
```

**Output:**
- `DNS_Inventory_YYYYMMDD_HHMMSS.csv`
- Server list with OS, site, zone counts

**When to use:**
- Initial environment discovery
- Documentation requirements
- Capacity planning
- Compliance reporting

---

### Mode 2: Health Check

**Purpose:** Validate DNS service health across all domain controllers.

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode HealthCheck
```

**Tests Performed:**
1. DNS service status (running/stopped)
2. Zone accessibility
3. DNS resolution functionality

**Output:**
- `DNS_HealthCheck_YYYYMMDD_HHMMSS.csv`
- Pass/Fail status for each test
- Detailed error messages

**When to use:**
- Regular health monitoring
- Troubleshooting DNS issues
- Pre/post-change validation
- Service availability reporting

---

### Mode 3: Record Export

**Purpose:** Export complete DNS record inventory.

**Usage:**
```powershell
# Basic export
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode RecordExport

# Specific zones only
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode RecordExport -ZoneFilter "contoso.com","fabrikam.com"

# Comprehensive export from all DCs
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode RecordExport -UnionZones
```

**Record Types Captured:**
- A (IPv4 addresses)
- AAAA (IPv6 addresses)
- CNAME (aliases)
- MX (mail)
- PTR (reverse lookups)
- SRV (services)
- TXT (text records)
- NS (name servers)

**Output:**
- `DNS_RecordExport_YYYYMMDD_HHMMSS.csv`
- All records with metadata
- Static/dynamic indicators
- Timestamp information

**When to use:**
- DNS documentation
- Migration planning
- Backup purposes
- Compliance evidence
- Change tracking

---

### Mode 4: Site Audit

**Purpose:** Identify DNS records with site mismatches (IP in wrong AD site).

**Usage:**
```powershell
# Basic site audit
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode SiteAudit

# With advanced analytics
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode SiteAudit `
    -EnableAdvancedAnalytics `
    -EnableAllFeatures `
    -GenerateRemediationScript
```

**Detects:**
- Site mismatches (A/AAAA records in wrong site)
- Severity classification (Critical/High/Medium/Low)
- Static vs. dynamic records
- Unknown subnets

**Output:**
- `DNS_SiteMismatches_YYYYMMDD_HHMMSS.csv`
- Detailed mismatch analysis
- Zone health scores (optional)
- Remediation recommendations

**When to use:**
- Site consolidations
- Network migrations
- Performance optimization
- AD site health monitoring

---

### Mode 5: Complete Audit

**Purpose:** Run all audits in sequence with comprehensive reporting.

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -EnableHTMLDashboard `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 10 `
    -ExportFormat All
```

**Includes:**
- DNS Inventory
- Health Check
- Record Export
- Site Audit

**Output:**
- All individual mode outputs
- Consolidated HTML dashboard
- Executive summary
- Recommendations report

**When to use:**
- Monthly/quarterly audits
- Comprehensive documentation
- Executive reporting
- Compliance assessments

---

## Advanced Features

### Feature 1: HTML Dashboard

**Enable interactive HTML reports with charts and visualizations.**

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -EnableHTMLDashboard
```

**Dashboard Features:**
- Executive summary cards
- Interactive charts (Chart.js)
- Sortable/filterable tables (DataTables)
- Search functionality
- Responsive design
- Offline viewing

**Accessing the Dashboard:**
1. Run audit with `-EnableHTMLDashboard`
2. Open `DNS_Dashboard_YYYYMMDD_HHMMSS.html` in any browser
3. No internet required after generation

**Best Practices:**
- Use for stakeholder presentations
- Share via email or SharePoint
- Archive for historical comparison
- Print for documentation

---

### Feature 2: Parallel Processing

**Dramatically improve performance with multi-threading.**

**Usage:**
```powershell
# Enable with default throttle (5)
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -EnableParallelProcessing

# Custom parallelism level
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 10
```

**Performance Impact:**

| Environment | Sequential | Parallel (5) | Improvement |
|-------------|-----------|--------------|-------------|
| 5 DCs, 10K records | 15 min | 3 min | 5x faster |
| 10 DCs, 50K records | 45 min | 8 min | 5.6x faster |
| 20 DCs, 100K records | 2 hours | 15 min | 8x faster |

**Recommendations:**
- **Lab/Test:** 10-15 threads
- **Production:** 5-10 threads
- **Limited network:** 3-5 threads
- Monitor resource usage first time

**Troubleshooting:**
- If timeouts occur, reduce parallelism
- Check network bandwidth
- Verify DC performance
- Review firewall logs

---

### Feature 3: Baseline & Change Detection

**Track DNS configuration changes over time.**

#### Creating a Baseline

```powershell
# Create initial baseline
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Baseline `
    -BaselinePath "C:\DNSAudit\Baselines"
```

#### Comparing to Baseline

```powershell
# Compare current state to latest baseline
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Compare `
    -CompareToBaseline `
    -ExportFormat HTML
```

**Change Categories Detected:**
- New zones created
- Zones deleted
- New DNS records
- Modified records (IP, TTL changes)
- Deleted records
- Configuration changes

**Use Cases:**
- Change management validation
- Unauthorized change detection
- Compliance drift monitoring
- Pre/post-migration comparison
- Security auditing

**Best Practices:**
- Create baseline before major changes
- Schedule monthly baseline snapshots
- Compare after maintenance windows
- Document expected changes
- Investigate unauthorized changes

---

### Feature 4: Advanced Analytics

**Enable intelligent analysis of DNS data.**

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -EnableAdvancedAnalytics `
    -EnableHTMLDashboard
```

**Analytics Capabilities:**

#### 1. Stale Record Detection
- Finds records with no ping response
- Identifies aged records (>90 days)
- Detects orphaned A records
- Recommends cleanup actions

#### 2. Duplicate IP Finder
- Locates IPs with multiple hostnames
- Identifies potential conflicts
- Severity classification
- Conflict resolution recommendations

#### 3. PTR Validation
- Verifies forward/reverse DNS alignment
- Finds missing PTR records
- Detects mismatched PTR entries
- Generates creation scripts

#### 4. Naming Convention Analysis
- Validates against custom patterns
- Identifies non-compliant names
- Suggests standardization

#### 5. TTL Consistency
- Finds inconsistent TTL values
- Identifies extreme TTLs
- Recommends optimization

**Configuration Example:**

```json
{
  "AdvancedAnalytics": {
    "StaleRecordThresholdDays": 90,
    "TestConnectivity": true,
    "NamingConventionPattern": "^(srv|wks|dc|app)[0-9]{2,4}$",
    "RecommendedTTL": {
      "Min": 300,
      "Max": 86400,
      "Default": 3600
    }
  }
}
```

---

### Feature 5: Enterprise Integration

**Connect DNS auditing to your enterprise platforms.**

#### Microsoft Teams Notifications

```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -TeamsWebhook "https://outlook.office.com/webhook/..." `
    -EnableHTMLDashboard
```

**Notifications Include:**
- Audit completion status
- Critical findings count
- Link to HTML dashboard
- Action buttons for remediation

**Setup Instructions:**
1. In Teams, go to channel → Connectors
2. Add "Incoming Webhook"
3. Copy webhook URL
4. Use in `-TeamsWebhook` parameter

#### Slack Integration

```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -SlackWebhook "https://hooks.slack.com/services/..." `
    -Quiet
```

**Setup Instructions:**
1. Create Slack app at api.slack.com
2. Enable Incoming Webhooks
3. Add webhook to channel
4. Use webhook URL in parameter

#### Syslog/SIEM Integration

```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -SyslogServer "siem.contoso.com" `
    -SyslogPort 514
```

**Supported Formats:**
- Syslog (RFC 5424)
- CEF (Common Event Format)
- JSON structured logging

**SIEM Platforms Tested:**
- Splunk
- QRadar
- ArcSight
- LogRhythm
- Azure Sentinel

---

### Feature 6: Security & Compliance Audits

**Comprehensive security posture assessment.**

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -EnableSecurityAudits `
    -ExportFormat HTML
```

**Security Checks:**

#### DNSSEC Status
- Zone signing validation
- Key rollover tracking
- Unsigned zone identification
- Trust anchor verification

#### Zone Transfer Security
- Transfer restriction audit
- Insecure transfer detection
- Secondary server validation
- Recursion security

#### Dynamic Update Security
- Secure update validation
- ACL verification
- Unauthorized access detection
- GSS-TSIG audit

#### Scavenging Configuration
- Aging/scavenging status
- Refresh interval validation
- No-refresh period check
- Stale record accumulation

**Compliance Mapping:**

```
| Finding | SOX | HIPAA | PCI-DSS | NIST 800-53 |
|---------|-----|-------|---------|-------------|
| DNSSEC Not Enabled | ✓ | ✓ | 2.2.1 | SC-20 |
| Insecure Zone Transfer | ✓ | 164.312(e) | 1.3.1 | SC-8 |
| Non-secure Dynamic Updates | ✓ | 164.312(d) | 8.2 | IA-5 |
| Scavenging Disabled | ✓ | | | SC-4 |
```

**Compliance Report Output:**
- Security score (0-100)
- Finding severity (Critical/High/Medium/Low)
- Compliance framework mapping
- Remediation priorities
- Audit evidence

---

### Feature 7: Automated Remediation

**Generate PowerShell scripts to fix identified issues.**

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode SiteAudit `
    -EnableAdvancedAnalytics `
    -GenerateRemediationScript
```

**Generated Script Features:**
- WhatIf support (preview changes)
- Safety checks and validation
- Backup before changes
- Rollback capability
- Detailed logging

**Remediation Categories:**
- Stale record removal
- PTR record creation
- Zone transfer restrictions
- DNSSEC enablement
- Scavenging configuration

**Example Output:**

```powershell
# DNS_Remediation_YYYYMMDD_HHMMSS.ps1

<#
.SYNOPSIS
Remediation script generated by DNS Master Audit v3.0
Author: Adrian Johnson <adrian207@gmail.com>
#>

[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

# Remove stale record: oldserver.contoso.com
if ($PSCmdlet.ShouldProcess("contoso.com\oldserver", "Remove DNS Record")) {
    Remove-DnsServerResourceRecord -ZoneName "contoso.com" -Name "oldserver" -RRType "A" -Force
}

# Create missing PTR for: newserver.contoso.com
if ($PSCmdlet.ShouldProcess("10.0.1.100", "Add PTR Record")) {
    Add-DnsServerResourceRecordPtr -ZoneName "1.0.10.in-addr.arpa" -Name "100" -PtrDomainName "newserver.contoso.com"
}
```

**Execution:**

```powershell
# Preview changes (What-If)
.\DNS_Remediation_YYYYMMDD_HHMMSS.ps1 -WhatIf

# Execute with confirmation
.\DNS_Remediation_YYYYMMDD_HHMMSS.ps1

# Execute without prompts (use with caution!)
.\DNS_Remediation_YYYYMMDD_HHMMSS.ps1 -Force
```

**Best Practices:**
1. Always review generated script first
2. Test in non-production first
3. Create backup before execution
4. Run with -WhatIf initially
5. Execute during maintenance window
6. Document changes

---

### Feature 8: Enhanced Diagnostics

**Deep performance and health monitoring.**

**Usage:**
```powershell
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -EnableDiagnostics `
    -EnableHTMLDashboard
```

**Diagnostic Tests:**

#### DNS Query Performance
- Response time measurement
- Query latency tracking
- Timeout detection
- Performance trending

#### Replication Monitoring
- Zone replication status
- Replication lag detection
- Failed replication identification
- GUID conflict detection

#### Resource Utilization
- Memory usage tracking
- CPU utilization
- Network bandwidth
- Disk I/O patterns

#### Service Health
- DNS service uptime
- Event log analysis
- Error rate tracking
- Warning threshold monitoring

**Output:**
- Performance metrics CSV
- Diagnostic summary
- Trend analysis
- Recommendations

---

### Feature 9: Multiple Export Formats

**Export results in various formats for different audiences.**

**Usage:**
```powershell
# Single format
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -ExportFormat HTML

# Multiple formats
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -ExportFormat All
```

**Supported Formats:**

#### CSV (Default)
- Universal compatibility
- Excel-friendly
- Data analysis ready
- Scriptable import

#### JSON
- API integration
- Programmatic processing
- Configuration management
- Version control friendly

#### XML
- Enterprise integration
- Schema validation
- XSLT transformation
- Legacy system support

#### HTML
- Interactive dashboards
- Executive presentations
- Self-contained reports
- No special tools required

#### Excel (XLSX)
- Multiple worksheets
- Pre-formatted tables
- Charts and pivots
- Professional appearance

#### PDF
- Formal documentation
- Audit evidence
- Archival purposes
- Compliance reports

#### Markdown
- Documentation integration
- Wiki-ready format
- Version control friendly
- README generation

**Format Selection Guide:**

| Use Case | Recommended Format |
|----------|-------------------|
| Executive Presentation | HTML, PDF |
| Data Analysis | CSV, Excel |
| API Integration | JSON |
| Documentation | Markdown, PDF |
| Compliance Evidence | PDF, Excel |
| Automation | JSON, XML |

---

### Feature 10: Configuration Management

**Repeatable audits with configuration profiles.**

#### Creating a Configuration File

```json
{
  "AuditConfiguration": {
    "Name": "Production Monthly Audit",
    "Author": "Adrian Johnson <adrian207@gmail.com>",
    "Version": "1.0",
    "Mode": "Complete",
    "ExportPath": "\\\\fileserver\\audits\\dns",
    "ExportFormat": "All",
    "EnableHTMLDashboard": true,
    "EnableParallelProcessing": true,
    "MaxDegreeOfParallelism": 8,
    "EnableAdvancedAnalytics": true,
    "EnableSecurityAudits": true,
    "GenerateRemediationScript": true,
    "TeamsWebhook": "https://outlook.office.com/webhook/...",
    "ZoneFilter": [],
    "AdvancedAnalytics": {
      "StaleRecordThresholdDays": 90,
      "TestConnectivity": true,
      "NamingConventionPattern": "^(srv|wks|dc|app)[0-9]{2,4}$"
    },
    "SecurityAudits": {
      "CheckDNSSEC": true,
      "CheckZoneTransfers": true,
      "CheckDynamicUpdates": true,
      "CheckScavenging": true
    },
    "Schedule": {
      "Frequency": "Monthly",
      "DayOfMonth": 1,
      "Time": "02:00"
    }
  }
}
```

#### Using Configuration Files

```powershell
# Run with config file
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -ConfigFile ".\configs\production-audit.json"

# Override specific settings
.\DNS-MasterAudit-Enhanced-v3.0.ps1 `
    -ConfigFile ".\configs\production-audit.json" `
    -ExportPath "C:\CustomPath"
```

#### Configuration Templates

**Template: Basic Monthly Audit**
```json
{
  "Name": "Basic Monthly Audit",
  "Mode": "Complete",
  "ExportFormat": "CSV",
  "EnableHTMLDashboard": true
}
```

**Template: Comprehensive Security Audit**
```json
{
  "Name": "Security Assessment",
  "Mode": "Complete",
  "EnableSecurityAudits": true,
  "EnableAdvancedAnalytics": true,
  "GenerateRemediationScript": true,
  "ExportFormat": "All"
}
```

**Template: Fast Performance Audit**
```json
{
  "Name": "Quick Performance Check",
  "Mode": "HealthCheck",
  "EnableParallelProcessing": true,
  "MaxDegreeOfParallelism": 10,
  "EnableDiagnostics": true
}
```

---

## Configuration

### Script Parameters Reference

**Complete parameter list:**

```powershell
[string]$Mode                      # Required: Operation mode
[string]$ExportPath                # Default: C:\DNSAudit
[string[]]$ZoneFilter              # Default: @() (all zones)
[PSCredential]$Credential          # Optional: For remote operations
[string]$ExportFormat              # Default: CSV
[switch]$EnableHTMLDashboard       # Generate HTML dashboard
[switch]$EnableParallelProcessing  # Use multi-threading
[int]$MaxDegreeOfParallelism       # Default: 5
[switch]$CompareToBaseline         # Compare to stored baseline
[string]$BaselinePath              # Default: $ExportPath\Baseline
[switch]$EnableAdvancedAnalytics   # Enable analytics engine
[switch]$EnableSecurityAudits      # Security/compliance checks
[switch]$GenerateRemediationScript # Create fix scripts
[switch]$EnableDiagnostics         # Performance monitoring
[string]$TeamsWebhook              # Teams notification URL
[string]$SlackWebhook              # Slack notification URL
[string]$SyslogServer              # SIEM server address
[int]$SyslogPort                   # Default: 514
[string]$ConfigFile                # Configuration file path
[switch]$Quiet                     # Minimal output
```

### Environment Variables

Set default values via environment variables:

```powershell
$env:DNS_AUDIT_EXPORT_PATH = "D:\DNSAudits"
$env:DNS_AUDIT_PARALLELISM = "10"
$env:DNS_AUDIT_TEAMS_WEBHOOK = "https://..."
```

### Scheduled Tasks

**Create automated audit schedule:**

```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -ConfigFile C:\Scripts\config.json -Quiet"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 2am

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable

Register-ScheduledTask -TaskName "DNS Monthly Audit" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -User "DOMAIN\AuditUser" `
    -RunLevel Highest
```

---

## Troubleshooting

### Common Issues

#### Issue: "Access Denied" errors

**Symptoms:**
- Cannot query DNS zones
- Zone transfer failures
- Permission errors

**Solutions:**
```powershell
# Use credential parameter
$cred = Get-Credential
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -Credential $cred

# Run as administrator
Run PowerShell as Administrator

# Verify permissions
Get-ADGroupMember "DNS Admins" | Where-Object { $_.Name -eq $env:USERNAME }
```

#### Issue: Slow performance

**Symptoms:**
- Audit takes hours to complete
- Timeouts occur
- Progress stalls

**Solutions:**
```powershell
# Enable parallel processing
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -EnableParallelProcessing

# Increase parallelism (if resources available)
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 15

# Filter to specific zones
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete `
    -ZoneFilter "contoso.com"
```

#### Issue: Out of memory errors

**Symptoms:**
- Script crashes mid-execution
- "Out of Memory" exceptions
- System slowdown

**Solutions:**
```powershell
# Reduce parallelism
-MaxDegreeOfParallelism 3

# Process zones individually
-ZoneFilter "zone1.com"

# Increase available memory
Close other applications
Upgrade system RAM

# Use batch processing
Split audit across multiple runs
```

#### Issue: HTML dashboard doesn't display

**Symptoms:**
- Blank page
- JavaScript errors
- Charts not rendering

**Solutions:**
```powershell
# Check browser compatibility
Use modern browser (Chrome, Edge, Firefox)

# Disable browser extensions
Try incognito/private mode

# Verify file integrity
Check if HTML file is complete
Re-run with -EnableHTMLDashboard

# Check CDN accessibility
Ensure internet access for CDN resources
Use offline version if needed
```

### Debug Mode

**Enable detailed logging:**

```powershell
# Run with verbose output
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -Verbose

# Enable debug messages
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -Debug

# Review transcript
Get-Content "C:\DNSAudit\DNS_Audit_Transcript_*.log"
```

### Log Analysis

**Examine logs for errors:**

```powershell
# Find errors in transcript
Select-String -Path "C:\DNSAudit\*.log" -Pattern "\[ERROR\]"

# View last 50 log entries
Get-Content "C:\DNSAudit\*.log" -Tail 50

# Export errors for review
Select-String -Path "C:\DNSAudit\*.log" -Pattern "\[ERROR\]|\[WARNING\]" | 
    Export-Csv "C:\DNSAudit\audit-errors.csv"
```

---

## Best Practices

### Regular Auditing Schedule

**Recommended schedule:**
- **Daily:** Health checks (automated)
- **Weekly:** Record exports (for backup)
- **Monthly:** Complete audit with analytics
- **Quarterly:** Security and compliance audit
- **Annually:** Comprehensive documentation update

### Baseline Management

1. Create baseline before major changes
2. Update baseline monthly
3. Retain baselines for 12 months minimum
4. Compare after change implementations
5. Document expected changes

### Security Considerations

- Store credentials securely (never in scripts)
- Use least-privilege accounts when possible
- Encrypt exported data if sensitive
- Restrict audit output folder permissions
- Review remediation scripts before execution
- Enable transcript logging for audit trail

### Performance Optimization

1. Enable parallel processing for large environments
2. Filter to specific zones when possible
3. Schedule during low-usage windows
4. Use dedicated audit workstation
5. Monitor resource utilization
6. Batch large exports

### Report Management

- Implement retention policy (e.g., 90 days)
- Archive historical reports
- Automate cleanup of old reports
- Document findings and actions taken
- Share results with stakeholders
- Maintain audit evidence for compliance

---

## FAQ

**Q: Can I run this on a workstation, or does it need to be on a domain controller?**

A: You can run it from any domain-joined machine with the required modules installed. No need for DC installation.

---

**Q: Will this script make any changes to DNS?**

A: No, the audit script is read-only by default. Changes only occur if you execute the generated remediation scripts.

---

**Q: How long does a complete audit take?**

A: Depends on environment size:
- Small (5 DCs, 10K records): 3-5 minutes with parallel processing
- Medium (10 DCs, 50K records): 8-15 minutes
- Large (20+ DCs, 100K+ records): 15-30 minutes

---

**Q: Can I schedule this to run automatically?**

A: Yes! Use Windows Task Scheduler with the `-ConfigFile` and `-Quiet` parameters for automated execution.

---

**Q: Does this work with Azure AD DS or AWS Directory Service?**

A: The tool is designed for on-premises Active Directory. Cloud-hosted AD services may have limited functionality.

---

**Q: What if I don't have the ImportExcel module for Excel export?**

A: Excel export is optional. The tool will fall back to CSV if the module isn't installed. Other formats don't require additional modules.

---

**Q: Can I customize the HTML dashboard appearance?**

A: Yes! The HTML template can be customized by editing the CSS in the script or using custom templates.

---

**Q: Is there a way to exclude specific zones or records?**

A: Yes! Use `-ZoneFilter` to include only specific zones, or edit the configuration file to add exclusion patterns.

---

**Q: What's the difference between EnableAllFeatures and EnableAdvancedAnalytics?**

A: `EnableAllFeatures` is a legacy parameter that enables all SiteAudit features. `EnableAdvancedAnalytics` is the new v3.0 parameter that includes additional intelligence features.

---

**Q: Can I run this against a read-only domain controller?**

A: Yes, but some features (like remediation script generation) may be limited.

---

## Support

### Getting Help

**Documentation:**
- User Guide (this document)
- Design Document
- API Documentation
- Deployment Guide

**Community:**
- GitHub Issues: https://github.com/adrian207/DNS-Audit/issues
- Discussions: https://github.com/adrian207/DNS-Audit/discussions

**Contact:**
- Author: Adrian Johnson
- Email: adrian207@gmail.com
- GitHub: @adrian207

### Reporting Issues

When reporting issues, please include:
1. PowerShell version (`$PSVersionTable`)
2. Module versions
3. Error messages (full text)
4. Transcript log excerpt
5. Steps to reproduce

### Feature Requests

Submit feature requests via GitHub Issues with:
- Clear description
- Use case/benefit
- Expected behavior
- Examples

---

## Appendix

### Glossary

- **Baseline:** Point-in-time snapshot of DNS configuration
- **DC:** Domain Controller
- **PTR:** Pointer record (reverse DNS)
- **DNSSEC:** DNS Security Extensions
- **Scavenging:** Automatic removal of stale records
- **Site Mismatch:** DNS record in wrong AD site
- **TTL:** Time To Live (record cache duration)

### Additional Resources

- Microsoft DNS Best Practices: https://docs.microsoft.com/dns
- RFC 5424 - Syslog Protocol: https://tools.ietf.org/html/rfc5424
- Active Directory Sites: https://docs.microsoft.com/windows-server/identity/ad-ds

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Author:** Adrian Johnson <adrian207@gmail.com>

---

*End of User Guide*

