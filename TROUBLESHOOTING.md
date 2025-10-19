# Troubleshooting Guide

Complete troubleshooting guide for DNS Master Audit and DNS Scavenging Manager.

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Last Updated:** 2025-10-19

---

## 📋 Table of Contents

1. [Common Error Messages](#common-error-messages)
2. [Permission Issues](#permission-issues)
3. [Network Connectivity Problems](#network-connectivity-problems)
4. [Performance Issues](#performance-issues)
5. [Module/Dependency Problems](#moduledependency-problems)
6. [Export and Reporting Issues](#export-and-reporting-issues)
7. [Parallel Processing Issues](#parallel-processing-issues)
8. [Cross-Site Authentication Detection Issues](#cross-site-authentication-detection-issues)
9. [Webhook Notification Problems](#webhook-notification-problems)
10. [Diagnostic Tools](#diagnostic-tools)

---

## Common Error Messages

### Error: "Get-ADDomainController : Unable to contact the server"

**Cause:** Cannot reach domain controller or AD module issues.

**Solutions:**
```powershell
# 1. Verify AD module is loaded
Import-Module ActiveDirectory -ErrorAction Stop

# 2. Test DC connectivity
Test-NetConnection -ComputerName DC01.contoso.com -Port 389

# 3. Check DNS resolution
Resolve-DnsName DC01.contoso.com

# 4. Verify credentials
Get-ADDomainController -Credential (Get-Credential) -Server contoso.com

# 5. Use specific server
.\DNS-MasterAudit.ps1 -Mode Inventory -DnsServer "DC01.contoso.com"
```

**Prevention:**
- Ensure workstation is domain-joined
- Verify AD Web Services is running on DCs
- Check firewall rules (LDAP 389, LDAPS 636)

---

### Error: "Access is denied" or "UnauthorizedAccessException"

**Cause:** Insufficient permissions for operation.

**Solutions:**
```powershell
# 1. Check current user permissions
whoami /groups

# 2. Use elevated credentials
$cred = Get-Credential
.\DNS-MasterAudit.ps1 -Mode Complete -Credential $cred

# 3. Verify required group memberships
# Minimum: Domain Users + DNS read permissions
# For scavenging: DNS Admins group

# 4. Test specific permission
Get-DnsServerZone -ComputerName DC01 -ErrorAction Stop
```

**Required Permissions:**
| Operation | Minimum Permission |
|-----------|-------------------|
| DNS Inventory | Domain Users |
| DNS Health Check | Domain Users |
| Record Export | Domain Users |
| Site Audit | Domain Users |
| Analytics/Security/Diagnostics | Domain Users |
| Scavenging Configure | DNS Admins |
| Cross-Site Auth Check | Read access to C$ shares |

---

### Error: "The term 'Get-DnsServerZone' is not recognized"

**Cause:** DNS Server PowerShell module not installed.

**Solutions:**
```powershell
# Windows 10/11 and Server 2016+
Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0

# Windows Server (older)
Install-WindowsFeature RSAT-DNS-Server

# Verify installation
Get-Module -ListAvailable DnsServer

# Import module
Import-Module DnsServer
```

---

### Error: "Cannot bind parameter 'Credential' because it is null"

**Cause:** Credential parameter passed but empty.

**Solutions:**
```powershell
# Option 1: Don't use -Credential if not needed
.\DNS-MasterAudit.ps1 -Mode Inventory

# Option 2: Create credential object first
$cred = Get-Credential -Message "Enter Domain Admin credentials"
.\DNS-MasterAudit.ps1 -Mode Complete -Credential $cred

# Option 3: Use saved credential (future feature)
.\DNS-MasterAudit.ps1 -Mode Complete -UseCredentialManager -CredentialName "DNS-Audit"
```

---

## Permission Issues

### Scenario: Script runs but reports "Access Denied" for some DCs

**Diagnosis:**
```powershell
# Test connectivity to each DC
$dcs = Get-ADDomainController -Filter *
foreach ($dc in $dcs) {
    Write-Host "Testing $($dc.Name)..." -ForegroundColor Cyan
    Test-NetConnection $dc.Name -Port 135 -InformationLevel Quiet
    Get-Service -ComputerName $dc.Name -Name DNS -ErrorAction SilentlyContinue
}
```

**Solutions:**
1. **Firewall blocking WMI/RPC:**
   ```powershell
   # Enable required firewall rules on DCs
   Enable-NetFirewallRule -DisplayGroup "Remote Service Management"
   Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)"
   ```

2. **UAC restrictions:**
   - Run PowerShell as Administrator
   - Add user to "Remote Management Users" group

3. **Credential delegation:**
   ```powershell
   # Enable CredSSP (use with caution)
   Enable-WSManCredSSP -Role Client -DelegateComputer "*.contoso.com"
   ```

---

### Scenario: Cannot access netlogon.log for cross-site check

**Error:**
```
Access to the path '\\DC01\C$\Windows\debug\netlogon.log' is denied
```

**Solutions:**
```powershell
# 1. Verify admin share access
Test-Path "\\DC01\C$"

# 2. Check local Administrators group membership
Invoke-Command -ComputerName DC01 -ScriptBlock {
    Get-LocalGroupMember -Group "Administrators"
}

# 3. Verify File and Printer Sharing is enabled
Get-NetFirewallRule -DisplayName "*File and Printer Sharing*" | 
    Where-Object {$_.Enabled -eq 'True'}

# 4. Use explicit credential
$cred = Get-Credential
.\DNS-MasterAudit.ps1 -Mode Diagnostics -CheckCrossSiteAuth -Credential $cred
```

---

## Network Connectivity Problems

### Scenario: Script hangs or times out

**Diagnosis:**
```powershell
# Test RPC connectivity
Test-NetConnection DC01.contoso.com -Port 135

# Test DNS query
Resolve-DnsName contoso.com -Server DC01.contoso.com

# Test SMB
Test-Path "\\DC01\C$"

# Check WinRM (if using Invoke-Command)
Test-WSMan -ComputerName DC01.contoso.com
```

**Solutions:**
1. **Increase timeout:**
   ```powershell
   # Modify script to increase CIM session timeout
   $option = New-CimSessionOption -Timeout 60000  # 60 seconds
   New-CimSession -ComputerName $dc -SessionOption $option
   ```

2. **Use parallel processing with lower throttle:**
   ```powershell
   .\DNS-MasterAudit.ps1 -Mode Complete `
       -EnableParallelProcessing `
       -MaxDegreeOfParallelism 3  # Lower concurrency
   ```

3. **Skip problematic DCs:**
   ```powershell
   # Manually exclude DCs
   -ExcludeDCs "SLOWDC01","OFFLINEDC02"
   ```

---

### Scenario: DNS resolution fails

**Error:**
```
Resolve-DnsName : DNS name does not exist
```

**Solutions:**
```powershell
# 1. Verify DNS server is reachable
nslookup contoso.com DC01.contoso.com

# 2. Check DNS client settings
Get-DnsClientServerAddress

# 3. Flush DNS cache
Clear-DnsClientCache
ipconfig /flushdns

# 4. Use specific DNS server
.\DNS-MasterAudit.ps1 -Mode HealthCheck -DnsServer "10.0.0.1"
```

---

## Performance Issues

### Scenario: Script runs very slowly (10+ minutes for 10 DCs)

**Diagnosis:**
```powershell
# Enable verbose output
.\DNS-MasterAudit.ps1 -Mode Inventory -Verbose

# Check network latency to DCs
$dcs = Get-ADDomainController -Filter *
$dcs | ForEach-Object {
    $ping = Test-Connection $_.Name -Count 1 -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        DC = $_.Name
        Latency = if ($ping) { "$($ping.ResponseTime)ms" } else { "TIMEOUT" }
    }
}
```

**Solutions:**
1. **Enable parallel processing:**
   ```powershell
   .\DNS-MasterAudit.ps1 -Mode Complete `
       -EnableParallelProcessing `
       -MaxDegreeOfParallelism 10  # Adjust based on DCs
   ```
   **Expected improvement:** 5-10x faster

2. **Use incremental scanning (future):**
   ```powershell
   .\DNS-MasterAudit.ps1 -Mode Diagnostics `
       -CheckCrossSiteAuth `
       -IncrementalMode `
       -SinceLast "1 hour"
   ```

3. **Limit scope:**
   ```powershell
   # Audit specific zones only
   .\DNS-MasterAudit.ps1 -Mode RecordExport `
       -ZoneFilter "contoso.com","sales.contoso.com"
   ```

4. **Schedule during off-hours:**
   ```powershell
   # Create scheduled task for 2 AM
   $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
       -Argument "-File C:\Scripts\DNS-MasterAudit.ps1 -Mode Complete"
   $trigger = New-ScheduledTaskTrigger -Daily -At 2am
   Register-ScheduledTask -TaskName "DNS-Audit" -Action $action -Trigger $trigger
   ```

---

### Scenario: High memory usage (> 1 GB)

**Cause:** Large environments with 100,000+ DNS records.

**Solutions:**
```powershell
# 1. Process zones individually instead of all at once
# Modify script to use streaming instead of arrays

# 2. Increase PowerShell memory limit
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command {
    $env:PSModulePath
} -WindowStyle Hidden -NoLogo

# 3. Run in 64-bit PowerShell
# C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

# 4. Clear variables between operations
[System.GC]::Collect()
```

---

## Module/Dependency Problems

### Scenario: ImportExcel module not found

**Error:**
```
Export-Excel : The term 'Export-Excel' is not recognized
```

**Solutions:**
```powershell
# Install ImportExcel module
Install-Module -Name ImportExcel -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable ImportExcel

# Alternative: Use different export format
.\DNS-MasterAudit.ps1 -Mode Complete -ExportFormat HTML  # or CSV, JSON
```

---

### Scenario: PowerShell version too old

**Error:**
```
#Requires: The "#requires" command requires PowerShell 5.1
```

**Solutions:**
```powershell
# Check current version
$PSVersionTable.PSVersion

# Option 1: Update to PowerShell 7.x (recommended)
# Download from: https://github.com/PowerShell/PowerShell/releases

# Option 2: Update to PowerShell 5.1 on Windows Server
# Install WMF 5.1 from Microsoft Update Catalog

# Option 3: Use different machine with newer PowerShell
```

---

## Export and Reporting Issues

### Scenario: HTML export shows garbled characters

**Cause:** Encoding issues with special characters.

**Solutions:**
```powershell
# Ensure UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Run script with UTF-8
powershell.exe -NoProfile -InputFormat None -OutputFormat Text `
    -File ".\DNS-MasterAudit.ps1" -Mode Complete -ExportFormat HTML
```

---

### Scenario: Export files not created

**Diagnosis:**
```powershell
# Check export path exists and is writable
Test-Path "C:\DNSAudit" -PathType Container
New-Item -Path "C:\DNSAudit\test.txt" -ItemType File -Force

# Check disk space
Get-PSDrive C | Select-Object Used,Free

# Check permissions
icacls "C:\DNSAudit"
```

**Solutions:**
```powershell
# 1. Use different export path
.\DNS-MasterAudit.ps1 -Mode Complete -ExportPath "D:\Audits"

# 2. Run as administrator
# Right-click PowerShell -> Run as Administrator

# 3. Create directory first
New-Item -Path "C:\DNSAudit" -ItemType Directory -Force
```

---

## Parallel Processing Issues

### Scenario: Parallel processing causes script to crash

**Error:**
```
Runspace pool error: The pipeline has been stopped
```

**Solutions:**
```powershell
# 1. Reduce throttle limit
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 3  # Lower from default 5

# 2. Disable parallel processing temporarily
.\DNS-MasterAudit.ps1 -Mode Complete  # Runs sequentially

# 3. Check for resource constraints
Get-Process powershell | Select-Object CPU,Memory,Threads
```

---

### Scenario: Some DCs not processed in parallel mode

**Diagnosis:**
Check transcript log for errors:
```powershell
Get-Content "C:\DNSAudit\MasterAudit_*.log" | 
    Select-String "ERROR|FAIL"
```

**Solutions:**
- Review per-DC errors in log
- Exclude problematic DCs
- Use sequential mode for debugging

---

## Cross-Site Authentication Detection Issues

### Scenario: No cross-site issues detected but you know they exist

**Diagnosis:**
```powershell
# 1. Check netlogon.log exists on DCs
Test-Path "\\DC01\C$\Windows\debug\netlogon.log"

# 2. View netlogon.log manually
Get-Content "\\DC01\C$\Windows\debug\netlogon.log" -Tail 50

# 3. Check if NO_CLIENT_SITE entries exist
Select-String -Path "\\DC01\C$\Windows\debug\netlogon.log" `
    -Pattern "NO_CLIENT_SITE"
```

**Solutions:**
1. **Enable netlogon logging:**
   ```powershell
   # On each DC
   nltest /DBFlag:0x2080ffff  # Enable verbose netlogon logging
   ```

2. **Wait for log entries to accumulate:**
   - Netlogon only logs when clients actually authenticate
   - Wait 24-48 hours for sufficient data

3. **Check log rotation:**
   - netlogon.log may have been cleared/rotated
   - Check netlogon.bak if exists

---

### Scenario: Too many false positives

**Cause:** VPN clients, guest networks, or transient connections.

**Solutions:**
```powershell
# Filter known VPN subnets (future feature)
-ExcludeSubnets "192.168.100.0/24","10.50.0.0/16"

# Adjust threshold (future feature)
-MinimumOccurrences 5  # Only report IPs seen 5+ times
```

---

## Webhook Notification Problems

### Scenario: Teams webhook doesn't post messages

**Diagnosis:**
```powershell
# Test webhook manually
$body = @{
    text = "Test message from DNS-MasterAudit"
} | ConvertTo-Json

Invoke-RestMethod -Uri "YOUR_WEBHOOK_URL" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

**Solutions:**
1. **Verify webhook URL is correct and active**
2. **Check Teams channel permissions**
3. **Ensure HTTPS (not HTTP)**
4. **Check firewall/proxy settings:**
   ```powershell
   # Test outbound HTTPS connectivity
   Test-NetConnection outlook.office.com -Port 443
   ```

---

### Scenario: Slack webhook returns 400 Bad Request

**Cause:** Invalid JSON payload format.

**Solutions:**
```powershell
# Verify JSON format
$payload = @{
    text = "Test message"
} | ConvertTo-Json

# Check for special characters
$payload -replace "`n","\n" -replace "`t","\t"
```

---

## Diagnostic Tools

### Built-in Diagnostics

```powershell
# 1. Run in WhatIf mode
.\DNS-MasterAudit.ps1 -Mode Configure -WhatIf

# 2. Enable verbose output
.\DNS-MasterAudit.ps1 -Mode Complete -Verbose

# 3. Check transcript logs
Get-ChildItem "C:\DNSAudit\*.log" | Sort-Object LastWriteTime | Select-Object -Last 1

# 4. Test connectivity
.\DNS-MasterAudit.ps1 -Mode HealthCheck

# 5. Validate configuration
Get-DnsServerZone -ComputerName DC01
Get-ADDomainController -Filter *
```

### Network Diagnostics

```powershell
# Comprehensive network check
$dcs = Get-ADDomainController -Filter *
foreach ($dc in $dcs) {
    Write-Host "`n=== Testing $($dc.Name) ===" -ForegroundColor Cyan
    
    # DNS
    Write-Host "DNS Resolution:" -NoNewline
    if (Resolve-DnsName $dc.Name -ErrorAction SilentlyContinue) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
    
    # ICMP
    Write-Host "Ping:" -NoNewline
    if (Test-Connection $dc.Name -Count 1 -Quiet) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
    
    # LDAP
    Write-Host "LDAP (389):" -NoNewline
    if (Test-NetConnection $dc.Name -Port 389 -InformationLevel Quiet) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
    
    # DNS Server
    Write-Host "DNS Server (53):" -NoNewline
    if (Test-NetConnection $dc.Name -Port 53 -InformationLevel Quiet) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
    
    # WMI/RPC
    Write-Host "RPC (135):" -NoNewline
    if (Test-NetConnection $dc.Name -Port 135 -InformationLevel Quiet) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
    
    # SMB
    Write-Host "SMB (445):" -NoNewline
    if (Test-NetConnection $dc.Name -Port 445 -InformationLevel Quiet) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}
```

---

## Getting Help

### 1. Built-in Help
```powershell
Get-Help .\DNS-MasterAudit.ps1 -Full
Get-Help .\DNS-MasterAudit.ps1 -Examples
Get-Help .\DNS-MasterAudit.ps1 -Parameter Mode
```

### 2. Check Logs
```powershell
# View latest transcript
Get-Content "C:\DNSAudit\MasterAudit_*.log" | Select-Object -Last 100
```

### 3. GitHub Issues
- Search existing issues: https://github.com/adrian207/DNS-Audit/issues
- Create new issue with details

### 4. Contact Support
- Email: adrian207@gmail.com
- Include: PowerShell version, error message, transcript log

---

## Quick Reference Card

| Problem | Quick Fix |
|---------|-----------|
| Module not found | `Install-Module -Name ImportExcel` |
| Permission denied | Run as Administrator or use `-Credential` |
| Script hangs | Enable parallel processing or reduce throttle |
| No output files | Check `-ExportPath` permissions |
| DNS errors | Verify DNS server connectivity |
| Cross-site detection fails | Check admin share access to C$ |
| Webhook doesn't work | Test URL manually, check firewall |
| Memory issues | Process fewer zones at once |
| Slow performance | Enable `-EnableParallelProcessing` |

---

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Last Updated:** 2025-10-19

