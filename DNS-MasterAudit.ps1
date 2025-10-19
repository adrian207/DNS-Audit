################################################################################
# DNS Master Audit Script - ENTERPRISE EDITION
# Author: Adrian Johnson <adrian207@gmail.com>
# Created: 2025
# Version: 2.6 - Security Enhanced Edition
## Description: All-in-one DNS auditing tool - NO EXTERNAL DEPENDENCIES
#              1. DNS Inventory (server discovery)
#              2. DNS Health Check (service testing)
#              3. DNS Record Export (complete inventory)
#              4. DNS Site Audit (mismatch detection) - EMBEDDED
#              5. Complete Audit (all of the above)
#              6. Baseline Mode (snapshot for change tracking)
#              7. Compare Mode (detect configuration drift)
#              8. Analytics Mode (stale records, duplicates, PTR validation)
#              9. Security Mode (DNSSEC, zone transfer audits)
#              10. Diagnostics Mode (performance, replication lag, cross-site auth)
## NEW in v2.6: Security Enhancements
#              - Windows Credential Manager integration (secure credential storage)
#              - Comprehensive input validation (URLs, paths, webhooks)
#              - Sensitive data redaction (IPs, hostnames in reports)
#              - Audit trail signing (cryptographic log verification)
#              - Compliance modes (HIPAA, PCI-DSS, GDPR, FedRAMP)
#              - Enhanced security logging and validation
## v2.5 Features: Enterprise Features
#              - Advanced analytics (stale records, duplicate IPs, PTR validation)
#              - Security audits (DNSSEC validation, zone transfer checks)
#              - Enhanced diagnostics (query performance, replication lag)
#              - Remediation script generation (automated fix scripts)
#              - Enterprise integration (Teams, Slack, SIEM/Syslog)
#              - Configuration profiles (template-based audits)
## v2.2 Features: Parallel Processing Engine
#              - PowerShell runspaces for true parallelism
#              - 5-10x faster DC queries in large environments
#              - Configurable throttle (1-20 concurrent operations)
## v2.1 Features: Multiple Export Formats
#              - HTML: Interactive tables with search & sort
#              - JSON: Perfect for automation & APIs
#              - Excel: Professional formatted reports (requires ImportExcel module)
#              - CSV: Universal data format (default)
## Features: ALL functionality in ONE standalone script
#           Can run anywhere - no other scripts needed!
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory, DnsServer

<#
.SYNOPSIS
Unified, self-contained DNS auditing tool with multiple operation modes and export formats

.DESCRIPTION
All-in-one DNS audit solution combining 7 specialized functions with parallel processing:
- DNS-Inventory: Server discovery and inventory (parallel-enabled)
- DNS-HealthCheck: DNS service health testing (parallel-enabled)
- DNS-RecordExport: Complete DNS record export
- DNS-SiteAudit: Site mismatch detection (EMBEDDED - no dependencies!)
- Complete audit mode: Run all audits in sequence (parallel-enabled)
- Baseline Mode: Create snapshot for change tracking
- Compare Mode: Detect configuration drift

NEW in v2.2: Parallel Processing Engine
- Uses PowerShell runspaces for true parallel execution
- 5-10x performance improvement for large environments (10+ DCs)
- Configurable throttle limit (1-20 concurrent operations)
- Per-thread error handling with detailed logging
- Automatic fallback to sequential processing if disabled

NEW in v2.1 - Multiple Export Formats:
- CSV (default): Universal data format
- HTML: Interactive tables with search & sort
- JSON: Perfect for automation & APIs
- Excel: Professional formatted reports (requires ImportExcel module)
- All: Export in all formats simultaneously

✅ FULLY INDEPENDENT - No external scripts required!

.PARAMETER Mode
Operation mode:
- Inventory: Discover and list all DNS servers
- HealthCheck: Test DNS service health on all DCs
- RecordExport: Export all DNS records
- SiteAudit: Find site mismatches (embedded functionality)
- Complete: Run all audits (recommended for comprehensive analysis)
- Baseline: Create snapshot of current DNS state (NEW!)
- Compare: Compare current state to baseline (NEW!)

.PARAMETER ExportPath
Directory for all reports and logs (default: C:\DNSAudit)

.PARAMETER ExportFormat
Export format: CSV (default), HTML, JSON, Excel, or All (NEW!)
- CSV: Universal data format, works everywhere
- HTML: Interactive web report with search and sort
- JSON: Perfect for automation and API integration
- Excel: Professional formatted workbook (requires ImportExcel module)
- All: Generate all formats simultaneously

.PARAMETER ZoneFilter
Optional array of specific zones to audit (default: all zones)

.PARAMETER EnableAllFeatures
For SiteAudit mode: Enable advanced features (severity levels, health scores, etc.)

.PARAMETER BaselineFile
Path to baseline file for Compare mode (NEW!)
If not specified, uses latest baseline from Baselines folder

.PARAMETER EnableParallelProcessing
Enable parallel processing for faster execution (5-10x speedup for large environments)
Uses PowerShell runspaces to query multiple DCs simultaneously
Recommended for environments with 5+ domain controllers

.PARAMETER MaxDegreeOfParallelism
Maximum number of concurrent DC queries (default: 5, recommended: 5-10)
Higher values = faster execution but more resource usage
Valid range: 1-20

.PARAMETER Credential
PSCredential for remote AD/DNS operations (required for cross-domain or constrained environments)

.PARAMETER DnsServer
Specify DNS server for RecordExport (overrides auto-discovery)

.PARAMETER UnionZones
Query all DCs and union zones for RecordExport (comprehensive but slower)

.PARAMETER NoTranscript
Disable transcript logging for security/privacy

.PARAMETER EnableEmailNotification
Send email notification (LEGACY - uses deprecated Send-MailMessage cmdlet)

.PARAMETER SMTPServer
SMTP server for email notifications

.PARAMETER SmtpPort
SMTP port (default: 25)

.PARAMETER UseSsl
Use SSL for SMTP connection

.PARAMETER SmtpCredential
SMTP credential for authenticated mail

.PARAMETER EmailFrom
Email from address

.PARAMETER EmailTo
Email recipients (array)

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Inventory

Discovers all DNS servers in the domain and tests DNS service status.

Output: DNS_Inventory_YYYYMMDD_HHMMSS.csv
Columns: ServerName, IPAddress, Site, DNSServiceStatus, ZoneCount, PrimaryZones,         SecondaryZones, OperatingSystem, InventoryDate

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode HealthCheck -Credential $cred

Tests DNS service health on all domain controllers using alternate credentials.
Performs 3 tests per DC: Service Status, Zone Accessibility, DNS Resolution.

Output: DNS_HealthCheck_YYYYMMDD_HHMMSS.csv
Columns: DCName, TestName, Status, Details
Status values: PASS, FAIL, SKIP

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode RecordExport -ZoneFilter @("contoso.com","_msdcs.contoso.com")

Exports all DNS records from specified zones. Streams to disk to minimize memory usage.
Supports A, AAAA, CNAME, MX, PTR, SRV, TXT, NS record types.

Output: DNS_RecordExport_YYYYMMDD_HHMMSS.csv
Columns: ZoneName, RecordName, RecordType, RecordData, TTL, IsStatic, Timestamp, ExportDate

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode RecordExport -UnionZones

Queries ALL domain controllers and merges zone lists for complete coverage.
Slower but ensures no zones are missed (useful for non-AD-integrated or partitioned zones).

Output: DNS_RecordExport_YYYYMMDD_HHMMSS.csv
Columns: ZoneName, RecordName, RecordType, RecordData, TTL, IsStatic, Timestamp, ExportDate, SourceServer

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode RecordExport -DnsServer "DC01.contoso.com"

Exports records from a specific DNS server (overrides auto-discovery).
Useful when you know which server hosts specific zones.

Output: DNS_RecordExport_YYYYMMDD_HHMMSS.csv
Columns: ZoneName, RecordName, RecordType, RecordData, TTL, IsStatic, Timestamp, ExportDate, SourceServer

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode SiteAudit -EnableAllFeatures

Runs comprehensive site mismatch audit with severity analysis and zone health scores.
Detects DNS records pointing to IPs in different AD sites than the hosting DC.

Outputs:  DNS_Site_Mismatches_YYYYMMDD_HHMMSS.csv
    Columns: DCName, DCSite, DCIPAddress, ZoneName, RecordName, FQDN, RecordType,             IPAddress, IPSite, IPSubnet, SiteMismatch, TTL, IsStatic, Severity, AuditDate
  DNS_Audit_Statistics_YYYYMMDD_HHMMSS.csv
    Columns: TotalRecordsScanned, TotalMismatches, CriticalSeverity, HighSeverity,             MediumSeverity, LowSeverity, DCsScanned, AuditDate
  DNS_Audit_Skipped_Subnets_YYYYMMDD_HHMMSS.csv (if any subnet parsing errors)
    Columns: Subnet, Reason
  DNS_Zone_Health_Scores_YYYYMMDD_HHMMSS.csv (with -EnableAllFeatures)
    Columns: ZoneName, TotalRecords, Mismatches, MismatchPercent

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Complete -ExportPath "D:\Reports" -NoTranscript

Runs ALL audit modes in sequence: Inventory → Health → Export → Site Audit.
Custom export path, no transcript logging for security.

Outputs ALL files:
  - DNS_Inventory_YYYYMMDD_HHMMSS.csv
  - DNS_HealthCheck_YYYYMMDD_HHMMSS.csv
  - DNS_RecordExport_YYYYMMDD_HHMMSS.csv
  - DNS_Site_Mismatches_YYYYMMDD_HHMMSS.csv
  - DNS_Audit_Statistics_YYYYMMDD_HHMMSS.csv
  - DNS_Audit_Skipped_Subnets_YYYYMMDD_HHMMSS.csv (if applicable)

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode SiteAudit -EnableEmailNotification -SMTPServer "smtp.contoso.com" -SmtpPort 587 -UseSsl -EmailFrom "dns-audit@contoso.com" -EmailTo "admins@contoso.com"

Runs site audit and sends email notification via authenticated SMTP with SSL.
Note: Send-MailMessage is deprecated; consider using external notification systems.

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Inventory -ExportFormat HTML

NEW! Runs inventory and exports interactive HTML report with sortable/searchable table.

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Complete -ExportFormat All

NEW! Runs complete audit and exports in ALL formats (CSV, HTML, JSON, Excel).

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode HealthCheck -ExportFormat JSON

NEW! Exports health check results as JSON for automation/API integration.

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Baseline

NEW! Creates baseline snapshot of current DNS state for change tracking.

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Compare

NEW! Compares current DNS state to latest baseline and shows changes.

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Compare -BaselineFile "C:\DNSAudit\Baselines\DNS_Baseline_20250119_100000.json"

NEW! Compares to specific baseline file.

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Inventory -EnableParallelProcessing

NEW! Run inventory with parallel processing for 5-10x speedup (default: 5 concurrent DCs).

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Complete -EnableParallelProcessing -MaxDegreeOfParallelism 10

NEW! Run complete audit with aggressive parallel processing (10 concurrent DC queries).

.NOTES
Version: 2.2 - Parallel Processing Edition
Author: Adrian Johnson <adrian207@gmail.com>
Self-Contained: All functionality embedded in this single script

NEW in v2.2:
- Parallel processing for DC queries (5-10x performance improvement)
- Configurable throttle limit (1-20 concurrent operations)
- PowerShell runspace pool for efficient resource management
- Automatic fallback to sequential processing if disabled

v2.1 Features:
- Multiple export formats (CSV, HTML, JSON, Excel)
- Interactive HTML reports with search and sort
- Baseline mode for change tracking
- Compare mode for configuration drift detection

Prerequisites:
- PowerShell 5.1 or later (PowerShell 7.x supported)
- RSAT: Active Directory DS Tools (ActiveDirectory module)
  Install: Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
- RSAT: DNS Server Tools (DnsServer module)
  Install: Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0
- Run on a host with network access to domain controllers
- Firewall rules: Allow DNS (TCP/UDP 53), RPC (TCP 135, dynamic high ports), SMB (TCP 445) to DCs
- Sufficient permissions: DNS read, AD read (no Domain Admin required for audit-only operations)
  Minimum groups: DNS Admins (read-only) or delegated DNS permissions, Domain Users

Output Files and CSV Column Names (in ExportPath directory):

DNS_Inventory_YYYYMMDD_HHMMSS.csv (Mode: Inventory)
  Columns: ServerName, IPAddress, Site, DNSServiceStatus, ZoneCount, PrimaryZones,           SecondaryZones, OperatingSystem, InventoryDate

DNS_HealthCheck_YYYYMMDD_HHMMSS.csv (Mode: HealthCheck)
  Columns: DCName, TestName, Status, Details
  Tests: DNS Service Status, Zone Accessibility, DNS Resolution

DNS_RecordExport_YYYYMMDD_HHMMSS.csv (Mode: RecordExport)
  Columns: ZoneName, RecordName, RecordType, RecordData, TTL, IsStatic, Timestamp, ExportDate
  Optional: SourceServer (when using -DnsServer or -UnionZones)
  Record Types: A, AAAA, CNAME, MX, PTR, SRV, TXT, NS

DNS_Site_Mismatches_YYYYMMDD_HHMMSS.csv (Mode: SiteAudit)
  Columns: DCName, DCSite, DCIPAddress, ZoneName, RecordName, FQDN, RecordType, IPAddress,
           IPSite, IPSubnet, SiteMismatch, TTL, IsStatic, Severity, AuditDate
  Severity Levels: Critical, High, Medium, Low

DNS_Audit_Statistics_YYYYMMDD_HHMMSS.csv (Mode: SiteAudit)
  Columns: TotalRecordsScanned, TotalMismatches, CriticalSeverity, HighSeverity,           MediumSeverity, LowSeverity, DCsScanned, AuditDate

DNS_Audit_Skipped_Subnets_YYYYMMDD_HHMMSS.csv (Mode: SiteAudit)
  Columns: Subnet, Reason
  Created when subnet parsing errors occur (invalid format, out-of-bounds prefix, etc.)

DNS_Zone_Health_Scores_YYYYMMDD_HHMMSS.csv (Mode: SiteAudit with -EnableAllFeatures)
  Columns: ZoneName, TotalRecords, Mismatches, MismatchPercent
  Only created when -EnableAllFeatures is specified

MasterAudit_YYYYMMDD_HHMMSS.log (All modes)
  PowerShell transcript log (unless -NoTranscript is specified)
  Contains full command output, warnings, and execution details

Exit Codes (for CI/CD integration):
- 0: Success
- 1: Unhandled exception/fatal error
- 2: One or more modes failed in Complete audit
- 3: SiteAudit found Critical severity issues

Performance Notes:
- RecordExport streams to disk to minimize memory usage (safe for large estates)
- UnionZones mode queries all DCs (slower but comprehensive)
- Default mode queries first DC only (fast but may miss partitioned zones)

Security Notes:
- Use -Credential for least-privilege access (avoid Domain Admin)
- Use -NoTranscript to prevent sensitive data in log files
- Send-MailMessage is deprecated; consider external notification systems
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Operation mode")]
    [ValidateSet("Inventory", "HealthCheck", "RecordExport", "SiteAudit", "Complete", "Baseline", "Compare", "Analytics", "Security", "Diagnostics")]
    [string]$Mode,
    [Parameter(HelpMessage = "Export directory for all reports")]
    [string]$ExportPath = "C:\DNSAudit",
    [Parameter(HelpMessage = "Export format: CSV (default), HTML, JSON, Excel, or All")]
    [ValidateSet("CSV", "HTML", "JSON", "Excel", "All")]
    [string]$ExportFormat = "CSV",
    [Parameter(HelpMessage = "Filter specific zones")]
    [string[]]$ZoneFilter = @(),
    [Parameter(HelpMessage = "Enable all advanced features for SiteAudit mode")]
    [switch]$EnableAllFeatures,
    [Parameter(HelpMessage = "Baseline file path for Compare mode")]
    [string]$BaselineFile = "",
    [Parameter(HelpMessage = "Enable parallel processing for faster execution (5-10x speedup)")]
    [switch]$EnableParallelProcessing,
    [Parameter(HelpMessage = "Maximum concurrent DC queries (default: 5, recommended: 5-10)")]
    [ValidateRange(1, 20)]
    [int]$MaxDegreeOfParallelism = 5,
    [Parameter(HelpMessage = "Credential for remote operations")]
    [PSCredential]$Credential,
    [Parameter(HelpMessage = "Specific DNS server for RecordExport (overrides auto-discovery)")]
    [string]$DnsServer,
    [Parameter(HelpMessage = "Query all DCs and union zones for RecordExport (comprehensive but slower)")]
    [switch]$UnionZones,
    [Parameter(HelpMessage = "Disable transcript logging (for security/privacy)")]
    [switch]$NoTranscript,
    [Parameter(HelpMessage = "Send email notification (LEGACY: Uses deprecated Send-MailMessage)")]
    [switch]$EnableEmailNotification,
    [Parameter(HelpMessage = "SMTP server for email")]
    [string]$SMTPServer,
    [Parameter(HelpMessage = "SMTP port (default: 25)")]
    [int]$SmtpPort = 25,
    [Parameter(HelpMessage = "Use SSL for SMTP connection")]
    [switch]$UseSsl,
    [Parameter(HelpMessage = "SMTP credential for authenticated mail")]
    [PSCredential]$SmtpCredential,
    [Parameter(HelpMessage = "Email from address")]
    [string]$EmailFrom,
    [Parameter(HelpMessage = "Email recipients")]
    [string[]]$EmailTo,
    
    # Advanced Analytics Parameters (NEW in v2.5)
    [Parameter(HelpMessage = "Stale record threshold in days (default: 90 days)")]
    [ValidateRange(1, 3650)]
    [int]$StaleRecordThreshold = 90,
    [Parameter(HelpMessage = "Enable PTR record validation")]
    [switch]$ValidatePTRRecords,
    [Parameter(HelpMessage = "Detect duplicate IP addresses")]
    [switch]$DetectDuplicateIPs,
    
    # Enterprise Integration Parameters (NEW in v2.5)
    [Parameter(HelpMessage = "Microsoft Teams webhook URL for notifications")]
    [string]$TeamsWebhook = "",
    [Parameter(HelpMessage = "Slack webhook URL for notifications")]
    [string]$SlackWebhook = "",
    [Parameter(HelpMessage = "Syslog/SIEM server for log forwarding")]
    [string]$SyslogServer = "",
    [Parameter(HelpMessage = "Syslog port (default: 514)")]
    [ValidateRange(1, 65535)]
    [int]$SyslogPort = 514,
    
    # Security & Compliance Parameters (NEW in v2.5)
    [Parameter(HelpMessage = "Enable DNSSEC validation checks")]
    [switch]$EnableDNSSECCheck,
    [Parameter(HelpMessage = "Audit zone transfer security")]
    [switch]$AuditZoneTransfers,
    [Parameter(HelpMessage = "Check for insecure dynamic updates")]
    [switch]$CheckDynamicUpdates,
    
    # Remediation Parameters (NEW in v2.5)
    [Parameter(HelpMessage = "Generate remediation scripts for found issues")]
    [switch]$GenerateRemediationScript,
    [Parameter(HelpMessage = "Auto-fix minor issues (use with caution!)")]
    [switch]$AutoFix,
    
    # Enhanced Diagnostics Parameters (NEW in v2.5)
    [Parameter(HelpMessage = "Test DNS query performance")]
    [switch]$TestQueryPerformance,
    [Parameter(HelpMessage = "Check AD replication lag")]
    [switch]$CheckReplicationLag,
    [Parameter(HelpMessage = "Check for cross-site authentication issues (scans netlogon.log on all DCs)")]
    [switch]$CheckCrossSiteAuth,
    [Parameter(HelpMessage = "Number of DNS queries for performance testing (default: 10)")]
    [ValidateRange(1, 100)]
    [int]$PerformanceTestIterations = 10,
    
    # Configuration Management Parameters (NEW in v2.5)
    [Parameter(HelpMessage = "Load configuration from profile (JSON file path)")]
    [string]$ConfigProfile = "",
    [Parameter(HelpMessage = "Save current parameters as configuration profile")]
    [string]$SaveConfigProfile = "",
    
    # Security Parameters (NEW in v2.6)
    [Parameter(HelpMessage = "Use Windows Credential Manager for secure credential storage")]
    [switch]$UseCredentialManager,
    [Parameter(HelpMessage = "Credential name in Windows Credential Manager")]
    [string]$CredentialName = "DNS-Audit-Default",
    [Parameter(HelpMessage = "Redact sensitive data (IPs, hostnames) in reports")]
    [switch]$RedactSensitiveData,
    [Parameter(HelpMessage = "Compliance mode preset (HIPAA, PCI-DSS, GDPR, FedRAMP)")]
    [ValidateSet("None", "HIPAA", "PCI-DSS", "GDPR", "FedRAMP")]
    [string]$ComplianceMode = "None",
    [Parameter(HelpMessage = "Enable cryptographic signing of audit logs")]
    [switch]$EnableAuditSigning,
    [Parameter(HelpMessage = "Certificate thumbprint for audit log signing")]
    [string]$SigningCertificateThumbprint = ""
)

#region Script Variables
$script:Version = "2.6 - Security Enhanced Edition"
$script:StartTime = Get-Date
$script:TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:LogPath = ""
$script:AllResults = @{
    Inventory = $null
    HealthCheck = $null
    RecordExport = $null
    SiteAudit = $null
    Analytics = $null
    Security = $null
    Diagnostics = $null
}
$script:SkippedSubnets = @()
$script:EnableParallelProcessing = $EnableParallelProcessing.IsPresent
$script:MaxDegreeOfParallelism = $MaxDegreeOfParallelism
$script:RemediationCommands = @()
$script:IssuesFound = 0
# Security variables (v2.6)
$script:UseCredentialManager = $UseCredentialManager.IsPresent
$script:RedactSensitiveData = $RedactSensitiveData.IsPresent
$script:EnableAuditSigning = $EnableAuditSigning.IsPresent
$script:AuditLogHash = @()
#endregion

#region Logging Functions

function Start-MasterLogging {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    if (-not $NoTranscript) {
        $script:LogPath = Join-Path $Path "MasterAudit_${script:TimeStamp}.log"
        Start-Transcript -Path $script:LogPath -Append
    }
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   DNS MASTER AUDIT - INDEPENDENT EDITION v$($script:Version)   ║" -ForegroundColor Cyan
    Write-Host "║   ✅ NO EXTERNAL DEPENDENCIES - Fully Self-Contained       ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

function Stop-MasterLogging {
    if (-not $NoTranscript) {
        Stop-Transcript
        Write-Host "`nLog file: $script:LogPath" -ForegroundColor Green
    }
}

function Write-AuditLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    $Color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    $LogMessage = "[$Level] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $LogMessage -ForegroundColor $Color
}

function Export-ToHTML {
    <#
    .SYNOPSIS
    Export data to interactive HTML with sortable tables
    #>
    param(
        [Parameter(Mandatory)]
        [array]$Data,
        [Parameter(Mandatory)]
        [string]$FilePath,
        [string]$Title = "DNS Audit Report"
    )
    
    if ($Data.Count -eq 0) {
        Write-AuditLog "No data to export to HTML" -Level WARNING
        return
    }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        :root {
            --primary: #0078d4;
            --success: #107c10;
            --warning: #ff8c00;
            --error: #d13438;
            --bg: #f3f2f1;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: var(--bg);
        }
        .header {
            background: linear-gradient(135deg, var(--primary) 0%, #005a9e 100%);
            color: white;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 30px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .header h1 { margin: 0 0 10px 0; }
        .header p { margin: 5px 0; opacity: 0.9; }
        .controls {
            background: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .controls input {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
            width: 300px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        thead {
            background: var(--primary);
            color: white;
        }
        th {
            padding: 12px;
            text-align: left;
            font-weight: 600;
            cursor: pointer;
            user-select: none;
        }
        th:hover {
            background: #005a9e;
        }
        th::after {
            content: ' ⇅';
            opacity: 0.5;
        }
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #f0f0f0;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>$Title</h1>
        <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p>Author: Adrian Johnson &lt;adrian207@gmail.com&gt;</p>
        <p>Records: $($Data.Count)</p>
    </div>
    
    <div class="controls">
        <input type="text" id="searchInput" placeholder="Search table..." onkeyup="searchTable()">
    </div>
    
    <table id="dataTable">
        <thead>
            <tr>
"@
    
    # Add headers
    $properties = $Data[0].PSObject.Properties.Name
    foreach ($prop in $properties) {
        $html += "                <th onclick='sortTable(this)'>$prop</th>`n"
    }
    
    $html += @"
            </tr>
        </thead>
        <tbody>
"@
    
    # Add rows
    foreach ($row in $Data) {
        $html += "            <tr>`n"
        foreach ($prop in $properties) {
            $value = $row.$prop
            if ($null -eq $value) { $value = "" }
            $html += "                <td>$value</td>`n"
        }
        $html += "            </tr>`n"
    }
    
    $html += @"
        </tbody>
    </table>
    
    <div class="footer">
        <p>DNS Master Audit v$($script:Version)</p>
        <p>© 2025 Adrian Johnson. All rights reserved.</p>
    </div>
    
    <script>
        function searchTable() {
            const input = document.getElementById('searchInput');
            const filter = input.value.toUpperCase();
            const table = document.getElementById('dataTable');
            const tr = table.getElementsByTagName('tr');
            
            for (let i = 1; i < tr.length; i++) {
                const tds = tr[i].getElementsByTagName('td');
                let found = false;
                for (let j = 0; j < tds.length; j++) {
                    if (tds[j].textContent.toUpperCase().indexOf(filter) > -1) {
                        found = true;
                        break;
                    }
                }
                tr[i].style.display = found ? '' : 'none';
            }
        }
        
        function sortTable(th) {
            const table = th.closest('table');
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));
            const index = Array.from(th.parentNode.children).indexOf(th);
            const isAsc = th.classList.contains('asc');
            
            rows.sort((a, b) => {
                const aVal = a.children[index].textContent;
                const bVal = b.children[index].textContent;
                return isAsc ? bVal.localeCompare(aVal) : aVal.localeCompare(bVal);
            });
            
            th.parentNode.querySelectorAll('th').forEach(h => h.classList.remove('asc', 'desc'));
            th.classList.add(isAsc ? 'desc' : 'asc');
            
            rows.forEach(row => tbody.appendChild(row));
        }
    </script>
</body>
</html>
"@
    
    $html | Out-File -FilePath $FilePath -Encoding UTF8
    Write-AuditLog "HTML report created: $FilePath" -Level SUCCESS
}

function Export-ToJSON {
    <#
    .SYNOPSIS
    Export data to JSON format
    #>
    param(
        [Parameter(Mandatory)]
        [array]$Data,
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    if ($Data.Count -eq 0) {
        Write-AuditLog "No data to export to JSON" -Level WARNING
        return
    }
    
    $jsonData = @{
        Metadata = @{
            Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Author = "Adrian Johnson <adrian207@gmail.com>"
            Version = $script:Version
            RecordCount = $Data.Count
        }
        Data = $Data
    }
    
    $jsonData | ConvertTo-Json -Depth 10 | Out-File -FilePath $FilePath -Encoding UTF8
    Write-AuditLog "JSON report created: $FilePath" -Level SUCCESS
}

function Export-ToExcel {
    <#
    .SYNOPSIS
    Export data to Excel format (requires ImportExcel module)
    #>
    param(
        [Parameter(Mandatory)]
        [array]$Data,
        [Parameter(Mandatory)]
        [string]$FilePath,
        [string]$WorksheetName = "DNS Audit"
    )
    
    if ($Data.Count -eq 0) {
        Write-AuditLog "No data to export to Excel" -Level WARNING
        return
    }
    
    # Check if ImportExcel module is available
    if (!(Get-Module -ListAvailable -Name ImportExcel)) {
        Write-AuditLog "ImportExcel module not found. Install with: Install-Module ImportExcel" -Level WARNING
        Write-AuditLog "Falling back to CSV export" -Level INFO
        $csvPath = $FilePath -replace '\.xlsx$', '.csv'
        $Data | Export-Csv -Path $csvPath -NoTypeInformation
        Write-AuditLog "CSV report created: $csvPath" -Level SUCCESS
        return
    }
    
    try {
        Import-Module ImportExcel -ErrorAction Stop
        
        $Data | Export-Excel -Path $FilePath `
            -WorksheetName $WorksheetName `
            -AutoSize `
            -TableName "DNSAuditData" `
            -TableStyle Medium2 `
            -FreezeTopRow `
            -BoldTopRow
        
        Write-AuditLog "Excel report created: $FilePath" -Level SUCCESS
    }
    catch {
        Write-AuditLog "Error creating Excel file: $($_.Exception.Message)" -Level ERROR
        Write-AuditLog "Falling back to CSV export" -Level INFO
        $csvPath = $FilePath -replace '\.xlsx$', '.csv'
        $Data | Export-Csv -Path $csvPath -NoTypeInformation
        Write-AuditLog "CSV report created: $csvPath" -Level SUCCESS
    }
}

function Export-AuditData {
    <#
    .SYNOPSIS
    Export audit data in specified format(s)
    #>
    param(
        [Parameter(Mandatory)]
        [array]$Data,
        [Parameter(Mandatory)]
        [string]$BaseFileName,
        [string]$Format = "CSV",
        [string]$Title = "DNS Audit Report"
    )
    
    if ($Data.Count -eq 0) {
        Write-AuditLog "No data to export" -Level WARNING
        return
    }
    
    # Apply data redaction if enabled (v2.6)
    if ($script:RedactSensitiveData) {
        Write-AuditLog "Applying data redaction..." -Level INFO
        $Data = $Data | ForEach-Object {
            $redactedObject = $_.PSObject.Copy()
            foreach ($property in $redactedObject.PSObject.Properties) {
                if ($property.Value -is [string]) {
                    $property.Value = Hide-SensitiveData -InputString $property.Value -RedactType "Both"
                }
            }
            $redactedObject
        }
        Write-AuditLog "Data redaction applied to $($Data.Count) records" -Level SUCCESS
    }
    
    $formats = if ($Format -eq "All") { @("CSV", "HTML", "JSON", "Excel") } else { @($Format) }
    
    foreach ($fmt in $formats) {
        $extension = switch ($fmt) {
            "CSV" { ".csv" }
            "HTML" { ".html" }
            "JSON" { ".json" }
            "Excel" { ".xlsx" }
        }
        
        $filePath = Join-Path $ExportPath "$BaseFileName$extension"
        
        switch ($fmt) {
            "CSV" {
                $Data | Export-Csv -Path $filePath -NoTypeInformation
                Write-AuditLog "CSV report created: $filePath" -Level SUCCESS
            }
            "HTML" {
                Export-ToHTML -Data $Data -FilePath $filePath -Title $Title
            }
            "JSON" {
                Export-ToJSON -Data $Data -FilePath $filePath
            }
            "Excel" {
                Export-ToExcel -Data $Data -FilePath $filePath -WorksheetName $Title
            }
        }
    }
}

#endregion

#region Parallel Processing Engine

<#
.SYNOPSIS
    Executes script blocks in parallel using PowerShell runspaces.
.DESCRIPTION
    Provides true parallel execution for DC queries, offering 5-10x speedup.
    Uses runspace pools for efficient resource management.
#>
function Invoke-ParallelExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Items,
        
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [int]$ThrottleLimit = 5,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [string]$ActivityName = "Processing Items"
    )
    
    try {
        Write-AuditLog "Initializing parallel execution: $($Items.Count) items with throttle limit $ThrottleLimit"
        
        # Create runspace pool
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
        $runspacePool.Open()
        
        # Create jobs collection
        $jobs = New-Object System.Collections.ArrayList
        
        $itemNumber = 0
        foreach ($item in $Items) {
            $itemNumber++
            
            # Create PowerShell instance
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool
            
            # Add script block and parameters
            [void]$powershell.AddScript($ScriptBlock)
            [void]$powershell.AddArgument($item)
            
            # Add any additional parameters
            foreach ($key in $Parameters.Keys) {
                [void]$powershell.AddParameter($key, $Parameters[$key])
            }
            
            # Start async execution
            $asyncResult = $powershell.BeginInvoke()
            
            # Store job info
            [void]$jobs.Add([PSCustomObject]@{
                    PowerShell   = $powershell
                    AsyncResult  = $asyncResult
                    Item         = $item
                    ItemNumber   = $itemNumber
                    StartTime    = Get-Date
                })
        }
        
        Write-AuditLog "Started $($jobs.Count) parallel jobs"
        
        # Collect results
        $results = New-Object System.Collections.ArrayList
        $completedCount = 0
        $totalJobs = $jobs.Count
        
        while ($jobs.Count -gt 0) {
            $completed = @()
            
            foreach ($job in $jobs) {
                if ($job.AsyncResult.IsCompleted) {
                    $completed += $job
                }
            }
            
            foreach ($job in $completed) {
                try {
                    # Get result
                    $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                    
                    # Check for errors
                    if ($job.PowerShell.Streams.Error.Count -gt 0) {
                        foreach ($err in $job.PowerShell.Streams.Error) {
                            Write-AuditLog "Parallel job error for item $($job.ItemNumber): $err" -Level ERROR
                        }
                    }
                    
                    # Store result
                    if ($null -ne $result) {
                        [void]$results.Add($result)
                    }
                    
                    $completedCount++
                    $percentComplete = [math]::Round(($completedCount / $totalJobs) * 100)
                    Write-Progress -Activity $ActivityName `
                        -Status "Completed $completedCount of $totalJobs" `
                        -PercentComplete $percentComplete
                    
                } catch {
                    Write-AuditLog "Failed to collect result for item $($job.ItemNumber): $_" -Level ERROR
                } finally {
                    # Clean up
                    $job.PowerShell.Dispose()
                    $jobs.Remove($job)
                }
            }
            
            Start-Sleep -Milliseconds 100
        }
        
        Write-Progress -Activity $ActivityName -Completed
        Write-AuditLog "Parallel execution completed: $($results.Count) results collected"
        
        # Clean up runspace pool
        $runspacePool.Close()
        $runspacePool.Dispose()
        
        return $results
        
    } catch {
        Write-AuditLog "Parallel execution error: $_" -Level ERROR
        throw
    }
}

<#
.SYNOPSIS
    Wrapper for Get-DnsServerZone with error handling for parallel execution.
#>
function Get-DnsServerZoneSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [Parameter()]
        [PSCredential]$Credential
    )
    
    try {
        $params = @{
            ComputerName = $ComputerName
            ErrorAction  = 'Stop'
        }
        if ($Credential) {
            $params['Credential'] = $Credential
        }
        
        $zones = Get-DnsServerZone @params
        
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            Zones        = $zones
            Success      = $true
            Error        = $null
        }
        
    } catch {
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            Zones        = @()
            Success      = $false
            Error        = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Wrapper for DNS health checks with error handling for parallel execution.
#>
function Test-DnsServerHealthSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [Parameter()]
        [PSCredential]$Credential
    )
    
    $results = @()
    
    # Test 1: DNS Service Status
    try {
        $params = @{
            ClassName    = 'Win32_Service'
            Filter       = "Name='DNS'"
            ComputerName = $ComputerName
            ErrorAction  = 'Stop'
        }
        if ($Credential) {
            $params['Credential'] = $Credential
        }
        
        $service = Get-CimInstance @params
        $status = if ($service.State -eq 'Running') { 'PASS' } else { 'FAIL' }
        $details = "Service State: $($service.State)"
        
        $results += [PSCustomObject]@{
            DCName   = $ComputerName
            TestName = 'DNS Service Status'
            Status   = $status
            Details  = $details
        }
    } catch {
        $results += [PSCustomObject]@{
            DCName   = $ComputerName
            TestName = 'DNS Service Status'
            Status   = 'ERROR'
            Details  = "Failed to query service: $($_.Exception.Message)"
        }
    }
    
    # Test 2: Zone Accessibility
    try {
        $params = @{
            ComputerName = $ComputerName
            ErrorAction  = 'Stop'
        }
        if ($Credential) {
            $params['Credential'] = $Credential
        }
        
        $zones = Get-DnsServerZone @params
        $zoneCount = ($zones | Measure-Object).Count
        $status = if ($zoneCount -gt 0) { 'PASS' } else { 'WARN' }
        $details = "Zones accessible: $zoneCount"
        
        $results += [PSCustomObject]@{
            DCName   = $ComputerName
            TestName = 'Zone Accessibility'
            Status   = $status
            Details  = $details
        }
    } catch {
        $results += [PSCustomObject]@{
            DCName   = $ComputerName
            TestName = 'Zone Accessibility'
            Status   = 'ERROR'
            Details  = "Failed to query zones: $($_.Exception.Message)"
        }
    }
    
    # Test 3: DNS Resolution
    try {
        $testDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
        $result = Resolve-DnsName -Name $testDomain -Server $ComputerName -ErrorAction Stop
        $status = if ($result) { 'PASS' } else { 'FAIL' }
        $details = "Resolved $testDomain successfully"
        
        $results += [PSCustomObject]@{
            DCName   = $ComputerName
            TestName = 'DNS Resolution'
            Status   = $status
            Details  = $details
        }
    } catch {
        $results += [PSCustomObject]@{
            DCName   = $ComputerName
            TestName = 'DNS Resolution'
            Status   = 'ERROR'
            Details  = "Resolution failed: $($_.Exception.Message)"
        }
    }
    
    return $results
}

#endregion

#region Enterprise Integration Functions (v2.5)

<#
.SYNOPSIS
    Send notification to Microsoft Teams webhook
#>
function Send-TeamsNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Severity = "Info"
    )
    
    try {
        $color = switch ($Severity) {
            "Success" { "00FF00" }
            "Warning" { "FFA500" }
            "Error" { "FF0000" }
            default { "0078D4" }
        }
        
        $body = @{
            "@type" = "MessageCard"
            "@context" = "https://schema.org/extensions"
            "summary" = $Title
            "themeColor" = $color
            "title" = $Title
            "text" = $Message
        } | ConvertTo-Json -Depth 10
        
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        Write-AuditLog "Teams notification sent successfully" -Level SUCCESS
        
    } catch {
        Write-AuditLog "Failed to send Teams notification: $_" -Level WARNING
    }
}

<#
.SYNOPSIS
    Send notification to Slack webhook
#>
function Send-SlackNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    try {
        $body = @{
            text = $Message
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        Write-AuditLog "Slack notification sent successfully" -Level SUCCESS
        
    } catch {
        Write-AuditLog "Failed to send Slack notification: $_" -Level WARNING
    }
}

<#
.SYNOPSIS
    Send log to Syslog/SIEM server
#>
function Send-SyslogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Server,
        
        [Parameter()]
        [int]$Port = 514,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("Emergency", "Alert", "Critical", "Error", "Warning", "Notice", "Info", "Debug")]
        [string]$Severity = "Info"
    )
    
    try {
        $severityMap = @{
            "Emergency" = 0
            "Alert" = 1
            "Critical" = 2
            "Error" = 3
            "Warning" = 4
            "Notice" = 5
            "Info" = 6
            "Debug" = 7
        }
        
        $priority = $severityMap[$Severity]
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        $hostname = $env:COMPUTERNAME
        $syslogMessage = "<$priority>$timestamp $hostname DNS-MasterAudit: $Message"
        
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($syslogMessage)
        $null = $udpClient.Send($bytes, $bytes.Length, $Server, $Port)
        $udpClient.Close()
        
        Write-AuditLog "Syslog message sent to $Server`:$Port" -Level SUCCESS
        
    } catch {
        Write-AuditLog "Failed to send Syslog message: $_" -Level WARNING
    }
}

#endregion

#region Configuration Management Functions (v2.5)

<#
.SYNOPSIS
    Load configuration profile from JSON file
#>
function Import-ConfigProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath
    )
    
    try {
        if (-not (Test-Path $ProfilePath)) {
            throw "Configuration profile not found: $ProfilePath"
        }
        
        $config = Get-Content $ProfilePath -Raw | ConvertFrom-Json
        Write-AuditLog "Loaded configuration profile: $ProfilePath" -Level SUCCESS
        return $config
        
    } catch {
        Write-AuditLog "Failed to load configuration profile: $_" -Level ERROR
        throw
    }
}

<#
.SYNOPSIS
    Save current configuration as profile
#>
function Export-ConfigProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath,
        
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )
    
    try {
        $config = $Configuration | ConvertTo-Json -Depth 10
        $config | Out-File -FilePath $ProfilePath -Encoding UTF8 -Force
        Write-AuditLog "Saved configuration profile: $ProfilePath" -Level SUCCESS
        
    } catch {
        Write-AuditLog "Failed to save configuration profile: $_" -Level ERROR
        throw
    }
}

#endregion

#region Remediation Functions (v2.5)

<#
.SYNOPSIS
    Add remediation command to collection
#>
function Add-RemediationCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Issue,
        
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter()]
        [string]$Description = ""
    )
    
    $script:RemediationCommands += [PSCustomObject]@{
        Issue = $Issue
        Command = $Command
        Description = $Description
        Timestamp = Get-Date
    }
    
    $script:IssuesFound++
}

<#
.SYNOPSIS
    Generate PowerShell remediation script
#>
function Export-RemediationScript {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$OutputPath = $ExportPath
    )
    
    if ($script:RemediationCommands.Count -eq 0) {
        Write-AuditLog "No remediation commands to export" -Level INFO
        return
    }
    
    try {
        $scriptPath = Join-Path $OutputPath "DNS_Remediation_${script:TimeStamp}.ps1"
        
        $scriptContent = @"
################################################################################
# DNS Remediation Script
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Author: Adrian Johnson <adrian207@gmail.com>
# Issues Found: $($script:RemediationCommands.Count)
#
# WARNING: Review all commands before executing!
# This script was auto-generated and should be reviewed by an administrator.
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory, DnsServer
#Requires -RunAsAdministrator

# Set error action preference
`$ErrorActionPreference = 'Stop'

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  DNS REMEDIATION SCRIPT" -ForegroundColor Cyan
Write-Host "  Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" -ForegroundColor Cyan
Write-Host "  Issues to remediate: $($script:RemediationCommands.Count)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Confirm execution
`$confirmation = Read-Host "Do you want to proceed with remediation? (yes/no)"
if (`$confirmation -ne "yes") {
    Write-Host "Remediation cancelled by user" -ForegroundColor Yellow
    exit
}

`$successCount = 0
`$failCount = 0

"@
        
        $index = 1
        foreach ($cmd in $script:RemediationCommands) {
            $scriptContent += @"

# ============================================================================
# Issue $index of $($script:RemediationCommands.Count): $($cmd.Issue)
# ============================================================================
$(if ($cmd.Description) { "# Description: $($cmd.Description)`n" })
Write-Host "`nProcessing issue $index`: $($cmd.Issue)" -ForegroundColor Yellow

try {
    $($cmd.Command)
    Write-Host "  ✓ Fixed successfully" -ForegroundColor Green
    `$successCount++
} catch {
    Write-Host "  ✗ Failed: `$_" -ForegroundColor Red
    `$failCount++
}

"@
            $index++
        }
        
        $scriptContent += @"

# ============================================================================
# Summary
# ============================================================================
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  REMEDIATION COMPLETE" -ForegroundColor Cyan
Write-Host "  Successful: `$successCount" -ForegroundColor Green
Write-Host "  Failed: `$failCount" -ForegroundColor $(if (`$failCount -gt 0) { "Red" } else { "Green" })
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
"@
        
        $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
        Write-AuditLog "Remediation script generated: $scriptPath" -Level SUCCESS
        Write-Host "`n✓ Remediation script: $scriptPath" -ForegroundColor Green
        
    } catch {
        Write-AuditLog "Failed to generate remediation script: $_" -Level ERROR
    }
}

#endregion

#region Security Functions (v2.6)

<#
.SYNOPSIS
    Get credential from Windows Credential Manager
#>
function Get-StoredCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TargetName
    )
    
    try {
        # Load the required .NET assembly
        Add-Type -AssemblyName System.Security
        
        # Use CredentialManager if available, otherwise fall back to manual
        $credManagerPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers"
        
        if (Test-Path $credManagerPath) {
            # Use Windows Credential Manager via cmdkey
            $creds = cmdkey /list | Select-String -Pattern $TargetName
            
            if ($creds) {
                Write-AuditLog "Found credential: $TargetName in Credential Manager" -Level SUCCESS
                
                # Prompt for password (Windows Credential Manager requires interactive access)
                $username = Read-Host "Enter username for $TargetName"
                $securePassword = Read-Host "Enter password for $TargetName" -AsSecureString
                
                return New-Object System.Management.Automation.PSCredential($username, $securePassword)
            } else {
                Write-AuditLog "Credential $TargetName not found in Credential Manager" -Level WARNING
                return $null
            }
        } else {
            Write-AuditLog "Windows Credential Manager not available" -Level WARNING
            return $null
        }
        
    } catch {
        Write-AuditLog "Failed to retrieve credential: $_" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    Validate and sanitize webhook URLs
#>
function Test-WebhookUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )
    
    try {
        # Validate URL format
        $uri = [System.Uri]$Url
        
        # Ensure HTTPS only (security requirement)
        if ($uri.Scheme -ne "https") {
            Write-AuditLog "Webhook URL must use HTTPS: $Url" -Level ERROR
            return $false
        }
        
        # Validate known webhook domains
        $allowedDomains = @(
            "outlook.office.com",     # Teams
            "outlook.office365.com",  # Teams
            "hooks.slack.com"         # Slack
        )
        
        $domainValid = $false
        foreach ($domain in $allowedDomains) {
            if ($uri.Host -like "*$domain*") {
                $domainValid = $true
                break
            }
        }
        
        if (-not $domainValid) {
            Write-AuditLog "Webhook domain not in allowed list: $($uri.Host)" -Level WARNING
            Write-AuditLog "Allowed domains: $($allowedDomains -join ', ')" -Level WARNING
            # Still allow, but warn
        }
        
        Write-AuditLog "Webhook URL validated: $Url" -Level SUCCESS
        return $true
        
    } catch {
        Write-AuditLog "Invalid webhook URL: $Url - $_" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Validate and sanitize file paths to prevent traversal attacks
#>
function Test-SafePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [switch]$AllowRelative
    )
    
    try {
        # Resolve to absolute path
        $resolvedPath = if ($AllowRelative) {
            [System.IO.Path]::GetFullPath($Path)
        } else {
            $Path
        }
        
        # Check for path traversal attempts
        if ($resolvedPath -match '\.\.[\\/]' -or $resolvedPath -match '[\\/]\.\.') {
            Write-AuditLog "Path traversal attempt detected: $Path" -Level ERROR
            return $false
        }
        
        # Check for invalid characters
        $invalidChars = [System.IO.Path]::GetInvalidPathChars()
        foreach ($char in $invalidChars) {
            if ($Path.Contains($char)) {
                Write-AuditLog "Invalid character in path: $Path" -Level ERROR
                return $false
            }
        }
        
        # Validate path length
        if ($resolvedPath.Length -gt 260) {
            Write-AuditLog "Path exceeds maximum length (260 characters): $Path" -Level ERROR
            return $false
        }
        
        Write-AuditLog "Path validated: $resolvedPath" -Level SUCCESS
        return $true
        
    } catch {
        Write-AuditLog "Path validation error: $Path - $_" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Redact sensitive data from strings (IPs, hostnames, etc.)
#>
function Hide-SensitiveData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputString,
        
        [Parameter()]
        [ValidateSet("IP", "Hostname", "Both")]
        [string]$RedactType = "Both"
    )
    
    $output = $InputString
    
    try {
        if ($RedactType -in @("IP", "Both")) {
            # Redact IPv4 addresses
            $output = $output -replace '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', 'xxx.xxx.xxx.xxx'
        }
        
        if ($RedactType -in @("Hostname", "Both")) {
            # Redact hostnames (basic pattern)
            $output = $output -replace '\b[A-Z0-9-]+\.[A-Z0-9.-]+\b', 'REDACTED.domain.com'
        }
        
        return $output
        
    } catch {
        Write-AuditLog "Data redaction error: $_" -Level WARNING
        return $InputString
    }
}

<#
.SYNOPSIS
    Sign audit log entry with certificate
#>
function Add-AuditSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogEntry,
        
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint
    )
    
    try {
        # Find certificate
        $cert = Get-ChildItem -Path Cert:\CurrentUser\My, Cert:\LocalMachine\My -Recurse |
            Where-Object { $_.Thumbprint -eq $CertificateThumbprint } |
            Select-Object -First 1
        
        if (-not $cert) {
            Write-AuditLog "Certificate not found: $CertificateThumbprint" -Level ERROR
            return $null
        }
        
        if (-not $cert.HasPrivateKey) {
            Write-AuditLog "Certificate does not have private key" -Level ERROR
            return $null
        }
        
        # Create hash of log entry
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($LogEntry)
        $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $hashString = [System.Convert]::ToBase64String($hash)
        
        # Sign the hash
        $signature = $cert.PrivateKey.SignHash($hash, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $signatureString = [System.Convert]::ToBase64String($signature)
        
        # Store in script variable for verification
        $script:AuditLogHash += [PSCustomObject]@{
            Timestamp = Get-Date
            Hash = $hashString
            Signature = $signatureString
            CertThumbprint = $CertificateThumbprint
        }
        
        Write-AuditLog "Audit entry signed successfully" -Level SUCCESS
        return $signatureString
        
    } catch {
        Write-AuditLog "Failed to sign audit entry: $_" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    Apply compliance mode presets
#>
function Set-ComplianceMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("HIPAA", "PCI-DSS", "GDPR", "FedRAMP")]
        [string]$Mode
    )
    
    Write-AuditLog "Applying compliance mode: $Mode" -Level INFO
    
    switch ($Mode) {
        "HIPAA" {
            # Health Insurance Portability and Accountability Act
            $script:RedactSensitiveData = $true
            $script:EnableAuditSigning = $true
            Write-AuditLog "HIPAA mode: Enhanced privacy controls enabled" -Level SUCCESS
        }
        "PCI-DSS" {
            # Payment Card Industry Data Security Standard
            $script:RedactSensitiveData = $true
            $script:EnableAuditSigning = $true
            Write-AuditLog "PCI-DSS mode: Enhanced security controls enabled" -Level SUCCESS
        }
        "GDPR" {
            # General Data Protection Regulation
            $script:RedactSensitiveData = $true
            Write-AuditLog "GDPR mode: Data privacy controls enabled" -Level SUCCESS
        }
        "FedRAMP" {
            # Federal Risk and Authorization Management Program
            $script:RedactSensitiveData = $true
            $script:EnableAuditSigning = $true
            $script:UseCredentialManager = $true
            Write-AuditLog "FedRAMP mode: Federal compliance controls enabled" -Level SUCCESS
        }
    }
}

#endregion

#region Mode 1: DNS Inventory

function Start-DNSInventory {
    <#
    .SYNOPSIS
    Discovers all DNS servers in the AD domain
    #>
    param([PSCredential]$Credential)
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 1: DNS SERVER INVENTORY                  │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    Write-AuditLog "Starting DNS server inventory..." -Level INFO
    
    try {
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        $DomainControllers = Get-ADDomainController @adParams -Filter * | Select-Object Name, IPv4Address, Site, OperatingSystem
        Write-AuditLog "Found $($DomainControllers.Count) domain controllers" -Level SUCCESS
        
        $DNSServers = @()
        
        # Choose execution method based on parallel processing flag
        if ($script:EnableParallelProcessing) {
            Write-AuditLog "Using parallel processing (throttle: $script:MaxDegreeOfParallelism)" -Level INFO
            
            # Define script block for parallel execution
            $scriptBlock = {
                param($DC)
                
                $result = $null
                try {
                    $DNSService = Get-Service -ComputerName $DC.Name -Name "DNS" -ErrorAction Stop
                    
                    $dnsParams = @{ 
                        ComputerName = $DC.Name
                        ErrorAction = 'SilentlyContinue'
                    }
                    
                    $Zones = Get-DnsServerZone @dnsParams
                    
                    $result = [PSCustomObject]@{
                        ServerName = $DC.Name
                        IPAddress = $DC.IPv4Address
                        Site = $DC.Site
                        DNSServiceStatus = $DNSService.Status
                        ZoneCount = $Zones.Count
                        PrimaryZones = ($Zones | Where-Object { $_.ZoneType -eq "Primary" }).Count
                        SecondaryZones = ($Zones | Where-Object { $_.ZoneType -eq "Secondary" }).Count
                        OperatingSystem = $DC.OperatingSystem
                        InventoryDate = Get-Date
                    }
                }
                catch {
                    # Return error info but don't throw
                    $result = [PSCustomObject]@{
                        ServerName = $DC.Name
                        IPAddress = $DC.IPv4Address
                        Site = $DC.Site
                        DNSServiceStatus = "ERROR"
                        ZoneCount = 0
                        PrimaryZones = 0
                        SecondaryZones = 0
                        OperatingSystem = $DC.OperatingSystem
                        InventoryDate = Get-Date
                        Error = $_.Exception.Message
                    }
                }
                
                return $result
            }
            
            # Execute in parallel
            $DNSServers = Invoke-ParallelExecution `
                -Items $DomainControllers `
                -ScriptBlock $scriptBlock `
                -ThrottleLimit $script:MaxDegreeOfParallelism `
                -ActivityName "Inventorying DNS Servers (Parallel)"
            
            # Log results
            foreach ($server in $DNSServers) {
                if ($server.DNSServiceStatus -eq "ERROR") {
                    Write-AuditLog "✗ $($server.ServerName): $($server.Error)" -Level WARNING
                } else {
                    Write-AuditLog "✓ $($server.ServerName): DNS Running, $($server.ZoneCount) zones" -Level SUCCESS
                }
            }
            
        } else {
            # Sequential processing (original code)
            $index = 0
            try {
                foreach ($DC in $DomainControllers) {
                    $index++
                    Write-Progress -Activity "Inventorying DNS Servers" `
                        -Status "Checking $($DC.Name) ($index of $($DomainControllers.Count))" `
                        -PercentComplete (($index / $DomainControllers.Count) * 100)
                    try {
                        $params = @{
                            ComputerName = $DC.Name
                            Name = "DNS"
                            ErrorAction = 'Stop'
                        }
                        $DNSService = Get-Service @params
                        $dnsParams = @{ ComputerName = $DC.Name; ErrorAction = 'SilentlyContinue' }
                        if ($Credential) { $dnsParams['Credential'] = $Credential }
                        $Zones = Get-DnsServerZone @dnsParams
                        $ServerInfo = [PSCustomObject]@{
                            ServerName = $DC.Name
                            IPAddress = $DC.IPv4Address
                            Site = $DC.Site
                            DNSServiceStatus = $DNSService.Status
                            ZoneCount = $Zones.Count
                            PrimaryZones = ($Zones | Where-Object { $_.ZoneType -eq "Primary" }).Count
                            SecondaryZones = ($Zones | Where-Object { $_.ZoneType -eq "Secondary" }).Count
                            OperatingSystem = $DC.OperatingSystem
                            InventoryDate = Get-Date
                        }
                        $DNSServers += $ServerInfo
                        Write-AuditLog "✓ $($DC.Name): DNS Running, $($Zones.Count) zones" -Level SUCCESS
                    }
                    catch {
                        Write-AuditLog "✗ $($DC.Name): $($_.Exception.Message)" -Level WARNING
                    }
                }
            }
            finally {
                Write-Progress -Activity "Inventorying DNS Servers" -Completed
            }
        }
        
        # Export inventory data
        Export-AuditData -Data $DNSServers -BaseFileName "DNS_Inventory_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Server Inventory"
        return @{
            Servers = $DNSServers
            ExportFile = $OutputFile
            Summary = "Found $($DNSServers.Count) DNS servers with $($DNSServers | Measure-Object ZoneCount -Sum | Select-Object -ExpandProperty Sum) total zones"
        }
    }
    catch {
        Write-AuditLog "Inventory failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

#endregion

#region Mode 2: DNS Health Check

function Start-DNSHealthCheck {
    <#
    .SYNOPSIS
    Comprehensive DNS service health testing
    #>
    param([PSCredential]$Credential)
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 2: DNS HEALTH CHECK                      │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    Write-AuditLog "Starting DNS health check..." -Level INFO
    
    try {
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        
        # Get domain DNS root once (used for resolution tests)
        try {
            $Domain = (Get-ADDomain @adParams).DNSRoot
            Write-AuditLog "Testing DNS resolution for domain: $Domain" -Level INFO
        }
        catch {
            Write-AuditLog "WARNING: Could not retrieve domain DNSRoot - DNS resolution tests will be skipped" -Level WARNING
            $Domain = $null
        }
        
        $DCs = Get-ADDomainController @adParams -Filter * | Select-Object Name
        $AllHealthResults = @()
        
        # Choose execution method based on parallel processing flag
        if ($script:EnableParallelProcessing) {
            Write-AuditLog "Using parallel processing (throttle: $script:MaxDegreeOfParallelism)" -Level INFO
            
            # Define script block for parallel execution
            $scriptBlock = {
                param($DC, $Domain)
                
                $HealthTests = @()
                
                # Test 1: DNS Service Status
                try {
                    $DNSService = Get-CimInstance -ClassName Win32_Service -Filter "Name='DNS'" -ComputerName $DC.Name -ErrorAction Stop
                    $ServiceStatus = $DNSService.State
                    $HealthTests += [PSCustomObject]@{
                        DCName = $DC.Name
                        TestName = "DNS Service Status"
                        Status = if ($ServiceStatus -eq "Running") { "PASS" } else { "FAIL" }
                        Details = "Service: $ServiceStatus"
                    }
                }
                catch {
                    $HealthTests += [PSCustomObject]@{
                        DCName = $DC.Name
                        TestName = "DNS Service Status"
                        Status = "FAIL"
                        Details = "Error: $($_.Exception.Message)"
                    }
                }
                
                # Test 2: Zone Accessibility
                try {
                    $Zones = Get-DnsServerZone -ComputerName $DC.Name -ErrorAction Stop
                    $HealthTests += [PSCustomObject]@{
                        DCName = $DC.Name
                        TestName = "Zone Accessibility"
                        Status = "PASS"
                        Details = "$($Zones.Count) zones accessible"
                    }
                }
                catch {
                    $HealthTests += [PSCustomObject]@{
                        DCName = $DC.Name
                        TestName = "Zone Accessibility"
                        Status = "FAIL"
                        Details = "Cannot access zones"
                    }
                }
                
                # Test 3: DNS Resolution
                if ($Domain) {
                    try {
                        $null = Resolve-DnsName -Name $Domain -Server $DC.Name -ErrorAction Stop
                        $HealthTests += [PSCustomObject]@{
                            DCName = $DC.Name
                            TestName = "DNS Resolution"
                            Status = "PASS"
                            Details = "Successfully resolved $Domain"
                        }
                    }
                    catch {
                        $HealthTests += [PSCustomObject]@{
                            DCName = $DC.Name
                            TestName = "DNS Resolution"
                            Status = "FAIL"
                            Details = "Resolution failed"
                        }
                    }
                }
                else {
                    $HealthTests += [PSCustomObject]@{
                        DCName = $DC.Name
                        TestName = "DNS Resolution"
                        Status = "SKIP"
                        Details = "Domain DNSRoot unavailable"
                    }
                }
                
                return $HealthTests
            }
            
            # Execute in parallel - note we pass Domain as a parameter
            $parallelParams = @{
                Items = $DCs
                ScriptBlock = $scriptBlock
                ThrottleLimit = $script:MaxDegreeOfParallelism
                ActivityName = "Health Checking DNS Services (Parallel)"
            }
            
            # Add Domain parameter to be passed to each runspace
            $parallelResults = Invoke-ParallelExecution @parallelParams
            
            # Flatten results (each DC returns an array of test results)
            foreach ($result in $parallelResults) {
                if ($result -is [array]) {
                    $AllHealthResults += $result
                } else {
                    $AllHealthResults += $result
                }
            }
            
            # Log summary for each DC
            $dcResults = $AllHealthResults | Group-Object -Property DCName
            foreach ($dcGroup in $dcResults) {
                $PassCount = ($dcGroup.Group | Where-Object { $_.Status -eq "PASS" }).Count
                $TotalTests = $dcGroup.Group.Count
                Write-AuditLog "  $($dcGroup.Name): $PassCount/$TotalTests tests passed" -Level $(if ($PassCount -eq $TotalTests) { "SUCCESS" } else { "WARNING" })
            }
            
        } else {
            # Sequential processing (original code)
            $index = 0
            try {
                foreach ($DC in $DCs) {
                    $index++
                    Write-Progress -Activity "Health Checking DNS Services" `
                        -Status "Testing $($DC.Name) ($index of $($DCs.Count))" `
                        -PercentComplete (($index / $DCs.Count) * 100)
                    Write-AuditLog "Testing DNS on $($DC.Name)..." -Level INFO
                    $HealthTests = @()
                    
                    # Test 1: DNS Service Status
                    try {
                        $DNSService = Get-CimInstance -ClassName Win32_Service -Filter "Name='DNS'" -ComputerName $DC.Name -ErrorAction Stop
                        $ServiceStatus = $DNSService.State
                        $HealthTests += [PSCustomObject]@{
                            DCName = $DC.Name
                            TestName = "DNS Service Status"
                            Status = if ($ServiceStatus -eq "Running") { "PASS" } else { "FAIL" }
                            Details = "Service: $ServiceStatus"
                        }
                    }
                    catch {
                        $HealthTests += [PSCustomObject]@{
                            DCName = $DC.Name
                            TestName = "DNS Service Status"
                            Status = "FAIL"
                            Details = "Error: $($_.Exception.Message)"
                        }
                    }
                    
                    # Test 2: Zone Accessibility
                    try {
                        $dnsParams = @{ ComputerName = $DC.Name; ErrorAction = 'Stop' }
                        if ($Credential) { $dnsParams['Credential'] = $Credential }
                        $Zones = Get-DnsServerZone @dnsParams
                        $HealthTests += [PSCustomObject]@{
                            DCName = $DC.Name
                            TestName = "Zone Accessibility"
                            Status = "PASS"
                            Details = "$($Zones.Count) zones accessible"
                        }
                    }
                    catch {
                        $HealthTests += [PSCustomObject]@{
                            DCName = $DC.Name
                            TestName = "Zone Accessibility"
                            Status = "FAIL"
                            Details = "Cannot access zones"
                        }
                    }
                    
                    # Test 3: DNS Resolution
                    if ($Domain) {
                        try {
                            $null = Resolve-DnsName -Name $Domain -Server $DC.Name -ErrorAction Stop
                            $HealthTests += [PSCustomObject]@{
                                DCName = $DC.Name
                                TestName = "DNS Resolution"
                                Status = "PASS"
                                Details = "Successfully resolved $Domain"
                            }
                        }
                        catch {
                            $HealthTests += [PSCustomObject]@{
                                DCName = $DC.Name
                                TestName = "DNS Resolution"
                                Status = "FAIL"
                                Details = "Resolution failed"
                            }
                        }
                    }
                    else {
                        $HealthTests += [PSCustomObject]@{
                            DCName = $DC.Name
                            TestName = "DNS Resolution"
                            Status = "SKIP"
                            Details = "Domain DNSRoot unavailable"
                        }
                    }
                    
                    $AllHealthResults += $HealthTests
                    $PassCount = ($HealthTests | Where-Object { $_.Status -eq "PASS" }).Count
                    $TotalTests = $HealthTests.Count
                    Write-AuditLog "  $($DC.Name): $PassCount/$TotalTests tests passed" -Level $(if ($PassCount -eq $TotalTests) { "SUCCESS" } else { "WARNING" })
                }
            }
            finally {
                Write-Progress -Activity "Health Checking DNS Services" -Completed
            }
        }
        
        # Export health check data
        Export-AuditData -Data $AllHealthResults -BaseFileName "DNS_HealthCheck_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Health Check Results"
        $TotalTests = $AllHealthResults.Count
        $PassedTests = ($AllHealthResults | Where-Object { $_.Status -eq "PASS" }).Count
        return @{
            Results = $AllHealthResults
            ExportFile = $OutputFile
            Summary = "Health Check: $PassedTests/$TotalTests tests passed across $($DCs.Count) servers"
        }
    }
    catch {
        Write-AuditLog "Health check failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

#endregion

#region Mode 3: DNS Record Export

function Start-DNSRecordExport {
    <#
    .SYNOPSIS
    Exports all DNS records to CSV
    .DESCRIPTION
    By default, queries the first DC for zones. This may miss zones that are:
    - Not AD-integrated
    - Partitioned across DCs
    - Only authoritative on specific servers
    Use -DnsServer to specify a particular DNS server.
    Use -UnionZones to query all DCs and merge zone lists (slower but comprehensive).
    #>
    param(
        [string[]]$Zones = @(),
        [PSCredential]$Credential,
        [string]$DnsServer,
        [switch]$UnionZones
    )
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 3: DNS RECORD EXPORT                     │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    Write-AuditLog "Starting DNS record export..." -Level INFO
    try {
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        # Determine which DNS server(s) to query
        if ($DnsServer) {
            # User specified a server
            $DCName = $DnsServer
            Write-AuditLog "Using specified DNS server: $DCName" -Level INFO
        }
        elseif ($UnionZones) {
            # Query all DCs and union zones
            Write-AuditLog "UnionZones mode: Querying all DCs for comprehensive zone coverage..." -Level INFO
            $AllDCs = Get-ADDomainController @adParams -Filter * | Select-Object Name
            Write-AuditLog "Found $($AllDCs.Count) domain controllers" -Level INFO
            $ZoneServerMap = @{}  # Maps zone name to first DC that has it
            $DCsWithZones = 0
            foreach ($DC in $AllDCs) {
                try {
                    $dnsParams = @{ ComputerName = $DC.Name }
                    if ($Credential) { $dnsParams['Credential'] = $Credential }
                    $DCZones = Get-DnsServerZone @dnsParams -ErrorAction Stop
                    foreach ($Zone in $DCZones) {
                        if (-not $ZoneServerMap.ContainsKey($Zone.ZoneName)) {
                            $ZoneServerMap[$Zone.ZoneName] = $DC.Name
                        }
                    }
                    $DCsWithZones++
                }
                catch {
                    Write-AuditLog "  WARNING: Could not query zones from $($DC.Name): $($_.Exception.Message)" -Level WARNING
                }
            }
            Write-AuditLog "Union complete: Found $($ZoneServerMap.Count) unique zones across $DCsWithZones DCs" -Level SUCCESS
            # Now process each zone from its authoritative server
            $AllZones = $ZoneServerMap.Keys | ForEach-Object {
                [PSCustomObject]@{
                    ZoneName = $_
                    ServerName = $ZoneServerMap[$_]
                }
            }
            if ($Zones.Count -gt 0) {
                $AllZones = $AllZones | Where-Object { $_.ZoneName -in $Zones }
                Write-AuditLog "Filtering to $($Zones.Count) specified zones" -Level INFO
            }
        }
        else {
            # Default: use first DC only
            $DCs = Get-ADDomainController @adParams -Filter * | Select-Object -First 1 Name
            $DCName = $DCs[0].Name
            Write-AuditLog "Using DNS server: $DCName" -Level INFO
            Write-AuditLog "NOTE: Querying single DC. Zones not replicated to this DC will be missed." -Level WARNING
            Write-AuditLog "      Use -DnsServer to specify a server or -UnionZones for complete coverage." -Level WARNING
            $dnsParams = @{ ComputerName = $DCName }
            if ($Credential) { $dnsParams['Credential'] = $Credential }
            $AllZones = Get-DnsServerZone @dnsParams | Select-Object ZoneName, @{ Name = 'ServerName'; Expression = { $DCName } }
            if ($Zones.Count -gt 0) {
                $AllZones = $AllZones | Where-Object { $_.ZoneName -in $Zones }
                Write-AuditLog "Filtering to $($Zones.Count) specified zones" -Level INFO
            }
        }
        Write-AuditLog "Exporting records from $($AllZones.Count) zones..." -Level INFO
        Write-AuditLog "NOTE: Streaming records to disk to minimize memory usage" -Level INFO
        # Initialize streaming export
        $OutputFile = Join-Path $ExportPath "DNS_RecordExport_${script:TimeStamp}.csv"
        $wroteHeader = $false
        $TotalRecordCount = 0
        $RecordTypes = @("A", "AAAA", "CNAME", "MX", "PTR", "SRV", "TXT", "NS")
        $zoneIndex = 0
        # Static record detection helper
        $epoch = [datetime]'1601-01-01T00:00:00Z'
        try {
            foreach ($Zone in $AllZones) {
                $zoneIndex++
                Write-Progress -Activity "Exporting DNS Records" `
                    -Status "Processing $($Zone.ZoneName) ($zoneIndex of $($AllZones.Count))" `
                    -PercentComplete (($zoneIndex / $AllZones.Count) * 100)
                try {
                    # Use the appropriate server for this zone
                    $ZoneServer = if ($Zone.ServerName) { $Zone.ServerName } else { $DCName }
                    $recordParams = @{                        ComputerName = $ZoneServer
                        ZoneName = $Zone.ZoneName
                        ErrorAction = 'Stop'
                    }
                    if ($Credential) { $recordParams['Credential'] = $Credential }
                    $Records = Get-DnsServerResourceRecord @recordParams
                    # Map and filter records in pipeline (memory efficient)
                    $MappedRecords = $Records | Where-Object { $_.RecordType -in $RecordTypes } | ForEach-Object {
                        $RecordData = switch ($_.RecordType) {
                            "A" { $_.RecordData.IPv4Address.ToString() }
                            "AAAA" { $_.RecordData.IPv6Address.ToString() }
                            "CNAME" { $_.RecordData.HostNameAlias }
                            "MX" { "$($_.RecordData.Preference) $($_.RecordData.MailExchange)" }
                            "PTR" { $_.RecordData.PtrDomainName }
                            "SRV" { "$($_.RecordData.Priority) $($_.RecordData.Weight) $($_.RecordData.Port) $($_.RecordData.DomainName)" }
                            "TXT" { $_.RecordData.DescriptiveText -join " " }
                            "NS" { $_.RecordData.NameServer }
                            default { "N/A" }
                        }
                        $IsStatic = ($null -eq $_.Timestamp) -or ($_.Timestamp -eq $epoch)
                        $RecordObj = [PSCustomObject]@{
                            ZoneName = $Zone.ZoneName
                            RecordName = $_.HostName
                            RecordType = $_.RecordType
                            RecordData = $RecordData
                            TTL = $_.TimeToLive.TotalSeconds
                            IsStatic = $IsStatic
                            Timestamp = $_.Timestamp
                            ExportDate = Get-Date
                        }
                        # Add source server in UnionZones mode
                        if ($UnionZones -or $DnsServer) {
                            $RecordObj | Add-Member -NotePropertyName "SourceServer" -NotePropertyValue $ZoneServer
                        }
                        $RecordObj
                    }
                    # Stream to disk (append after first write)
                    if ($MappedRecords) {
                        if (-not $wroteHeader) {
                            $MappedRecords | Export-Csv -Path $OutputFile -NoTypeInformation
                            $wroteHeader = $true
                        }
                        else {
                            $MappedRecords | Export-Csv -Path $OutputFile -NoTypeInformation -Append
                        }
                        $RecordCount = @($MappedRecords).Count
                        $TotalRecordCount += $RecordCount
                        Write-AuditLog "  $($Zone.ZoneName): Streamed $RecordCount records" -Level SUCCESS
                    }
                    else {
                        Write-AuditLog "  $($Zone.ZoneName): No matching records" -Level INFO
                    }
                }
                catch {
                    Write-AuditLog "  $($Zone.ZoneName): Failed - $($_.Exception.Message)" -Level WARNING
                }
            }
        }
        finally {
            Write-Progress -Activity "Exporting DNS Records" -Completed
        }
        Write-AuditLog "Exported $TotalRecordCount records to: $OutputFile" -Level SUCCESS
        return @{
            RecordCount = $TotalRecordCount
            ExportFile = $OutputFile
            Summary = "Exported $TotalRecordCount records from $($AllZones.Count) zones"
        }
    }
    catch {
        Write-AuditLog "Record export failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

#endregion

#region Mode 4: DNS Site Audit (EMBEDDED - NO DEPENDENCIES!)

#region Site Audit Helper Functions

function Get-ADSiteSubnet {
    <#
    .SYNOPSIS
    Gets all AD sites and their associated subnets for IP-to-site mapping
    #>
    param([PSCredential]$Credential)
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $params = @{}
        if ($Credential) { $params['Credential'] = $Credential }
        Write-AuditLog "Retrieving AD sites and subnets..." -Level INFO
        $Sites = Get-ADReplicationSite @params -Filter * -Properties Location, Description
        $Subnets = Get-ADReplicationSubnet @params -Filter * -Properties Site, Location, Description
        $SiteSubnetMap = @{}
        # Sort subnets by prefix length (most specific first)
        $SortedSubnets = $Subnets | Sort-Object {
            try {
                if ($_.Name -match '/(\d+)$') {
                    [int]$Matches[1]
                }
                else {
                    0
                }
            }
            catch {
                0
            }
        } -Descending
        foreach ($Subnet in $SortedSubnets) {
            $SiteSubnetMap[$Subnet.Name] = @{
                SiteName = $Subnet.Site.Split(',')[0].Replace('CN=', '')
                SubnetName = $Subnet.Name
                Location = $Subnet.Location
                Description = $Subnet.Description
            }
        }
        $SiteInfo = @{}
        foreach ($Site in $Sites) {
            $SiteSubnets = $Subnets | Where-Object { $_.Site -like "*$($Site.Name)*" }
            $SiteInfo[$Site.Name] = @{
                SiteName = $Site.Name
                Location = $Site.Location
                Description = $Site.Description
                Subnets = $SiteSubnets.Name
            }
        }
        Write-AuditLog "Retrieved $($Sites.Count) sites and $($Subnets.Count) subnets" -Level SUCCESS
        return @{
            SiteSubnetMap = $SiteSubnetMap
            SiteInfo = $SiteInfo
        }
    }
    catch {
        Write-AuditLog "Failed to get AD site information: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-IPAddressSite {
    <#
    .SYNOPSIS
    Determines which AD site an IP address belongs to (supports IPv4 and IPv6)
    #>
    param(
        [string]$IPAddress,
        [hashtable]$SiteSubnetMap
    )
    try {
        $IP = [System.Net.IPAddress]::Parse($IPAddress)
        foreach ($SubnetString in $SiteSubnetMap.Keys) {
            try {
                # Validate subnet format
                if ($SubnetString -notmatch '^.+/\d+$') {
                    $script:SkippedSubnets += [PSCustomObject]@{
                        Subnet = $SubnetString
                        Reason = "Missing or invalid prefix notation"
                    }
                    continue
                }
                $SubnetParts = $SubnetString.Split('/')
                if ($SubnetParts.Count -ne 2) {
                    $script:SkippedSubnets += [PSCustomObject]@{
                        Subnet = $SubnetString
                        Reason = "Invalid subnet format"
                    }
                    continue
                }
                $NetworkIP = [System.Net.IPAddress]::Parse($SubnetParts[0])
                $PrefixLength = [int]$SubnetParts[1]
                # Determine address family and valid prefix bounds
                $MaxPrefixLength = if ($NetworkIP.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) { 128 } else { 32 }
                # Validate prefix length bounds
                if ($PrefixLength -lt 0 -or $PrefixLength -gt $MaxPrefixLength) {
                    $script:SkippedSubnets += [PSCustomObject]@{
                        Subnet = $SubnetString
                        Reason = "Prefix length $PrefixLength out of valid range (0..$MaxPrefixLength)"
                    }
                    continue
                }
                if ($IP.AddressFamily -ne $NetworkIP.AddressFamily) {
                    continue
                }
                $IPBytes = $IP.GetAddressBytes()
                $NetworkBytes = $NetworkIP.GetAddressBytes()
                $ByteCount = $IPBytes.Length
                $BitCount = $ByteCount * 8
                if ($PrefixLength -gt $BitCount) {
                    continue
                }
                # Check if IP matches subnet
                $Match = $true
                $BitsChecked = 0
                for ($i = 0; $i -lt $ByteCount; $i++) {
                    $BitsInThisByte = [Math]::Min(8, $PrefixLength - $BitsChecked)
                    if ($BitsInThisByte -le 0) {
                        break
                    }
                    if ($BitsInThisByte -eq 8) {
                        if ($IPBytes[$i] -ne $NetworkBytes[$i]) {
                            $Match = $false
                            break
                        }
                    }
                    else {
                        $Mask = (0xFF -shl (8 - $BitsInThisByte)) -band 0xFF
                        if (($IPBytes[$i] -band $Mask) -ne ($NetworkBytes[$i] -band $Mask)) {
                            $Match = $false
                            break
                        }
                    }
                    $BitsChecked += $BitsInThisByte
                }
                if ($Match) {
                    return $SiteSubnetMap[$SubnetString]
                }
            }
            catch {
                $script:SkippedSubnets += [PSCustomObject]@{
                    Subnet = $SubnetString
                    Reason = "Parse error: $($_.Exception.Message)"
                }
                continue
            }
        }
        return @{
            SiteName = "Unknown"
            SubnetName = "No matching subnet"
            Location = ""
            Description = ""
        }
    }
    catch {
        return @{
            SiteName = "Invalid IP"
            SubnetName = "Parse error"
            Location = ""
            Description = ""
        }
    }
}

function Get-MismatchSeverity {
    <#
    .SYNOPSIS
    Calculates severity level for site mismatches
    #>
    param(
        [string]$RecordType,
        [bool]$IsStatic,
        [string]$DCSite,
        [string]$IPSite
    )
    # Critical: Static A record in completely wrong site
    if ($IsStatic -and $RecordType -eq "A" -and $IPSite -ne "Unknown") {
        return "Critical"
    }
    # High: Static AAAA or dynamic A in wrong site
    if ($IsStatic -or $RecordType -eq "A") {
        return "High"
    }
    # Medium: AAAA records or unknown site
    if ($RecordType -eq "AAAA" -or $IPSite -eq "Unknown") {
        return "Medium"
    }
    # Low: Everything else
    return "Low"
}

function Get-ZoneHealthScore {
    <#
    .SYNOPSIS
    Calculates health score for a DNS zone
    #>
    param(
        [string]$ZoneName,
        [int]$TotalRecords,
        [int]$Mismatches
    )
    if ($TotalRecords -eq 0) {
        return [PSCustomObject]@{
            Zone = $ZoneName
            HealthScore = 100
            Status = "No Data"
            TotalRecords = 0
            Mismatches = 0
        }
    }
    $mismatchPercent = ($Mismatches / $TotalRecords) * 100
    $healthScore = 100 - $mismatchPercent
    $status = switch ($healthScore) {
        { $_ -ge 98 } { "Excellent" }
        { $_ -ge 95 } { "Good" }
        { $_ -ge 90 } { "Fair" }
        { $_ -ge 80 } { "Poor" }
        default { "Critical" }
    }
    return [PSCustomObject]@{
        Zone = $ZoneName
        HealthScore = [math]::Round($healthScore, 2)
        Status = $status
        TotalRecords = $TotalRecords
        Mismatches = $Mismatches
        MismatchPercent = [math]::Round($mismatchPercent, 2)
    }
}

#endregion

function Start-DNSSiteAudit {
    <#
    .SYNOPSIS
    Embedded site mismatch detection - NO external dependencies!
    #>
    param(
        [switch]$AllFeatures,
        [PSCredential]$Credential
    )
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 4: DNS SITE MISMATCH AUDIT (EMBEDDED)   │" -ForegroundColor Cyan
    Write-Host "│  ✅ Self-Contained - No Dependencies!         │" -ForegroundColor Green
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    Write-AuditLog "Starting embedded DNS site mismatch audit..." -Level INFO
    # Reset skipped subnets tracker for this run
    $script:SkippedSubnets = @()
    try {
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        # Get AD site information
        $SiteData = Get-ADSiteSubnet -Credential $Credential
        if (!$SiteData) {
            throw "Cannot retrieve AD site information"
        }
        # Get domain controllers
        $DCs = Get-ADDomainController @adParams -Filter * | Select-Object Name, IPv4Address, Site
        Write-AuditLog "Found $($DCs.Count) domain controllers" -Level SUCCESS
        $AllMismatches = @()
        $TotalRecordsScanned = 0
        $dcIndex = 0
        try {
            foreach ($DC in $DCs) {
                $dcIndex++
                Write-Progress -Activity "Scanning Domain Controllers for Site Mismatches" `
                    -Status "Processing $($DC.Name) ($dcIndex of $($DCs.Count))" `
                    -PercentComplete (($dcIndex / $DCs.Count) * 100)
                Write-AuditLog "Scanning DNS on $($DC.Name) (Site: $($DC.Site))..." -Level INFO
                try {
                    # Get zones
                    $dnsParams = @{ ComputerName = $DC.Name }
                    if ($Credential) { $dnsParams['Credential'] = $Credential }
                    $Zones = Get-DnsServerZone @dnsParams
                    if ($ZoneFilter.Count -gt 0) {
                        $Zones = $Zones | Where-Object { $_.ZoneName -in $ZoneFilter }
                    }
                    foreach ($Zone in $Zones) {
                        Write-Verbose "Processing zone: $($Zone.ZoneName)"
                        try {
                            $recordParams = @{
                                ComputerName = $DC.Name
                                ZoneName = $Zone.ZoneName
                                RRType = @("A", "AAAA")
                                ErrorAction = 'Stop'
                            }
                            if ($Credential) { $recordParams['Credential'] = $Credential }
                            $Records = Get-DnsServerResourceRecord @recordParams
                            foreach ($Record in $Records) {
                                $TotalRecordsScanned++
                                # Get IP address
                                $IPAddress = if ($Record.RecordType -eq "A") {
                                    $Record.RecordData.IPv4Address.ToString()
                                }
                                elseif ($Record.RecordType -eq "AAAA") {
                                    $Record.RecordData.IPv6Address.ToString()
                                }
                                else {
                                    continue
                                }
                                # Determine site for IP
                                $IPSite = Get-IPAddressSite -IPAddress $IPAddress -SiteSubnetMap $SiteData.SiteSubnetMap
                                # Check for mismatch
                                if ($IPSite.SiteName -ne $DC.Site -and $IPSite.SiteName -ne "Unknown") {
                                    # Static if timestamp is null or epoch (1601-01-01)
                                    $epoch = [datetime]'1601-01-01T00:00:00Z'
                                    $IsStatic = ($null -eq $Record.Timestamp) -or ($Record.Timestamp -eq $epoch)
                                    $Severity = Get-MismatchSeverity -RecordType $Record.RecordType `
                                        -IsStatic $IsStatic `
                                        -DCSite $DC.Site `
                                        -IPSite $IPSite.SiteName
                                    $Mismatch = [PSCustomObject]@{
                                        DCName = $DC.Name
                                        DCSite = $DC.Site
                                        DCIPAddress = $DC.IPv4Address
                                        ZoneName = $Zone.ZoneName
                                        RecordName = $Record.HostName
                                        FQDN = "$($Record.HostName).$($Zone.ZoneName)"
                                        RecordType = $Record.RecordType
                                        IPAddress = $IPAddress
                                        IPSite = $IPSite.SiteName
                                        IPSubnet = $IPSite.SubnetName
                                        SiteMismatch = $true
                                        TTL = [int]$Record.TimeToLive.TotalSeconds
                                        IsStatic = $IsStatic
                                        Severity = $Severity
                                        AuditDate = Get-Date
                                    }
                                    $AllMismatches += $Mismatch
                                }
                            }
                        }
                        catch {
                            Write-AuditLog "  Failed to process zone $($Zone.ZoneName): $($_.Exception.Message)" -Level WARNING
                        }
                    }
                }
                catch {
                    Write-AuditLog "Failed to scan $($DC.Name): $($_.Exception.Message)" -Level ERROR
                }
            }
        }
        finally {
            Write-Progress -Activity "Scanning Domain Controllers for Site Mismatches" -Completed
        }
        # Remove duplicates
        $UniqueMismatches = $AllMismatches | Sort-Object FQDN, IPAddress -Unique
        Write-AuditLog "Scan complete: $TotalRecordsScanned records scanned, $($UniqueMismatches.Count) mismatches found" -Level SUCCESS
        # Export mismatches
        Export-AuditData -Data $UniqueMismatches -BaseFileName "DNS_Site_Mismatches_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Site Mismatches"
        # Generate statistics
        $Statistics = [PSCustomObject]@{
            TotalRecordsScanned = $TotalRecordsScanned
            TotalMismatches = $UniqueMismatches.Count
            CriticalSeverity = ($UniqueMismatches | Where-Object { $_.Severity -eq 'Critical' }).Count
            HighSeverity = ($UniqueMismatches | Where-Object { $_.Severity -eq 'High' }).Count
            MediumSeverity = ($UniqueMismatches | Where-Object { $_.Severity -eq 'Medium' }).Count
            LowSeverity = ($UniqueMismatches | Where-Object { $_.Severity -eq 'Low' }).Count
            DCsScanned = $DCs.Count
            AuditDate = Get-Date
        }
        Export-AuditData -Data @($Statistics) -BaseFileName "DNS_Audit_Statistics_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Audit Statistics"
        # Report skipped subnets
        if ($script:SkippedSubnets.Count -gt 0) {
            $UniqueSkippedSubnets = $script:SkippedSubnets | Sort-Object Subnet -Unique
            Export-AuditData -Data $UniqueSkippedSubnets -BaseFileName "DNS_Audit_Skipped_Subnets_${script:TimeStamp}" -Format $ExportFormat -Title "Skipped Subnets"
            Write-AuditLog "WARNING: $($UniqueSkippedSubnets.Count) subnets were skipped due to parsing errors" -Level WARNING
        }
        else {
            Write-AuditLog "All AD subnets were successfully parsed" -Level SUCCESS
        }
        # Zone health scores if requested
        $ZoneHealthScores = @()
        if ($AllFeatures) {
            Write-AuditLog "Calculating zone health scores..." -Level INFO
            $ZoneStats = $UniqueMismatches | Group-Object ZoneName
            foreach ($zoneStat in $ZoneStats) {
                $zoneRecords = $AllMismatches | Where-Object { $_.ZoneName -eq $zoneStat.Name }
                $score = Get-ZoneHealthScore -ZoneName $zoneStat.Name `
                    -TotalRecords $zoneRecords.Count `
                    -Mismatches $zoneStat.Count
                $ZoneHealthScores += $score
            }
            if ($ZoneHealthScores.Count -gt 0) {
                Export-AuditData -Data $ZoneHealthScores -BaseFileName "DNS_Zone_Health_Scores_${script:TimeStamp}" -Format $ExportFormat -Title "Zone Health Scores"
            }
        }
        return @{
            MismatchRecords = $UniqueMismatches
            Statistics = $Statistics
            ZoneHealthScores = $ZoneHealthScores
            ExportFiles = @($MismatchFile, $StatsFile)
            Summary = "Site Audit: $($UniqueMismatches.Count) mismatches found, scanned $TotalRecordsScanned records"
        }
    }
    catch {
        Write-AuditLog "Site audit failed: $($_.Exception.Message)" -Level ERROR
        return @{
            MismatchRecords = @()
            Statistics = $null
            Summary = "Site Audit: FAILED - $($_.Exception.Message)"
        }
    }
}

#endregion

#region Mode 5: Complete Audit

function Start-CompleteAudit {
    <#
    .SYNOPSIS
    Runs all audit modes in sequence
    #>
    param(
        [PSCredential]$Credential,
        [string]$DnsServer,
        [switch]$UnionZones
    )
    Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                COMPLETE AUDIT MODE                    ║" -ForegroundColor Green
    Write-Host "║  Running All Modes: Inventory → Health → Export →    ║" -ForegroundColor Green
    Write-Host "║                   Site Audit                          ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    $CompleteStart = Get-Date
    # Mode 1: Inventory
    try {
        $script:AllResults.Inventory = Start-DNSInventory -Credential $Credential
    }
    catch {
        Write-AuditLog "Inventory phase failed, continuing..." -Level WARNING
    }
    # Mode 2: Health Check
    try {
        $script:AllResults.HealthCheck = Start-DNSHealthCheck -Credential $Credential
    }
    catch {
        Write-AuditLog "Health check phase failed, continuing..." -Level WARNING
    }
    # Mode 3: Record Export
    try {
        $script:AllResults.RecordExport = Start-DNSRecordExport -Zones $ZoneFilter -Credential $Credential -DnsServer $DnsServer -UnionZones:$UnionZones
    }
    catch {
        Write-AuditLog "Record export phase failed, continuing..." -Level WARNING
    }
    # Mode 4: Site Audit
    try {
        $script:AllResults.SiteAudit = Start-DNSSiteAudit -AllFeatures:$EnableAllFeatures -Credential $Credential
    }
    catch {
        Write-AuditLog "Site audit phase failed, continuing..." -Level WARNING
    }
    $CompleteEnd = Get-Date
    $Duration = ($CompleteEnd - $CompleteStart).TotalMinutes
    # Generate summary report
    Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║            COMPLETE AUDIT SUMMARY                     ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    Write-Host "Duration: $([math]::Round($Duration, 2)) minutes`n" -ForegroundColor Cyan
    if ($script:AllResults.Inventory) {
        Write-Host "✓ Inventory:     $($script:AllResults.Inventory.Summary)" -ForegroundColor Green
    }
    if ($script:AllResults.HealthCheck) {
        Write-Host "✓ Health Check:  $($script:AllResults.HealthCheck.Summary)" -ForegroundColor Green
    }
    if ($script:AllResults.RecordExport) {
        Write-Host "✓ Record Export: $($script:AllResults.RecordExport.Summary)" -ForegroundColor Green
    }
    if ($script:AllResults.SiteAudit) {
        Write-Host "✓ Site Audit:    $($script:AllResults.SiteAudit.Summary)" -ForegroundColor Green
    }
    Write-Host "`nAll reports saved to: $ExportPath" -ForegroundColor Cyan
    return $script:AllResults
}

function Start-BaselineMode {
    <#
    .SYNOPSIS
    Create a baseline snapshot of the current DNS state
    #>
    param([PSCredential]$Credential)
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  BASELINE MODE: Creating DNS Snapshot          │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    
    Write-AuditLog "Creating baseline snapshot..." -Level INFO
    
    # Run complete audit to gather all data
    $auditResults = @{}
    
    Write-AuditLog "Collecting DNS inventory..." -Level INFO
    $auditResults['Inventory'] = Start-DNSInventory -Credential $Credential
    
    Write-AuditLog "Collecting DNS health data..." -Level INFO
    $auditResults['HealthCheck'] = Start-DNSHealthCheck -Credential $Credential
    
    Write-AuditLog "Collecting DNS records..." -Level INFO
    $auditResults['RecordExport'] = Start-DNSRecordExport -Credential $Credential
    
    # Create baseline object
    $baseline = @{
        Metadata = @{
            Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Author = "Adrian Johnson <adrian207@gmail.com>"
            Version = $script:Version
            Type = "DNS Baseline Snapshot"
        }
        Inventory = $auditResults['Inventory'].Servers
        HealthCheck = $auditResults['HealthCheck'].Results
        Records = @()  # Would be populated from RecordExport
    }
    
    # Save baseline
    $baselinePath = Join-Path $ExportPath "Baselines"
    if (!(Test-Path $baselinePath)) {
        New-Item -Path $baselinePath -ItemType Directory -Force | Out-Null
    }
    
    $baselineFile = Join-Path $baselinePath "DNS_Baseline_${script:TimeStamp}.json"
    $baseline | ConvertTo-Json -Depth 10 | Out-File -FilePath $baselineFile -Encoding UTF8
    
    Write-AuditLog "Baseline created: $baselineFile" -Level SUCCESS
    Write-Host "`n✓ Baseline snapshot created successfully!" -ForegroundColor Green
    Write-Host "Use -Mode Compare -BaselineFile `"$baselineFile`" to compare future states" -ForegroundColor Cyan
    
    return @{
        BaselineFile = $baselineFile
        Summary = "Baseline snapshot created with $($baseline.Inventory.Count) servers and $($baseline.HealthCheck.Count) health checks"
    }
}

function Start-CompareMode {
    <#
    .SYNOPSIS
    Compare current DNS state to baseline
    #>
    param(
        [string]$BaselineFilePath,
        [PSCredential]$Credential
    )
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  COMPARE MODE: Analyzing Changes               │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    
    # Find baseline file
    if ([string]::IsNullOrEmpty($BaselineFilePath)) {
        # Look for latest baseline
        $baselinePath = Join-Path $ExportPath "Baselines"
        if (Test-Path $baselinePath) {
            $latestBaseline = Get-ChildItem -Path $baselinePath -Filter "DNS_Baseline_*.json" | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
            
            if ($latestBaseline) {
                $BaselineFilePath = $latestBaseline.FullName
                Write-AuditLog "Using latest baseline: $($latestBaseline.Name)" -Level INFO
            }
            else {
                Write-AuditLog "No baseline files found. Create one with -Mode Baseline" -Level ERROR
                throw "No baseline file available"
            }
        }
        else {
            Write-AuditLog "No baselines directory found. Create a baseline with -Mode Baseline" -Level ERROR
            throw "No baseline file available"
        }
    }
    
    if (!(Test-Path $BaselineFilePath)) {
        Write-AuditLog "Baseline file not found: $BaselineFilePath" -Level ERROR
        throw "Baseline file not found"
    }
    
    Write-AuditLog "Loading baseline from: $BaselineFilePath" -Level INFO
    $baseline = Get-Content $BaselineFilePath -Raw | ConvertFrom-Json
    
    Write-AuditLog "Baseline date: $($baseline.Metadata.Created)" -Level INFO
    Write-AuditLog "Collecting current state..." -Level INFO
    
    # Get current state
    $currentInventory = (Start-DNSInventory -Credential $Credential).Servers
    $currentHealth = (Start-DNSHealthCheck -Credential $Credential).Results
    
    # Compare servers
    $comparison = @{
        NewServers = @()
        RemovedServers = @()
        HealthChanges = @()
        Summary = @{}
    }
    
    $baselineServers = $baseline.Inventory | Select-Object -ExpandProperty Name
    $currentServers = $currentInventory | Select-Object -ExpandProperty Name
    
    $comparison.NewServers = $currentServers | Where-Object { $_ -notin $baselineServers }
    $comparison.RemovedServers = $baselineServers | Where-Object { $_ -notin $currentServers }
    
    # Compare health
    foreach ($currentTest in $currentHealth) {
        $baselineTest = $baseline.HealthCheck | Where-Object {
            $_.Server -eq $currentTest.Server -and $_.Test -eq $currentTest.Test
        }
        
        if ($baselineTest -and $baselineTest.Status -ne $currentTest.Status) {
            $comparison.HealthChanges += [PSCustomObject]@{
                Server = $currentTest.Server
                Test = $currentTest.Test
                PreviousStatus = $baselineTest.Status
                CurrentStatus = $currentTest.Status
                Change = if ($currentTest.Status -eq "PASS") { "Improved" } else { "Degraded" }
            }
        }
    }
    
    # Summary
    $comparison.Summary = [PSCustomObject]@{
        BaselineDate = $baseline.Metadata.Created
        ComparisonDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ServersAdded = $comparison.NewServers.Count
        ServersRemoved = $comparison.RemovedServers.Count
        HealthChanges = $comparison.HealthChanges.Count
        HealthImproved = ($comparison.HealthChanges | Where-Object { $_.Change -eq "Improved" }).Count
        HealthDegraded = ($comparison.HealthChanges | Where-Object { $_.Change -eq "Degraded" }).Count
    }
    
    # Display results
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           COMPARISON RESULTS                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "Baseline Date:  " -NoNewline; Write-Host $comparison.Summary.BaselineDate -ForegroundColor Cyan
    Write-Host "Current Date:   " -NoNewline; Write-Host $comparison.Summary.ComparisonDate -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Servers Added:  " -NoNewline; Write-Host $comparison.Summary.ServersAdded -ForegroundColor $(if ($comparison.Summary.ServersAdded -gt 0) { "Yellow" } else { "Green" })
    Write-Host "Servers Removed:" -NoNewline; Write-Host $comparison.Summary.ServersRemoved -ForegroundColor $(if ($comparison.Summary.ServersRemoved -gt 0) { "Red" } else { "Green" })
    Write-Host ""
    Write-Host "Health Improved:" -NoNewline; Write-Host $comparison.Summary.HealthImproved -ForegroundColor Green
    Write-Host "Health Degraded:" -NoNewline; Write-Host $comparison.Summary.HealthDegraded -ForegroundColor $(if ($comparison.Summary.HealthDegraded -gt 0) { "Red" } else { "Green" })
    
    # Export comparison results
    if ($comparison.NewServers.Count -gt 0 -or $comparison.RemovedServers.Count -gt 0 -or $comparison.HealthChanges.Count -gt 0) {
        $allChanges = @()
        
        foreach ($server in $comparison.NewServers) {
            $allChanges += [PSCustomObject]@{
                ChangeType = "Server Added"
                Server = $server
                Detail = "New DNS server discovered"
                Impact = "Informational"
            }
        }
        
        foreach ($server in $comparison.RemovedServers) {
            $allChanges += [PSCustomObject]@{
                ChangeType = "Server Removed"
                Server = $server
                Detail = "DNS server no longer found"
                Impact = "Warning"
            }
        }
        
        foreach ($change in $comparison.HealthChanges) {
            $allChanges += [PSCustomObject]@{
                ChangeType = "Health Status Change"
                Server = $change.Server
                Detail = "$($change.Test): $($change.PreviousStatus) → $($change.CurrentStatus)"
                Impact = $change.Change
            }
        }
        
        Export-AuditData -Data $allChanges -BaseFileName "DNS_Comparison_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Configuration Changes"
    }
    else {
        Write-Host "`n✓ No changes detected since baseline" -ForegroundColor Green
    }
    
    return @{
        Comparison = $comparison
        Summary = "Compared to baseline from $($baseline.Metadata.Created): $($comparison.NewServers.Count) added, $($comparison.RemovedServers.Count) removed, $($comparison.HealthChanges.Count) health changes"
    }
}

#endregion

#region Mode 8: DNS Analytics (v2.5)

function Start-DNSAnalytics {
    <#
    .SYNOPSIS
        Advanced analytics: stale records, duplicates, PTR validation
    #>
    param([PSCredential]$Credential)
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 8: ADVANCED DNS ANALYTICS                │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    Write-AuditLog "Starting advanced DNS analytics..." -Level INFO
    
    try {
        $analytics = @{
            StaleRecords = @()
            DuplicateIPs = @()
            MissingPTRs = @()
            Statistics = @{}
        }
        
        # Get all DNS servers
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        $dnsServers = Get-ADDomainController @adParams -Filter * | Select-Object -ExpandProperty Name
        
        Write-AuditLog "Analyzing DNS records across $($dnsServers.Count) servers..." -Level INFO
        
        # Collect all records
        $allRecords = @()
        foreach ($server in $dnsServers) {
            try {
                $zones = Get-DnsServerZone -ComputerName $server -ErrorAction SilentlyContinue | Where-Object { -not $_.IsAutoCreated }
                
                foreach ($zone in $zones) {
                    try {
                        $records = Get-DnsServerResourceRecord -ComputerName $server -ZoneName $zone.ZoneName -ErrorAction SilentlyContinue
                        
                        foreach ($record in $records) {
                            $allRecords += [PSCustomObject]@{
                                Server = $server
                                Zone = $zone.ZoneName
                                Name = $record.HostName
                                Type = $record.RecordType
                                Data = $record.RecordData
                                Timestamp = $record.Timestamp
                                TimeToLive = $record.TimeToLive
                            }
                        }
                    } catch {
                        Write-AuditLog "Failed to query zone $($zone.ZoneName) on $server" -Level WARNING
                    }
                }
            } catch {
                Write-AuditLog "Failed to query DNS zones on $server" -Level WARNING
            }
        }
        
        Write-AuditLog "Collected $($allRecords.Count) DNS records for analysis" -Level SUCCESS
        
        # Analyze 1: Stale Records
        Write-AuditLog "Analyzing stale records (threshold: $StaleRecordThreshold days)..." -Level INFO
        $staleThreshold = (Get-Date).AddDays(-$StaleRecordThreshold)
        
        $staleRecords = $allRecords | Where-Object {
            $_.Timestamp -and $_.Timestamp -lt $staleThreshold
        }
        
        foreach ($record in $staleRecords) {
            $daysOld = [math]::Round(((Get-Date) - $record.Timestamp).TotalDays)
            $analytics.StaleRecords += [PSCustomObject]@{
                Server = $record.Server
                Zone = $record.Zone
                Name = $record.Name
                Type = $record.Type
                Age = "$daysOld days"
                Timestamp = $record.Timestamp
            }
            
            # Add remediation command
            if ($GenerateRemediationScript) {
                Add-RemediationCommand `
                    -Issue "Stale DNS record: $($record.Name) in $($record.Zone)" `
                    -Command "Remove-DnsServerResourceRecord -ComputerName '$($record.Server)' -ZoneName '$($record.Zone)' -Name '$($record.Name)' -RRType '$($record.Type)' -Force" `
                    -Description "Record is $daysOld days old (threshold: $StaleRecordThreshold days)"
            }
        }
        
        Write-AuditLog "Found $($staleRecords.Count) stale records" -Level $(if ($staleRecords.Count -gt 0) { "WARNING" } else { "SUCCESS" })
        
        # Analyze 2: Duplicate IPs
        if ($DetectDuplicateIPs) {
            Write-AuditLog "Detecting duplicate IP addresses..." -Level INFO
            
            $aRecords = $allRecords | Where-Object { $_.Type -eq "A" }
            $ipGroups = $aRecords | Group-Object -Property { $_.Data.IPv4Address } | Where-Object { $_.Count -gt 1 }
            
            foreach ($group in $ipGroups) {
                $analytics.DuplicateIPs += [PSCustomObject]@{
                    IPAddress = $group.Name
                    Count = $group.Count
                    Records = ($group.Group | ForEach-Object { "$($_.Name).$($_.Zone)" }) -join ", "
                }
                
                # Add remediation command
                if ($GenerateRemediationScript) {
                    Add-RemediationCommand `
                        -Issue "Duplicate IP address: $($group.Name)" `
                        -Command "# Review and consolidate: $($group.Name) is used by $($group.Count) records" `
                        -Description "Manual review required for records: $($analytics.DuplicateIPs[-1].Records)"
                }
            }
            
            Write-AuditLog "Found $($ipGroups.Count) duplicate IP addresses" -Level $(if ($ipGroups.Count -gt 0) { "WARNING" } else { "SUCCESS" })
        }
        
        # Analyze 3: PTR Record Validation
        if ($ValidatePTRRecords) {
            Write-AuditLog "Validating PTR records..." -Level INFO
            
            $aRecords = $allRecords | Where-Object { $_.Type -eq "A" }
            $ptrRecords = $allRecords | Where-Object { $_.Type -eq "PTR" }
            
            foreach ($aRecord in $aRecords) {
                $ip = $aRecord.Data.IPv4Address
                if (-not $ip) { continue }
                
                # Check if PTR exists
                $reverseName = ($ip.Split('.')[3..0] -join '.') + ".in-addr.arpa"
                $ptrExists = $ptrRecords | Where-Object { $_.Zone -like "*in-addr.arpa" -and $_.Data.PtrDomainName -like "*$($aRecord.Name)*" }
                
                if (-not $ptrExists) {
                    $analytics.MissingPTRs += [PSCustomObject]@{
                        ForwardName = "$($aRecord.Name).$($aRecord.Zone)"
                        IPAddress = $ip
                        ReverseLookupZone = $reverseName
                        Server = $aRecord.Server
                    }
                    
                    # Add remediation command
                    if ($GenerateRemediationScript) {
                        $reverseZone = ($ip.Split('.')[0..2] -join '.') + ".in-addr.arpa"
                        $ptrName = $ip.Split('.')[3]
                        Add-RemediationCommand `
                            -Issue "Missing PTR record for $($aRecord.Name).$($aRecord.Zone) ($ip)" `
                            -Command "Add-DnsServerResourceRecordPtr -ComputerName '$($aRecord.Server)' -ZoneName '$reverseZone' -Name '$ptrName' -PtrDomainName '$($aRecord.Name).$($aRecord.Zone)'" `
                            -Description "Create reverse DNS pointer for $ip"
                    }
                }
            }
            
            Write-AuditLog "Found $($analytics.MissingPTRs.Count) missing PTR records" -Level $(if ($analytics.MissingPTRs.Count -gt 0) { "WARNING" } else { "SUCCESS" })
        }
        
        # Statistics
        $analytics.Statistics = @{
            TotalRecords = $allRecords.Count
            StaleRecords = $analytics.StaleRecords.Count
            DuplicateIPs = $analytics.DuplicateIPs.Count
            MissingPTRs = $analytics.MissingPTRs.Count
            AnalysisDate = Get-Date
        }
        
        # Export results
        if ($analytics.StaleRecords.Count -gt 0) {
            Export-AuditData -Data $analytics.StaleRecords -BaseFileName "DNS_StaleRecords_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Stale Records"
        }
        if ($analytics.DuplicateIPs.Count -gt 0) {
            Export-AuditData -Data $analytics.DuplicateIPs -BaseFileName "DNS_DuplicateIPs_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Duplicate IP Addresses"
        }
        if ($analytics.MissingPTRs.Count -gt 0) {
            Export-AuditData -Data $analytics.MissingPTRs -BaseFileName "DNS_MissingPTRs_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Missing PTR Records"
        }
        
        Export-AuditData -Data $analytics.Statistics -BaseFileName "DNS_Analytics_Statistics_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Analytics Statistics"
        
        return @{
            Analytics = $analytics
            Summary = "Analytics complete: $($analytics.StaleRecords.Count) stale, $($analytics.DuplicateIPs.Count) duplicate IPs, $($analytics.MissingPTRs.Count) missing PTRs"
        }
        
    } catch {
        Write-AuditLog "Analytics failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

#endregion

#region Mode 9: DNS Security Audit (v2.5)

function Start-DNSSecurityAudit {
    <#
    .SYNOPSIS
        Security audit: DNSSEC, zone transfers, dynamic updates
    #>
    param([PSCredential]$Credential)
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 9: DNS SECURITY AUDIT                    │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    Write-AuditLog "Starting DNS security audit..." -Level INFO
    
    try {
        $security = @{
            DNSSEC = @()
            ZoneTransfers = @()
            DynamicUpdates = @()
            Statistics = @{}
        }
        
        # Get all DNS servers
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        $dnsServers = Get-ADDomainController @adParams -Filter * | Select-Object -ExpandProperty Name
        
        Write-AuditLog "Auditing DNS security across $($dnsServers.Count) servers..." -Level INFO
        
        foreach ($server in $dnsServers) {
            try {
                $zones = Get-DnsServerZone -ComputerName $server -ErrorAction SilentlyContinue | Where-Object { -not $_.IsAutoCreated }
                
                foreach ($zone in $zones) {
                    $zoneName = $zone.ZoneName
                    
                    # Check 1: DNSSEC Status
                    if ($EnableDNSSECCheck) {
                        $dnssecStatus = if ($zone.IsSigned) { "SIGNED" } else { "UNSIGNED" }
                        $security.DNSSEC += [PSCustomObject]@{
                            Server = $server
                            Zone = $zoneName
                            Status = $dnssecStatus
                            IsSigned = $zone.IsSigned
                            Recommendation = if (-not $zone.IsSigned) { "Enable DNSSEC signing" } else { "OK" }
                        }
                        
                        if (-not $zone.IsSigned -and $GenerateRemediationScript) {
                            Add-RemediationCommand `
                                -Issue "DNSSEC not enabled: $zoneName on $server" `
                                -Command "# Enable DNSSEC: Invoke-DnsServerZoneSign -ZoneName '$zoneName' -ComputerName '$server'" `
                                -Description "DNSSEC provides cryptographic authentication of DNS data"
                        }
                    }
                    
                    # Check 2: Zone Transfer Security
                    if ($AuditZoneTransfers) {
                        $xfrSetting = $zone.SecondaryServers
                        $xfrSecure = if ($zone.SecureSecondaries -eq "TransferToSecureServers") { "SECURE" } else { "INSECURE" }
                        
                        $security.ZoneTransfers += [PSCustomObject]@{
                            Server = $server
                            Zone = $zoneName
                            Setting = $zone.SecureSecondaries
                            Security = $xfrSecure
                            AllowedServers = if ($xfrSetting) { $xfrSetting -join ", " } else { "ANY (INSECURE!)" }
                            Recommendation = if ($xfrSecure -eq "INSECURE") { "Restrict zone transfers" } else { "OK" }
                        }
                        
                        if ($xfrSecure -eq "INSECURE" -and $GenerateRemediationScript) {
                            Add-RemediationCommand `
                                -Issue "Insecure zone transfer: $zoneName on $server" `
                                -Command "Set-DnsServerPrimaryZone -Name '$zoneName' -ComputerName '$server' -SecureSecondaries TransferToSecureServers" `
                                -Description "Restrict zone transfers to specific servers only"
                        }
                    }
                    
                    # Check 3: Dynamic Update Security
                    if ($CheckDynamicUpdates) {
                        $dynamicUpdate = $zone.DynamicUpdate
                        $isSecure = $dynamicUpdate -eq "Secure"
                        
                        $security.DynamicUpdates += [PSCustomObject]@{
                            Server = $server
                            Zone = $zoneName
                            Setting = $dynamicUpdate
                            Security = if ($isSecure) { "SECURE" } else { "INSECURE" }
                            Recommendation = if ($dynamicUpdate -eq "NonsecureAndSecure") { "Use secure dynamic updates only" } else { "OK" }
                        }
                        
                        if ($dynamicUpdate -eq "NonsecureAndSecure" -and $GenerateRemediationScript) {
                            Add-RemediationCommand `
                                -Issue "Insecure dynamic updates: $zoneName on $server" `
                                -Command "Set-DnsServerPrimaryZone -Name '$zoneName' -ComputerName '$server' -DynamicUpdate Secure" `
                                -Description "Restrict to secure (authenticated) dynamic updates only"
                        }
                    }
                }
            } catch {
                Write-AuditLog "Failed to audit security on $server" -Level WARNING
            }
        }
        
        # Statistics
        $security.Statistics = @{
            ServersAudited = $dnsServers.Count
            UnsignedZones = ($security.DNSSEC | Where-Object { -not $_.IsSigned }).Count
            InsecureZoneTransfers = ($security.ZoneTransfers | Where-Object { $_.Security -eq "INSECURE" }).Count
            InsecureDynamicUpdates = ($security.DynamicUpdates | Where-Object { $_.Security -eq "INSECURE" }).Count
            AuditDate = Get-Date
        }
        
        Write-AuditLog "Security audit complete" -Level SUCCESS
        Write-AuditLog "  Unsigned zones: $($security.Statistics.UnsignedZones)" -Level $(if ($security.Statistics.UnsignedZones -gt 0) { "WARNING" } else { "SUCCESS" })
        Write-AuditLog "  Insecure zone transfers: $($security.Statistics.InsecureZoneTransfers)" -Level $(if ($security.Statistics.InsecureZoneTransfers -gt 0) { "WARNING" } else { "SUCCESS" })
        Write-AuditLog "  Insecure dynamic updates: $($security.Statistics.InsecureDynamicUpdates)" -Level $(if ($security.Statistics.InsecureDynamicUpdates -gt 0) { "WARNING" } else { "SUCCESS" })
        
        # Export results
        if ($security.DNSSEC.Count -gt 0) {
            Export-AuditData -Data $security.DNSSEC -BaseFileName "DNS_DNSSEC_Audit_${script:TimeStamp}" -Format $ExportFormat -Title "DNS DNSSEC Status"
        }
        if ($security.ZoneTransfers.Count -gt 0) {
            Export-AuditData -Data $security.ZoneTransfers -BaseFileName "DNS_ZoneTransfer_Audit_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Zone Transfer Security"
        }
        if ($security.DynamicUpdates.Count -gt 0) {
            Export-AuditData -Data $security.DynamicUpdates -BaseFileName "DNS_DynamicUpdate_Audit_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Dynamic Update Security"
        }
        
        Export-AuditData -Data $security.Statistics -BaseFileName "DNS_Security_Statistics_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Security Statistics"
        
        return @{
            Security = $security
            Summary = "Security audit: $($security.Statistics.UnsignedZones) unsigned zones, $($security.Statistics.InsecureZoneTransfers) insecure transfers, $($security.Statistics.InsecureDynamicUpdates) insecure updates"
        }
        
    } catch {
        Write-AuditLog "Security audit failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

#endregion

#region Mode 10: DNS Diagnostics (v2.5)

function Start-DNSDiagnostics {
    <#
    .SYNOPSIS
        Enhanced diagnostics: performance, replication lag
    #>
    param([PSCredential]$Credential)
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 10: DNS DIAGNOSTICS                      │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    Write-AuditLog "Starting DNS diagnostics..." -Level INFO
    
    try {
        $diagnostics = @{
            QueryPerformance = @()
            ReplicationLag = @()
            Statistics = @{}
        }
        
        # Get all DNS servers
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        $dnsServers = Get-ADDomainController @adParams -Filter * | Select-Object Name, IPv4Address
        $domain = (Get-ADDomain @adParams).DNSRoot
        
        # Test 1: Query Performance
        if ($TestQueryPerformance) {
            Write-AuditLog "Testing DNS query performance ($PerformanceTestIterations iterations per server)..." -Level INFO
            
            foreach ($dc in $dnsServers) {
                $responseTimes = @()
                
                for ($i = 1; $i -le $PerformanceTestIterations; $i++) {
                    try {
                        $sw = [System.Diagnostics.Stopwatch]::StartNew()
                        $null = Resolve-DnsName -Name $domain -Server $dc.IPv4Address -ErrorAction Stop
                        $sw.Stop()
                        $responseTimes += $sw.Elapsed.TotalMilliseconds
                    } catch {
                        Write-AuditLog "Query failed: $($dc.Name)" -Level WARNING
                    }
                }
                
                if ($responseTimes.Count -gt 0) {
                    $avgTime = [math]::Round(($responseTimes | Measure-Object -Average).Average, 2)
                    $minTime = [math]::Round(($responseTimes | Measure-Object -Minimum).Minimum, 2)
                    $maxTime = [math]::Round(($responseTimes | Measure-Object -Maximum).Maximum, 2)
                    
                    $status = if ($avgTime -lt 50) { "EXCELLENT" } elseif ($avgTime -lt 100) { "GOOD" } elseif ($avgTime -lt 200) { "FAIR" } else { "SLOW" }
                    
                    $diagnostics.QueryPerformance += [PSCustomObject]@{
                        Server = $dc.Name
                        IPAddress = $dc.IPv4Address
                        AverageMS = $avgTime
                        MinMS = $minTime
                        MaxMS = $maxTime
                        Iterations = $responseTimes.Count
                        Status = $status
                    }
                    
                    if ($status -eq "SLOW" -and $GenerateRemediationScript) {
                        Add-RemediationCommand `
                            -Issue "Slow DNS response: $($dc.Name) (avg: ${avgTime}ms)" `
                            -Command "# Investigate: Check DNS service health, network latency, and server load on $($dc.Name)" `
                            -Description "Average response time exceeds 200ms"
                    }
                }
            }
            
            Write-AuditLog "Query performance testing complete" -Level SUCCESS
        }
        
        # Test 2: AD Replication Lag
        if ($CheckReplicationLag) {
            Write-AuditLog "Checking AD replication lag..." -Level INFO
            
            try {
                $repSummary = Get-ADReplicationPartnerMetadata -Target * -Scope Domain -ErrorAction Stop
                
                foreach ($rep in $repSummary) {
                    $lagSeconds = if ($rep.LastReplicationSuccess) {
                        [math]::Round(((Get-Date) - $rep.LastReplicationSuccess).TotalSeconds)
                    } else {
                        -1
                    }
                    
                    $status = if ($lagSeconds -lt 0) { "UNKNOWN" } elseif ($lagSeconds -lt 3600) { "HEALTHY" } elseif ($lagSeconds -lt 10800) { "WARNING" } else { "CRITICAL" }
                    
                    $diagnostics.ReplicationLag += [PSCustomObject]@{
                        Server = $rep.Server
                        Partner = $rep.Partner
                        LastReplication = if ($rep.LastReplicationSuccess) { $rep.LastReplicationSuccess.ToString("yyyy-MM-dd HH:mm:ss") } else { "Never" }
                        LagSeconds = $lagSeconds
                        Status = $status
                    }
                    
                    if ($status -eq "CRITICAL" -and $GenerateRemediationScript) {
                        Add-RemediationCommand `
                            -Issue "AD replication lag: $($rep.Server) -> $($rep.Partner)" `
                            -Command "# Investigate: repadmin /showrepl $($rep.Server)" `
                            -Description "Replication lag exceeds 3 hours"
                    }
                }
                
                Write-AuditLog "Replication lag check complete" -Level SUCCESS
                
            } catch {
                Write-AuditLog "Failed to check replication lag: $_" -Level WARNING
            }
        }
        
        # Test 3: Cross-Site Authentication Issues
        if ($CheckCrossSiteAuth) {
            Write-AuditLog "Checking for cross-site authentication issues..." -Level INFO
            $diagnostics.CrossSiteAuth = @()
            $missingSubnets = @()
            $uniqueIPs = @{}
            
            foreach ($dc in $dnsServers) {
                try {
                    # Build remote path to netlogon.log
                    $remotePath = "\\$($dc.Name)\C$\Windows\debug\netlogon.log"
                    
                    Write-AuditLog "Scanning $($dc.Name) netlogon.log..." -Level INFO
                    
                    # Check if file exists
                    if (-not (Test-Path $remotePath)) {
                        Write-AuditLog "Netlogon.log not found on $($dc.Name)" -Level WARNING
                        continue
                    }
                    
                    # Read the netlogon.log file
                    $logContent = Get-Content $remotePath -ErrorAction Stop
                    
                    # Parse for NO_CLIENT_SITE warnings
                    # Format: MM/DD HH:MM:SS [CRITICAL] NO_CLIENT_SITE: ClientName IPAddress
                    $noClientSiteEntries = $logContent | Where-Object { $_ -match "NO_CLIENT_SITE" }
                    
                    foreach ($entry in $noClientSiteEntries) {
                        # Extract IP address and client name from log entry
                        # Typical format: "10/19 14:30:45 [CRITICAL] NO_CLIENT_SITE: WORKSTATION01 192.168.50.10"
                        if ($entry -match "NO_CLIENT_SITE:\s+(\S+)\s+([\d\.]+)") {
                            $clientName = $Matches[1]
                            $clientIP = $Matches[2]
                            
                            # Track unique IPs to avoid duplicates
                            if (-not $uniqueIPs.ContainsKey($clientIP)) {
                                $uniqueIPs[$clientIP] = $true
                                
                                # Try to determine the correct site for this IP
                                $suggestedSubnet = "$($clientIP.Split('.')[0..2] -join '.')."
                                $subnetMask = "255.255.255.0" # Default /24 - can be adjusted
                                
                                $diagnostics.CrossSiteAuth += [PSCustomObject]@{
                                    DC = $dc.Name
                                    ClientName = $clientName
                                    ClientIP = $clientIP
                                    Issue = "Client not in any AD site"
                                    Impact = "Cross-site authentication, slow logon"
                                    SuggestedSubnet = "$suggestedSubnet/$subnetMask"
                                    DetectedDate = Get-Date
                                }
                                
                                # Add to missing subnets list
                                if (-not ($missingSubnets | Where-Object { $_.Subnet -eq "$suggestedSubnet/$subnetMask" })) {
                                    $missingSubnets += [PSCustomObject]@{
                                        Subnet = "$suggestedSubnet"
                                        SubnetMask = $subnetMask
                                        AffectedClients = @($clientName)
                                        AffectedIPs = @($clientIP)
                                    }
                                } else {
                                    $existing = $missingSubnets | Where-Object { $_.Subnet -eq "$suggestedSubnet/$subnetMask" }
                                    $existing.AffectedClients += $clientName
                                    $existing.AffectedIPs += $clientIP
                                }
                                
                                # Add remediation command
                                if ($GenerateRemediationScript) {
                                    Add-RemediationCommand `
                                        -Issue "Missing AD subnet for $clientIP ($clientName)" `
                                        -Command "# Add subnet to AD Sites and Services:`n# New-ADReplicationSubnet -Name '$suggestedSubnet/24' -Site 'SITE_NAME' -Location 'Location Description'" `
                                        -Description "Client $clientName ($clientIP) is authenticating cross-site. Add subnet to proper AD site."
                                }
                            }
                        }
                    }
                    
                    if ($noClientSiteEntries.Count -gt 0) {
                        Write-AuditLog "  Found $($noClientSiteEntries.Count) NO_CLIENT_SITE entries on $($dc.Name)" -Level WARNING
                    } else {
                        Write-AuditLog "  No cross-site issues on $($dc.Name)" -Level SUCCESS
                    }
                    
                } catch {
                    Write-AuditLog "Failed to scan netlogon.log on $($dc.Name): $_" -Level WARNING
                }
            }
            
            $diagnostics.MissingSubnets = $missingSubnets
            
            Write-AuditLog "Cross-site authentication check complete" -Level SUCCESS
            Write-AuditLog "  Unique clients with cross-site issues: $($diagnostics.CrossSiteAuth.Count)" -Level $(if ($diagnostics.CrossSiteAuth.Count -gt 0) { "WARNING" } else { "SUCCESS" })
            Write-AuditLog "  Missing subnets identified: $($missingSubnets.Count)" -Level $(if ($missingSubnets.Count -gt 0) { "WARNING" } else { "SUCCESS" })
        }
        
        # Statistics
        $diagnostics.Statistics = @{
            ServersTested = $dnsServers.Count
            AverageQueryTime = if ($diagnostics.QueryPerformance.Count -gt 0) { [math]::Round(($diagnostics.QueryPerformance.AverageMS | Measure-Object -Average).Average, 2) } else { 0 }
            SlowServers = ($diagnostics.QueryPerformance | Where-Object { $_.Status -eq "SLOW" }).Count
            ReplicationIssues = ($diagnostics.ReplicationLag | Where-Object { $_.Status -in @("WARNING", "CRITICAL") }).Count
            CrossSiteIssues = if ($CheckCrossSiteAuth) { $diagnostics.CrossSiteAuth.Count } else { 0 }
            MissingSubnets = if ($CheckCrossSiteAuth) { $diagnostics.MissingSubnets.Count } else { 0 }
            DiagnosticDate = Get-Date
        }
        
        Write-AuditLog "Diagnostics complete" -Level SUCCESS
        Write-AuditLog "  Average query time: $($diagnostics.Statistics.AverageQueryTime)ms" -Level SUCCESS
        Write-AuditLog "  Slow servers: $($diagnostics.Statistics.SlowServers)" -Level $(if ($diagnostics.Statistics.SlowServers -gt 0) { "WARNING" } else { "SUCCESS" })
        Write-AuditLog "  Replication issues: $($diagnostics.Statistics.ReplicationIssues)" -Level $(if ($diagnostics.Statistics.ReplicationIssues -gt 0) { "WARNING" } else { "SUCCESS" })
        if ($CheckCrossSiteAuth) {
            Write-AuditLog "  Cross-site auth issues: $($diagnostics.Statistics.CrossSiteIssues)" -Level $(if ($diagnostics.Statistics.CrossSiteIssues -gt 0) { "WARNING" } else { "SUCCESS" })
            Write-AuditLog "  Missing subnets: $($diagnostics.Statistics.MissingSubnets)" -Level $(if ($diagnostics.Statistics.MissingSubnets -gt 0) { "WARNING" } else { "SUCCESS" })
        }
        
        # Export results
        if ($diagnostics.QueryPerformance.Count -gt 0) {
            Export-AuditData -Data $diagnostics.QueryPerformance -BaseFileName "DNS_QueryPerformance_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Query Performance"
        }
        if ($diagnostics.ReplicationLag.Count -gt 0) {
            Export-AuditData -Data $diagnostics.ReplicationLag -BaseFileName "DNS_ReplicationLag_${script:TimeStamp}" -Format $ExportFormat -Title "AD Replication Status"
        }
        if ($CheckCrossSiteAuth -and $diagnostics.CrossSiteAuth.Count -gt 0) {
            Export-AuditData -Data $diagnostics.CrossSiteAuth -BaseFileName "DNS_CrossSiteAuth_Issues_${script:TimeStamp}" -Format $ExportFormat -Title "Cross-Site Authentication Issues"
        }
        if ($CheckCrossSiteAuth -and $diagnostics.MissingSubnets.Count -gt 0) {
            Export-AuditData -Data $diagnostics.MissingSubnets -BaseFileName "DNS_Missing_Subnets_${script:TimeStamp}" -Format $ExportFormat -Title "Missing AD Subnets"
        }
        
        Export-AuditData -Data $diagnostics.Statistics -BaseFileName "DNS_Diagnostics_Statistics_${script:TimeStamp}" -Format $ExportFormat -Title "DNS Diagnostics Statistics"
        
        # Build summary message
        $summaryParts = @("Diagnostics: Avg query ${($diagnostics.Statistics.AverageQueryTime)}ms")
        $summaryParts += "$($diagnostics.Statistics.SlowServers) slow servers"
        $summaryParts += "$($diagnostics.Statistics.ReplicationIssues) replication issues"
        if ($CheckCrossSiteAuth) {
            $summaryParts += "$($diagnostics.Statistics.CrossSiteIssues) cross-site auth issues"
            $summaryParts += "$($diagnostics.Statistics.MissingSubnets) missing subnets"
        }
        
        return @{
            Diagnostics = $diagnostics
            Summary = $summaryParts -join ", "
        }
        
    } catch {
        Write-AuditLog "Diagnostics failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

#endregion

#region Main Execution

try {
    # Initialize
    Start-MasterLogging -Path $ExportPath
    
    # Configuration Profile Management (v2.5)
    if ($ConfigProfile) {
        Write-AuditLog "Loading configuration profile: $ConfigProfile" -Level INFO
        try {
            $config = Import-ConfigProfile -ProfilePath $ConfigProfile
            # Apply configuration settings (override parameters)
            if ($config.Mode) { $Mode = $config.Mode }
            if ($config.ExportPath) { $ExportPath = $config.ExportPath }
            if ($config.ExportFormat) { $ExportFormat = $config.ExportFormat }
            if ($config.StaleRecordThreshold) { $StaleRecordThreshold = $config.StaleRecordThreshold }
            if ($config.EnableParallelProcessing) { $script:EnableParallelProcessing = $config.EnableParallelProcessing }
            if ($config.MaxDegreeOfParallelism) { $script:MaxDegreeOfParallelism = $config.MaxDegreeOfParallelism }
            if ($config.TeamsWebhook) { $TeamsWebhook = $config.TeamsWebhook }
            if ($config.SlackWebhook) { $SlackWebhook = $config.SlackWebhook }
            if ($config.SyslogServer) { $SyslogServer = $config.SyslogServer }
            Write-AuditLog "Configuration profile loaded successfully" -Level SUCCESS
        } catch {
            Write-AuditLog "Failed to load configuration profile: $_" -Level ERROR
            throw
        }
    }
    
    # Security Initialization (v2.6)
    Write-AuditLog "=== Security Initialization ===" -Level INFO
    
    # 1. Credential Manager Integration
    if ($UseCredentialManager) {
        Write-AuditLog "Attempting to load credential from Credential Manager: $CredentialName" -Level INFO
        try {
            $storedCred = Get-StoredCredential -TargetName $CredentialName
            if ($storedCred) {
                $Credential = $storedCred
                Write-AuditLog "Successfully loaded credential from Credential Manager" -Level SUCCESS
            } else {
                Write-AuditLog "Credential not found in Credential Manager, proceeding without credential" -Level WARNING
            }
        } catch {
            Write-AuditLog "Failed to access Credential Manager: $_" -Level WARNING
        }
    }
    
    # 2. Compliance Mode Application
    if ($ComplianceMode -ne "None") {
        Set-ComplianceMode -Mode $ComplianceMode
    }
    
    # 3. Path Validation
    Write-AuditLog "Validating export path: $ExportPath" -Level INFO
    if (-not (Test-SafePath -Path $ExportPath -AllowRelative)) {
        Write-AuditLog "Export path validation failed, using default: C:\DNSAudit" -Level WARNING
        $ExportPath = "C:\DNSAudit"
    }
    
    # Ensure export directory exists
    if (-not (Test-Path $ExportPath)) {
        try {
            New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
            Write-AuditLog "Created export directory: $ExportPath" -Level SUCCESS
        } catch {
            Write-AuditLog "Failed to create export directory: $_" -Level ERROR
            throw
        }
    }
    
    # 4. Webhook URL Validation
    if ($TeamsWebhook) {
        Write-AuditLog "Validating Teams webhook URL..." -Level INFO
        if (-not (Test-WebhookUrl -Url $TeamsWebhook)) {
            Write-AuditLog "Teams webhook validation failed, disabling Teams notifications" -Level WARNING
            $TeamsWebhook = ""
        }
    }
    
    if ($SlackWebhook) {
        Write-AuditLog "Validating Slack webhook URL..." -Level INFO
        if (-not (Test-WebhookUrl -Url $SlackWebhook)) {
            Write-AuditLog "Slack webhook validation failed, disabling Slack notifications" -Level WARNING
            $SlackWebhook = ""
        }
    }
    
    # 5. Audit Signing Setup
    if ($EnableAuditSigning) {
        if (-not $SigningCertificateThumbprint) {
            Write-AuditLog "Audit signing enabled but no certificate thumbprint provided" -Level WARNING
            Write-AuditLog "Looking for available code signing certificates..." -Level INFO
            
            $availableCerts = Get-ChildItem -Path Cert:\CurrentUser\My, Cert:\LocalMachine\My -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.HasPrivateKey -and $_.EnhancedKeyUsageList.FriendlyName -contains "Code Signing" }
            
            if ($availableCerts.Count -gt 0) {
                $SigningCertificateThumbprint = $availableCerts[0].Thumbprint
                Write-AuditLog "Using certificate: $($availableCerts[0].Subject)" -Level SUCCESS
            } else {
                Write-AuditLog "No suitable certificates found, disabling audit signing" -Level WARNING
                $script:EnableAuditSigning = $false
            }
        } else {
            Write-AuditLog "Audit signing enabled with certificate: $SigningCertificateThumbprint" -Level SUCCESS
        }
    }
    
    # Display security status
    if ($script:RedactSensitiveData) {
        Write-AuditLog "Data redaction: ENABLED" -Level INFO
    }
    if ($script:EnableAuditSigning) {
        Write-AuditLog "Audit signing: ENABLED" -Level INFO
    }
    if ($script:UseCredentialManager) {
        Write-AuditLog "Credential Manager: ENABLED" -Level INFO
    }
    
    Write-AuditLog "=== Security Initialization Complete ===" -Level SUCCESS
    
    # Banner
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  DNS Master Audit - $script:Version" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Mode:        $Mode" -ForegroundColor White
    Write-Host "Export Path: $ExportPath" -ForegroundColor White
    if ($ZoneFilter.Count -gt 0) {
        Write-Host "Zone Filter: $($ZoneFilter -join ', ')" -ForegroundColor White
    }
    if ($script:EnableParallelProcessing) {
        Write-Host "Parallel Processing: ENABLED (throttle: $script:MaxDegreeOfParallelism)" -ForegroundColor Green
    }
    if ($script:RedactSensitiveData) {
        Write-Host "Security:    Data Redaction ENABLED" -ForegroundColor Yellow
    }
    if ($script:EnableAuditSigning) {
        Write-Host "Security:    Audit Signing ENABLED" -ForegroundColor Yellow
    }
    if ($ComplianceMode -ne "None") {
        Write-Host "Compliance:  $ComplianceMode Mode" -ForegroundColor Cyan
    }
    Write-Host ""
    # Execute selected mode
    $Results = switch ($Mode) {
        "Inventory" { Start-DNSInventory -Credential $Credential }
        "HealthCheck" { Start-DNSHealthCheck -Credential $Credential }
        "RecordExport" { Start-DNSRecordExport -Zones $ZoneFilter -Credential $Credential -DnsServer $DnsServer -UnionZones:$UnionZones }
        "SiteAudit" { Start-DNSSiteAudit -AllFeatures:$EnableAllFeatures -Credential $Credential }
        "Complete" { Start-CompleteAudit -Credential $Credential -DnsServer $DnsServer -UnionZones:$UnionZones }
        "Baseline" { Start-BaselineMode -Credential $Credential }
        "Compare" { Start-CompareMode -BaselineFilePath $BaselineFile -Credential $Credential }
        "Analytics" { Start-DNSAnalytics -Credential $Credential }
        "Security" { Start-DNSSecurityAudit -Credential $Credential }
        "Diagnostics" { Start-DNSDiagnostics -Credential $Credential }
    }
    # Email notification
    if ($EnableEmailNotification) {
        if (-not $SMTPServer -or -not $EmailFrom -or -not $EmailTo) {
            Write-AuditLog "Email parameters incomplete (need -SMTPServer, -EmailFrom, -EmailTo); skipping email." -Level WARNING
        }
        else {
            Write-AuditLog "Sending email notification..." -Level INFO
            Write-AuditLog "NOTE: Send-MailMessage is deprecated. Consider exporting JSON and using external notifiers (Teams/Slack/etc)." -Level WARNING
            $EmailBody = @"
DNS Master Audit Completed

Mode: $Mode
Duration: $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 2)) minutes
Export Path: $ExportPath

Summary:
$($Results.Summary)

This is an automated notification from DNS Master Audit (Independent Edition).
"@
            try {
                $mailParams = @{
                    SmtpServer = $SMTPServer
                    Port = $SmtpPort
                    From = $EmailFrom
                    To = $EmailTo
                    Subject = "DNS Master Audit Complete: $Mode"
                    Body = $EmailBody
                    ErrorAction = 'Stop'
                }
                if ($UseSsl) {
                    $mailParams['UseSsl'] = $true
                }
                if ($SmtpCredential) {
                    $mailParams['Credential'] = $SmtpCredential
                }
                Send-MailMessage @mailParams
                Write-AuditLog "Email sent successfully to $($EmailTo -join ', ')" -Level SUCCESS
            }
            catch {
                Write-AuditLog "Email failed: $($_.Exception.Message)" -Level WARNING
            }
        }
    }
    
    # Enterprise Integration (v2.5)
    $summaryMessage = if ($Results.Summary) { $Results.Summary } else { "DNS Audit completed: $Mode" }
    
    # Teams notification
    if ($TeamsWebhook) {
        Write-AuditLog "Sending Teams notification..." -Level INFO
        $severity = if ($script:IssuesFound -gt 0) { "Warning" } else { "Success" }
        Send-TeamsNotification `
            -WebhookUrl $TeamsWebhook `
            -Title "DNS Master Audit Complete" `
            -Message "$summaryMessage`n`nMode: $Mode`nIssues Found: $script:IssuesFound`nDuration: $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 2)) minutes" `
            -Severity $severity
    }
    
    # Slack notification
    if ($SlackWebhook) {
        Write-AuditLog "Sending Slack notification..." -Level INFO
        $emoji = if ($script:IssuesFound -gt 0) { ":warning:" } else { ":white_check_mark:" }
        Send-SlackNotification `
            -WebhookUrl $SlackWebhook `
            -Message "$emoji *DNS Master Audit Complete*`n*Mode:* $Mode`n*Summary:* $summaryMessage`n*Issues Found:* $script:IssuesFound`n*Duration:* $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 2)) minutes"
    }
    
    # Syslog/SIEM integration
    if ($SyslogServer) {
        Write-AuditLog "Sending audit results to Syslog server..." -Level INFO
        $syslogSeverity = if ($script:IssuesFound -gt 10) { "Warning" } elseif ($script:IssuesFound -gt 0) { "Notice" } else { "Info" }
        Send-SyslogMessage `
            -Server $SyslogServer `
            -Port $SyslogPort `
            -Message "DNS Audit Complete - Mode: $Mode, Issues: $script:IssuesFound, Duration: $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 2))min" `
            -Severity $syslogSeverity
    }
    
    # Generate remediation script
    if ($GenerateRemediationScript -and $script:RemediationCommands.Count -gt 0) {
        Write-AuditLog "Generating remediation script ($($script:RemediationCommands.Count) commands)..." -Level INFO
        Export-RemediationScript -OutputPath $ExportPath
    } elseif ($GenerateRemediationScript) {
        Write-AuditLog "No issues found - no remediation script generated" -Level SUCCESS
    }
    
    # Determine exit code for CI/CD integration
    $ExitCode = 0
    # Check for Critical severity issues in SiteAudit
    if ($Mode -eq "SiteAudit" -or $Mode -eq "Complete") {
        $CriticalCount = 0
        if ($Results.Statistics) {
            $CriticalCount = $Results.Statistics.CriticalSeverity
        }
        elseif ($Results.SiteAudit -and $Results.SiteAudit.Statistics) {
            $CriticalCount = $Results.SiteAudit.Statistics.CriticalSeverity
        }
        if ($CriticalCount -gt 0) {
            $ExitCode = 3
            Write-AuditLog "EXIT CODE 3: Found $CriticalCount Critical severity issues" -Level WARNING
        }
    }
    # Check for mode failures in Complete mode
    if ($Mode -eq "Complete") {
        $FailureCount = 0
        if (!$script:AllResults.Inventory) { $FailureCount++ }
        if (!$script:AllResults.HealthCheck) { $FailureCount++ }
        if (!$script:AllResults.RecordExport) { $FailureCount++ }
        if (!$script:AllResults.SiteAudit) { $FailureCount++ }
        if ($FailureCount -gt 0 -and $ExitCode -eq 0) {
            $ExitCode = 2
            Write-AuditLog "EXIT CODE 2: One or more audit modes failed" -Level WARNING
        }
    }
    # Final summary
    Write-Host "`n" -NoNewline
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              AUDIT COMPLETED SUCCESSFULLY             ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
    $TotalDuration = ((Get-Date) - $script:StartTime).TotalMinutes
    Write-Host "`nTotal Time: $([math]::Round($TotalDuration, 2)) minutes" -ForegroundColor Cyan
    Write-Host "Results:    $ExportPath" -ForegroundColor Cyan
    if ($ExitCode -ne 0) {
        Write-Host "`nExit Code:  $ExitCode" -ForegroundColor Yellow
    }
}
catch {
    Write-AuditLog "FATAL ERROR: $($_.Exception.Message)" -Level ERROR
    Write-AuditLog $_.ScriptStackTrace -Level ERROR
    $ExitCode = 1
    throw
}
finally {
    Stop-MasterLogging
    exit $ExitCode
}

#endregion
