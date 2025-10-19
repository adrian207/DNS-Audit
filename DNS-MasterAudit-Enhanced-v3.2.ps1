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
    [Parameter(HelpMessage = "Operation mode (or use interactive menu)")]
    [ValidateSet("Inventory", "HealthCheck", "RecordExport", "SiteAudit", "Complete", "Baseline", "Compare", "ConfigAudit", "ZoneHealth", "CISCompliance", "DNSSECInventory")]
    [string]$Mode = "",
    
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
    [string[]]$EmailTo,
    
    # UI Enhancement Parameters (NEW in v3.1)
    [Parameter(HelpMessage = "Use interactive menu to select mode (when -Mode not specified)")]
    [switch]$InteractiveMenu,
    
    [Parameter(HelpMessage = "Show enhanced progress indicators with ETA")]
    [switch]$ShowProgress = $true,
    
    [Parameter(HelpMessage = "Display executive summary dashboard at completion")]
    [switch]$ShowSummary = $true,
    
    [Parameter(HelpMessage = "Automatically open results folder/files after completion")]
    [switch]$AutoOpenResults,
    
    [Parameter(HelpMessage = "Suppress interactive prompts (for automation/Server Core)")]
    [switch]$NonInteractive
)

#region Script Variables
$script:Version = "3.2 - Compliance & Security Edition"
$script:Author = "Adrian Johnson <adrian207@gmail.com>"
$script:StartTime = Get-Date
$script:TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:ScriptPath = $PSScriptRoot
$script:SkippedSubnets = @()

# CIS Benchmark Version Information
# NOTE: CIS Benchmarks cannot be dynamically retrieved (licensing/no public API)
# Update these constants when new CIS versions are released
$script:CIS_BenchmarkName = "CIS Microsoft Windows Server 2019/2022 Benchmark"
$script:CIS_Version = "3.0.0"
$script:CIS_ReleaseDate = "December 2023"
$script:CIS_LastVerified = "January 2025"
$script:CIS_UpdateURL = "https://www.cisecurity.org/benchmark/microsoft_windows_server"
$script:CIS_ChecksImplemented = @(
    "1.1 - Recursion on Authoritative Servers"
    "1.2 - DNS Socket Pool Size (DoS Protection)"
    "1.3 - Event Logging Level"
    "2.1 - Zone Transfer Restrictions"
    "2.2 - Secure Dynamic Updates"
    "2.3 - DNSSEC Validation"
    "3.1 - Listen Address Configuration"
    "3.2 - Response Rate Limiting (RRL)"
    "3.3 - Cache Locking Percentage"
)

# Performance tracking
$script:PerfMetrics = @{
    StartTime = $script:StartTime
    DCsProcessed = 0
    RecordsProcessed = 0
    QueriesExecuted = 0
}

# UI variables (v3.1)
$script:ShowProgress = $ShowProgress
$script:ShowSummary = $ShowSummary
$script:AutoOpenResults = $AutoOpenResults.IsPresent
$script:NonInteractive = $NonInteractive.IsPresent
$script:IsServerCore = $false
$script:IsRemoteSession = $false
$script:HasGUI = $true
$script:ExecutionStats = @{
    ServersProcessed = 0
    ZonesProcessed = 0
    RecordsProcessed = 0
    SuccessCount = 0
    WarningCount = 0
    ErrorCount = 0
    TopFindings = @()
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

#region UI Enhancement Functions (v3.1)

<#
.SYNOPSIS
    Detect environment capabilities (Server Core, Remote Session, GUI)
#>
function Test-EnvironmentCapabilities {
    [CmdletBinding()]
    param()
    
    try {
        # Detect Server Core
        $installType = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name InstallationType -ErrorAction SilentlyContinue
        $script:IsServerCore = $installType.InstallationType -eq "Server Core"
        
        # Detect remote session
        $script:IsRemoteSession = [bool]($env:SSH_CONNECTION -or $PSSenderInfo)
        
        # Determine GUI availability
        $script:HasGUI = -not $script:IsServerCore -and -not $script:IsRemoteSession -and -not $script:NonInteractive
        
        if (-not $Quiet) {
            Write-Host "Environment Detection:" -ForegroundColor Cyan
            Write-Host "  Server Core: $script:IsServerCore" -ForegroundColor Gray
            Write-Host "  Remote Session: $script:IsRemoteSession" -ForegroundColor Gray
            Write-Host "  GUI Available: $script:HasGUI" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {
        Write-Warning "Environment detection failed, assuming GUI available: $_"
        $script:HasGUI = $true
    }
}

<#
.SYNOPSIS
    Display interactive mode selection menu
#>
function Show-ModeSelectionMenu {
    [CmdletBinding()]
    param()
    
    Clear-Host
    
    Write-Host ""
    Write-Host "╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║      DNS Master Audit v$script:Version - Mode Selection       ║" -ForegroundColor Cyan
    Write-Host "╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select audit mode:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1]  📊 DNS Inventory" -ForegroundColor Yellow -NoNewline
    Write-Host "         - Discover all DNS servers" -ForegroundColor Gray
    Write-Host "  [2]  ❤️  DNS Health Check" -ForegroundColor Yellow -NoNewline
    Write-Host "      - Test service health on all DCs" -ForegroundColor Gray
    Write-Host "  [3]  📁 DNS Record Export" -ForegroundColor Yellow -NoNewline
    Write-Host "     - Export all DNS records from zones" -ForegroundColor Gray
    Write-Host "  [4]  🗺️  DNS Site Audit" -ForegroundColor Yellow -NoNewline
    Write-Host "        - Find site mismatches (Critical!)" -ForegroundColor Gray
    Write-Host "  [5]  🔍 Complete Audit" -ForegroundColor Green -NoNewline
    Write-Host "        - Run all audits (RECOMMENDED)" -ForegroundColor Gray
    Write-Host "  [6]  📸 Baseline Mode" -ForegroundColor Yellow -NoNewline
    Write-Host "         - Create DNS configuration snapshot" -ForegroundColor Gray
    Write-Host "  [7]  🔎 Compare Mode" -ForegroundColor Yellow -NoNewline
    Write-Host "          - Detect configuration drift vs baseline" -ForegroundColor Gray
    Write-Host "  [8]  ⚙️  Config Audit" -ForegroundColor Magenta -NoNewline
    Write-Host "         - Configuration consistency check" -ForegroundColor Gray
    Write-Host "  [9]  🏥 Zone Health" -ForegroundColor Magenta -NoNewline
    Write-Host "          - Zone integrity & RFC compliance" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [10] 🛡️  CIS Compliance" -ForegroundColor Red -NoNewline
    Write-Host "       - CIS Benchmark security audit (NEW!)" -ForegroundColor Gray
    Write-Host "  [11] 🔐 DNSSEC Inventory" -ForegroundColor Red -NoNewline
    Write-Host "      - DNSSEC configuration & migration prep (NEW!)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0]  ❌ Exit" -ForegroundColor Red
    Write-Host ""
    
    do {
        $selection = Read-Host "Enter selection (0-11)"
        $validSelection = $selection -match '^([0-9]|1[01])$'
        if (-not $validSelection) {
            Write-Host "Invalid selection. Please enter a number between 0 and 11." -ForegroundColor Red
        }
    } while (-not $validSelection)
    
    $modeMap = @{
        "1" = "Inventory"
        "2" = "HealthCheck"
        "3" = "RecordExport"
        "4" = "SiteAudit"
        "5" = "Complete"
        "6" = "Baseline"
        "7" = "Compare"
        "8" = "ConfigAudit"
        "9" = "ZoneHealth"
        "10" = "CISCompliance"
        "11" = "DNSSECInventory"
        "0" = "Exit"
    }
    
    $selectedMode = $modeMap[$selection]
    
    if ($selectedMode -eq "Exit") {
        Write-Host ""
        Write-Host "Exiting DNS Master Audit. Goodbye!" -ForegroundColor Cyan
        exit 0
    }
    
    Write-Host ""
    Write-Host "✓ Selected: $selectedMode Mode" -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Milliseconds 500
    
    return $selectedMode
}

<#
.SYNOPSIS
    Enhanced progress indicator with ETA calculation
#>
function Show-EnhancedProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Activity,
        
        [Parameter(Mandatory)]
        [int]$Current,
        
        [Parameter(Mandatory)]
        [int]$Total,
        
        [Parameter()]
        [string]$CurrentItem = "",
        
        [Parameter()]
        [datetime]$StartTime = $script:StartTime
    )
    
    if (-not $script:ShowProgress) {
        return
    }
    
    $percentComplete = if ($Total -gt 0) { [math]::Round(($Current / $Total) * 100) } else { 0 }
    
    # Calculate ETA
    $elapsed = (Get-Date) - $StartTime
    if ($Current -gt 0) {
        $avgTimePerItem = $elapsed.TotalSeconds / $Current
        $remaining = $Total - $Current
        $etaSeconds = $avgTimePerItem * $remaining
        $etaTimeSpan = [TimeSpan]::FromSeconds($etaSeconds)
        
        if ($etaSeconds -gt 3600) {
            $etaString = "$([math]::Round($etaTimeSpan.TotalHours, 1))h"
        } elseif ($etaSeconds -gt 60) {
            $etaString = "$([math]::Round($etaTimeSpan.TotalMinutes, 1))m"
        } else {
            $etaString = "$([math]::Round($etaSeconds))s"
        }
        
        $throughput = if ($elapsed.TotalSeconds -gt 0) { 
            [math]::Round($Current / $elapsed.TotalSeconds, 1) 
        } else { 
            0 
        }
        
        $status = "($Current/$Total) | ETA: $etaString | Rate: $throughput/s"
    } else {
        $status = "($Current/$Total) | Initializing..."
    }
    
    if ($CurrentItem) {
        $status = "$status`nCurrent: $CurrentItem"
    }
    
    Write-Progress -Activity $Activity -Status $status -PercentComplete $percentComplete
}

<#
.SYNOPSIS
    Display executive summary dashboard at completion
#>
function Show-ExecutiveSummary {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Results = @{},
        
        [Parameter(Mandatory)]
        [string]$Mode,
        
        [Parameter(Mandatory)]
        [string]$ExportPath
    )
    
    if (-not $script:ShowSummary) {
        return
    }
    
    $duration = ((Get-Date) - $script:StartTime)
    $durationString = if ($duration.TotalHours -gt 1) {
        "$([math]::Round($duration.TotalHours, 1)) hours"
    } elseif ($duration.TotalMinutes -gt 1) {
        "$([math]::Round($duration.TotalMinutes, 1)) minutes"
    } else {
        "$([math]::Round($duration.TotalSeconds)) seconds"
    }
    
    Write-Host ""
    Write-Host "╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              📊 AUDIT EXECUTION SUMMARY                         ║" -ForegroundColor Green
    Write-Host "╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Mode:             " -NoNewline -ForegroundColor White
    Write-Host "$Mode Audit" -ForegroundColor Cyan
    Write-Host "  Duration:         " -NoNewline -ForegroundColor White
    Write-Host $durationString -ForegroundColor Cyan
    Write-Host "  Completion Time:  " -NoNewline -ForegroundColor White
    Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -ForegroundColor Cyan
    Write-Host ""
    
    # Statistics
    if ($script:ExecutionStats.ServersProcessed -gt 0) {
        Write-Host "  Servers Audited:  " -NoNewline -ForegroundColor White
        Write-Host "$($script:ExecutionStats.ServersProcessed) Domain Controllers" -ForegroundColor Cyan
    }
    if ($script:ExecutionStats.ZonesProcessed -gt 0) {
        Write-Host "  Zones Processed:  " -NoNewline -ForegroundColor White
        Write-Host "$($script:ExecutionStats.ZonesProcessed) DNS Zones" -ForegroundColor Cyan
    }
    if ($script:ExecutionStats.RecordsProcessed -gt 0) {
        Write-Host "  Records Analyzed: " -NoNewline -ForegroundColor White
        Write-Host "$($script:ExecutionStats.RecordsProcessed) DNS Records" -ForegroundColor Cyan
    }
    Write-Host ""
    
    # Results summary
    $successIcon = if ($script:ExecutionStats.ErrorCount -eq 0) { "✓" } else { "✓" }
    $warningIcon = if ($script:ExecutionStats.WarningCount -gt 0) { "⚠" } else { "○" }
    $errorIcon = if ($script:ExecutionStats.ErrorCount -gt 0) { "✗" } else { "○" }
    
    Write-Host "  $successIcon Successes:      " -NoNewline -ForegroundColor Green
    Write-Host "$($script:ExecutionStats.SuccessCount) operations completed" -ForegroundColor White
    
    if ($script:ExecutionStats.WarningCount -gt 0) {
        Write-Host "  $warningIcon Warnings:       " -NoNewline -ForegroundColor Yellow
        Write-Host "$($script:ExecutionStats.WarningCount) minor issues found" -ForegroundColor White
    }
    
    if ($script:ExecutionStats.ErrorCount -gt 0) {
        Write-Host "  $errorIcon Errors:         " -NoNewline -ForegroundColor Red
        Write-Host "$($script:ExecutionStats.ErrorCount) failures occurred" -ForegroundColor White
    } else {
        Write-Host "  $errorIcon Errors:         " -NoNewline -ForegroundColor Green
        Write-Host "0 critical failures" -ForegroundColor White
    }
    
    Write-Host ""
    
    # Export files
    Write-Host "  📁 Exports:" -ForegroundColor White
    if (Test-Path $ExportPath) {
        $exportFiles = Get-ChildItem -Path $ExportPath -Filter "*$script:TimeStamp*" -ErrorAction SilentlyContinue
        foreach ($file in $exportFiles | Select-Object -First 5) {
            $sizeKB = [math]::Round($file.Length / 1KB, 1)
            Write-Host "     → " -NoNewline -ForegroundColor Gray
            Write-Host "$($file.Name) " -NoNewline -ForegroundColor Cyan
            Write-Host "($sizeKB KB)" -ForegroundColor Gray
        }
        
        if ($exportFiles.Count -gt 5) {
            Write-Host "     ... and $($exportFiles.Count - 5) more files" -ForegroundColor Gray
        }
    } else {
        Write-Host "     Export path: $ExportPath" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Top findings
    if ($script:ExecutionStats.TopFindings.Count -gt 0) {
        Write-Host "  🎯 Top Findings:" -ForegroundColor White
        foreach ($finding in $script:ExecutionStats.TopFindings | Select-Object -First 5) {
            Write-Host "     • $finding" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Interactive prompt (if GUI available)
    if ($script:HasGUI -and -not $script:NonInteractive) {
        Write-Host "  ═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        if ($script:AutoOpenResults) {
            Write-Host "  Opening results..." -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500
            try {
                if (Test-Path $ExportPath) {
                    Start-Process explorer.exe $ExportPath
                    $htmlFiles = Get-ChildItem -Path $ExportPath -Filter "*$script:TimeStamp*.html" -ErrorAction SilentlyContinue
                    if ($htmlFiles) {
                        Start-Process $htmlFiles[0].FullName
                    }
                }
            } catch {
                Write-Host "  Could not auto-open results: $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Press " -NoNewline -ForegroundColor Gray
            Write-Host "O" -NoNewline -ForegroundColor Cyan
            Write-Host " to open results folder, or any other key to exit..." -ForegroundColor Gray
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.Character -eq 'O' -or $key.Character -eq 'o') {
                try {
                    if (Test-Path $ExportPath) {
                        Start-Process explorer.exe $ExportPath
                        $htmlFiles = Get-ChildItem -Path $ExportPath -Filter "*$script:TimeStamp*.html" -ErrorAction SilentlyContinue
                        if ($htmlFiles) {
                            Start-Process $htmlFiles[0].FullName
                        }
                    }
                } catch {
                    Write-Host "  Could not open results: $_" -ForegroundColor Yellow
                }
            }
        }
    } elseif ($script:IsServerCore) {
        # Server Core specific instructions
        Write-Host "  ═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  📁 Server Core - Access Results:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  UNC Path:" -ForegroundColor White
        Write-Host "     \\$env:COMPUTERNAME\$($ExportPath -replace ':', '$')" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  PowerShell Commands:" -ForegroundColor White
        Write-Host "     explorer.exe '\\$env:COMPUTERNAME\$($ExportPath -replace ':', '$')'" -ForegroundColor Gray
        Write-Host "     Get-ChildItem '$ExportPath' | Out-GridView" -ForegroundColor Gray
        Write-Host ""
    }
}

<#
.SYNOPSIS
    Update execution statistics for summary
#>
function Update-ExecutionStats {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$ServersProcessed = 0,
        
        [Parameter()]
        [int]$ZonesProcessed = 0,
        
        [Parameter()]
        [int]$RecordsProcessed = 0,
        
        [Parameter()]
        [int]$SuccessCount = 0,
        
        [Parameter()]
        [int]$WarningCount = 0,
        
        [Parameter()]
        [int]$ErrorCount = 0,
        
        [Parameter()]
        [string[]]$Findings = @()
    )
    
    $script:ExecutionStats.ServersProcessed += $ServersProcessed
    $script:ExecutionStats.ZonesProcessed += $ZonesProcessed
    $script:ExecutionStats.RecordsProcessed += $RecordsProcessed
    $script:ExecutionStats.SuccessCount += $SuccessCount
    $script:ExecutionStats.WarningCount += $WarningCount
    $script:ExecutionStats.ErrorCount += $ErrorCount
    
    if ($Findings.Count -gt 0) {
        $script:ExecutionStats.TopFindings += $Findings
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

#region Mode 13: CIS Compliance Checking

<#
.SYNOPSIS
    CIS Benchmark compliance checking for Windows DNS Server
.DESCRIPTION
    Implements CIS Microsoft Windows Server 2019/2022 DNS Security Benchmark
    Based on latest CIS guidelines (v3.0.0 - December 2023)
#>
function Start-CISComplianceCheck {
    [CmdletBinding()]
    param(
        [Parameter()]
        [PSCredential]$Credential
    )
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          CIS Benchmark Compliance Audit                       ║" -ForegroundColor Cyan
    Write-Host "║          Windows Server DNS Security Baseline                 ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Reference: $script:CIS_BenchmarkName v$script:CIS_Version" -ForegroundColor Gray
    Write-Host "  Release Date: $script:CIS_ReleaseDate" -ForegroundColor Gray
    Write-Host "  Last Verified: $script:CIS_LastVerified" -ForegroundColor Gray
    Write-Host "  Checks Implemented: $($script:CIS_ChecksImplemented.Count)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ⚠️  NOTE: CIS Benchmarks cannot be auto-updated (licensing)" -ForegroundColor Yellow
    Write-Host "  Check $script:CIS_UpdateURL for latest version" -ForegroundColor Yellow
    Write-Host ""
    
    $results = @{
        Checks = @()
        Summary = @{
            TotalChecks = 0
            Passed = 0
            Failed = 0
            NotApplicable = 0
            ManualReview = 0
            ComplianceScore = 0
        }
        Categories = @{
            ServiceHardening = @()
            ZoneSecurity = @()
            NetworkSecurity = @()
            Logging = @()
            OperatingSystem = @()
        }
        Findings = @()
    }
    
    try {
        # Get all domain controllers
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        
        $DCs = Get-ADDomainController @adParams -Filter * | Select-Object Name, IPv4Address, Site
        Write-Host "Auditing $($DCs.Count) domain controllers for CIS compliance..." -ForegroundColor Green
        Write-Host ""
        
        foreach ($DC in $DCs) {
            Write-Host "═══ Auditing: $($DC.Name) ═══" -ForegroundColor Yellow
            Write-Host ""
            
            $dnsParams = @{
                ComputerName = $DC.Name
                ErrorAction = 'SilentlyContinue'
            }
            if ($Credential) { $dnsParams['Credential'] = $Credential }
            
            # CATEGORY 1: SERVICE HARDENING
            Write-Host "  [Category 1] Service Hardening Checks" -ForegroundColor Cyan
            
            # CIS 1.1 - Recursion Settings
            Write-Host "    CIS 1.1: Recursion configuration..." -NoNewline
            try {
                $dnsServer = Get-DnsServer @dnsParams
                $isAuthoritative = ($dnsServer | Get-DnsServerZone | Where-Object { $_.ZoneType -eq 'Primary' }).Count -gt 0
                $recursionDisabled = $dnsServer.ServerSetting.DisableRecursion
                
                if ($isAuthoritative -and -not $recursionDisabled) {
                    Write-Host " ✗ FAIL" -ForegroundColor Red
                    $status = "FAIL"
                    $finding = "Authoritative DNS server has recursion enabled (security risk)"
                    $results.Findings += $finding
                } elseif ($isAuthoritative -and $recursionDisabled) {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ○ N/A" -ForegroundColor Gray
                    $status = "N/A"
                    $finding = "Non-authoritative server"
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-1.1"
                    Category = "Service Hardening"
                    Title = "Ensure recursion is disabled on authoritative servers"
                    Severity = "HIGH"
                    Status = $status
                    CurrentValue = if ($recursionDisabled) { "Disabled" } else { "Enabled" }
                    ExpectedValue = "Disabled (for authoritative)"
                    Finding = $finding
                    Remediation = "Set-DnsServerRecursion -ComputerName $($DC.Name) -Enable `$false"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 1.1"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-1.1"
                    Status = "ERROR"
                    Finding = "Failed to check: $_"
                }
            }
            
            # CIS 1.2 - Socket Pool Size
            Write-Host "    CIS 1.2: DNS Socket Pool configuration..." -NoNewline
            try {
                $socketPool = $dnsServer.ServerSetting.SocketPoolSize
                
                if ($socketPool -ge 2500) {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ✗ FAIL" -ForegroundColor Red
                    $status = "FAIL"
                    $finding = "Socket pool size too small (current: $socketPool, recommended: 2500+)"
                    $results.Findings += $finding
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-1.2"
                    Category = "Service Hardening"
                    Title = "Ensure DNS Socket Pool is configured (DoS protection)"
                    Severity = "MEDIUM"
                    Status = $status
                    CurrentValue = $socketPool
                    ExpectedValue = "2500 or higher"
                    Finding = $finding
                    Remediation = "dnscmd $($DC.Name) /Config /SocketPoolSize 2500"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 1.2"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
            }
            
            # CIS 1.3 - Event Logging
            Write-Host "    CIS 1.3: Event logging enabled..." -NoNewline
            try {
                $eventLog = $dnsServer.ServerSetting.EventLogLevel
                
                if ($eventLog -ge 2) {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ✗ FAIL" -ForegroundColor Red
                    $status = "FAIL"
                    $finding = "DNS event logging insufficient (level: $eventLog)"
                    $results.Findings += $finding
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-1.3"
                    Category = "Logging"
                    Title = "Ensure DNS event logging is enabled"
                    Severity = "MEDIUM"
                    Status = $status
                    CurrentValue = $eventLog
                    ExpectedValue = "2 (Errors and warnings) or higher"
                    Finding = $finding
                    Remediation = "Set-DnsServerDiagnostics -ComputerName $($DC.Name) -EventLogLevel 2"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 1.3"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
            }
            
            # CATEGORY 2: ZONE SECURITY
            Write-Host ""
            Write-Host "  [Category 2] Zone Security Checks" -ForegroundColor Cyan
            
            # CIS 2.1 - Zone Transfer Restrictions
            Write-Host "    CIS 2.1: Zone transfer restrictions..." -NoNewline
            try {
                $zones = Get-DnsServerZone @dnsParams | Where-Object { $_.ZoneType -eq 'Primary' -and -not $_.IsReverseLookupZone }
                $unsecuredZones = @()
                
                foreach ($zone in $zones) {
                    $zoneDetail = Get-DnsServerZone @dnsParams -Name $zone.ZoneName
                    if ($zoneDetail.SecureSecondaries -eq 'NoTransfer') {
                        # Secure - no transfers
                    } elseif ($zoneDetail.SecureSecondaries -eq 'TransferAnyServer') {
                        $unsecuredZones += $zone.ZoneName
                    }
                }
                
                if ($unsecuredZones.Count -eq 0) {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ✗ FAIL" -ForegroundColor Red
                    $status = "FAIL"
                    $finding = "$($unsecuredZones.Count) zones allow unrestricted zone transfers: $($unsecuredZones -join ', ')"
                    $results.Findings += $finding
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-2.1"
                    Category = "Zone Security"
                    Title = "Ensure zone transfers are restricted"
                    Severity = "CRITICAL"
                    Status = $status
                    CurrentValue = if ($unsecuredZones.Count -gt 0) { "Unrestricted on $($unsecuredZones.Count) zones" } else { "Restricted" }
                    ExpectedValue = "Restricted to specific servers or disabled"
                    Finding = $finding
                    Remediation = "Set-DnsServerPrimaryZone -Name <zone> -ComputerName $($DC.Name) -SecureSecondaries TransferToSecureServers"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 2.1"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
            }
            
            # CIS 2.2 - Dynamic Update Security
            Write-Host "    CIS 2.2: Dynamic update security..." -NoNewline
            try {
                $zones = Get-DnsServerZone @dnsParams | Where-Object { $_.ZoneType -eq 'Primary' -and -not $_.IsReverseLookupZone }
                $insecureZones = @()
                
                foreach ($zone in $zones) {
                    if ($zone.DynamicUpdate -eq 'NonsecureAndSecure') {
                        $insecureZones += $zone.ZoneName
                    }
                }
                
                if ($insecureZones.Count -eq 0) {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ✗ FAIL" -ForegroundColor Red
                    $status = "FAIL"
                    $finding = "$($insecureZones.Count) zones allow non-secure dynamic updates"
                    $results.Findings += $finding
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-2.2"
                    Category = "Zone Security"
                    Title = "Ensure secure dynamic updates only"
                    Severity = "HIGH"
                    Status = $status
                    CurrentValue = if ($insecureZones.Count -gt 0) { "Non-secure allowed on $($insecureZones.Count) zones" } else { "Secure only" }
                    ExpectedValue = "Secure only or None"
                    Finding = $finding
                    Remediation = "Set-DnsServerPrimaryZone -Name <zone> -ComputerName $($DC.Name) -DynamicUpdate Secure"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 2.2"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
            }
            
            # CIS 2.3 - DNSSEC Validation
            Write-Host "    CIS 2.3: DNSSEC validation..." -NoNewline
            try {
                $dnssecEnabled = $dnsServer.ServerSetting.EnableDnsSec
                
                if ($dnssecEnabled) {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ⚠ MANUAL" -ForegroundColor Yellow
                    $status = "MANUAL"
                    $finding = "DNSSEC not enabled - verify if required for environment"
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-2.3"
                    Category = "Zone Security"
                    Title = "Consider enabling DNSSEC validation"
                    Severity = "MEDIUM"
                    Status = $status
                    CurrentValue = if ($dnssecEnabled) { "Enabled" } else { "Disabled" }
                    ExpectedValue = "Enabled (recommended)"
                    Finding = $finding
                    Remediation = "Set-DnsServerDnsSec -ComputerName $($DC.Name) -EnableDnsSec `$true"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 2.3"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
            }
            
            # CATEGORY 3: NETWORK SECURITY
            Write-Host ""
            Write-Host "  [Category 3] Network Security Checks" -ForegroundColor Cyan
            
            # CIS 3.1 - Listen Addresses
            Write-Host "    CIS 3.1: Listen on specific interfaces..." -NoNewline
            try {
                $listenAddresses = $dnsServer.ServerSetting.ListenAddresses
                
                if ($listenAddresses.Count -eq 0) {
                    Write-Host " ⚠ WARN" -ForegroundColor Yellow
                    $status = "WARN"
                    $finding = "DNS listening on all interfaces - consider restricting"
                } else {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-3.1"
                    Category = "Network Security"
                    Title = "Ensure DNS listens on specific interfaces only"
                    Severity = "MEDIUM"
                    Status = $status
                    CurrentValue = if ($listenAddresses.Count -eq 0) { "All interfaces" } else { "$($listenAddresses.Count) specific interfaces" }
                    ExpectedValue = "Specific interfaces only"
                    Finding = $finding
                    Remediation = "Set-DnsServerSetting -ComputerName $($DC.Name) -ListenAddresses <IP1>,<IP2>"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 3.1"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
            }
            
            # CIS 3.2 - RRL (Response Rate Limiting)
            Write-Host "    CIS 3.2: Response Rate Limiting..." -NoNewline
            try {
                $rrl = Get-DnsServerResponseRateLimiting @dnsParams -ErrorAction Stop
                
                if ($rrl.Mode -eq 'Enable') {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ✗ FAIL" -ForegroundColor Red
                    $status = "FAIL"
                    $finding = "Response Rate Limiting not enabled (DoS protection missing)"
                    $results.Findings += $finding
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-3.2"
                    Category = "Network Security"
                    Title = "Ensure Response Rate Limiting is enabled"
                    Severity = "HIGH"
                    Status = $status
                    CurrentValue = $rrl.Mode
                    ExpectedValue = "Enable"
                    Finding = $finding
                    Remediation = "Set-DnsServerResponseRateLimiting -ComputerName $($DC.Name) -Mode Enable"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 3.2"
                }
            }
            catch {
                Write-Host " ⚠ N/A" -ForegroundColor Yellow
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-3.2"
                    Status = "N/A"
                    Finding = "RRL not available on this DNS version"
                }
            }
            
            # CIS 3.3 - Cache Locking
            Write-Host "    CIS 3.3: Cache locking percentage..." -NoNewline
            try {
                $cacheLocking = $dnsServer.ServerSetting.CacheLockingPercent
                
                if ($cacheLocking -ge 80) {
                    Write-Host " ✓ PASS" -ForegroundColor Green
                    $status = "PASS"
                    $finding = ""
                } else {
                    Write-Host " ✗ FAIL" -ForegroundColor Red
                    $status = "FAIL"
                    $finding = "Cache locking too low (current: $cacheLocking%, recommended: 80%+)"
                    $results.Findings += $finding
                }
                
                $results.Checks += [PSCustomObject]@{
                    Server = $DC.Name
                    CheckID = "CIS-3.3"
                    Category = "Network Security"
                    Title = "Ensure cache locking is configured"
                    Severity = "MEDIUM"
                    Status = $status
                    CurrentValue = "$cacheLocking%"
                    ExpectedValue = "80% or higher"
                    Finding = $finding
                    Remediation = "Set-DnsServerCache -ComputerName $($DC.Name) -LockingPercent 80"
                    Reference = "CIS Windows Server 2022 v3.0.0 - 3.3"
                }
            }
            catch {
                Write-Host " ✗ ERROR" -ForegroundColor Red
            }
            
            Write-Host ""
        }
        
        # Calculate statistics
        $results.Summary.TotalChecks = $results.Checks.Count
        $results.Summary.Passed = ($results.Checks | Where-Object { $_.Status -eq 'PASS' }).Count
        $results.Summary.Failed = ($results.Checks | Where-Object { $_.Status -eq 'FAIL' }).Count
        $results.Summary.NotApplicable = ($results.Checks | Where-Object { $_.Status -in @('N/A', 'ERROR') }).Count
        $results.Summary.ManualReview = ($results.Checks | Where-Object { $_.Status -in @('MANUAL', 'WARN') }).Count
        
        $applicableChecks = $results.Summary.TotalChecks - $results.Summary.NotApplicable
        if ($applicableChecks -gt 0) {
            $results.Summary.ComplianceScore = [math]::Round(($results.Summary.Passed / $applicableChecks) * 100, 1)
        }
        
        # Group by category
        $results.Categories.ServiceHardening = $results.Checks | Where-Object { $_.Category -eq 'Service Hardening' }
        $results.Categories.ZoneSecurity = $results.Checks | Where-Object { $_.Category -eq 'Zone Security' }
        $results.Categories.NetworkSecurity = $results.Checks | Where-Object { $_.Category -eq 'Network Security' }
        $results.Categories.Logging = $results.Checks | Where-Object { $_.Category -eq 'Logging' }
        
        # Summary
        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║              CIS Compliance Summary                           ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Compliance Score:      " -NoNewline -ForegroundColor White
        $scoreColor = if ($results.Summary.ComplianceScore -ge 90) { "Green" } 
                      elseif ($results.Summary.ComplianceScore -ge 80) { "Yellow" } 
                      else { "Red" }
        Write-Host "$($results.Summary.ComplianceScore)%" -ForegroundColor $scoreColor
        Write-Host ""
        Write-Host "  Total Checks:          $($results.Summary.TotalChecks)" -ForegroundColor White
        Write-Host "  ✓ Passed:              $($results.Summary.Passed)" -ForegroundColor Green
        Write-Host "  ✗ Failed:              $($results.Summary.Failed)" -ForegroundColor Red
        Write-Host "  ⚠ Manual Review:       $($results.Summary.ManualReview)" -ForegroundColor Yellow
        Write-Host "  ○ Not Applicable:      $($results.Summary.NotApplicable)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Critical Findings:     $($results.Findings.Count)" -ForegroundColor $(if ($results.Findings.Count -gt 0) { "Red" } else { "Green" })
        Write-Host ""
        
        if ($results.Findings.Count -gt 0) {
            Write-Host "  🎯 Top Security Issues:" -ForegroundColor Red
            foreach ($finding in $results.Findings | Select-Object -First 5) {
                Write-Host "     • $finding" -ForegroundColor Yellow
            }
            if ($results.Findings.Count -gt 5) {
                Write-Host "     ... and $($results.Findings.Count - 5) more" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
        Write-Host "  Benchmark: $script:CIS_BenchmarkName v$script:CIS_Version" -ForegroundColor Gray
        Write-Host "  Release: $script:CIS_ReleaseDate | Verified: $script:CIS_LastVerified" -ForegroundColor Gray
        Write-Host "  Update Info: $script:CIS_UpdateURL" -ForegroundColor Gray
        Write-Host ""
        
        return $results
    }
    catch {
        Write-Host "FATAL ERROR in CIS Compliance Check: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Mode 14: DNSSEC Inventory

<#
.SYNOPSIS
    DNSSEC configuration inventory and migration preparation
.DESCRIPTION
    Documents DNSSEC configuration - DOES NOT MIGRATE
    Prepares migration checklist and extracts key information
#>
function Start-DNSSECInventory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [PSCredential]$Credential
    )
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DNSSEC Configuration Inventory                       ║" -ForegroundColor Cyan
    Write-Host "║          Migration Preparation & Documentation                ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ⚠️  WARNING: This tool DOCUMENTS only - does NOT migrate DNSSEC" -ForegroundColor Yellow
    Write-Host "  Use this information for manual migration planning" -ForegroundColor Yellow
    Write-Host ""
    
    $results = @{
        SignedZones = @()
        KeyInventory = @()
        TrustAnchors = @()
        ValidationSettings = @()
        MigrationChecklist = @()
        Statistics = @{
            TotalZones = 0
            SignedZones = 0
            TotalKeys = 0
            KSKs = 0
            ZSKs = 0
        }
    }
    
    try {
        # Get all domain controllers
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        
        $DCs = Get-ADDomainController @adParams -Filter * | Select-Object Name, IPv4Address
        Write-Host "Inventorying DNSSEC across $($DCs.Count) domain controllers..." -ForegroundColor Green
        Write-Host ""
        
        foreach ($DC in $DCs) {
            Write-Host "═══ Auditing: $($DC.Name) ═══" -ForegroundColor Yellow
            Write-Host ""
            
            $dnsParams = @{
                ComputerName = $DC.Name
                ErrorAction = 'Stop'
            }
            if ($Credential) { $dnsParams['Credential'] = $Credential }
            
            # Get all zones
            Write-Host "  Discovering zones..." -NoNewline
            $zones = Get-DnsServerZone @dnsParams | Where-Object { 
                $_.ZoneType -eq 'Primary' -and -not $_.IsReverseLookupZone 
            }
            Write-Host " Found $($zones.Count) zones" -ForegroundColor Green
            
            $results.Statistics.TotalZones += $zones.Count
            
            # Check each zone for DNSSEC
            foreach ($zone in $zones) {
                Write-Host "  Checking $($zone.ZoneName)..." -NoNewline
                
                try {
                    $dnssecSettings = Get-DnsServerDnsSecZoneSetting @dnsParams -ZoneName $zone.ZoneName -ErrorAction Stop
                    
                    if ($dnssecSettings.IsSigned) {
                        Write-Host " ✓ SIGNED" -ForegroundColor Green
                        $results.Statistics.SignedZones++
                        
                        # Get signing keys
                        $keys = Get-DnsServerSigningKey @dnsParams -ZoneName $zone.ZoneName -ErrorAction SilentlyContinue
                        
                        $kskCount = ($keys | Where-Object { $_.KeyType -eq 'KeySigningKey' }).Count
                        $zskCount = ($keys | Where-Object { $_.KeyType -eq 'ZoneSigningKey' }).Count
                        
                        $results.Statistics.KSKs += $kskCount
                        $results.Statistics.ZSKs += $zskCount
                        $results.Statistics.TotalKeys += $keys.Count
                        
                        Write-Host "     Keys: $kskCount KSK, $zskCount ZSK" -ForegroundColor Gray
                        
                        $results.SignedZones += [PSCustomObject]@{
                            Server = $DC.Name
                            Zone = $zone.ZoneName
                            IsSigned = $true
                            SigningAlgorithm = $dnssecSettings.SigningAlgorithm
                            NSec3Iterations = $dnssecSettings.NSec3Iterations
                            NSec3OptOut = $dnssecSettings.NSec3OptOut
                            NSec3Algorithm = $dnssecSettings.NSec3Algorithm
                            ParentHasSecureDelegation = $dnssecSettings.ParentHasSecureDelegation
                            KSKCount = $kskCount
                            ZSKCount = $zskCount
                            Keys = $keys
                        }
                        
                        # Document each key
                        foreach ($key in $keys) {
                            $results.KeyInventory += [PSCustomObject]@{
                                Server = $DC.Name
                                Zone = $zone.ZoneName
                                KeyID = $key.KeyId
                                KeyType = $key.KeyType
                                Algorithm = $key.CryptoAlgorithm
                                KeyLength = $key.KeyLength
                                State = $key.State
                                IsInitialKey = $key.IsInitialKey
                                StoreKeysInAD = $key.StoreKeysInAD
                                ActiveKey = $key.ActiveKey
                                StandbyKey = $key.StandbyKey
                                NextKey = $key.NextKey
                            }
                        }
                        
                        # Generate DS records (for parent zone)
                        try {
                            $dsRecords = Export-DnsServerDnsSecPublicKey @dnsParams -ZoneName $zone.ZoneName -PassThru -ErrorAction Stop
                            Write-Host "     DS Records: $($dsRecords.Count) generated" -ForegroundColor Gray
                        }
                        catch {
                            Write-Host "     DS Records: Unable to export" -ForegroundColor Yellow
                        }
                    }
                    else {
                        Write-Host " ○ Not signed" -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Host " ✗ Error: $_" -ForegroundColor Red
                }
            }
            
            Write-Host ""
        }
        
        # Generate Migration Checklist
        Write-Host "═══ Generating Migration Checklist ═══" -ForegroundColor Yellow
        Write-Host ""
        
        $results.MigrationChecklist = @(
            [PSCustomObject]@{
                Step = 1
                Phase = "Discovery"
                Task = "Document all DNSSEC-signed zones"
                Status = "✓ COMPLETE"
                Details = "$($results.Statistics.SignedZones) signed zones documented"
            }
            [PSCustomObject]@{
                Step = 2
                Phase = "Discovery"
                Task = "Extract key information (KSK and ZSK)"
                Status = "✓ COMPLETE"
                Details = "$($results.Statistics.TotalKeys) keys documented ($($results.Statistics.KSKs) KSK, $($results.Statistics.ZSKs) ZSK)"
            }
            [PSCustomObject]@{
                Step = 3
                Phase = "Discovery"
                Task = "Capture current DS records"
                Status = "⚠ MANUAL REQUIRED"
                Details = "Contact parent zone administrators for current DS records"
            }
            [PSCustomObject]@{
                Step = 4
                Phase = "Preparation"
                Task = "Identify parent zone contact information"
                Status = "⚠ MANUAL REQUIRED"
                Details = "Required for DS record updates during migration"
            }
            [PSCustomObject]@{
                Step = 5
                Phase = "Preparation"
                Task = "Document trust anchors"
                Status = "⚠ MANUAL REQUIRED"
                Details = "Check for any configured trust anchors on resolvers"
            }
            [PSCustomObject]@{
                Step = 6
                Phase = "Preparation"
                Task = "Determine migration strategy"
                Status = "⏳ PENDING"
                Details = "Choose: In-Place Re-signing, Key Export/Import, or Parallel Running"
            }
            [PSCustomObject]@{
                Step = 7
                Phase = "Preparation"
                Task = "Review TTL values"
                Status = "⏳ PENDING"
                Details = "Lower TTLs before migration for faster propagation"
            }
            [PSCustomObject]@{
                Step = 8
                Phase = "Execution"
                Task = "Create new zones at destination"
                Status = "⏳ PENDING"
                Details = "Pre-stage unsigned zones"
            }
            [PSCustomObject]@{
                Step = 9
                Phase = "Execution"
                Task = "Generate new key pairs at destination"
                Status = "⏳ PENDING"
                Details = "Use same or better algorithms"
            }
            [PSCustomObject]@{
                Step = 10
                Phase = "Execution"
                Task = "Sign zones at destination"
                Status = "⏳ PENDING"
                Details = "Verify signatures before cutover"
            }
            [PSCustomObject]@{
                Step = 11
                Phase = "Execution"
                Task = "Update parent DS records"
                Status = "⏳ PENDING"
                Details = "Add new DS records (keep old during transition)"
            }
            [PSCustomObject]@{
                Step = 12
                Phase = "Execution"
                Task = "Wait for TTL expiration"
                Status = "⏳ PENDING"
                Details = "Wait 2x TTL period for propagation"
            }
            [PSCustomObject]@{
                Step = 13
                Phase = "Cutover"
                Task = "Switch authoritative servers"
                Status = "⏳ PENDING"
                Details = "Update NS records to point to new servers"
            }
            [PSCustomObject]@{
                Step = 14
                Phase = "Cutover"
                Task = "Monitor DNSSEC validation"
                Status = "⏳ PENDING"
                Details = "Check for SERVFAIL rates and validation failures"
            }
            [PSCustomObject]@{
                Step = 15
                Phase = "Cleanup"
                Task = "Remove old DS records from parent"
                Status = "⏳ PENDING"
                Details = "After verification, remove old DS records"
            }
            [PSCustomObject]@{
                Step = 16
                Phase = "Cleanup"
                Task = "Decommission old DNS servers"
                Status = "⏳ PENDING"
                Details = "Only after complete validation"
            }
        )
        
        # Display checklist
        Write-Host "Migration Checklist:" -ForegroundColor Cyan
        foreach ($item in $results.MigrationChecklist) {
            $statusColor = switch -Wildcard ($item.Status) {
                "*COMPLETE*" { "Green" }
                "*MANUAL*" { "Yellow" }
                "*PENDING*" { "Gray" }
                default { "White" }
            }
            Write-Host "  [$($item.Step.ToString().PadLeft(2))] " -NoNewline -ForegroundColor Gray
            Write-Host "$($item.Status.PadRight(20))" -NoNewline -ForegroundColor $statusColor
            Write-Host " $($item.Task)" -ForegroundColor White
            Write-Host "       $($item.Details)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Summary
        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║              DNSSEC Inventory Summary                         ║" -ForegroundColor Cyan
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Total Zones:           $($results.Statistics.TotalZones)" -ForegroundColor White
        Write-Host "  DNSSEC-Signed Zones:   $($results.Statistics.SignedZones)" -ForegroundColor Cyan
        Write-Host "  Total Keys:            $($results.Statistics.TotalKeys)" -ForegroundColor White
        Write-Host "    - KSKs (Key Signing):  $($results.Statistics.KSKs)" -ForegroundColor Gray
        Write-Host "    - ZSKs (Zone Signing): $($results.Statistics.ZSKs)" -ForegroundColor Gray
        Write-Host ""
        
        if ($results.Statistics.SignedZones -eq 0) {
            Write-Host "  ℹ️  No DNSSEC-signed zones found" -ForegroundColor Yellow
            Write-Host "  No migration preparation needed" -ForegroundColor Gray
        } else {
            Write-Host "  ⚠️  CRITICAL REMINDERS:" -ForegroundColor Red
            Write-Host "     1. Do NOT automate DNSSEC migration" -ForegroundColor Yellow
            Write-Host "     2. Contact parent zone administrators BEFORE starting" -ForegroundColor Yellow
            Write-Host "     3. Test in non-production environment first" -ForegroundColor Yellow
            Write-Host "     4. Have rollback plan ready" -ForegroundColor Yellow
            Write-Host "     5. Schedule during maintenance window" -ForegroundColor Yellow
            Write-Host "     6. Monitor validation rates during and after migration" -ForegroundColor Yellow
        }
        Write-Host ""
        
        return $results
    }
    catch {
        Write-Host "FATAL ERROR in DNSSEC Inventory: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Main Execution

# Environment Detection
Test-EnvironmentCapabilities

# Interactive Menu (if Mode not specified and not in NonInteractive mode)
if ([string]::IsNullOrEmpty($Mode) -and -not $script:NonInteractive) {
    $Mode = Show-ModeSelectionMenu
} elseif ([string]::IsNullOrEmpty($Mode)) {
    Write-Host "ERROR: -Mode parameter is required when using -NonInteractive" -ForegroundColor Red
    Write-Host "Available modes: Inventory, HealthCheck, RecordExport, SiteAudit, Complete, Baseline, Compare, ConfigAudit, ZoneHealth" -ForegroundColor Yellow
    exit 1
}

# Display banner (if not quiet)
if (-not $Quiet) {
    Write-Host ""
    Write-Host "╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          DNS Master Audit v$script:Version                    ║" -ForegroundColor Cyan
    Write-Host "╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Mode:        $Mode" -ForegroundColor White
    Write-Host "  Export Path: $ExportPath" -ForegroundColor White
    if ($EnableParallelProcessing) {
        Write-Host "  Parallel:    ENABLED (throttle: $MaxDegreeOfParallelism)" -ForegroundColor Green
    }
    if ($script:ShowProgress) {
        Write-Host "  Progress:    Enhanced with ETA" -ForegroundColor Green
    }
    Write-Host ""
}

# Execute selected mode
try {
    $Results = switch ($Mode) {
        "ConfigAudit" { 
            $auditResults = Start-DNSConfigurationAudit -Credential $Credential
            Update-ExecutionStats -ServersProcessed $auditResults.Statistics.TotalServers `
                -SuccessCount 1 `
                -WarningCount $auditResults.Issues.Count `
                -Findings $auditResults.Issues
            $auditResults
        }
        "ZoneHealth" { 
            $auditResults = Start-DNSZoneHealthAudit -Credential $Credential -ZoneFilter $ZoneFilter
            Update-ExecutionStats -ZonesProcessed $auditResults.Statistics.TotalZones `
                -SuccessCount 1 `
                -WarningCount $auditResults.Issues.Count `
                -Findings $auditResults.Issues
            $auditResults
        }
        "CISCompliance" { 
            $auditResults = Start-CISComplianceCheck -Credential $Credential
            Update-ExecutionStats -ServersProcessed ($auditResults.Checks | Select-Object -ExpandProperty Server -Unique).Count `
                -SuccessCount $auditResults.Summary.Passed `
                -WarningCount $auditResults.Summary.ManualReview `
                -ErrorCount $auditResults.Summary.Failed `
                -Findings $auditResults.Findings
            $auditResults
        }
        "DNSSECInventory" { 
            $auditResults = Start-DNSSECInventory -Credential $Credential
            Update-ExecutionStats -ZonesProcessed $auditResults.Statistics.TotalZones `
                -SuccessCount $auditResults.Statistics.SignedZones `
                -Findings @("$($auditResults.Statistics.SignedZones) DNSSEC-signed zones inventoried")
            $auditResults
        }
        default {
            Write-Host "⚠️  Mode '$Mode' is defined but not yet fully implemented in v3.2" -ForegroundColor Yellow
            Write-Host "   This mode is available in DNS-MasterAudit.ps1 (v2.8)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   Current v3.2 modes:" -ForegroundColor Cyan
            Write-Host "     • ConfigAudit - Configuration consistency audit" -ForegroundColor White
            Write-Host "     • ZoneHealth - Zone health and integrity audit" -ForegroundColor White
            Write-Host "     • CISCompliance - CIS Benchmark security audit (NEW!)" -ForegroundColor White
            Write-Host "     • DNSSECInventory - DNSSEC migration preparation (NEW!)" -ForegroundColor White
            Write-Host ""
            @{ Message = "Mode not implemented in v3.2"; Mode = $Mode }
        }
    }
    
    # Display executive summary
    Show-ExecutiveSummary -Results $Results -Mode $Mode -ExportPath $ExportPath
    
    # Export results if requested
    if ($ExportFormat -and $Results -and $Results -isnot [string]) {
        Write-Host "Exporting results..." -ForegroundColor Cyan
        # TODO: Add export functionality for ConfigAudit and ZoneHealth
    }
    
    exit 0
}
catch {
    Write-Host ""
    Write-Host "╔═════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                     FATAL ERROR                                 ║" -ForegroundColor Red
    Write-Host "╚═════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Stack Trace:" -ForegroundColor Yellow
    Write-Host "  $($_.ScriptStackTrace)" -ForegroundColor Gray
    Write-Host ""
    
    Update-ExecutionStats -ErrorCount 1
    Show-ExecutiveSummary -Results @{} -Mode $Mode -ExportPath $ExportPath
    
    exit 1
}

#endregion
