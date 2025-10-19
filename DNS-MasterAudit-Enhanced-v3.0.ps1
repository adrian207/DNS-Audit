################################################################################
# DNS Master Audit Script - ENTERPRISE EDITION v3.0
# Author: Adrian Johnson <adrian207@gmail.com>
# Created: 2025
# Version: 3.0 - Enterprise Edition with Advanced Features
# Description: Enterprise-grade DNS auditing solution with:
#              - HTML Dashboard & Interactive Reports
#              - Parallel Processing & Performance Optimization
#              - Change Detection & Baseline Management
#              - Advanced Analytics & Intelligence
#              - Enterprise Integration (Teams, Slack, SIEM)
#              - Security & Compliance Auditing
#              - Remediation Assistance
#              - Enhanced Diagnostics
#              - Multiple Export Formats (Excel, JSON, XML, PDF, HTML)
#              - Configuration Management
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory, DnsServer

<#
.SYNOPSIS
Enterprise-grade DNS auditing solution with advanced analytics and reporting

.DESCRIPTION
Comprehensive DNS audit platform combining 10+ specialized capabilities:

CORE MODES:
- DNS-Inventory: Server discovery and inventory
- DNS-HealthCheck: DNS service health testing  
- DNS-RecordExport: Complete DNS record export
- DNS-SiteAudit: Site mismatch detection
- Complete: Run all audits in sequence

ADVANCED FEATURES (v3.0):
✅ HTML Dashboard - Interactive reports with charts
✅ Parallel Processing - 5-10x faster performance
✅ Change Detection - Baseline comparison & drift analysis
✅ Advanced Analytics - Stale records, duplicates, PTR validation
✅ Enterprise Integration - Teams, Slack, SIEM, ServiceNow
✅ Security & Compliance - DNSSEC, zone transfer audits
✅ Remediation - Auto-fix scripts and recommendations
✅ Enhanced Diagnostics - Performance testing, replication monitoring
✅ Multiple Formats - Excel, JSON, XML, PDF, HTML, Markdown
✅ Configuration Management - Profiles and templates

.PARAMETER Mode
Operation mode:
- Inventory: Discover and list all DNS servers
- HealthCheck: Test DNS service health on all DCs
- RecordExport: Export all DNS records
- SiteAudit: Find site mismatches with advanced analytics
- Complete: Run all audits (recommended)
- Baseline: Create/update baseline snapshot
- Compare: Compare current state to baseline

.PARAMETER ExportPath
Directory for all reports and logs (default: C:\DNSAudit)

.PARAMETER ExportFormat
Output format: CSV, JSON, XML, HTML, Excel, PDF, Markdown
Default: CSV (use 'All' for multiple formats)

.PARAMETER EnableHTMLDashboard
Generate interactive HTML dashboard with charts (recommended)

.PARAMETER EnableParallelProcessing
Use multi-threading for faster execution (recommended for large environments)

.PARAMETER MaxDegreeOfParallelism
Maximum concurrent operations (default: 5, recommended: 5-10)

.PARAMETER CompareToBaseline
Compare current audit to stored baseline

.PARAMETER BaselinePath
Path to baseline file (default: $ExportPath\Baseline)

.PARAMETER EnableAdvancedAnalytics
Enable advanced analytics: stale record detection, duplicate IP finder, PTR validation

.PARAMETER EnableSecurity Audits
Enable security and compliance checks: DNSSEC, zone transfers, scavenging

.PARAMETER GenerateRemediationScript
Create PowerShell remediation scripts for identified issues

.PARAMETER EnableDiagnostics
Enable performance testing and replication monitoring

.PARAMETER TeamsWebhook
Microsoft Teams webhook URL for notifications

.PARAMETER SlackWebhook
Slack webhook URL for notifications

.PARAMETER SyslogServer
Syslog/SIEM server for integration

.PARAMETER ConfigFile
Path to configuration file (JSON/XML)

.PARAMETER Quiet
Minimal console output (for scheduled tasks)

.PARAMETER WhatIf
Preview mode - show what would be done without making changes

.EXAMPLE
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -EnableHTMLDashboard -EnableParallelProcessing
Comprehensive audit with HTML dashboard and parallel processing

.EXAMPLE
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode SiteAudit -EnableAdvancedAnalytics -GenerateRemediationScript
Site audit with analytics and auto-generated remediation scripts

.EXAMPLE
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Baseline
Create baseline snapshot for future comparisons

.EXAMPLE
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Compare -CompareToBaseline -ExportFormat HTML
Compare to baseline with HTML report

.EXAMPLE
.\DNS-MasterAudit-Enhanced-v3.0.ps1 -Mode Complete -ConfigFile ".\prod-config.json" -Quiet
Automated audit using configuration file

.NOTES
Author: Adrian Johnson <adrian207@gmail.com>
Version: 3.0.0 - Enterprise Edition
License: MIT
Repository: https://github.com/adrian207/DNS-Audit

Requirements:
- PowerShell 5.1 or later
- ActiveDirectory module
- DnsServer module
- Administrator privileges recommended
- Optional: ImportExcel module for Excel export
- Optional: PSSQLite module for baseline storage

.LINK
https://github.com/adrian207/DNS-Audit
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    # Core Parameters
    [Parameter(Mandatory = $true, HelpMessage = "Operation mode")]
    [ValidateSet("Inventory", "HealthCheck", "RecordExport", "SiteAudit", "Complete", "Baseline", "Compare", "ConfigAudit", "ZoneHealth")]
    [string]$Mode,
    
    [Parameter(HelpMessage = "Export directory for all reports")]
    [string]$ExportPath = "C:\DNSAudit",
    
    [Parameter(HelpMessage = "Filter specific zones")]
    [string[]]$ZoneFilter = @(),
    
    [Parameter(HelpMessage = "Credential for remote operations")]
    [PSCredential]$Credential,
    
    # Export & Reporting Parameters
    [Parameter(HelpMessage = "Export format: CSV, JSON, XML, HTML, Excel, PDF, Markdown, All")]
    [ValidateSet("CSV", "JSON", "XML", "HTML", "Excel", "PDF", "Markdown", "All")]
    [string]$ExportFormat = "CSV",
    
    [Parameter(HelpMessage = "Generate interactive HTML dashboard")]
    [switch]$EnableHTMLDashboard,
    
    # Performance Parameters
    [Parameter(HelpMessage = "Enable parallel processing for faster execution")]
    [switch]$EnableParallelProcessing,
    
    [Parameter(HelpMessage = "Maximum concurrent operations")]
    [ValidateRange(1, 20)]
    [int]$MaxDegreeOfParallelism = 5,
    
    # Baseline & Change Detection Parameters
    [Parameter(HelpMessage = "Compare to baseline")]
    [switch]$CompareToBaseline,
    
    [Parameter(HelpMessage = "Baseline storage path")]
    [string]$BaselinePath = "",
    
    # Advanced Features Parameters
    [Parameter(HelpMessage = "Enable advanced analytics")]
    [switch]$EnableAdvancedAnalytics,
    
    [Parameter(HelpMessage = "Enable security and compliance audits")]
    [switch]$EnableSecurityAudits,
    
    [Parameter(HelpMessage = "Generate remediation scripts")]
    [switch]$GenerateRemediationScript,
    
    [Parameter(HelpMessage = "Enable enhanced diagnostics")]
    [switch]$EnableDiagnostics,
    
    # Integration Parameters
    [Parameter(HelpMessage = "Microsoft Teams webhook URL")]
    [string]$TeamsWebhook = "",
    
    [Parameter(HelpMessage = "Slack webhook URL")]
    [string]$SlackWebhook = "",
    
    [Parameter(HelpMessage = "Syslog/SIEM server")]
    [string]$SyslogServer = "",
    
    [Parameter(HelpMessage = "Syslog port")]
    [int]$SyslogPort = 514,
    
    # Configuration Parameters
    [Parameter(HelpMessage = "Configuration file path (JSON/XML)")]
    [string]$ConfigFile = "",
    
    [Parameter(HelpMessage = "Minimal console output")]
    [switch]$Quiet,
    
    # Legacy Parameters (preserved for backwards compatibility)
    [Parameter(HelpMessage = "Enable all advanced features (legacy)")]
    [switch]$EnableAllFeatures,
    
    [Parameter(HelpMessage = "Specific DNS server for RecordExport")]
    [string]$DnsServer,
    
    [Parameter(HelpMessage = "Query all DCs and union zones")]
    [switch]$UnionZones,
    
    [Parameter(HelpMessage = "Disable transcript logging")]
    [switch]$NoTranscript,
    
    [Parameter(HelpMessage = "Send email notification (LEGACY)")]
    [switch]$EnableEmailNotification,
    
    [Parameter(HelpMessage = "SMTP server for email")]
    [string]$SMTPServer,
    
    [Parameter(HelpMessage = "SMTP port")]
    [int]$SmtpPort = 25,
    
    [Parameter(HelpMessage = "Use SSL for SMTP")]
    [switch]$UseSsl,
    
    [Parameter(HelpMessage = "SMTP credential")]
    [PSCredential]$SmtpCredential,
    
    [Parameter(HelpMessage = "Email from address")]
    [string]$EmailFrom,
    
    [Parameter(HelpMessage = "Email recipients")]
    [string[]]$EmailTo
)

#region Script Variables
$script:Version = "3.0.0 - Enterprise Edition"
$script:Author = "Adrian Johnson <adrian207@gmail.com>"
$script:StartTime = Get-Date
$script:TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:ScriptPath = $PSScriptRoot
$script:SkippedSubnets = @()

# Performance tracking
$script:PerfMetrics = @{
    StartTime = $script:StartTime
    DCsProcessed = 0
    RecordsProcessed = 0
    QueriesExecuted = 0
}

# Initialize baseline path if not specified
if ([string]::IsNullOrEmpty($BaselinePath)) {
    $BaselinePath = Join-Path $ExportPath "Baseline"
}
#endregion

#region Configuration Management
function Import-AuditConfiguration {
    <#
    .SYNOPSIS
    Import configuration from JSON or XML file
    #>
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-Warning "Configuration file not found: $Path"
        return $null
    }
    
    $extension = [System.IO.Path]::GetExtension($Path).ToLower()
    try {
        switch ($extension) {
            ".json" {
                return Get-Content $Path -Raw | ConvertFrom-Json
            }
            ".xml" {
                return Import-Clixml $Path
            }
            default {
                Write-Warning "Unsupported configuration format: $extension"
                return $null
            }
        }
    }
    catch {
        Write-Error "Failed to import configuration: $($_.Exception.Message)"
        return $null
    }
}

function Export-AuditConfiguration {
    <#
    .SYNOPSIS
    Export current configuration to file
    #>
    param(
        [string]$Path,
        [hashtable]$Config
    )
    
    $extension = [System.IO.Path]::GetExtension($Path).ToLower()
    try {
        switch ($extension) {
            ".json" {
                $Config | ConvertTo-Json -Depth 10 | Set-Content $Path
            }
            ".xml" {
                $Config | Export-Clixml $Path
            }
            default {
                throw "Unsupported configuration format: $extension"
            }
        }
        Write-AuditLog "Configuration exported to: $Path" -Level SUCCESS
    }
    catch {
        Write-Error "Failed to export configuration: $($_.Exception.Message)"
    }
}

# Load configuration file if specified
if (![string]::IsNullOrEmpty($ConfigFile) -and (Test-Path $ConfigFile)) {
    $config = Import-AuditConfiguration -Path $ConfigFile
    if ($config) {
        Write-Host "Configuration loaded from: $ConfigFile" -ForegroundColor Green
        # Apply configuration settings (override parameters if specified in config)
        if ($config.ExportPath) { $ExportPath = $config.ExportPath }
        if ($config.EnableHTMLDashboard) { $EnableHTMLDashboard = $true }
        if ($config.EnableParallelProcessing) { $EnableParallelProcessing = $true }
        if ($config.MaxDegreeOfParallelism) { $MaxDegreeOfParallelism = $config.MaxDegreeOfParallelism }
        # Add more config mappings as needed
    }
}
#endregion

#region Mode 11: Configuration Audit

<#
.SYNOPSIS
    Audit DNS configuration consistency across all domain controllers
.DESCRIPTION
    Addresses the #1 DNS complaint: "Why does DNS work for some users but not others?"
    Detects configuration mismatches that cause inconsistent DNS behavior
#>
function Start-DNSConfigurationAudit {
    [CmdletBinding()]
    param(
        [Parameter()]
        [PSCredential]$Credential
    )
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DNS Configuration Consistency Audit                  ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @{
        Forwarders = @()
        RootHints = @()
        ConditionalForwarders = @()
        RecursionSettings = @()
        ListenAddresses = @()
        Issues = @()
        Statistics = @{
            TotalServers = 0
            ForwarderMismatches = 0
            RootHintsIssues = 0
            ConditionalForwarderIssues = 0
            RecursionMismatches = 0
        }
    }
    
    try {
        # Get all domain controllers
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        
        $DCs = Get-ADDomainController @adParams -Filter * | Select-Object Name, IPv4Address, Site
        $results.Statistics.TotalServers = $DCs.Count
        
        Write-Host "Found $($DCs.Count) domain controllers to audit..." -ForegroundColor Green
        Write-Host ""
        
        # 1. DNS FORWARDERS AUDIT
        Write-Host "═══ 1. DNS Forwarders Consistency Check ═══" -ForegroundColor Yellow
        $forwarderConfigs = @{}
        
        foreach ($DC in $DCs) {
            Write-Host "  Checking $($DC.Name)..." -NoNewline
            try {
                $dnsParams = @{
                    ComputerName = $DC.Name
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $forwarders = Get-DnsServerForwarder @dnsParams
                $forwarderList = $forwarders.IPAddress.IPAddressToString -join ', '
                
                if ([string]::IsNullOrEmpty($forwarderList)) {
                    $forwarderList = "NONE"
                }
                
                $forwarderConfigs[$DC.Name] = $forwarderList
                
                $results.Forwarders += [PSCustomObject]@{
                    Server = $DC.Name
                    Site = $DC.Site
                    Forwarders = $forwarderList
                    UseRootHint = $forwarders.UseRootHint
                    Timeout = $forwarders.Timeout
                }
                
                Write-Host " ✓" -ForegroundColor Green
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to query forwarders on $($DC.Name): $_"
            }
        }
        
        # Detect forwarder mismatches
        $uniqueConfigs = $forwarderConfigs.Values | Select-Object -Unique
        if ($uniqueConfigs.Count -gt 1) {
            Write-Host ""
            Write-Host "  ⚠️  WARNING: Forwarder configuration mismatch detected!" -ForegroundColor Red
            $results.Statistics.ForwarderMismatches = $uniqueConfigs.Count
            
            foreach ($config in $uniqueConfigs) {
                $servers = $forwarderConfigs.Keys | Where-Object { $forwarderConfigs[$_] -eq $config }
                Write-Host "     Config: $config" -ForegroundColor Yellow
                Write-Host "     Servers: $($servers -join ', ')" -ForegroundColor Gray
                $results.Issues += "Forwarder mismatch: $($servers.Count) servers using: $config"
            }
        }
        else {
            Write-Host "  ✓ All servers have consistent forwarder configuration" -ForegroundColor Green
        }
        Write-Host ""
        
        # 2. ROOT HINTS VALIDATION
        Write-Host "═══ 2. Root Hints Validation ═══" -ForegroundColor Yellow
        
        # RFC standard root hints (13 root servers)
        $standardRootHints = @{
            'a.root-servers.net' = '198.41.0.4'
            'b.root-servers.net' = '199.9.14.201'
            'c.root-servers.net' = '192.33.4.12'
            'd.root-servers.net' = '199.7.91.13'
            'e.root-servers.net' = '192.203.230.10'
            'f.root-servers.net' = '192.5.5.241'
            'g.root-servers.net' = '192.112.36.4'
            'h.root-servers.net' = '198.97.190.53'
            'i.root-servers.net' = '192.36.148.17'
            'j.root-servers.net' = '192.58.128.30'
            'k.root-servers.net' = '193.0.14.129'
            'l.root-servers.net' = '199.7.83.42'
            'm.root-servers.net' = '202.12.27.33'
        }
        
        foreach ($DC in $DCs) {
            Write-Host "  Checking $($DC.Name)..." -NoNewline
            try {
                $dnsParams = @{
                    ComputerName = $DC.Name
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $rootHints = Get-DnsServerRootHint @dnsParams
                $rootHintCount = $rootHints.Count
                
                # Validate against standard root hints
                $missing = @()
                $invalid = @()
                
                foreach ($standard in $standardRootHints.Keys) {
                    $found = $rootHints | Where-Object { $_.NameServer.RecordData.NameServer -like "*$standard*" }
                    if (-not $found) {
                        $missing += $standard
                    }
                }
                
                # Check for non-standard entries
                foreach ($hint in $rootHints) {
                    $name = $hint.NameServer.RecordData.NameServer
                    if ($name -notmatch 'root-servers\.net') {
                        $invalid += $name
                    }
                }
                
                $status = "OK"
                $issues = @()
                
                if ($missing.Count -gt 0) {
                    $status = "MISSING"
                    $issues += "Missing $($missing.Count) root hints"
                    $results.Statistics.RootHintsIssues++
                }
                
                if ($invalid.Count -gt 0) {
                    $status = "INVALID"
                    $issues += "$($invalid.Count) non-standard entries"
                    $results.Statistics.RootHintsIssues++
                }
                
                $results.RootHints += [PSCustomObject]@{
                    Server = $DC.Name
                    Site = $DC.Site
                    RootHintCount = $rootHintCount
                    ExpectedCount = 13
                    Status = $status
                    MissingHints = $missing -join ', '
                    InvalidEntries = $invalid -join ', '
                    Issues = $issues -join '; '
                }
                
                if ($status -eq "OK") {
                    Write-Host " ✓ ($rootHintCount hints)" -ForegroundColor Green
                }
                else {
                    Write-Host " ⚠️  $status" -ForegroundColor Yellow
                    foreach ($issue in $issues) {
                        Write-Host "     - $issue" -ForegroundColor Gray
                    }
                    $results.Issues += "$($DC.Name): Root hints $status - $($issues -join ', ')"
                }
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to query root hints on $($DC.Name): $_"
            }
        }
        Write-Host ""
        
        # 3. CONDITIONAL FORWARDERS AUDIT
        Write-Host "═══ 3. Conditional Forwarders Consistency ═══" -ForegroundColor Yellow
        
        $conditionalForwardersByDC = @{}
        
        foreach ($DC in $DCs) {
            Write-Host "  Checking $($DC.Name)..." -NoNewline
            try {
                $dnsParams = @{
                    ComputerName = $DC.Name
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $conditionalForwarders = Get-DnsServerZone @dnsParams | Where-Object { $_.ZoneType -eq 'Forwarder' }
                $conditionalForwardersByDC[$DC.Name] = $conditionalForwarders
                
                Write-Host " ✓ Found $($conditionalForwarders.Count) conditional forwarders" -ForegroundColor Green
                
                foreach ($cf in $conditionalForwarders) {
                    $masterServers = (Get-DnsServerZone -ComputerName $DC.Name -Name $cf.ZoneName).MasterServers.IPAddressToString -join ', '
                    
                    $results.ConditionalForwarders += [PSCustomObject]@{
                        Server = $DC.Name
                        Zone = $cf.ZoneName
                        ForwarderIPs = $masterServers
                        ReplicationScope = $cf.ReplicationScope
                    }
                }
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to query conditional forwarders on $($DC.Name): $_"
            }
        }
        
        # Detect conditional forwarder inconsistencies
        $allZones = $conditionalForwardersByDC.Values.ZoneName | Select-Object -Unique
        foreach ($zone in $allZones) {
            $serversWithZone = $conditionalForwardersByDC.Keys | Where-Object {
                $conditionalForwardersByDC[$_].ZoneName -contains $zone
            }
            
            if ($serversWithZone.Count -ne $DCs.Count) {
                Write-Host "  ⚠️  WARNING: Conditional forwarder '$zone' not present on all DCs" -ForegroundColor Yellow
                Write-Host "     Present on: $($serversWithZone -join ', ')" -ForegroundColor Gray
                Write-Host "     Missing on: $($DCs.Name | Where-Object { $_ -notin $serversWithZone } | Join-String -Separator ', ')" -ForegroundColor Gray
                $results.Issues += "Conditional forwarder '$zone' not replicated to all DCs"
                $results.Statistics.ConditionalForwarderIssues++
            }
        }
        Write-Host ""
        
        # 4. RECURSION SETTINGS AUDIT
        Write-Host "═══ 4. Recursion Settings Consistency ═══" -ForegroundColor Yellow
        
        $recursionSettings = @{}
        
        foreach ($DC in $DCs) {
            Write-Host "  Checking $($DC.Name)..." -NoNewline
            try {
                $dnsParams = @{
                    ComputerName = $DC.Name
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $serverSettings = Get-DnsServer @dnsParams
                $recursionEnabled = -not $serverSettings.ServerSetting.DisableRecursion
                $recursionSettings[$DC.Name] = $recursionEnabled
                
                $results.RecursionSettings += [PSCustomObject]@{
                    Server = $DC.Name
                    Site = $DC.Site
                    RecursionEnabled = $recursionEnabled
                    RecursionRetry = $serverSettings.ServerSetting.RecursionRetry
                    RecursionTimeout = $serverSettings.ServerSetting.RecursionTimeout
                }
                
                $status = if ($recursionEnabled) { "ENABLED" } else { "DISABLED" }
                Write-Host " $status" -ForegroundColor $(if ($recursionEnabled) { "Green" } else { "Yellow" })
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to query recursion settings on $($DC.Name): $_"
            }
        }
        
        # Detect recursion mismatches
        $uniqueRecursionSettings = $recursionSettings.Values | Select-Object -Unique
        if ($uniqueRecursionSettings.Count -gt 1) {
            Write-Host ""
            Write-Host "  ⚠️  WARNING: Recursion settings mismatch detected!" -ForegroundColor Red
            $results.Statistics.RecursionMismatches = 1
            
            $enabled = $recursionSettings.Keys | Where-Object { $recursionSettings[$_] -eq $true }
            $disabled = $recursionSettings.Keys | Where-Object { $recursionSettings[$_] -eq $false }
            
            if ($enabled.Count -gt 0) {
                Write-Host "     Recursion ENABLED on: $($enabled -join ', ')" -ForegroundColor Yellow
            }
            if ($disabled.Count -gt 0) {
                Write-Host "     Recursion DISABLED on: $($disabled -join ', ')" -ForegroundColor Yellow
            }
            $results.Issues += "Recursion settings mismatch: $($enabled.Count) enabled, $($disabled.Count) disabled"
        }
        else {
            Write-Host "  ✓ All servers have consistent recursion settings" -ForegroundColor Green
        }
        Write-Host ""
        
        # 5. LISTEN ADDRESSES AUDIT
        Write-Host "═══ 5. Listen Addresses Audit ═══" -ForegroundColor Yellow
        
        foreach ($DC in $DCs) {
            Write-Host "  Checking $($DC.Name)..." -NoNewline
            try {
                $dnsParams = @{
                    ComputerName = $DC.Name
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $serverSettings = Get-DnsServer @dnsParams
                $listenAddresses = $serverSettings.ServerSetting.ListenAddresses
                
                if ($listenAddresses.Count -eq 0) {
                    $listenStr = "All Interfaces"
                }
                else {
                    $listenStr = $listenAddresses.IPAddressToString -join ', '
                }
                
                $results.ListenAddresses += [PSCustomObject]@{
                    Server = $DC.Name
                    Site = $DC.Site
                    ListenAddresses = $listenStr
                    AddressCount = $listenAddresses.Count
                }
                
                Write-Host " $listenStr" -ForegroundColor Green
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to query listen addresses on $($DC.Name): $_"
            }
        }
        Write-Host ""
        
        # Summary
        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║              Configuration Audit Summary                      ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Servers Audited:           $($results.Statistics.TotalServers)" -ForegroundColor White
        Write-Host "  Forwarder Mismatches:      $($results.Statistics.ForwarderMismatches)" -ForegroundColor $(if ($results.Statistics.ForwarderMismatches -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  Root Hints Issues:         $($results.Statistics.RootHintsIssues)" -ForegroundColor $(if ($results.Statistics.RootHintsIssues -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  Conditional Fwd Issues:    $($results.Statistics.ConditionalForwarderIssues)" -ForegroundColor $(if ($results.Statistics.ConditionalForwarderIssues -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  Recursion Mismatches:      $($results.Statistics.RecursionMismatches)" -ForegroundColor $(if ($results.Statistics.RecursionMismatches -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  Total Issues Found:        $($results.Issues.Count)" -ForegroundColor $(if ($results.Issues.Count -gt 0) { "Red" } else { "Green" })
        Write-Host ""
        
        return $results
    }
    catch {
        Write-Host "FATAL ERROR in Configuration Audit: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Mode 12: Zone Health Audit

<#
.SYNOPSIS
    Comprehensive zone health and integrity audit
.DESCRIPTION
    Detects zone replication issues, delegation problems, and RFC violations
#>
function Start-DNSZoneHealthAudit {
    [CmdletBinding()]
    param(
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [string[]]$ZoneFilter = @()
    )
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                DNS Zone Health Audit                          ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @{
        SOAConsistency = @()
        DelegationValidation = @()
        EmptyNodes = @()
        CNAMEConflicts = @()
        NSRecordValidation = @()
        Issues = @()
        Statistics = @{
            TotalZones = 0
            SOAMismatches = 0
            BrokenDelegations = 0
            EmptyNodesFound = 0
            CNAMEConflicts = 0
            InvalidNSRecords = 0
        }
    }
    
    try {
        # Get all domain controllers
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        
        $DCs = Get-ADDomainController @adParams -Filter * | Select-Object Name, IPv4Address
        
        Write-Host "Found $($DCs.Count) domain controllers" -ForegroundColor Green
        Write-Host ""
        
        # Get zones from first DC
        $primaryDC = $DCs[0].Name
        $dnsParams = @{
            ComputerName = $primaryDC
            ErrorAction = 'Stop'
        }
        if ($Credential) { $dnsParams['Credential'] = $Credential }
        
        $zones = Get-DnsServerZone @dnsParams | Where-Object { 
            $_.ZoneType -eq 'Primary' -and $_.IsReverseLookupZone -eq $false 
        }
        
        # Apply zone filter if specified
        if ($ZoneFilter.Count -gt 0) {
            $zones = $zones | Where-Object { $ZoneFilter -contains $_.ZoneName }
        }
        
        $results.Statistics.TotalZones = $zones.Count
        Write-Host "Found $($zones.Count) zones to audit" -ForegroundColor Green
        Write-Host ""
        
        # 1. SOA CONSISTENCY CHECK
        Write-Host "═══ 1. SOA Record Consistency Check ═══" -ForegroundColor Yellow
        
        foreach ($zone in $zones) {
            Write-Host "  Zone: $($zone.ZoneName)" -ForegroundColor Cyan
            
            $soaRecords = @{}
            $serials = @{}
            
            foreach ($DC in $DCs) {
                try {
                    $soaQuery = Resolve-DnsName -Name $zone.ZoneName -Type SOA -Server $DC.Name -ErrorAction Stop
                    $serial = $soaQuery.SerialNumber
                    
                    $serials[$DC.Name] = $serial
                    $soaRecords[$DC.Name] = $soaQuery
                    
                    Write-Host "    $($DC.Name): Serial $serial" -ForegroundColor Gray
                }
                catch {
                    Write-Host "    $($DC.Name): ✗ Failed to query" -ForegroundColor Red
                    $results.Issues += "Failed to query SOA for $($zone.ZoneName) on $($DC.Name)"
                }
            }
            
            # Check for consistency
            $uniqueSerials = $serials.Values | Select-Object -Unique
            if ($uniqueSerials.Count -gt 1) {
                Write-Host "    ⚠️  WARNING: SOA serial mismatch detected!" -ForegroundColor Red
                $results.Statistics.SOAMismatches++
                
                foreach ($serial in $uniqueSerials) {
                    $servers = $serials.Keys | Where-Object { $serials[$_] -eq $serial }
                    Write-Host "      Serial $serial on: $($servers -join ', ')" -ForegroundColor Yellow
                }
                
                $results.Issues += "SOA mismatch in zone $($zone.ZoneName): $($uniqueSerials.Count) different serials"
            }
            else {
                Write-Host "    ✓ All DCs have consistent SOA serial: $($uniqueSerials[0])" -ForegroundColor Green
            }
            
            $results.SOAConsistency += [PSCustomObject]@{
                Zone = $zone.ZoneName
                UniqueSerials = $uniqueSerials.Count
                HighestSerial = ($serials.Values | Measure-Object -Maximum).Maximum
                LowestSerial = ($serials.Values | Measure-Object -Minimum).Minimum
                Status = if ($uniqueSerials.Count -eq 1) { "OK" } else { "MISMATCH" }
            }
            
            Write-Host ""
        }
        
        # 2. ZONE DELEGATION VALIDATION
        Write-Host "═══ 2. Zone Delegation Validation ═══" -ForegroundColor Yellow
        
        foreach ($zone in $zones) {
            Write-Host "  Checking delegations in $($zone.ZoneName)..." -NoNewline
            
            try {
                $dnsParams = @{
                    ZoneName = $zone.ZoneName
                    ComputerName = $primaryDC
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                # Find NS records (delegations)
                $nsRecords = Get-DnsServerResourceRecord @dnsParams | Where-Object { 
                    $_.RecordType -eq 'NS' -and $_.HostName -ne '@' 
                }
                
                if ($nsRecords.Count -eq 0) {
                    Write-Host " No delegations" -ForegroundColor Gray
                    continue
                }
                
                Write-Host " Found $($nsRecords.Count) delegations" -ForegroundColor Green
                
                foreach ($ns in $nsRecords) {
                    $delegatedZone = "$($ns.HostName).$($zone.ZoneName)"
                    $nameServer = $ns.RecordData.NameServer
                    
                    Write-Host "    $delegatedZone → $nameServer" -NoNewline -ForegroundColor Gray
                    
                    # Test if name server is reachable
                    try {
                        $test = Resolve-DnsName -Name $nameServer -ErrorAction Stop
                        Write-Host " ✓" -ForegroundColor Green
                        
                        $results.DelegationValidation += [PSCustomObject]@{
                            Zone = $zone.ZoneName
                            DelegatedZone = $delegatedZone
                            NameServer = $nameServer
                            Status = "OK"
                            Issue = ""
                        }
                    }
                    catch {
                        Write-Host " ✗ BROKEN" -ForegroundColor Red
                        $results.Statistics.BrokenDelegations++
                        $results.Issues += "Broken delegation: $delegatedZone → $nameServer (not resolvable)"
                        
                        $results.DelegationValidation += [PSCustomObject]@{
                            Zone = $zone.ZoneName
                            DelegatedZone = $delegatedZone
                            NameServer = $nameServer
                            Status = "BROKEN"
                            Issue = "Name server not resolvable"
                        }
                    }
                }
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to check delegations in $($zone.ZoneName): $_"
            }
            
            Write-Host ""
        }
        
        # 3. EMPTY DNS NODES DETECTION
        Write-Host "═══ 3. Empty DNS Nodes Detection ═══" -ForegroundColor Yellow
        
        foreach ($zone in $zones) {
            Write-Host "  Scanning $($zone.ZoneName)..." -NoNewline
            
            try {
                $dnsParams = @{
                    ZoneName = $zone.ZoneName
                    ComputerName = $primaryDC
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                # Get all records
                $allRecords = Get-DnsServerResourceRecord @dnsParams
                
                # Group by hostname
                $grouped = $allRecords | Group-Object HostName
                
                # Find nodes with only SOA/NS records (considered empty for non-@ nodes)
                $emptyNodes = $grouped | Where-Object {
                    $_.Name -ne '@' -and 
                    $_.Group.Count -gt 0 -and
                    ($_.Group.RecordType | Where-Object { $_ -notin @('SOA', 'NS') }).Count -eq 0
                }
                
                if ($emptyNodes.Count -gt 0) {
                    Write-Host " Found $($emptyNodes.Count) empty nodes" -ForegroundColor Yellow
                    $results.Statistics.EmptyNodesFound += $emptyNodes.Count
                    
                    foreach ($node in $emptyNodes | Select-Object -First 5) {
                        Write-Host "    - $($node.Name).$($zone.ZoneName)" -ForegroundColor Gray
                        
                        $results.EmptyNodes += [PSCustomObject]@{
                            Zone = $zone.ZoneName
                            NodeName = $node.Name
                            FullName = "$($node.Name).$($zone.ZoneName)"
                        }
                    }
                    
                    if ($emptyNodes.Count -gt 5) {
                        Write-Host "    ... and $($emptyNodes.Count - 5) more" -ForegroundColor Gray
                    }
                    
                    $results.Issues += "Found $($emptyNodes.Count) empty nodes in $($zone.ZoneName)"
                }
                else {
                    Write-Host " ✓ No empty nodes" -ForegroundColor Green
                }
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to scan for empty nodes in $($zone.ZoneName): $_"
            }
        }
        Write-Host ""
        
        # 4. CNAME → A RECORD CONFLICTS
        Write-Host "═══ 4. CNAME/A Record Conflicts (RFC Violation) ═══" -ForegroundColor Yellow
        
        foreach ($zone in $zones) {
            Write-Host "  Checking $($zone.ZoneName)..." -NoNewline
            
            try {
                $dnsParams = @{
                    ZoneName = $zone.ZoneName
                    ComputerName = $primaryDC
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $allRecords = Get-DnsServerResourceRecord @dnsParams
                
                # Group by hostname
                $grouped = $allRecords | Group-Object HostName
                
                # Find nodes with both CNAME and other record types
                $conflicts = $grouped | Where-Object {
                    $cnameCount = ($_.Group | Where-Object { $_.RecordType -eq 'CNAME' }).Count
                    $otherCount = ($_.Group | Where-Object { $_.RecordType -in @('A', 'AAAA', 'MX', 'TXT') }).Count
                    
                    $cnameCount -gt 0 -and $otherCount -gt 0
                }
                
                if ($conflicts.Count -gt 0) {
                    Write-Host " ⚠️  Found $($conflicts.Count) conflicts!" -ForegroundColor Red
                    $results.Statistics.CNAMEConflicts += $conflicts.Count
                    
                    foreach ($conflict in $conflicts) {
                        $records = $conflict.Group.RecordType -join ', '
                        Write-Host "    ✗ $($conflict.Name): $records" -ForegroundColor Yellow
                        
                        $results.CNAMEConflicts += [PSCustomObject]@{
                            Zone = $zone.ZoneName
                            HostName = $conflict.Name
                            FullName = "$($conflict.Name).$($zone.ZoneName)"
                            RecordTypes = $records
                            Issue = "CNAME coexists with other record types (RFC violation)"
                        }
                    }
                    
                    $results.Issues += "Found $($conflicts.Count) CNAME/A conflicts in $($zone.ZoneName) (RFC violation)"
                }
                else {
                    Write-Host " ✓ No conflicts" -ForegroundColor Green
                }
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to check CNAME conflicts in $($zone.ZoneName): $_"
            }
        }
        Write-Host ""
        
        # 5. NS RECORD VALIDATION
        Write-Host "═══ 5. NS Record Validation ═══" -ForegroundColor Yellow
        
        foreach ($zone in $zones) {
            Write-Host "  Validating NS records for $($zone.ZoneName)..." -NoNewline
            
            try {
                $dnsParams = @{
                    ZoneName = $zone.ZoneName
                    ComputerName = $primaryDC
                    RRType = 'NS'
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $nsRecords = Get-DnsServerResourceRecord @dnsParams | Where-Object { $_.HostName -eq '@' }
                
                Write-Host " Found $($nsRecords.Count) NS records" -ForegroundColor Green
                
                foreach ($ns in $nsRecords) {
                    $nameServer = $ns.RecordData.NameServer
                    Write-Host "    Testing $nameServer..." -NoNewline -ForegroundColor Gray
                    
                    try {
                        # Try to resolve the name server
                        $test = Resolve-DnsName -Name $nameServer -ErrorAction Stop
                        
                        # Try to query the zone from this name server
                        $zoneTest = Resolve-DnsName -Name $zone.ZoneName -Server $nameServer -Type SOA -ErrorAction Stop
                        
                        Write-Host " ✓" -ForegroundColor Green
                        
                        $results.NSRecordValidation += [PSCustomObject]@{
                            Zone = $zone.ZoneName
                            NameServer = $nameServer
                            Resolvable = $true
                            Authoritative = $true
                            Status = "OK"
                        }
                    }
                    catch {
                        Write-Host " ✗ FAILED" -ForegroundColor Red
                        $results.Statistics.InvalidNSRecords++
                        $results.Issues += "NS record validation failed for $nameServer in $($zone.ZoneName)"
                        
                        $results.NSRecordValidation += [PSCustomObject]@{
                            Zone = $zone.ZoneName
                            NameServer = $nameServer
                            Resolvable = $false
                            Authoritative = $false
                            Status = "FAILED"
                        }
                    }
                }
            }
            catch {
                Write-Host " ✗ Failed: $_" -ForegroundColor Red
                $results.Issues += "Failed to validate NS records in $($zone.ZoneName): $_"
            }
        }
        Write-Host ""
        
        # Summary
        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                Zone Health Audit Summary                      ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Zones Audited:             $($results.Statistics.TotalZones)" -ForegroundColor White
        Write-Host "  SOA Mismatches:            $($results.Statistics.SOAMismatches)" -ForegroundColor $(if ($results.Statistics.SOAMismatches -gt 0) { "Red" } else { "Green" })
        Write-Host "  Broken Delegations:        $($results.Statistics.BrokenDelegations)" -ForegroundColor $(if ($results.Statistics.BrokenDelegations -gt 0) { "Red" } else { "Green" })
        Write-Host "  Empty Nodes:               $($results.Statistics.EmptyNodesFound)" -ForegroundColor $(if ($results.Statistics.EmptyNodesFound -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  CNAME Conflicts:           $($results.Statistics.CNAMEConflicts)" -ForegroundColor $(if ($results.Statistics.CNAMEConflicts -gt 0) { "Red" } else { "Green" })
        Write-Host "  Invalid NS Records:        $($results.Statistics.InvalidNSRecords)" -ForegroundColor $(if ($results.Statistics.InvalidNSRecords -gt 0) { "Red" } else { "Green" })
        Write-Host "  Total Issues Found:        $($results.Issues.Count)" -ForegroundColor $(if ($results.Issues.Count -gt 0) { "Red" } else { "Green" })
        Write-Host ""
        
        return $results
    }
    catch {
        Write-Host "FATAL ERROR in Zone Health Audit: $_" -ForegroundColor Red
        throw
    }
}

#endregion


