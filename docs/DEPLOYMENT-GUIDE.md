# DNS Master Audit v3.0 - Deployment Guide

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Enterprise Deployment & Operations Guide**

---

## Table of Contents

1. [Deployment Overview](#deployment-overview)
2. [Pre-Deployment Planning](#pre-deployment-planning)
3. [Installation Methods](#installation-methods)
4. [Configuration](#configuration)
5. [Automation & Scheduling](#automation--scheduling)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Security Hardening](#security-hardening)
8. [Scaling Considerations](#scaling-considerations)

---

## Deployment Overview

### Deployment Models

#### Model 1: Standalone Workstation
- **Use Case:** Small environments (<10 DCs)
- **Requirements:** Domain-joined workstation
- **Effort:** Low
- **Automation:** Manual or Task Scheduler

#### Model 2: Dedicated Audit Server
- **Use Case:** Medium environments (10-50 DCs)
- **Requirements:** Dedicated VM
- **Effort:** Medium
- **Automation:** Task Scheduler + monitoring

#### Model 3: Enterprise Integration
- **Use Case:** Large environments (50+ DCs)
- **Requirements:** Automation platform integration
- **Effort:** High
- **Automation:** Jenkins/Azure Automation/SCCM

---

## Pre-Deployment Planning

### Infrastructure Assessment

**Inventory Requirements:**
```powershell
# Count domain controllers
(Get-ADDomainController -Filter *).Count

# Estimate DNS zones
(Get-DnsServerZone).Count

# Estimate DNS records (sample zone)
(Get-DnsServerResourceRecord -ZoneName "contoso.com").Count
```

**Sizing Guide:**

| Environment Size | DCs | Zones | Records | CPU | RAM | Disk |
|-----------------|-----|-------|---------|-----|-----|------|
| Small | 1-5 | 1-10 | <10K | 2 vCPU | 4 GB | 20 GB |
| Medium | 6-20 | 11-50 | 10K-100K | 4 vCPU | 8 GB | 50 GB |
| Large | 21-50 | 51-200 | 100K-500K | 8 vCPU | 16 GB | 100 GB |
| Enterprise | 50+ | 200+ | 500K+ | 16 vCPU | 32 GB | 200 GB |

### Network Requirements

**Firewall Rules:**
- **DNS:** Port 53 (TCP/UDP) - Outbound to DCs
- **WinRM:** Port 5985/5986 - For remote PowerShell
- **AD:** Port 389/636 (LDAP/LDAPS)
- **Notifications:** Port 443 (HTTPS) - For Teams/Slack webhooks
- **Syslog:** Port 514 (UDP) - For SIEM integration

**Bandwidth Estimate:**
- Small environment: 10 Mbps
- Medium environment: 50 Mbps
- Large environment: 100+ Mbps

---

## Installation Methods

### Method 1: Manual Installation

```powershell
# 1. Create directory structure
New-Item -Path "C:\DNSAudit" -ItemType Directory
New-Item -Path "C:\DNSAudit\Configs" -ItemType Directory
New-Item -Path "C:\DNSAudit\Logs" -ItemType Directory
New-Item -Path "C:\DNSAudit\Reports" -ItemType Directory
New-Item -Path "C:\DNSAudit\Baselines" -ItemType Directory

# 2. Download script
$scriptUrl = "https://github.com/adrian207/DNS-Audit/releases/latest/DNS-MasterAudit-Enhanced-v3.0.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile "C:\DNSAudit\DNS-MasterAudit.ps1"

# 3. Unblock
Unblock-File "C:\DNSAudit\DNS-MasterAudit.ps1"

# 4. Verify modules
Install-WindowsFeature RSAT-AD-PowerShell, RSAT-DNS-Server

# 5. Test run
C:\DNSAudit\DNS-MasterAudit.ps1 -Mode Inventory -ExportPath "C:\DNSAudit\Reports"
```

### Method 2: Automated Deployment (GPO)

```powershell
# Create deployment package
$deployScript = @"
# DNS Audit Deployment Script
`$targetPath = "C:\Program Files\DNSAudit"
if (!(Test-Path `$targetPath)) {
    New-Item -Path `$targetPath -ItemType Directory -Force
}

# Copy files from network share
Copy-Item "\\\\fileserver\\software\\DNSAudit\\*" -Destination `$targetPath -Recurse -Force

# Create scheduled task
# (See Automation section)
"@

$deployScript | Out-File "\\fileserver\NETLOGON\Deploy-DNSAudit.ps1"

# Create GPO startup script
# Group Policy → Computer Configuration → Scripts → Startup
# Add: \\fileserver\NETLOGON\Deploy-DNSAudit.ps1
```

### Method 3: Configuration Management (SCCM/Intune)

```powershell
# SCCM Package
# 1. Create application in SCCM console
# 2. Add detection method: File exists C:\Program Files\DNSAudit\DNS-MasterAudit.ps1
# 3. Install command: PowerShell.exe -ExecutionPolicy Bypass -File Deploy-DNSAudit.ps1
# 4. Deploy to collection

# Intune Package
# 1. Create Win32 app
# 2. Upload intunewin package
# 3. Set detection: Registry/File/Script
# 4. Assign to group
```

---

## Configuration

### Configuration File Template

Create `production-config.json`:

```json
{
  "AuditConfiguration": {
    "Name": "Production DNS Audit",
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
    "TeamsWebhook": "${ENV:TEAMS_WEBHOOK}",
    "SyslogServer": "siem.contoso.com",
    "SyslogPort": 514,
    "ZoneFilter": [],
    "AdvancedAnalytics": {
      "StaleRecordThresholdDays": 90,
      "TestConnectivity": false,
      "NamingConventionPattern": "^(srv|wks|dc|app)[0-9]{2,4}$",
      "RecommendedTTL": {
        "Min": 300,
        "Max": 86400,
        "Default": 3600
      }
    },
    "SecurityAudits": {
      "CheckDNSSEC": true,
      "CheckZoneTransfers": true,
      "CheckDynamicUpdates": true,
      "CheckScavenging": true,
      "ComplianceFrameworks": ["PCI-DSS", "HIPAA", "SOX"]
    },
    "Notifications": {
      "SendOnCompletion": true,
      "SendOnErrors": true,
      "SendOnCriticalFindings": true,
      "Recipients": ["dns-team@contoso.com"]
    },
    "Retention": {
      "KeepReportsDays": 90,
      "KeepBaselinesDays": 365,
      "ArchiveLocation": "\\\\fileserver\\archives\\dns"
    }
  }
}
```

### Environment-Specific Configurations

**Development:**
```json
{
  "Name": "Dev DNS Audit",
  "MaxDegreeOfParallelism": 15,
  "TestConnectivity": true,
  "ZoneFilter": ["dev.contoso.com"]
}
```

**Production:**
```json
{
  "Name": "Prod DNS Audit",
  "MaxDegreeOfParallelism": 8,
  "EnableAllSecurityFeatures": true,
  "SendNotifications": true,
  "RequireApprovalForRemediation": true
}
```

---

## Automation & Scheduling

### Task Scheduler Setup

```powershell
# Create service account
$user = "CONTOSO\svc-dnsaudit"
$credPath = "C:\DNSAudit\Configs\service-cred.xml"

# Store credential (one-time, run interactively)
Get-Credential $user | Export-Clixml $credPath

# Create scheduled task
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -File C:\DNSAudit\DNS-MasterAudit.ps1 -ConfigFile C:\DNSAudit\Configs\production-config.json -Quiet"

# Monthly trigger (1st of month, 2 AM)
$trigger = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek Monday `
    -At 2am

# Settings
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 4)

# Register task
$principal = New-ScheduledTaskPrincipal `
    -UserId $user `
    -LogonType Password `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName "DNS Master Audit - Monthly" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Monthly comprehensive DNS audit"
```

### Multiple Schedule Examples

```powershell
# Daily health check (6 AM)
$dailyTrigger = New-ScheduledTaskTrigger -Daily -At 6am
$dailyAction = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-File C:\DNSAudit\DNS-MasterAudit.ps1 -Mode HealthCheck -Quiet"

Register-ScheduledTask -TaskName "DNS Health Check - Daily" `
    -Action $dailyAction -Trigger $dailyTrigger -Settings $settings -Principal $principal

# Weekly record export (Sunday, 1 AM)
$weeklyTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 1am
$weeklyAction = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-File C:\DNSAudit\DNS-MasterAudit.ps1 -Mode RecordExport -EnableParallelProcessing -Quiet"

Register-ScheduledTask -TaskName "DNS Record Export - Weekly" `
    -Action $weeklyAction -Trigger $weeklyTrigger -Settings $settings -Principal $principal

# Quarterly security audit (1st Jan/Apr/Jul/Oct, 3 AM)
# Use multiple triggers for quarterly
$q1 = New-ScheduledTaskTrigger -Once -At "2025-01-01T03:00:00" -RepetitionInterval (New-TimeSpan -Days 90)
$quarterlyAction = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-File C:\DNSAudit\DNS-MasterAudit.ps1 -Mode Complete -EnableSecurityAudits -EnableAdvancedAnalytics -GenerateRemediationScript -ExportFormat All -Quiet"

Register-ScheduledTask -TaskName "DNS Security Audit - Quarterly" `
    -Action $quarterlyAction -Trigger $q1 -Settings $settings -Principal $principal
```

### Jenkins Integration

**Jenkinsfile:**
```groovy
pipeline {
    agent any
    
    parameters {
        choice(name: 'MODE', choices: ['Complete', 'HealthCheck', 'SiteAudit'], description: 'Audit Mode')
        booleanParam(name: 'PARALLEL', defaultValue: true, description: 'Enable Parallel Processing')
    }
    
    stages {
        stage('DNS Audit') {
            steps {
                script {
                    powershell """
                        C:\\DNSAudit\\DNS-MasterAudit.ps1 `
                            -Mode ${params.MODE} `
                            -EnableHTMLDashboard `
                            -EnableParallelProcessing:\$${params.PARALLEL} `
                            -ExportPath "C:\\Jenkins\\workspace\\dns-audit\\reports" `
                            -Quiet
                    """
                }
            }
        }
        
        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: false
                publishHTML([
                    reportDir: 'reports',
                    reportFiles: 'DNS_Dashboard_*.html',
                    reportName: 'DNS Audit Dashboard'
                ])
            }
        }
        
        stage('Notify') {
            steps {
                emailext (
                    to: 'dns-team@contoso.com',
                    subject: "DNS Audit Complete - ${params.MODE}",
                    body: "DNS audit completed. View dashboard: ${BUILD_URL}DNS_20Audit_20Dashboard/",
                    attachmentsPattern: 'reports/*.csv'
                )
            }
        }
    }
}
```

### Azure Automation

**Runbook:**
```powershell
# Azure Automation Runbook
param(
    [string]$Mode = "Complete",
    [bool]$EnableParallelProcessing = $true
)

# Connect to Azure
$connectionName = "AzureRunAsConnection"
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

# Get audit credential from Azure Key Vault
$cred = Get-AutomationPSCredential -Name 'DNSAuditCredential'

# Run audit
C:\Automation\DNS-MasterAudit.ps1 `
    -Mode $Mode `
    -EnableHTMLDashboard `
    -EnableParallelProcessing:$EnableParallelProcessing `
    -Credential $cred `
    -ExportPath "D:\Audits\DNS" `
    -TeamsWebhook $env:TEAMS_WEBHOOK `
    -Quiet

# Upload to Azure Blob Storage
$storageAccount = Get-AzStorageAccount -ResourceGroupName "RG-DNS-Audit" -Name "dnsauditstg"
$ctx = $storageAccount.Context

Get-ChildItem "D:\Audits\DNS\*.html" | ForEach-Object {
    Set-AzStorageBlobContent -File $_.FullName -Container "audit-reports" -Blob $_.Name -Context $ctx
}
```

---

## Monitoring & Maintenance

### Health Monitoring Script

```powershell
# Monitor-DNSAuditHealth.ps1
# Run this daily to ensure audit system is healthy

$auditPath = "C:\DNSAudit"
$maxAge = 7 # days

# Check last successful audit
$latestReport = Get-ChildItem "$auditPath\Reports\DNS_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!$latestReport) {
    Write-Warning "No audit reports found!"
    # Send alert
}
elseif ((Get-Date) - $latestReport.LastWriteTime -gt (New-TimeSpan -Days $maxAge)) {
    Write-Warning "Last audit is $((Get-Date) - $latestReport.LastWriteTime).Days days old!"
    # Send alert
}
else {
    Write-Host "Last audit: $($latestReport.LastWriteTime) - OK" -ForegroundColor Green
}

# Check scheduled task
$task = Get-ScheduledTask -TaskName "DNS Master Audit*" -ErrorAction SilentlyContinue

if (!$task) {
    Write-Warning "Scheduled task not found!"
}
elseif ($task.State -ne "Ready") {
    Write-Warning "Scheduled task in state: $($task.State)"
}
else {
    Write-Host "Scheduled task: $($task.State) - OK" -ForegroundColor Green
}

# Check disk space
$drive = Get-PSDrive C
$freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)

if ($freeSpaceGB -lt 10) {
    Write-Warning "Low disk space: ${freeSpaceGB} GB free"
}
else {
    Write-Host "Disk space: ${freeSpaceGB} GB free - OK" -ForegroundColor Green
}

# Check service account
$task = Get-ScheduledTask -TaskName "DNS Master Audit - Monthly"
$principal = $task.Principal
Write-Host "Service account: $($principal.UserId)" -ForegroundColor Cyan

# Test account password
$user = $principal.UserId
# Note: Can't directly test, but can check last password change in AD
```

### Retention Management

```powershell
# Cleanup-OldAudits.ps1
# Run weekly to manage storage

$reportsPath = "C:\DNSAudit\Reports"
$retentionDays = 90
$archivePath = "\\fileserver\archives\dns"

# Archive old reports
$oldReports = Get-ChildItem $reportsPath -Recurse | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) -and $_.LastWriteTime -gt (Get-Date).AddDays(-$retentionDays) }

foreach ($report in $oldReports) {
    $archiveFile = Join-Path $archivePath $report.Name
    Move-Item $report.FullName $archiveFile -Force
}

Write-Host "Archived $($oldReports.Count) reports"

# Delete very old reports
$veryOldReports = Get-ChildItem $reportsPath -Recurse | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retentionDays) }

foreach ($report in $veryOldReports) {
    Remove-Item $report.FullName -Force
}

Write-Host "Deleted $($veryOldReports.Count) old reports"

# Clean up baselines (keep yearly snapshots)
$baselinesPath = "C:\DNSAudit\Baselines"
$baselines = Get-ChildItem $baselinesPath | Sort-Object LastWriteTime -Descending

# Keep: Last 12 monthly + 1 yearly snapshot
$keepBaselines = $baselines | Select-Object -First 12
$keepBaselines += $baselines | Where-Object { $_.LastWriteTime.Month -eq 1 }

$baselines | Where-Object { $_ -notin $keepBaselines } | Remove-Item -Force
```

---

## Security Hardening

### Service Account Setup

```powershell
# Create dedicated service account
New-ADUser -Name "DNS Audit Service" `
    -SamAccountName "svc-dnsaudit" `
    -UserPrincipalName "svc-dnsaudit@contoso.com" `
    -Description "Service account for DNS Master Audit" `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -Enabled $true

# Add to required groups
Add-ADGroupMember -Identity "DNS Admins" -Members "svc-dnsaudit"

# Grant specific permissions (least privilege)
# Grant read-only access to DNS zones
# Grant read access to AD Sites and Services
```

### Secure Credential Storage

```powershell
# Never store passwords in plain text!

# Option 1: Windows Credential Manager
cmdkey /add:DNSAudit /user:CONTOSO\svc-dnsaudit /pass

# Option 2: Encrypted XML
$cred = Get-Credential
$cred | Export-Clixml -Path "C:\DNSAudit\Configs\cred.xml"

# Option 3: Azure Key Vault (recommended for Azure environments)
$secret = ConvertTo-SecureString $password -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName "audit-vault" -Name "dns-audit-cred" -SecretValue $secret

# Use in script
$secretValue = Get-AzKeyVaultSecret -VaultName "audit-vault" -Name "dns-audit-cred"
$cred = New-Object PSCredential("CONTOSO\svc-dnsaudit", $secretValue.SecretValue)
```

### File System Permissions

```powershell
# Secure audit directory
$auditPath = "C:\DNSAudit"

# Remove inherited permissions
$acl = Get-Acl $auditPath
$acl.SetAccessRuleProtection($true, $false)

# Add specific permissions
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$serviceRule = New-Object System.Security.AccessControl.FileSystemAccessRule("CONTOSO\svc-dnsaudit", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")

$acl.AddAccessRule($adminRule)
$acl.AddAccessRule($serviceRule)

Set-Acl $auditPath $acl
```

### Network Security

```powershell
# Restrict script execution to specific hosts
$allowedHosts = @("AUDIT-SERVER01", "AUDIT-SERVER02")

if ($env:COMPUTERNAME -notin $allowedHosts) {
    Write-Error "This script can only run on approved audit servers"
    exit 1
}

# Verify domain membership
if ((Get-WmiObject Win32_ComputerSystem).PartOfDomain -eq $false) {
    Write-Error "This script must run on domain-joined machine"
    exit 1
}

# Check execution policy
if ((Get-ExecutionPolicy) -eq "Unrestricted") {
    Write-Warning "Unrestricted execution policy detected - security risk!"
}
```

---

## Scaling Considerations

### Large Environment Optimization

**For environments with 50+ DCs or 500K+ records:**

```powershell
# 1. Enable all performance features
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 15 `
    -ExportPath "E:\FastDrive\DNSAudit"

# 2. Zone-based splitting (process in batches)
$zones = Get-DnsServerZone | Select-Object -ExpandProperty ZoneName
$batchSize = 10

for ($i = 0; $i -lt $zones.Count; $i += $batchSize) {
    $batch = $zones[$i..([Math]::Min($i + $batchSize - 1, $zones.Count - 1))]
    
    .\DNS-MasterAudit.ps1 -Mode RecordExport `
        -ZoneFilter $batch `
        -ExportPath "E:\DNSAudit\Batch$($i/$batchSize)"
}

# 3. Distributed execution (multiple audit servers)
# Run different modes on different servers simultaneously
# Server 1: Inventory + HealthCheck
# Server 2: RecordExport (zones 1-50)
# Server 3: RecordExport (zones 51-100)
# Server 4: SiteAudit

# 4. Use SSD for export path
# Move $ExportPath to SSD for faster I/O

# 5. Increase memory allocation
# Ensure audit server has adequate RAM
# Consider scaling up VM if virtualized
```

### Multi-Forest Support

```powershell
# Audit multiple forests
$forests = @("contoso.com", "fabrikam.com", "northwind.com")

foreach ($forest in $forests) {
    $cred = Get-Credential -Message "Enter credentials for $forest"
    
    .\DNS-MasterAudit.ps1 -Mode Complete `
        -Credential $cred `
        -ExportPath "C:\DNSAudit\$forest" `
        -EnableHTMLDashboard
}
```

---

## Rollback Procedures

### Restore from Backup

If audit script causes issues (should be read-only):

```powershell
# 1. Stop scheduled tasks
Disable-ScheduledTask -TaskName "DNS Master Audit*"

# 2. Restore previous version
Copy-Item "\\fileserver\backup\DNS-MasterAudit-v2.0.ps1" -Destination "C:\DNSAudit\DNS-MasterAudit.ps1" -Force

# 3. Restore configuration
Copy-Item "\\fileserver\backup\configs\*.json" -Destination "C:\DNSAudit\Configs\" -Force

# 4. Test
C:\DNSAudit\DNS-MasterAudit.ps1 -Mode Inventory -WhatIf

# 5. Re-enable tasks
Enable-ScheduledTask -TaskName "DNS Master Audit*"
```

---

## Upgrade Procedures

### Upgrading to v3.0

```powershell
# 1. Backup current installation
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item "C:\DNSAudit" -Destination "C:\DNSAudit_Backup_$timestamp" -Recurse

# 2. Download new version
Invoke-WebRequest -Uri "https://github.com/adrian207/DNS-Audit/releases/v3.0/DNS-MasterAudit-Enhanced-v3.0.ps1" `
    -OutFile "C:\DNSAudit\DNS-MasterAudit-v3.0.ps1"

# 3. Test new version
C:\DNSAudit\DNS-MasterAudit-v3.0.ps1 -Mode Inventory -WhatIf

# 4. Update configuration files
# Review and update configs for new parameters

# 5. Update scheduled tasks
# Modify tasks to use new script path

# 6. Verify
C:\DNSAudit\DNS-MasterAudit-v3.0.ps1 -Mode HealthCheck

# 7. Remove old version (after validation)
Remove-Item "C:\DNSAudit\DNS-MasterAudit.ps1"
Rename-Item "C:\DNSAudit\DNS-MasterAudit-v3.0.ps1" "DNS-MasterAudit.ps1"
```

---

## Support & Maintenance

### Change Log

Keep detailed change log:

```markdown
# DNS Audit Change Log

## 2025-01-15 - Initial Deployment
- Deployed v3.0 to AUDIT-SERVER01
- Created service account svc-dnsaudit
- Configured monthly scheduled task
- Integrated Teams notifications

## 2025-02-01 - Configuration Update
- Updated parallel processing to 10 threads
- Added zone filters for dev environment
- Enabled advanced analytics

## 2025-03-01 - Scaling Update
- Migrated to dedicated audit server
- Increased resources to 8 vCPU, 16 GB RAM
- Enabled all enterprise features
```

### Documentation

Maintain local documentation:
- Deployment diagram
- Network diagram
- Configuration file versions
- Service account details (not passwords!)
- Escalation contacts
- Troubleshooting runbook

---

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Version:** 1.0  
**Last Updated:** January 2025

---

*End of Deployment Guide*

