# DNS Master Audit - Unified Edition Guide

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Version:** 1.0  
**Status:** ✅ All-in-One Solution

---

## 🎯 What Is This?

**DNS-MasterAudit.ps1** is a **unified script** that combines ALL 5 DNS audit tools into ONE comprehensive solution!

Instead of running 5 separate scripts, you now have **ONE script with 5 modes**:

| Mode | What It Does | Original Script |
|------|--------------|-----------------|
| **Inventory** | Discover all DNS servers | DNS-Inventory.ps1 |
| **HealthCheck** | Test DNS service health | DNS-Ops-Audit.ps1 |
| **RecordExport** | Export all DNS records | DNS-Static-Audit.ps1 |
| **SiteAudit** | Find site mismatches | ADSite-Audit.ps1 v2.2 |
| **Complete** | Run all 4 above in sequence | *(New)* |

---

## 🚀 Quick Start

### Option 1: Run Complete Audit (Recommended)
```powershell
# Run everything in one go!
.\DNS-MasterAudit.ps1 -Mode Complete
```

### Option 2: Run Individual Modes
```powershell
# Just inventory
.\DNS-MasterAudit.ps1 -Mode Inventory

# Just health check
.\DNS-MasterAudit.ps1 -Mode HealthCheck

# Just export records
.\DNS-MasterAudit.ps1 -Mode RecordExport

# Just site audit
.\DNS-MasterAudit.ps1 -Mode SiteAudit -EnableAllFeatures
```

---

## 📖 Mode Details

### Mode 1: Inventory
**Discovers all DNS servers in your AD domain**

```powershell
.\DNS-MasterAudit.ps1 -Mode Inventory
```

**Output:**
- `DNS_Inventory_[timestamp].csv`
  - Server name, IP, site, DNS service status
  - Zone counts (primary/secondary)
  - Operating system version

**Use When:** "What DNS servers do I have?"

---

### Mode 2: HealthCheck
**Comprehensive DNS service health testing**

```powershell
.\DNS-MasterAudit.ps1 -Mode HealthCheck
```

**Tests Performed:**
- ✅ DNS service status
- ✅ Zone accessibility  
- ✅ DNS resolution functionality

**Output:**
- `DNS_HealthCheck_[timestamp].csv`
  - Per-DC, per-test results (PASS/FAIL)
  - Detailed error messages for failures

**Use When:** "Is DNS working correctly?"

---

### Mode 3: RecordExport
**Export all DNS records to CSV for documentation**

```powershell
# Export all zones
.\DNS-MasterAudit.ps1 -Mode RecordExport

# Export specific zones
.\DNS-MasterAudit.ps1 -Mode RecordExport -ZoneFilter @("contoso.com", "fabrikam.com")
```

**Exports These Record Types:**
- A, AAAA, CNAME, MX, PTR, SRV, TXT, NS

**Output:**
- `DNS_RecordExport_[timestamp].csv`
  - Complete inventory with zone, name, type, data, TTL, timestamp

**Use When:** "Give me a complete export of all DNS records"

---

### Mode 4: SiteAudit
**Find DNS records in the wrong AD sites (ADSite-Audit v2.2 functionality)**

```powershell
# Basic site audit
.\DNS-MasterAudit.ps1 -Mode SiteAudit

# Enable ALL v2.2 features
.\DNS-MasterAudit.ps1 -Mode SiteAudit -EnableAllFeatures
```

**When `-EnableAllFeatures` is used, it activates:**
- ✅ DNS health validation
- ✅ Consistency checks across DCs
- ✅ Zone health scoring
- ✅ Reverse lookup validation
- ✅ CNAME resolution
- ✅ Record ownership tracking
- ✅ Compliance report generation

**Output:**
- `DNS_Site_Mismatches_[timestamp].csv`
- `DNS_DC_Processing_Summary_[timestamp].csv`
- `DNS_Audit_Statistics_[timestamp].csv`
- Plus all v2.2 reports if `-EnableAllFeatures` is used

**Use When:** "Find records in wrong AD sites"

---

### Mode 5: Complete
**Runs ALL 4 modes in sequence (recommended for comprehensive audits)**

```powershell
# Complete audit with all features
.\DNS-MasterAudit.ps1 -Mode Complete -EnableAllFeatures

# Complete audit for specific zones
.\DNS-MasterAudit.ps1 -Mode Complete -ZoneFilter @("contoso.com")
```

**Execution Order:**
1. Inventory → Discover servers
2. HealthCheck → Validate health
3. RecordExport → Document records
4. SiteAudit → Find mismatches

**Output:**
- All CSV files from all 4 modes
- Unified log file with complete audit trail

**Use When:** "Give me a complete DNS audit"

---

## 🎛️ All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Mode` | String | *Required* | Inventory / HealthCheck / RecordExport / SiteAudit / Complete |
| `-ExportPath` | String | C:\DNSAudit | Directory for all reports |
| `-ZoneFilter` | String[] | @() | Specific zones to audit |
| `-EnableAllFeatures` | Switch | False | Enable all v2.2 features (SiteAudit/Complete modes) |
| `-Credential` | PSCredential | $null | Credentials for remote operations |
| `-GenerateHTML` | Switch | False | Generate HTML reports (future) |
| `-EnableEmailNotification` | Switch | False | Send email when complete |
| `-SMTPServer` | String | "" | SMTP server for email |
| `-EmailFrom` | String | "" | From address |
| `-EmailTo` | String[] | @() | Recipient addresses |

---

## 💡 Usage Examples

### Example 1: Monthly Audit (Recommended)
```powershell
# Complete audit with all features and email
.\DNS-MasterAudit.ps1 `
    -Mode Complete `
    -EnableAllFeatures `
    -ExportPath "C:\DNSAudit\$(Get-Date -Format 'yyyy-MM')" `
    -EnableEmailNotification `
    -SMTPServer "smtp.company.com" `
    -EmailFrom "dnsaudit@company.com" `
    -EmailTo @("it-team@company.com")
```

### Example 2: Quick Health Check
```powershell
# Just check if DNS is healthy
.\DNS-MasterAudit.ps1 -Mode HealthCheck
```

### Example 3: Zone-Specific Analysis
```powershell
# Complete audit for one zone
.\DNS-MasterAudit.ps1 `
    -Mode Complete `
    -ZoneFilter @("problematic-zone.com") `
    -EnableAllFeatures
```

### Example 4: Inventory Only
```powershell
# Discover all DNS servers
.\DNS-MasterAudit.ps1 -Mode Inventory
```

### Example 5: Site Audit with Full v2.2 Features
```powershell
# Comprehensive site mismatch audit
.\DNS-MasterAudit.ps1 `
    -Mode SiteAudit `
    -EnableAllFeatures `
    -ExportPath "C:\Audit\SiteMismatches"
```

---

## 📂 Output Structure

After running Complete mode, your export directory will contain:

```
C:\DNSAudit\
├── DNS_Inventory_20251016_143022.csv
├── DNS_HealthCheck_20251016_143025.csv
├── DNS_RecordExport_20251016_143045.csv
├── DNS_Site_Mismatches_20251016_143110.csv
├── DNS_DC_Processing_Summary_20251016_143110.csv
├── DNS_Audit_Statistics_20251016_143110.csv
├── DNS_Zone_Performance_20251016_143110.csv
├── DNS_Consistency_Issues_20251016_143110.csv (if -EnableAllFeatures)
├── DNS_Zone_Health_Scores_20251016_143110.csv (if -EnableAllFeatures)
└── MasterAudit_20251016_143022.log
```

---

## 🔄 How It Works

### Architecture

```
┌─────────────────────────────────────────┐
│     DNS-MasterAudit.ps1                 │
│     (Single Entry Point)                │
└─────────────────────────────────────────┘
                 │
    ┌────────────┼───────────────────┐
    │            │                   │
    ▼            ▼                   ▼
┌─────────┐ ┌─────────┐        ┌─────────┐
│  Mode 1 │ │  Mode 2 │  ...   │  Mode 5 │
│Inventory│ │ Health  │        │Complete │
└─────────┘ └─────────┘        └─────────┘
                                     │
                        ┌────────────┼────────────┐
                        │            │            │
                        ▼            ▼            ▼
                    Mode 1 ─────→ Mode 2 ─────→ Mode 3 ─────→ Mode 4
```

### For Site Audit Mode

The master script **calls** the existing `ADSite-Audit.ps1` v2.2 script:

```
DNS-MasterAudit.ps1 (Mode: SiteAudit)
          │
          └──> Executes DNS-Site\ADSite-Audit.ps1
                    │
                    └──> Full v2.2 functionality (2,836 lines)
```

**Benefits:**
- ✅ No code duplication
- ✅ Leverages existing tested v2.2 code
- ✅ Automatic updates when ADSite-Audit.ps1 is enhanced

---

## ⚡ Performance

[Inference] Estimated execution times:

| Mode | Small Environment | Medium Environment | Large Environment |
|------|-------------------|-------------------|-------------------|
| Inventory | 30 seconds | 1-2 minutes | 3-5 minutes |
| HealthCheck | 1-2 minutes | 3-5 minutes | 5-10 minutes |
| RecordExport | 2-5 minutes | 10-20 minutes | 30-60 minutes |
| SiteAudit | 3-10 minutes | 15-30 minutes | 60-120 minutes |
| **Complete** | **10-20 min** | **30-60 min** | **2-4 hours** |

**Environment Sizes:**
- Small: 1-5 DCs, <10,000 records
- Medium: 5-20 DCs, 10,000-100,000 records
- Large: 20+ DCs, >100,000 records

---

## 🆚 Comparison: Unified vs. Individual Scripts

### Before (5 Separate Scripts)
```powershell
# You had to run 5 different commands
.\DNS-Inventory.ps1
.\DNS-Ops-Audit.ps1 -DCName DC01
.\DNS-Ops-Audit.ps1 -DCName DC02
.\DNS-Static-Audit.ps1 -DNSServers @("DC01","DC02")
.\DNS-Site\ADSite-Audit.ps1 -EnableAllFeatures
```

### After (1 Unified Script)
```powershell
# Now just one command
.\DNS-MasterAudit.ps1 -Mode Complete -EnableAllFeatures
```

---

## ✅ Advantages of the Unified Script

### 1. Simplicity
- **One script to learn** instead of 5
- **One command** for complete audit
- **Consistent parameters** across all modes

### 2. Efficiency
- **Single log file** for all operations
- **One export directory** for all reports
- **Unified email notification**

### 3. Integration
- Modes work together seamlessly
- Results can cross-reference each other
- Complete mode provides comprehensive view

### 4. Maintainability
- **One script to update**
- **One help file** to reference
- **One set of parameters**

---

## 🔧 Requirements

- PowerShell 5.1 or later
- Active Directory PowerShell module
- DNS Server PowerShell module
- Domain Admin or equivalent permissions
- Network access to all domain controllers

---

## 📋 Comparison Table

| Feature | Individual Scripts | Unified Script |
|---------|-------------------|----------------|
| **Commands to run** | 5 | 1 |
| **Log files** | 5 | 1 |
| **Export locations** | 5 different | 1 unified |
| **Email notifications** | 5 separate | 1 combined |
| **Learning curve** | 5 scripts | 1 script |
| **Complete audit time** | Manual coordination | Automated |
| **Error handling** | Per-script | Unified |
| **Results correlation** | Manual | Automatic |

---

## 🎯 When to Use Which

### Use **DNS-MasterAudit.ps1** when:
- ✅ You want ONE tool for everything
- ✅ You need a complete audit workflow
- ✅ You prefer simplicity and consistency
- ✅ You want unified logging and reporting

### Use **Individual Scripts** when:
- ✅ You only need ONE specific function
- ✅ You want maximum customization
- ✅ You're integrating into existing workflows
- ✅ You need absolute control over each step

---

## 💡 Pro Tips

### Tip 1: Schedule Monthly Complete Audits
```powershell
# Create scheduled task
$Action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\DNS-MasterAudit.ps1 -Mode Complete -EnableAllFeatures -ExportPath C:\DNSAudit\Monthly\$(Get-Date -Format 'yyyy-MM')"

$Trigger = New-ScheduledTaskTrigger -Monthly -At 2AM -DaysOfMonth 1

Register-ScheduledTask `
    -TaskName "Monthly DNS Audit" `
    -Action $Action `
    -Trigger $Trigger `
    -RunLevel Highest
```

### Tip 2: Keep Historical Data
```powershell
# Organize by month
$MonthPath = "C:\DNSAudit\$(Get-Date -Format 'yyyy-MM')"
.\DNS-MasterAudit.ps1 -Mode Complete -ExportPath $MonthPath
```

### Tip 3: Quick Daily Health Check
```powershell
# Fast daily check
.\DNS-MasterAudit.ps1 -Mode HealthCheck
```

### Tip 4: Investigate Specific Issues
```powershell
# Focus on problem zone
.\DNS-MasterAudit.ps1 `
    -Mode Complete `
    -ZoneFilter @("problem-zone.com") `
    -EnableAllFeatures
```

---

## 🐛 Troubleshooting

### Issue: "Cannot find ADSite-Audit.ps1"
**Solution:** Ensure `DNS-Site\ADSite-Audit.ps1` exists relative to DNS-MasterAudit.ps1

```
Your-Directory\
├── DNS-MasterAudit.ps1
└── DNS-Site\
    └── ADSite-Audit.ps1
```

### Issue: "Access Denied" errors
**Solution:** Run with elevated permissions or provide `-Credential` parameter

### Issue: Mode takes too long
**Solution:** Use zone filtering to reduce scope:
```powershell
.\DNS-MasterAudit.ps1 -Mode RecordExport -ZoneFilter @("main-zone.com")
```

---

## 📊 Success Metrics

After running Complete mode, you'll have answered:

- ✅ **Inventory:** How many DNS servers? What zones?
- ✅ **Health:** Are services running? Any failures?
- ✅ **Records:** What's the complete DNS inventory?
- ✅ **Sites:** Any mismatches? What severity?

**All in ONE execution!**

---

## 🎉 Summary

**You asked: "Can I have it all in one script?"**

**Answer: YES! ✅**

`DNS-MasterAudit.ps1` gives you:
- ✅ All 5 scripts' functionality
- ✅ In ONE unified tool
- ✅ With 5 operation modes
- ✅ Plus a "Complete" mode that runs everything

**You can still use the individual scripts** if you prefer, but now you have the option of a **unified, streamlined solution**.

---

## 📞 Support

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Script:** DNS-MasterAudit.ps1 v1.0 - Unified Edition

---

**Enjoy your all-in-one DNS auditing solution! 🚀**

