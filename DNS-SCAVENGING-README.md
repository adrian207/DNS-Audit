# DNS Scavenging Manager

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Version:** 1.0  
**Purpose:** Comprehensive DNS scavenging analysis and configuration tool

---

## 🎉 What's Included

### 1. DNS-ScavengingManager.ps1
**Production-ready PowerShell script** that provides:

✅ **Analysis Mode** - Audit current scavenging configuration  
✅ **Configuration Mode** - Apply scavenging settings across all DNS servers  
✅ **Report Mode** - Generate detailed CSV reports  
✅ **Script Generation Mode** - Create remediation scripts for review  

### 2. docs/DNS-SCAVENGING-GUIDE.md
**Complete user guide** with:
- Quick start examples
- Understanding scavenging intervals
- Complete command reference
- Common scenarios and troubleshooting
- Monitoring and best practices

---

## ⚡ Quick Start

### Option 1: Use Your 3-Day Aggressive Cleanup

```powershell
# Analyze current state
.\DNS-ScavengingManager.ps1 -Mode Analyze

# Apply 3+3 day scavenging (aggressive cleanup)
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -WhatIf  # Preview first

# Apply for real
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -Force
```

### Option 2: Use Microsoft Best Practice (7+7 days)

```powershell
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 7 `
    -RefreshInterval 7 `
    -ApplyToAllZones `
    -EnableServerScavenging
```

---

## 📊 What It Does

### Comprehensive Analysis
- ✅ Scans all DNS servers in your domain
- ✅ Checks server-level scavenging settings
- ✅ Audits zone-level aging configuration
- ✅ Identifies misconfigured or disabled zones
- ✅ Compares against your target configuration

### Smart Configuration
- ✅ Applies consistent settings across all servers
- ✅ Configures zone aging on all AD-integrated zones
- ✅ Enables server scavenging automatically
- ✅ Supports zone exclusions
- ✅ WhatIf support for safe previewing

### Safety Features
- ✅ WhatIf mode (preview without changes)
- ✅ Confirmation prompts (unless -Force)
- ✅ Zone exclusion support
- ✅ Detailed logging and transcripts
- ✅ Backup recommendations

---

## 🎯 Understanding Your Options

### 3+3 Days (Aggressive - Your Request)
- **Total Period:** 6 days
- **Best For:** Highly dynamic environments, DHCP, VDI, containers
- **Pros:** Fast cleanup, minimal stale records
- **Cons:** Risk of removing valid records if systems offline >6 days
- **Recommendation:** Test thoroughly in non-production first

### 7+7 Days (Microsoft Best Practice - Default)
- **Total Period:** 14 days
- **Best For:** Most enterprise environments
- **Pros:** Safe, balanced, widely tested
- **Cons:** Stale records accumulate for 14 days
- **Recommendation:** Good starting point for most organizations

### Custom Intervals
```powershell
# Example: 5+5 days (compromise)
-NoRefreshInterval 5 -RefreshInterval 5

# Example: 14+14 days (conservative)
-NoRefreshInterval 14 -RefreshInterval 14
```

---

## 📋 Four Modes of Operation

### Mode: Analyze
**Purpose:** Assess current configuration without making changes

```powershell
.\DNS-ScavengingManager.ps1 -Mode Analyze
```

**Output:**
- Server scavenging status
- Zone aging configuration
- Issues requiring attention
- Current vs. target configuration comparison

---

### Mode: Configure
**Purpose:** Apply scavenging settings

```powershell
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging
```

**What It Does:**
- Enables server scavenging on all DNS servers
- Configures aging on all AD-integrated zones
- Applies your specified intervals (3+3, 7+7, custom)
- Logs all changes

---

### Mode: Report
**Purpose:** Generate detailed CSV reports

```powershell
.\DNS-ScavengingManager.ps1 -Mode Report
```

**Creates:**
- `ScavengingAnalysis_TIMESTAMP.csv` - All zone settings
- `ScavengingIssues_TIMESTAMP.csv` - Problems found
- `ServerScavengingSettings_TIMESTAMP.csv` - Server configuration

---

### Mode: GenerateScript
**Purpose:** Create remediation script for manual review/execution

```powershell
.\DNS-ScavengingManager.ps1 -Mode GenerateScript `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging
```

**Creates:**
- `Apply-ScavengingSettings_TIMESTAMP.ps1`
- Fully executable PowerShell script
- Includes all your configuration
- Can be reviewed before execution

---

## 🛡️ Safety and Best Practices

### Testing Approach

```powershell
# 1. Analyze current state
.\DNS-ScavengingManager.ps1 -Mode Analyze

# 2. Preview changes
.\DNS-ScavengingManager.ps1 -Mode Configure -ApplyToAllZones -EnableServerScavenging -WhatIf

# 3. Apply to test zones first
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -ApplyToAllZones `
    -ExcludeZones "prod.com","contoso.com" `
    -EnableServerScavenging

# 4. Monitor for 24-48 hours

# 5. Apply to all zones
.\DNS-ScavengingManager.ps1 -Mode Configure -ApplyToAllZones -EnableServerScavenging -Force
```

### Monitoring After Configuration

**Event Viewer - DNS Server Log:**
```powershell
Get-WinEvent -LogName "DNS Server" | 
    Where-Object { $_.Id -in 2501,2502 } |
    Format-Table TimeCreated, Message -AutoSize
```

**Key Event IDs:**
- **2501:** Scavenging cycle started
- **2502:** Scavenging completed (shows # records deleted)

### When to Use 3+3 Days

✅ **Good Fit:**
- DHCP environments (dynamic IP allocation)
- VDI/virtual desktop pools
- Container orchestration (Kubernetes, Docker)
- Development/test environments
- Cloud/ephemeral workloads

❌ **Not Recommended:**
- Static DNS records for critical systems
- Systems that go offline for extended periods
- Environments with poor network connectivity
- Without thorough testing first

---

## 📁 Output Files

All files are saved to: `C:\DNSScavenging` (customizable with `-ExportPath`)

```
C:\DNSScavenging\
├── ScavengingManager_TIMESTAMP.log          # Execution log
├── Transcript_TIMESTAMP.log                 # PowerShell transcript
├── ScavengingAnalysis_TIMESTAMP.csv         # Zone analysis
├── ScavengingIssues_TIMESTAMP.csv           # Issues found
├── ServerScavengingSettings_TIMESTAMP.csv   # Server config
└── Apply-ScavengingSettings_TIMESTAMP.ps1   # Generated script
```

---

## 🔧 Complete Parameter Reference

```powershell
.\DNS-ScavengingManager.ps1 `
    -Mode <Analyze|Configure|Report|GenerateScript> `
    -NoRefreshInterval <days> `           # Default: 7
    -RefreshInterval <days> `             # Default: 7
    -ApplyToAllZones `                    # Apply to all zones
    -ExcludeZones @("zone1","zone2") `    # Exclude specific zones
    -EnableServerScavenging `             # Enable on servers
    -ScavengingInterval <hours> `         # Default: 168 (7 days)
    -ExportPath "C:\Reports" `            # Custom output path
    -Credential $cred `                   # For remote ops
    -WhatIf `                             # Preview only
    -Force                                # Skip confirmations
```

---

## 💡 Common Scenarios

### Scenario 1: First-Time Setup with 3+3 Days

```powershell
# Step 1: Analyze
.\DNS-ScavengingManager.ps1 -Mode Analyze

# Step 2: Generate script for review
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

# Step 4: Apply for real
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -EnableServerScavenging `
    -Force
```

### Scenario 2: Exclude Production Zones During Testing

```powershell
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -ExcludeZones "prod.contoso.com","corporate.local" `
    -EnableServerScavenging
```

### Scenario 3: Generate Compliance Report

```powershell
.\DNS-ScavengingManager.ps1 -Mode Report

# Review CSVs for audit evidence
```

### Scenario 4: Change Existing Configuration

```powershell
# From 7+7 to 3+3
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 3 `
    -RefreshInterval 3 `
    -ApplyToAllZones `
    -Force
```

---

## ⚠️ Important Notes

### Before You Start

1. **Test in non-production first!**
2. Review current scavenging settings
3. Document expected DNS record counts
4. Brief support team on changes
5. Plan monitoring strategy

### After Configuration

1. **Monitor for 24-48 hours minimum**
2. Check Event Viewer for scavenging events
3. Verify no valid records are being deleted
4. Document baseline record counts
5. Run analysis mode to confirm settings

### Rollback Plan

If issues occur:
```powershell
# Revert to conservative settings immediately
.\DNS-ScavengingManager.ps1 -Mode Configure `
    -NoRefreshInterval 14 `
    -RefreshInterval 14 `
    -ApplyToAllZones `
    -Force

# Or disable aging on problem zones
Set-DnsServerZoneAging -Name "problem-zone.com" -Aging $false
```

---

## 📞 Support

**Author:** Adrian Johnson  
**Email:** adrian207@gmail.com  
**Documentation:** See `docs/DNS-SCAVENGING-GUIDE.md` for complete guide

---

## 🎉 Summary

You now have a **professional, production-ready tool** that:

✅ Analyzes DNS scavenging configuration across all servers  
✅ Applies your preferred 3-day aggressive cleanup (or any interval)  
✅ Generates detailed reports for compliance  
✅ Includes comprehensive safety features  
✅ Provides complete documentation  

**Next Steps:**
1. Review the documentation: `docs/DNS-SCAVENGING-GUIDE.md`
2. Run analysis: `.\DNS-ScavengingManager.ps1 -Mode Analyze`
3. Apply your 3+3 day configuration (with WhatIf first!)

---

**Version:** 1.0  
**Author:** Adrian Johnson <adrian207@gmail.com>  
**Created:** January 2025


