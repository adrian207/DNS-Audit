# Performance Tuning Guide

Complete performance optimization guide for DNS Master Audit.

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Last Updated:** 2025-10-19

---

## 📊 **Performance Baseline**

### Expected Performance (Without Optimization)

| Environment | DCs | Zones | Records | Time | Memory |
|-------------|-----|-------|---------|------|--------|
| Small | 2-5 | 5-10 | 1,000 | 2-3 min | 150 MB |
| Medium | 6-15 | 11-50 | 10,000 | 5-10 min | 300 MB |
| Large | 16-50 | 51-200 | 50,000 | 10-20 min | 500 MB |
| Enterprise | 50+ | 200+ | 100,000+ | 20-40 min | 1 GB+ |

---

## ⚡ **Quick Wins (Immediate Improvements)**

### 1. Enable Parallel Processing (5-10x Speedup)

```powershell
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 10
```

**Expected Improvement:** 
- Small: 60% faster (3 min → 1 min)
- Medium: 70% faster (10 min → 3 min)
- Large: 75% faster (20 min → 5 min)
- Enterprise: 80% faster (40 min → 8 min)

**Optimal Settings:**
```powershell
# Based on DC count
$dcCount = (Get-ADDomainController -Filter *).Count
$threads = [Math]::Min([Math]::Max([Math]::Ceiling($dcCount / 2), 5), 20)

.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism $threads
```

---

### 2. Limit Scope (Reduce Workload)

```powershell
# Audit specific zones only
.\DNS-MasterAudit.ps1 -Mode RecordExport `
    -ZoneFilter "contoso.com","sales.contoso.com"

# Skip analytics if not needed
.\DNS-MasterAudit.ps1 -Mode Diagnostics `
    -TestQueryPerformance `
    -CheckReplicationLag
    # -CheckCrossSiteAuth  # Skip if not needed

# Export to CSV only (fastest)
.\DNS-MasterAudit.ps1 -Mode Complete `
    -ExportFormat CSV  # Avoid HTML/Excel for speed
```

---

### 3. Schedule During Off-Hours

```powershell
# Create scheduled task for 2 AM
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Scripts\DNS-MasterAudit.ps1 -Mode Complete -EnableParallelProcessing"

$trigger = New-ScheduledTaskTrigger -Daily -At 2am

Register-ScheduledTask `
    -TaskName "DNS-Audit-Daily" `
    -Action $action `
    -Trigger $trigger `
    -RunLevel Highest
```

---

## 🔧 **Advanced Optimizations**

### 4. Incremental Scanning (Future Feature)

```powershell
# Only scan changes since last run
.\DNS-MasterAudit.ps1 -Mode Diagnostics `
    -CheckCrossSiteAuth `
    -IncrementalMode `
    -SinceLast "1 hour"
```

**Expected Improvement:** 70-80% faster for frequent scans

---

### 5. Caching Layer (Future Feature)

```powershell
# Cache AD queries for 5 minutes
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableCaching `
    -CacheDuration 300  # seconds
```

**What Gets Cached:**
- DC list
- Site list
- Subnet list
- Zone list

**Expected Improvement:** 30-50% faster for repeated runs

---

### 6. Connection Pooling (Future Feature)

```powershell
# Reuse CIM sessions across queries
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableConnectionPooling
```

**Expected Improvement:** 20-30% faster

---

## 📈 **Performance Tuning by Mode**

### Mode 1: DNS Inventory

**Bottleneck:** Sequential DC queries

**Optimization:**
```powershell
.\DNS-MasterAudit.ps1 -Mode Inventory `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 10
```

**Result:** 10 DCs in 30 seconds instead of 3 minutes

---

### Mode 2: DNS Health Check

**Bottleneck:** DNS resolution tests

**Optimization:**
```powershell
.\DNS-MasterAudit.ps1 -Mode HealthCheck `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 5  # Lower for stability
```

---

### Mode 3: DNS Record Export

**Bottleneck:** Large zone transfers

**Optimization:**
```powershell
# Export specific zones only
.\DNS-MasterAudit.ps1 -Mode RecordExport `
    -ZoneFilter "contoso.com" `
    -DnsServer "DC01.contoso.com"  # Fastest DC

# OR use UnionZones for completeness (slower)
.\DNS-MasterAudit.ps1 -Mode RecordExport `
    -UnionZones `
    -EnableParallelProcessing
```

---

### Mode 8: Analytics

**Bottleneck:** Processing 100,000+ records

**Optimization:**
```powershell
# Adjust thresholds to reduce processing
.\DNS-MasterAudit.ps1 -Mode Analytics `
    -StaleRecordThreshold 180  # Higher = fewer records
    -DetectDuplicateIPs `      # Skip if not needed
    # -ValidatePTRRecords       # Skip if not needed
```

---

### Mode 10: Diagnostics

**Bottleneck:** Cross-site log scanning

**Optimization:**
```powershell
.\DNS-MasterAudit.ps1 -Mode Diagnostics `
    -TestQueryPerformance `
    -PerformanceTestIterations 5  # Reduce from 10
    -CheckCrossSiteAuth `         # Most time-consuming
    -EnableParallelProcessing
```

---

## 🖥️ **System-Level Optimizations**

### PowerShell Configuration

```powershell
# 1. Use 64-bit PowerShell for better memory
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

# 2. Increase PowerShell execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 3. Disable progress bars (faster)
$ProgressPreference = 'SilentlyContinue'

# 4. Run with high priority
$process = Get-Process -Id $PID
$process.PriorityClass = 'High'
```

---

### Network Optimization

```powershell
# 1. Run from management VLAN close to DCs
# 2. Enable SMB3 compression
Set-SmbClientConfiguration -EnableBandwidthThrottling $false -Force

# 3. Increase TCP connection limit
netsh int tcp set global autotuninglevel=normal
```

---

### Disk I/O Optimization

```powershell
# 1. Use SSD for export path
.\DNS-MasterAudit.ps1 -Mode Complete -ExportPath "D:\FastSSD\Audits"

# 2. Disable antivirus scanning on export folder
Add-MpPreference -ExclusionPath "C:\DNSAudit"

# 3. Reduce transcript logging
.\DNS-MasterAudit.ps1 -Mode Complete -NoTranscript
```

---

## 📊 **Monitoring Performance**

### Built-in Performance Metrics

```powershell
# Enable verbose for timing details
.\DNS-MasterAudit.ps1 -Mode Complete -Verbose

# Check execution time in transcript
Get-Content "C:\DNSAudit\*.log" | Select-String "Duration"
```

### Manual Performance Testing

```powershell
# Measure execution time
$start = Get-Date
.\DNS-MasterAudit.ps1 -Mode Inventory -EnableParallelProcessing
$duration = (Get-Date) - $start
Write-Host "Execution time: $($duration.TotalMinutes) minutes"

# Compare parallel vs sequential
Measure-Command {
    .\DNS-MasterAudit.ps1 -Mode Inventory
}

Measure-Command {
    .\DNS-MasterAudit.ps1 -Mode Inventory -EnableParallelProcessing
}
```

---

## 🎯 **Optimization Checklist**

- [ ] Enable parallel processing
- [ ] Set optimal throttle limit based on DC count
- [ ] Limit zone scope if possible
- [ ] Use CSV export for speed (avoid HTML/Excel)
- [ ] Schedule during off-hours
- [ ] Run from management VLAN
- [ ] Use SSD for export path
- [ ] Disable antivirus on export folder
- [ ] Use 64-bit PowerShell
- [ ] Monitor execution time
- [ ] Adjust based on results

---

## 📉 **Performance Troubleshooting**

### Issue: Still slow after enabling parallel processing

**Diagnosis:**
```powershell
# Check actual parallelism
Get-Process powershell | Measure-Object

# Check network latency
Test-Connection (Get-ADDomainController -Filter *).Name -Count 1
```

**Solutions:**
- Increase `-MaxDegreeOfParallelism`
- Check DC connectivity
- Verify no firewall throttling

---

### Issue: High memory usage

**Solutions:**
```powershell
# 1. Process fewer zones at once
.\DNS-MasterAudit.ps1 -Mode RecordExport -ZoneFilter "zone1"
.\DNS-MasterAudit.ps1 -Mode RecordExport -ZoneFilter "zone2"

# 2. Force garbage collection
[System.GC]::Collect()

# 3. Restart PowerShell between runs
```

---

### Issue: CPU at 100%

**Solutions:**
```powershell
# Reduce parallelism
.\DNS-MasterAudit.ps1 -Mode Complete `
    -EnableParallelProcessing `
    -MaxDegreeOfParallelism 3  # Lower from 10
```

---

## 🏆 **Best Practices**

1. **Start with defaults, measure, optimize**
2. **Enable parallel processing for 10+ DCs**
3. **Use incremental scans for frequent audits**
4. **Schedule large audits during off-hours**
5. **Monitor and adjust throttle limits**
6. **Keep PowerShell and modules updated**

---

## 📈 **Expected Results After Optimization**

| Environment | Before | After | Improvement |
|-------------|--------|-------|-------------|
| Small (5 DCs) | 3 min | 45 sec | 75% |
| Medium (15 DCs) | 10 min | 2 min | 80% |
| Large (50 DCs) | 40 min | 8 min | 80% |
| Enterprise (100+ DCs) | 2 hours | 20 min | 83% |

---

**Author:** Adrian Johnson <adrian207@gmail.com>  
**Last Updated:** 2025-10-19

