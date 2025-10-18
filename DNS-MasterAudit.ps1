################################################################################
# DNS Master Audit Script - INDEPENDENT EDITION
# Author: Adrian Johnson <adrian207@gmail.com>
# Created: 2025
# Version: 2.0 - Fully Self-Contained
## Description: All-in-one DNS auditing tool - NO EXTERNAL DEPENDENCIES
#              1. DNS Inventory (server discovery)
#              2. DNS Health Check (service testing)
#              3. DNS Record Export (complete inventory)
#              4. DNS Site Audit (mismatch detection) - EMBEDDED
#              5. Complete Audit (all of the above)
## Features: ALL functionality in ONE standalone script
#           Can run anywhere - no other scripts needed!
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory, DnsServer

<#
.SYNOPSIS
Unified, self-contained DNS auditing tool with multiple operation modes

.DESCRIPTION
All-in-one DNS audit solution combining 5 specialized functions:
- DNS-Inventory: Server discovery and inventory
- DNS-HealthCheck: DNS service health testing
- DNS-RecordExport: Complete DNS record export
- DNS-SiteAudit: Site mismatch detection (EMBEDDED - no dependencies!)
- Complete audit mode: Run all audits in sequence

✅ FULLY INDEPENDENT - No external scripts required!

.PARAMETER Mode
Operation mode:
- Inventory: Discover and list all DNS servers
- HealthCheck: Test DNS service health on all DCs
- RecordExport: Export all DNS records to CSV
- SiteAudit: Find site mismatches (embedded functionality)
- Complete: Run all audits (recommended for comprehensive analysis)

.PARAMETER ExportPath
Directory for all reports and logs (default: C:\DNSAudit)

.PARAMETER ZoneFilter
Optional array of specific zones to audit (default: all zones)

.PARAMETER EnableAllFeatures
For SiteAudit mode: Enable advanced features (severity levels, health scores, etc.)

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

.NOTES
Version: 2.0 - Independent Edition (NO external dependencies!)
Author: Adrian Johnson <adrian207@gmail.com>
Self-Contained: All functionality embedded in this single script

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
    [ValidateSet("Inventory", "HealthCheck", "RecordExport", "SiteAudit", "Complete")]
    [string]$Mode,
    [Parameter(HelpMessage = "Export directory for all reports")]
    [string]$ExportPath = "C:\DNSAudit",
    [Parameter(HelpMessage = "Filter specific zones")]
    [string[]]$ZoneFilter = @(),
    [Parameter(HelpMessage = "Enable all advanced features for SiteAudit mode")]
    [switch]$EnableAllFeatures,
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
    [string[]]$EmailTo
)

#region Script Variables
$script:Version = "2.0 - Independent Edition"
$script:StartTime = Get-Date
$script:TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:LogPath = ""
$script:AllResults = @{
    Inventory = $null
    HealthCheck = $null
    RecordExport = $null
    SiteAudit = $null
}
$script:SkippedSubnets = @()
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
        $OutputFile = Join-Path $ExportPath "DNS_Inventory_${script:TimeStamp}.csv"
        $DNSServers | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-AuditLog "Exported inventory to: $OutputFile" -Level SUCCESS
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
                    # Use CIM for cross-platform compatibility (PS 5.1 and 7.x)
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
        $OutputFile = Join-Path $ExportPath "DNS_HealthCheck_${script:TimeStamp}.csv"
        $AllHealthResults | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-AuditLog "Exported health check to: $OutputFile" -Level SUCCESS
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
        # Export results
        $MismatchFile = Join-Path $ExportPath "DNS_Site_Mismatches_${script:TimeStamp}.csv"
        $UniqueMismatches | Export-Csv -Path $MismatchFile -NoTypeInformation
        Write-AuditLog "Exported mismatches to: $MismatchFile" -Level SUCCESS
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
        $StatsFile = Join-Path $ExportPath "DNS_Audit_Statistics_${script:TimeStamp}.csv"
        $Statistics | Export-Csv -Path $StatsFile -NoTypeInformation
        # Report skipped subnets
        if ($script:SkippedSubnets.Count -gt 0) {
            $UniqueSkippedSubnets = $script:SkippedSubnets | Sort-Object Subnet -Unique
            $SkippedFile = Join-Path $ExportPath "DNS_Audit_Skipped_Subnets_${script:TimeStamp}.csv"
            $UniqueSkippedSubnets | Export-Csv -Path $SkippedFile -NoTypeInformation
            Write-AuditLog "WARNING: $($UniqueSkippedSubnets.Count) subnets were skipped due to parsing errors" -Level WARNING
            Write-AuditLog "  Skipped subnets exported to: $SkippedFile" -Level INFO
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
                $HealthFile = Join-Path $ExportPath "DNS_Zone_Health_Scores_${script:TimeStamp}.csv"
                $ZoneHealthScores | Export-Csv -Path $HealthFile -NoTypeInformation
                Write-AuditLog "Zone health scores exported to: $HealthFile" -Level SUCCESS
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

#endregion

#region Main Execution

try {
    # Initialize
    Start-MasterLogging -Path $ExportPath
    Write-Host "Mode:        $Mode" -ForegroundColor White
    Write-Host "Export Path: $ExportPath" -ForegroundColor White
    if ($ZoneFilter.Count -gt 0) {
        Write-Host "Zone Filter: $($ZoneFilter -join ', ')" -ForegroundColor White
    }
    Write-Host ""
    # Execute selected mode
    $Results = switch ($Mode) {
        "Inventory" { Start-DNSInventory -Credential $Credential }
        "HealthCheck" { Start-DNSHealthCheck -Credential $Credential }
        "RecordExport" { Start-DNSRecordExport -Zones $ZoneFilter -Credential $Credential -DnsServer $DnsServer -UnionZones:$UnionZones }
        "SiteAudit" { Start-DNSSiteAudit -AllFeatures:$EnableAllFeatures -Credential $Credential }
        "Complete" { Start-CompleteAudit -Credential $Credential -DnsServer $DnsServer -UnionZones:$UnionZones }
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
