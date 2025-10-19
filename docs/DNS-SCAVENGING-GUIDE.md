# DNS Scavenging Manager - Quick Reference Guide

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Version:** 1.0

---

## 🎯 Overview

The DNS Scavenging Manager helps you analyze and configure DNS scavenging settings across your entire DNS infrastructure following Microsoft best practices (or with custom intervals like the aggressive 3-day option).

---

## ⚡ Quick Start

### 1. Analyze Current Configuration

```powershell
.\DNS-ScavengingManager.ps1 -Mode Analyze
```

This will show you:
- Which servers have scavenging enabled/disabled
- Which zones have aging enabled/disabled
- Current scavenging intervals
- Issues requiring attention

### 2. Apply 3-Day Aggressive Scavenging (Your Request)

```powershell
# Preview first (recommended)
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -WhatIf

# Apply for real
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -Force
```

### 3. Apply Microsoft Best Practice (7+7 days)

```powershell
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 7 `
    -RefreshInterval 7 `
    -ApplyToAllZones `
    -EnableServerScavenging
```

---

## 📋 Understanding Scavenging Intervals

### Microsoft Best Practice (Default)
- **No-Refresh:** 7 days
- **Refresh:** 7 days
- **Total:** 14 days
- **Best for:** Most environments, balanced cleanup

### Aggressive Cleanup (Your Preference)
- **No-Refresh:** 3 days
- **Refresh:** 3 days
- **Total:** 6 days
- **Best for:** Highly dynamic environments
- **⚠ Caution:** May remove valid records if systems are offline >6 days

### Conservative Cleanup
- **No-Refresh:** 14 days
- **Refresh:** 14 days
- **Total:** 28 days
- **Best for:** Stable environments with long-lived systems

---

## 🔍 How Scavenging Works

```
┌─────────────────────────────────────────────────────────────┐
│                   DNS Record Lifecycle                      │
└─────────────────────────────────────────────────────────────┘

Record Created/Updated (timestamp set)
        │
        ├─► NO-REFRESH INTERVAL (3 or 7 days)
        │   └─► Record cannot be refreshed (timestamp frozen)
        │
        ├─► REFRESH INTERVAL (3 or 7 days)
        │   └─► Record can be refreshed (timestamp updated if accessed)
        │
        └─► SCAVENGING
            └─► If not refreshed, record is deleted
```

**Example with 3+3 days:**
1. Day 0: Record created with timestamp
2. Days 0-3: No-refresh period (locked)
3. Days 3-6: Refresh period (can be updated)
4. Day 6+: If not refreshed, eligible for deletion

---

## 📊 Complete Command Reference

### Mode: Analyze
```powershell
# Basic analysis
.\DNS-ScavengingManager.ps1 -Mode Analyze

# With credentials
.\DNS-ScavengingManager.ps1 -Mode Analyze -Credential (Get-Credential)

# Custom export path
.\DNS-ScavengingManager.ps1 -Mode Analyze -ExportPath "D:\DNSReports"
```

### Mode: Report
```powershell
# Generate detailed CSV reports
.\DNS-ScavengingManager.ps1 -Mode Report

# Reports created:
# - ScavengingAnalysis_TIMESTAMP.csv
# - ScavengingIssues_TIMESTAMP.csv
# - ServerScavengingSettings_TIMESTAMP.csv
```

### Mode: GenerateScript
```powershell
# Create remediation script for manual execution
.\DNS-ScavengingManager.ps1 -Mode GenerateScript `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging

# Review the generated script before running
```

### Mode: Configure
```powershell
# Apply 3-day aggressive scavenging
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -Force

# Apply with zone exclusions
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -ExcludeZones "contoso.com","corp.local" `
    -EnableServerScavenging

# Apply only to servers (not zones)
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -EnableServerScavenging `
    -ScavengingInterval 168

# WhatIf mode (preview only)
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -WhatIf
```

---

## 🛡️ Safety Features

### 1. WhatIf Support
```powershell
# Preview changes without applying
-WhatIf
```

### 2. Confirmation Prompts
```powershell
# Interactive confirmation (default)
# Use -Force to skip
```

### 3. Zone Exclusions
```powershell
# Exclude specific zones
-ExcludeZones "zone1.com","zone2.com"
```

### 4. Detailed Logging
```powershell
# All actions logged to:
# C:\DNSScavenging\ScavengingManager_TIMESTAMP.log
# C:\DNSScavenging\Transcript_TIMESTAMP.log
```

---

## 📈 Monitoring After Configuration

### 1. Check Event Viewer

```powershell
# View scavenging events on DNS server
Get-WinEvent -LogName "DNS Server" | 
    Where-Object { $_.Id -in 2501,2502,2503,2504 } |
    Format-Table TimeCreated, Id, Message -AutoSize
```

**Event IDs:**
- **2501:** Scavenging cycle started
- **2502:** Scavenging cycle completed (shows records deleted)
- **2503:** Scavenging cycle failed
- **2504:** Aging/scavenging enabled on zone

### 2. Verify Configuration

```powershell
# Re-run analysis to confirm settings
.\DNS-ScavengingManager.ps1 -Mode Analyze
```

### 3. Monitor DNS Records

```powershell
# Check for unexpected deletions
Get-DnsServerResourceRecord -ZoneName "contoso.com" | 
    Where-Object { $_.TimeStamp -gt (Get-Date).AddDays(-1) }
```

---

## ⚙️ All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Mode** | String | Required | Analyze, Configure, Report, GenerateScript |
| **NoRefreshInterval** | Int | 7 | No-refresh period in days (1-365) |
| **RefreshInterval** | Int | 7 | Refresh period in days (1-365) |
| **ApplyToAllZones** | Switch | False | Apply settings to all AD-integrated zones |
| **ExcludeZones** | String[] | @() | Zones to exclude from configuration |
| **EnableServerScavenging** | Switch | False | Enable automatic scavenging on DNS servers |
| **ScavengingInterval** | Int | 168 | Server scavenging interval in hours (default: 7 days) |
| **ExportPath** | String | C:\DNSScavenging | Directory for reports and logs |
| **Credential** | PSCredential | None | Credential for remote operations |
| **WhatIf** | Switch | False | Preview changes without applying |
| **Force** | Switch | False | Skip confirmation prompts |

---

## 🎯 Common Scenarios

### Scenario 1: First-Time Setup

```powershell
# Step 1: Analyze current state
.\DNS-ScavengingManager.ps1 -Mode Analyze

# Step 2: Generate and review script
.\DNS-ScavengingManager.ps1 -Mode GenerateScript `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging

# Step 3: Test with WhatIf
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -WhatIf

# Step 4: Apply to test zone first
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -ExcludeZones "prod.com","contoso.com" `
    -EnableServerScavenging

# Step 5: Monitor for 24-48 hours

# Step 6: Apply to all zones
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -Force
```

### Scenario 2: Change from 7+7 to 3+3

```powershell
# Current: Microsoft best practice (7+7)
# Target: Aggressive cleanup (3+3)

# Apply new intervals
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -Force

# Note: Already-timestamped records will be evaluated 
# against new intervals on next scavenging cycle
```

### Scenario 3: Enable Scavenging on New Zone

```powershell
# Option A: Apply to all zones (includes new ones)
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones

# Option B: Manual for specific zone
Set-DnsServerZoneAging -Name "newzone.com" `
    -Aging $true `
    -NoRefreshInterval 3.0:0:0 `
    -RefreshInterval 3.0:0:0
```

### Scenario 4: Audit and Report for Compliance

```powershell
# Generate comprehensive report
.\DNS-ScavengingManager.ps1 -Mode Report

# Review reports:
# - ScavengingAnalysis_TIMESTAMP.csv (all zones)
# - ScavengingIssues_TIMESTAMP.csv (non-compliant items)
# - ServerScavengingSettings_TIMESTAMP.csv (server config)
```

---

## ⚠️ Important Considerations

### Before Implementing 3+3 Days

✅ **Do This:**
- Test in non-production first
- Ensure systems register DNS every 1-2 days
- Monitor for 1-2 weeks in test environment
- Document expected record counts
- Brief support team on changes

❌ **Avoid:**
- Implementing during change freeze
- Applying to production without testing
- Skipping monitoring period
- Using on zones with static critical records
- Applying without stakeholder approval

### Signs Your Interval is Too Aggressive

🚨 **Warning Signs:**
- Valid records being deleted
- Users reporting name resolution failures
- Systems can't rejoin domain
- DHCP clients losing DNS entries
- Event ID 2503 (scavenging failures)

**Solution:** Increase intervals back to 7+7 days

### When 3+3 Days Works Well

✅ **Good Fit:**
- DHCP-based environments
- VDI/virtual desktop pools
- Container/kubernetes clusters
- Dev/test environments
- Environments with frequent IP changes

---

## 🔧 Troubleshooting

### Issue: Scavenging Not Running

**Check:**
```powershell
# Verify server scavenging enabled
Get-DnsServer | Select-Object ServerScavenging

# Check zone aging
Get-DnsServerZone | Select-Object ZoneName, Aging, *Interval*

# Review event log
Get-WinEvent -LogName "DNS Server" -MaxEvents 50
```

### Issue: Valid Records Being Deleted

**Fix:**
```powershell
# Increase intervals immediately
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 7 `
    -RefreshInterval 7 `
    -ApplyToAllZones `
    -Force

# Exclude affected zones
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -ExcludeZones "affected-zone.com" `
    -ApplyToAllZones
```

### Issue: Configuration Not Applied

**Solutions:**
```powershell
# Check permissions
# Requires: DNS Admins or equivalent

# Verify connectivity
Test-NetConnection -ComputerName DC01 -Port 53

# Check credentials
$cred = Get-Credential
.\DNS-ScavengingManager.ps1 -Mode Analyze -Credential $cred

# Review transcript log
Get-Content C:\DNSScavenging\Transcript_*.log
```

---

## 📞 Support

**Author:** Adrian Johnson  
**Email:** adrian207@gmail.com  
**GitHub:** https://github.com/adrian207/DNS-Audit

---

## 📚 Additional Resources

- [Microsoft DNS Scavenging Best Practices](https://docs.microsoft.com/windows-server/networking/dns/manage-dns-scavenging)
- [Understanding DNS Aging and Scavenging](https://docs.microsoft.com/troubleshoot/windows-server/networking/dns-aging-scavenging-procedure)
- [Event ID 2501-2504 Reference](https://docs.microsoft.com/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc755164)

---

**Version:** 1.0  
**Last Updated:** January 2025  
**Author:** Adrian Johnson <adrian207@gmail.com>

---

*Back to [Documentation Index](README.md)*

