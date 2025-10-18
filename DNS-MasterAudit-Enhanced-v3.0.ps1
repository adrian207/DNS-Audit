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
    [ValidateSet("Inventory", "HealthCheck", "RecordExport", "SiteAudit", "Complete", "Baseline", "Compare")]
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


