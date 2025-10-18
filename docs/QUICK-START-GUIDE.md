# DNS Master Audit v3.0 - Quick Start Guide

**Author:** Adrian Johnson <adrian207@gmail.com>  
**5-Minute Setup Guide**

---

## Installation (2 minutes)

```powershell
# 1. Download script
Invoke-WebRequest -Uri "https://github.com/adrian207/DNS-Audit/releases/latest/DNS-MasterAudit-Enhanced-v3.0.ps1" -OutFile "DNS-MasterAudit.ps1"

# 2. Unblock file
Unblock-File ".\DNS-MasterAudit.ps1"

# 3. Verify modules
Get-Module -ListAvailable ActiveDirectory, DnsServer
```

---

## First Run (3 minutes)

### Option 1: Quick Inventory
```powershell
.\DNS-MasterAudit.ps1 -Mode Inventory
```
📊 **Output:** CSV list of all DNS servers

### Option 2: Complete Audit (Recommended)
```powershell
.\DNS-MasterAudit.ps1 -Mode Complete -EnableHTMLDashboard -EnableParallelProcessing
```
📊 **Output:** Full audit + Interactive HTML dashboard

---

## View Results

```powershell
# Open results folder
explorer C:\DNSAudit

# View HTML dashboard
start C:\DNSAudit\DNS_Dashboard_*.html
```

---

## Next Steps

✅ Review HTML dashboard  
✅ Check CSV files for data analysis  
✅ Read full User Guide for advanced features  
✅ Schedule automated audits  

---

## Common Commands

```powershell
# Health check only
.\DNS-MasterAudit.ps1 -Mode HealthCheck

# Specific zones
.\DNS-MasterAudit.ps1 -Mode RecordExport -ZoneFilter "contoso.com"

# With credentials
$cred = Get-Credential
.\DNS-MasterAudit.ps1 -Mode Complete -Credential $cred

# All features enabled
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableHTMLDashboard `
    -EnableParallelProcessing `
    -EnableAdvancedAnalytics `
    -EnableSecurityAudits `
    -GenerateRemediationScript
```

---

## Troubleshooting

**Permission issues?**
```powershell
# Run PowerShell as Administrator
# OR provide credentials
-Credential (Get-Credential)
```

**Slow performance?**
```powershell
# Enable parallel processing
-EnableParallelProcessing -MaxDegreeOfParallelism 10
```

**Need help?**
- Full docs: See USER-GUIDE.md
- Issues: GitHub.com/adrian207/DNS-Audit
- Email: adrian207@gmail.com

---

**That's it! You're ready to audit DNS! 🚀**

