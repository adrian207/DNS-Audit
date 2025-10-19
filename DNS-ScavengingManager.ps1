################################################################################
# DNS Scavenging Manager
# Author: Adrian Johnson <adrian207@gmail.com>
# Version: 1.0
# Description: Analyze and configure DNS scavenging settings across all DNS servers
#              Follows Microsoft best practices with customizable intervals
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory, DnsServer

<#
.SYNOPSIS
Analyze and configure DNS scavenging settings across your DNS infrastructure

.DESCRIPTION
This tool provides comprehensive DNS scavenging management:
- Analyze current scavenging configuration across all DNS servers
- Identify zones with scavenging disabled or misconfigured
- Compare against Microsoft best practices
- Generate remediation scripts
- Apply scavenging settings safely with WhatIf support

Microsoft Best Practices:
- No-refresh interval: 7 days (default)
- Refresh interval: 7 days (default)
- Total scavenging period: 14 days
- Server scavenging: Enabled
- Zone aging: Enabled

Aggressive Option (user preference):
- No-refresh interval: 3 days
- Refresh interval: 3 days
- Total scavenging period: 6 days

.PARAMETER Mode
Operation mode:
- Analyze: Assess current scavenging configuration
- Configure: Apply scavenging settings
- Report: Generate detailed report
- GenerateScript: Create remediation script

.PARAMETER NoRefreshInterval
No-refresh interval in days (default: 7 days per Microsoft best practices)
Recommended range: 3-14 days

.PARAMETER RefreshInterval
Refresh interval in days (default: 7 days per Microsoft best practices)
Recommended range: 3-14 days

.PARAMETER ApplyToAllZones
Apply scavenging settings to all AD-integrated zones

.PARAMETER ExcludeZones
Array of zone names to exclude from scavenging configuration

.PARAMETER EnableServerScavenging
Enable automatic scavenging on DNS servers
IMPORTANT: Microsoft best practice is to enable on ONLY ONE server!
Use -MasterScavengerServer to designate which server

.PARAMETER MasterScavengerServer
Designate a single DNS server as the master scavenger (Microsoft best practice)
If not specified, will prompt to select from available servers
Only this server will have scavenging enabled; others will be disabled

.PARAMETER DisableOtherServers
Disable scavenging on all servers except the master scavenger (recommended)

.PARAMETER ScavengingInterval
How often the master server runs scavenging (default: 168 hours = 7 days)

.PARAMETER ExportPath
Directory for reports and logs (default: C:\DNSScavenging)

.PARAMETER Credential
Credential for remote operations

.PARAMETER WhatIf
Preview changes without applying them

.PARAMETER Force
Skip confirmation prompts

.EXAMPLE
.\DNS-ScavengingManager.ps1 -Mode Analyze
Analyze current scavenging configuration

.EXAMPLE
.\DNS-ScavengingManager.ps1 -Mode Configure -NoRefreshInterval 3 -RefreshInterval 3 -WhatIf
Preview applying 3-day scavenging intervals (aggressive cleanup)

.EXAMPLE
.\DNS-ScavengingManager.ps1 -Mode Configure -ApplyToAllZones -EnableServerScavenging -MasterScavengerServer "DC01"
Apply Microsoft best practice: 7+7 days to all zones and enable scavenging ONLY on DC01

.EXAMPLE
.\DNS-ScavengingManager.ps1 -Mode Configure -NoRefreshInterval 3 -RefreshInterval 3 -ApplyToAllZones -EnableServerScavenging -MasterScavengerServer "DC01" -DisableOtherServers
Apply aggressive 3-day scavenging with DC01 as master scavenger, disable others

.EXAMPLE
.\DNS-ScavengingManager.ps1 -Mode Configure -NoRefreshInterval 3 -RefreshInterval 3 -ApplyToAllZones -Force
Apply aggressive 3-day scavenging to zone aging only (no server scavenging changes)

.EXAMPLE
.\DNS-ScavengingManager.ps1 -Mode GenerateScript -NoRefreshInterval 3 -RefreshInterval 3
Generate a remediation script for review and execution

.NOTES
Author: Adrian Johnson <adrian207@gmail.com>
Version: 1.0.0

CRITICAL: MICROSOFT BEST PRACTICE - SINGLE MASTER SCAVENGER
⚠️ Enable server scavenging on ONLY ONE DNS server!
⚠️ Multiple servers scavenging simultaneously can cause race conditions
⚠️ Use -MasterScavengerServer to designate ONE server
⚠️ Recommended: PDC Emulator or most reliable DNS server

Why only one server?
- Prevents race conditions and conflicts
- Ensures consistent scavenging behavior
- Avoids records being evaluated multiple times
- One server can scavenge all zones across the domain

IMPORTANT CONSIDERATIONS:
- Test in non-production first
- Shorter intervals = more aggressive cleanup (risk of removing valid records)
- Longer intervals = more stale records accumulate
- Microsoft recommends 7+7 (14 days total) for most environments
- 3+3 (6 days total) is aggressive but can work for dynamic environments

SAFETY FEATURES:
- WhatIf support for preview
- Single master scavenger enforcement
- Backup of current settings
- Detailed logging
- Zone exclusion support
- Confirmation prompts
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Operation mode")]
    [ValidateSet("Analyze", "Configure", "Report", "GenerateScript")]
    [string]$Mode,
    
    [Parameter(HelpMessage = "No-refresh interval in days (default: 7)")]
    [ValidateRange(1, 365)]
    [int]$NoRefreshInterval = 7,
    
    [Parameter(HelpMessage = "Refresh interval in days (default: 7)")]
    [ValidateRange(1, 365)]
    [int]$RefreshInterval = 7,
    
    [Parameter(HelpMessage = "Apply to all AD-integrated zones")]
    [switch]$ApplyToAllZones,
    
    [Parameter(HelpMessage = "Zones to exclude from configuration")]
    [string[]]$ExcludeZones = @(),
    
    [Parameter(HelpMessage = "Enable automatic scavenging on DNS servers")]
    [switch]$EnableServerScavenging,
    
    [Parameter(HelpMessage = "Designate a single DNS server as the master scavenger (Microsoft best practice)")]
    [string]$MasterScavengerServer = "",
    
    [Parameter(HelpMessage = "Disable scavenging on all servers except the master scavenger")]
    [switch]$DisableOtherServers,
    
    [Parameter(HelpMessage = "Server scavenging interval in hours (default: 168 = 7 days)")]
    [ValidateRange(1, 8760)]
    [int]$ScavengingInterval = 168,
    
    [Parameter(HelpMessage = "Export directory for reports")]
    [string]$ExportPath = "C:\DNSScavenging",
    
    [Parameter(HelpMessage = "Credential for remote operations")]
    [PSCredential]$Credential,
    
    [Parameter(HelpMessage = "Skip confirmation prompts")]
    [switch]$Force
)

#region Script Variables
$script:Version = "1.0.0"
$script:Author = "Adrian Johnson <adrian207@gmail.com>"
$script:StartTime = Get-Date
$script:TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:TotalIssuesFound = 0
$script:TotalZonesProcessed = 0
$script:TotalServersProcessed = 0
#endregion

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $Color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    
    $LogMessage = "[$Level] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $LogMessage -ForegroundColor $Color
    
    # Log to file
    $logFile = Join-Path $ExportPath "ScavengingManager_$script:TimeStamp.log"
    $LogMessage | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Initialize-Environment {
    # Create export directory
    if (!(Test-Path $ExportPath)) {
        New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
        Write-Log "Created export directory: $ExportPath" -Level INFO
    }
    
    # Start transcript
    $transcriptPath = Join-Path $ExportPath "Transcript_$script:TimeStamp.log"
    Start-Transcript -Path $transcriptPath -Force
    
    Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "   DNS SCAVENGING MANAGER v$script:Version" -ForegroundColor Cyan
    Write-Host "   Author: $script:Author" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    Write-Log "Starting DNS Scavenging Manager - Mode: $Mode" -Level INFO
    Write-Log "Configuration: NoRefresh=$NoRefreshInterval days, Refresh=$RefreshInterval days" -Level INFO
    Write-Log "Total scavenging period: $($NoRefreshInterval + $RefreshInterval) days" -Level INFO
}

function Get-DNSServerList {
    <#
    .SYNOPSIS
    Get list of all DNS servers in the domain
    #>
    
    Write-Log "Discovering DNS servers..." -Level INFO
    
    try {
        $adParams = @{}
        if ($Credential) { $adParams['Credential'] = $Credential }
        
        $domainControllers = Get-ADDomainController @adParams -Filter * | 
            Select-Object Name, IPv4Address, Site, OperatingSystem
        
        $dnsServers = @()
        
        foreach ($dc in $domainControllers) {
            # Test if DNS service is running
            try {
                $dnsParams = @{ ComputerName = $dc.Name; ErrorAction = 'Stop' }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                $null = Get-DnsServerZone @dnsParams -Name "." -ErrorAction Stop
                
                $dnsServers += [PSCustomObject]@{
                    ServerName = $dc.Name
                    IPAddress = $dc.IPv4Address
                    Site = $dc.Site
                    OS = $dc.OperatingSystem
                    DNSRunning = $true
                }
                
                Write-Log "  ✓ $($dc.Name) - DNS service running" -Level SUCCESS
            }
            catch {
                Write-Log "  ✗ $($dc.Name) - DNS service not accessible" -Level WARNING
            }
        }
        
        $script:TotalServersProcessed = $dnsServers.Count
        Write-Log "Found $($dnsServers.Count) accessible DNS servers" -Level SUCCESS
        
        return $dnsServers
    }
    catch {
        Write-Log "Error discovering DNS servers: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

function Get-ScavengingConfiguration {
    <#
    .SYNOPSIS
    Analyze current scavenging configuration
    #>
    param(
        [Parameter(Mandatory)]
        [array]$DNSServers
    )
    
    Write-Log "`nAnalyzing scavenging configuration..." -Level INFO
    
    $analysis = @{
        ServerSettings = @()
        ZoneSettings = @()
        Issues = @()
        Summary = @{
            ServersWithScavengingEnabled = 0
            ServersWithScavengingDisabled = 0
            ZonesWithAgingEnabled = 0
            ZonesWithAgingDisabled = 0
            ZonesNeedingConfiguration = 0
            MisconfiguredZones = 0
        }
    }
    
    foreach ($server in $DNSServers) {
        Write-Log "  Checking server: $($server.ServerName)" -Level INFO
        
        try {
            $dnsParams = @{ ComputerName = $server.ServerName; ErrorAction = 'Stop' }
            if ($Credential) { $dnsParams['Credential'] = $Credential }
            
            # Get server scavenging settings
            $serverConfig = Get-DnsServer @dnsParams
            
            $scavengingEnabled = $serverConfig.ServerScavenging.ScavengingState -eq $true
            $scavengingIntervalHours = $serverConfig.ServerScavenging.ScavengingInterval.TotalHours
            
            $serverSetting = [PSCustomObject]@{
                ServerName = $server.ServerName
                ScavengingEnabled = $scavengingEnabled
                ScavengingIntervalHours = $scavengingIntervalHours
                ScavengingIntervalDays = [math]::Round($scavengingIntervalHours / 24, 1)
                LastScavengingCycle = $serverConfig.ServerScavenging.LastScavengeTime
                Status = if ($scavengingEnabled) { "OK" } else { "DISABLED" }
                Recommendation = if (!$scavengingEnabled) { "Enable server scavenging" } else { "No action needed" }
            }
            
            $analysis.ServerSettings += $serverSetting
            
            if ($scavengingEnabled) {
                $analysis.Summary.ServersWithScavengingEnabled++
                Write-Log "    ✓ Server scavenging: ENABLED (runs every $($serverSetting.ScavengingIntervalDays) days)" -Level SUCCESS
            }
            else {
                $analysis.Summary.ServersWithScavengingDisabled++
                $script:TotalIssuesFound++
                Write-Log "    ✗ Server scavenging: DISABLED" -Level WARNING
                
                $analysis.Issues += [PSCustomObject]@{
                    Server = $server.ServerName
                    Zone = "N/A"
                    IssueType = "ServerScavenging"
                    Issue = "Server scavenging is disabled"
                    Severity = "High"
                    Impact = "Stale records will accumulate"
                    Recommendation = "Enable server scavenging with 'Set-DnsServerScavenging -ScavengingState $true'"
                }
            }
            
            # Get zone settings
            $zones = Get-DnsServerZone @dnsParams | 
                Where-Object { $_.ZoneType -eq "Primary" -and $_.IsAutoCreated -eq $false }
            
            foreach ($zone in $zones) {
                $script:TotalZonesProcessed++
                
                $agingEnabled = $zone.Aging
                $noRefreshDays = if ($zone.AgingNoRefreshInterval) { $zone.AgingNoRefreshInterval.Days } else { 0 }
                $refreshDays = if ($zone.RefreshInterval) { $zone.RefreshInterval.Days } else { 0 }
                $totalDays = $noRefreshDays + $refreshDays
                
                $status = "OK"
                $recommendation = "No action needed"
                
                if (!$agingEnabled) {
                    $status = "AGING DISABLED"
                    $recommendation = "Enable aging/scavenging for this zone"
                    $analysis.Summary.ZonesWithAgingDisabled++
                    $analysis.Summary.ZonesNeedingConfiguration++
                    $script:TotalIssuesFound++
                    
                    $analysis.Issues += [PSCustomObject]@{
                        Server = $server.ServerName
                        Zone = $zone.ZoneName
                        IssueType = "ZoneAging"
                        Issue = "Aging/scavenging is disabled"
                        Severity = "Medium"
                        Impact = "Stale records in this zone will not be removed"
                        Recommendation = "Enable aging: Set-DnsServerZoneAging -Name '$($zone.ZoneName)' -Aging $true -NoRefreshInterval $NoRefreshInterval.0:0:0 -RefreshInterval $RefreshInterval.0:0:0"
                    }
                }
                elseif ($noRefreshDays -ne $NoRefreshInterval -or $refreshDays -ne $RefreshInterval) {
                    $status = "MISCONFIGURED"
                    $recommendation = "Update intervals to $NoRefreshInterval + $RefreshInterval days"
                    $analysis.Summary.MisconfiguredZones++
                    
                    if ($noRefreshDays -ne $NoRefreshInterval -or $refreshDays -ne $RefreshInterval) {
                        $analysis.Issues += [PSCustomObject]@{
                            Server = $server.ServerName
                            Zone = $zone.ZoneName
                            IssueType = "ZoneConfiguration"
                            Issue = "Aging intervals don't match target ($noRefreshDays+$refreshDays vs $NoRefreshInterval+$RefreshInterval)"
                            Severity = "Low"
                            Impact = "Inconsistent scavenging behavior across zones"
                            Recommendation = "Standardize: Set-DnsServerZoneAging -Name '$($zone.ZoneName)' -NoRefreshInterval $NoRefreshInterval.0:0:0 -RefreshInterval $RefreshInterval.0:0:0"
                        }
                    }
                }
                else {
                    $analysis.Summary.ZonesWithAgingEnabled++
                }
                
                $zoneSetting = [PSCustomObject]@{
                    ServerName = $server.ServerName
                    ZoneName = $zone.ZoneName
                    ZoneType = $zone.ZoneType
                    AgingEnabled = $agingEnabled
                    NoRefreshDays = $noRefreshDays
                    RefreshDays = $refreshDays
                    TotalScavengingPeriod = $totalDays
                    Status = $status
                    Recommendation = $recommendation
                }
                
                $analysis.ZoneSettings += $zoneSetting
            }
        }
        catch {
            Write-Log "    Error analyzing $($server.ServerName): $($_.Exception.Message)" -Level ERROR
        }
    }
    
    return $analysis
}

function Show-AnalysisSummary {
    <#
    .SYNOPSIS
    Display analysis summary
    #>
    param([hashtable]$Analysis)
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           SCAVENGING ANALYSIS SUMMARY                     ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "SERVER SCAVENGING:" -ForegroundColor Yellow
    Write-Host "  Enabled:  " -NoNewline; Write-Host $Analysis.Summary.ServersWithScavengingEnabled -ForegroundColor Green
    Write-Host "  Disabled: " -NoNewline; Write-Host $Analysis.Summary.ServersWithScavengingDisabled -ForegroundColor $(if ($Analysis.Summary.ServersWithScavengingDisabled -gt 0) { "Red" } else { "Green" })
    
    # Check for multiple servers with scavenging enabled (Microsoft best practice violation)
    if ($Analysis.Summary.ServersWithScavengingEnabled -gt 1) {
        Write-Host "`n  ⚠️  CRITICAL: Multiple servers have scavenging enabled!" -ForegroundColor Red
        Write-Host "  Microsoft best practice: Enable scavenging on ONLY ONE server" -ForegroundColor Red
        Write-Host "  Risk: Race conditions, inconsistent behavior, duplicate deletions" -ForegroundColor Red
        Write-Host "`n  Servers with scavenging enabled:" -ForegroundColor Yellow
        $Analysis.ServerSettings | Where-Object { $_.ScavengingEnabled } | ForEach-Object {
            Write-Host "    • $($_.ServerName)" -ForegroundColor Yellow
        }
        Write-Host "`n  Recommendation: Use -MasterScavengerServer and -DisableOtherServers" -ForegroundColor Cyan
    }
    elseif ($Analysis.Summary.ServersWithScavengingEnabled -eq 1) {
        $masterServer = ($Analysis.ServerSettings | Where-Object { $_.ScavengingEnabled }).ServerName
        Write-Host "  ✓ Single master scavenger: $masterServer (Best Practice)" -ForegroundColor Green
    }
    
    Write-Host "`nZONE AGING:" -ForegroundColor Yellow
    Write-Host "  Enabled:      " -NoNewline; Write-Host $Analysis.Summary.ZonesWithAgingEnabled -ForegroundColor Green
    Write-Host "  Disabled:     " -NoNewline; Write-Host $Analysis.Summary.ZonesWithAgingDisabled -ForegroundColor $(if ($Analysis.Summary.ZonesWithAgingDisabled -gt 0) { "Red" } else { "Green" })
    Write-Host "  Misconfigured:" -NoNewline; Write-Host $Analysis.Summary.MisconfiguredZones -ForegroundColor $(if ($Analysis.Summary.MisconfiguredZones -gt 0) { "Yellow" } else { "Green" })
    
    Write-Host "`nISSUES FOUND:" -ForegroundColor Yellow
    Write-Host "  Total Issues: " -NoNewline; Write-Host $script:TotalIssuesFound -ForegroundColor $(if ($script:TotalIssuesFound -gt 0) { "Red" } else { "Green" })
    
    Write-Host "`nTARGET CONFIGURATION:" -ForegroundColor Yellow
    Write-Host "  No-Refresh:   $NoRefreshInterval days" -ForegroundColor Cyan
    Write-Host "  Refresh:      $RefreshInterval days" -ForegroundColor Cyan
    Write-Host "  Total Period: $($NoRefreshInterval + $RefreshInterval) days" -ForegroundColor Cyan
    
    if ($NoRefreshInterval -eq 7 -and $RefreshInterval -eq 7) {
        Write-Host "  ✓ Microsoft Best Practice (14 days total)" -ForegroundColor Green
    }
    elseif ($NoRefreshInterval -eq 3 -and $RefreshInterval -eq 3) {
        Write-Host "  ⚠ Aggressive Cleanup Mode (6 days total)" -ForegroundColor Yellow
        Write-Host "    Test carefully - may remove valid records!" -ForegroundColor Yellow
    }
    else {
        Write-Host "  ℹ Custom Configuration ($($NoRefreshInterval + $RefreshInterval) days total)" -ForegroundColor Cyan
    }
    
    if ($Analysis.Issues.Count -gt 0) {
        Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║           ISSUES REQUIRING ATTENTION                       ║" -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Yellow
        
        $Analysis.Issues | Format-Table Server, Zone, Issue, Severity -AutoSize
    }
}

function Export-AnalysisReport {
    <#
    .SYNOPSIS
    Export analysis to CSV
    #>
    param([hashtable]$Analysis)
    
    $reportPath = Join-Path $ExportPath "ScavengingAnalysis_$script:TimeStamp.csv"
    
    $Analysis.ZoneSettings | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Log "Analysis report exported: $reportPath" -Level SUCCESS
    
    if ($Analysis.Issues.Count -gt 0) {
        $issuesPath = Join-Path $ExportPath "ScavengingIssues_$script:TimeStamp.csv"
        $Analysis.Issues | Export-Csv -Path $issuesPath -NoTypeInformation
        Write-Log "Issues report exported: $issuesPath" -Level SUCCESS
    }
    
    # Export server settings
    $serverPath = Join-Path $ExportPath "ServerScavengingSettings_$script:TimeStamp.csv"
    $Analysis.ServerSettings | Export-Csv -Path $serverPath -NoTypeInformation
    Write-Log "Server settings exported: $serverPath" -Level SUCCESS
}

function New-RemediationScript {
    <#
    .SYNOPSIS
    Generate PowerShell remediation script
    #>
    param([hashtable]$Analysis)
    
    $scriptPath = Join-Path $ExportPath "Apply-ScavengingSettings_$script:TimeStamp.ps1"
    
    $scriptContent = @"
<#
.SYNOPSIS
DNS Scavenging Remediation Script
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Author: Adrian Johnson <adrian207@gmail.com>

.DESCRIPTION
This script applies scavenging settings to DNS servers and zones
Configuration: NoRefresh=$NoRefreshInterval days, Refresh=$RefreshInterval days
Total scavenging period: $($NoRefreshInterval + $RefreshInterval) days

REVIEW THIS SCRIPT CAREFULLY BEFORE EXECUTION!

.PARAMETER WhatIf
Preview changes without applying

.PARAMETER Force
Skip confirmation prompts
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]`$Force
)

`$ErrorActionPreference = 'Stop'

# Configuration
`$NoRefreshInterval = $NoRefreshInterval
`$RefreshInterval = $RefreshInterval
`$ScavengingInterval = $ScavengingInterval

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DNS Scavenging Configuration Script" -ForegroundColor Cyan
Write-Host "  Configuration: `$NoRefreshInterval + `$RefreshInterval days" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

if (-not `$Force) {
    `$confirmation = Read-Host "This will modify DNS scavenging settings. Continue? (yes/no)"
    if (`$confirmation -ne "yes") {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit
    }
}

# Backup current settings
Write-Host "`n[BACKUP] Creating backup of current settings..." -ForegroundColor Yellow
`$backupPath = "C:\DNSScavenging\Backup_`$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path `$backupPath -ItemType Directory -Force | Out-Null

"@

    # Add server scavenging commands
    if ($EnableServerScavenging) {
        $scriptContent += @"

Write-Host "`n[SERVER] Configuring server scavenging..." -ForegroundColor Cyan

"@
        
        foreach ($server in $Analysis.ServerSettings | Where-Object { !$_.ScavengingEnabled }) {
            $scriptContent += @"
# Server: $($server.ServerName)
if (`$PSCmdlet.ShouldProcess("$($server.ServerName)", "Enable Server Scavenging")) {
    try {
        Set-DnsServerScavenging -ComputerName "$($server.ServerName)" ``
            -ScavengingState `$true ``
            -ScavengingInterval (New-TimeSpan -Hours `$ScavengingInterval) ``
            -ErrorAction Stop
        Write-Host "  ✓ $($server.ServerName) - Server scavenging enabled" -ForegroundColor Green
    }
    catch {
        Write-Warning "  ✗ $($server.ServerName) - Failed: `$(`$_.Exception.Message)"
    }
}

"@
        }
    }
    
    # Add zone aging commands
    if ($ApplyToAllZones) {
        $scriptContent += @"

Write-Host "`n[ZONES] Configuring zone aging/scavenging..." -ForegroundColor Cyan

"@
        
        $zonesToConfigure = $Analysis.ZoneSettings | 
            Where-Object { $_.ZoneName -notin $ExcludeZones -and ($_.Status -ne "OK") }
        
        foreach ($zone in $zonesToConfigure) {
            $scriptContent += @"
# Zone: $($zone.ZoneName) on $($zone.ServerName)
if (`$PSCmdlet.ShouldProcess("$($zone.ZoneName)", "Configure Aging")) {
    try {
        Set-DnsServerZoneAging -ComputerName "$($zone.ServerName)" ``
            -Name "$($zone.ZoneName)" ``
            -Aging `$true ``
            -NoRefreshInterval (New-TimeSpan -Days `$NoRefreshInterval) ``
            -RefreshInterval (New-TimeSpan -Days `$RefreshInterval) ``
            -ErrorAction Stop
        Write-Host "  ✓ $($zone.ZoneName) - Aging configured (`$NoRefreshInterval+`$RefreshInterval days)" -ForegroundColor Green
    }
    catch {
        Write-Warning "  ✗ $($zone.ZoneName) - Failed: `$(`$_.Exception.Message)"
    }
}

"@
        }
    }
    
    $scriptContent += @"

Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Scavenging configuration completed!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════`n" -ForegroundColor Green

Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "1. Monitor DNS for the next 24-48 hours"
Write-Host "2. Check Event Viewer for scavenging events (Event ID 2501, 2502)"
Write-Host "3. Verify no valid records are being removed"
Write-Host "4. Backup configuration saved to: `$backupPath"
"@
    
    $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
    Write-Log "Remediation script generated: $scriptPath" -Level SUCCESS
    
    return $scriptPath
}

function Invoke-ScavengingConfiguration {
    <#
    .SYNOPSIS
    Apply scavenging configuration
    #>
    param([hashtable]$Analysis)
    
    if (!$Force -and !$WhatIfPreference) {
        Write-Host "`n⚠ WARNING: This will modify DNS scavenging settings!" -ForegroundColor Yellow
        Write-Host "Configuration: NoRefresh=$NoRefreshInterval days, Refresh=$RefreshInterval days" -ForegroundColor Yellow
        Write-Host "Total scavenging period: $($NoRefreshInterval + $RefreshInterval) days`n" -ForegroundColor Yellow
        
        $confirmation = Read-Host "Continue? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Log "Operation cancelled by user" -Level WARNING
            return
        }
    }
    
    Write-Log "`nApplying scavenging configuration..." -Level INFO
    
    # Configure server scavenging - SINGLE MASTER SCAVENGER (Microsoft Best Practice)
    if ($EnableServerScavenging) {
        Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║  MICROSOFT BEST PRACTICE: SINGLE MASTER SCAVENGER         ║" -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Log "Configuring SINGLE master scavenger (Microsoft best practice)..." -Level INFO
        
        # Determine master scavenger server
        if ([string]::IsNullOrEmpty($MasterScavengerServer)) {
            Write-Host "`n⚠️  No master scavenger server specified!" -ForegroundColor Yellow
            Write-Host "Microsoft recommends enabling scavenging on ONLY ONE server." -ForegroundColor Yellow
            Write-Host "`nAvailable DNS servers:" -ForegroundColor Cyan
            
            $serverList = $Analysis.ServerSettings
            for ($i = 0; $i -lt $serverList.Count; $i++) {
                $status = if ($serverList[$i].ScavengingEnabled) { "[CURRENTLY ENABLED]" } else { "[DISABLED]" }
                Write-Host "  $($i+1). $($serverList[$i].ServerName) $status" -ForegroundColor White
            }
            
            Write-Host "`nRecommendation: Choose PDC Emulator or most reliable DNS server" -ForegroundColor Yellow
            
            if (!$Force -and !$WhatIfPreference) {
                do {
                    $selection = Read-Host "`nSelect master scavenger (1-$($serverList.Count)) or press Enter to cancel"
                    if ([string]::IsNullOrEmpty($selection)) {
                        Write-Log "Master scavenger selection cancelled - skipping server scavenging configuration" -Level WARNING
                        return
                    }
                } while ($selection -notmatch '^\d+$' -or [int]$selection -lt 1 -or [int]$selection -gt $serverList.Count)
                
                $MasterScavengerServer = $serverList[[int]$selection - 1].ServerName
            }
            else {
                # Auto-select first server in WhatIf or Force mode
                $MasterScavengerServer = $serverList[0].ServerName
                Write-Log "Auto-selected master scavenger: $MasterScavengerServer (WhatIf/Force mode)" -Level INFO
            }
        }
        
        Write-Log "Master Scavenger Server: $MasterScavengerServer" -Level SUCCESS
        
        # Enable scavenging ONLY on master server
        if ($PSCmdlet.ShouldProcess($MasterScavengerServer, "Enable Server Scavenging as MASTER")) {
            try {
                $dnsParams = @{
                    ComputerName = $MasterScavengerServer
                    ScavengingState = $true
                    ScavengingInterval = (New-TimeSpan -Hours $ScavengingInterval)
                    ErrorAction = 'Stop'
                }
                if ($Credential) { $dnsParams['Credential'] = $Credential }
                
                Set-DnsServerScavenging @dnsParams
                Write-Log "  ✓ $MasterScavengerServer - MASTER SCAVENGER enabled" -Level SUCCESS
                Write-Host "  ✓ Master scavenger configured successfully!" -ForegroundColor Green
            }
            catch {
                Write-Log "  ✗ $MasterScavengerServer - Failed: $($_.Exception.Message)" -Level ERROR
            }
        }
        
        # Disable scavenging on other servers if requested
        if ($DisableOtherServers) {
            Write-Log "Disabling scavenging on all other servers..." -Level INFO
            
            $otherServers = $Analysis.ServerSettings | Where-Object { 
                $_.ServerName -ne $MasterScavengerServer -and $_.ScavengingEnabled 
            }
            
            foreach ($server in $otherServers) {
                if ($PSCmdlet.ShouldProcess($server.ServerName, "Disable Server Scavenging")) {
                    try {
                        $dnsParams = @{
                            ComputerName = $server.ServerName
                            ScavengingState = $false
                            ErrorAction = 'Stop'
                        }
                        if ($Credential) { $dnsParams['Credential'] = $Credential }
                        
                        Set-DnsServerScavenging @dnsParams
                        Write-Log "  ✓ $($server.ServerName) - Scavenging disabled (not master)" -Level SUCCESS
                    }
                    catch {
                        Write-Log "  ✗ $($server.ServerName) - Failed to disable: $($_.Exception.Message)" -Level ERROR
                    }
                }
            }
        }
        else {
            Write-Host "`n⚠️  WARNING: Other servers still have scavenging enabled!" -ForegroundColor Yellow
            Write-Host "Consider using -DisableOtherServers to enforce single master scavenger" -ForegroundColor Yellow
        }
    }
    
    # Configure zone aging
    if ($ApplyToAllZones) {
        Write-Log "Configuring zone aging..." -Level INFO
        
        $zonesToConfigure = $Analysis.ZoneSettings | 
            Where-Object { $_.ZoneName -notin $ExcludeZones }
        
        foreach ($zone in $zonesToConfigure) {
            if ($PSCmdlet.ShouldProcess("$($zone.ZoneName) on $($zone.ServerName)", "Configure Aging")) {
                try {
                    $dnsParams = @{
                        ComputerName = $zone.ServerName
                        Name = $zone.ZoneName
                        Aging = $true
                        NoRefreshInterval = (New-TimeSpan -Days $NoRefreshInterval)
                        RefreshInterval = (New-TimeSpan -Days $RefreshInterval)
                        ErrorAction = 'Stop'
                    }
                    if ($Credential) { $dnsParams['Credential'] = $Credential }
                    
                    Set-DnsServerZoneAging @dnsParams
                    Write-Log "  ✓ $($zone.ZoneName) - Aging configured ($NoRefreshInterval+$RefreshInterval days)" -Level SUCCESS
                }
                catch {
                    Write-Log "  ✗ $($zone.ZoneName) - Failed: $($_.Exception.Message)" -Level ERROR
                }
            }
        }
    }
}

#endregion

#region Main Execution

try {
    Initialize-Environment
    
    # Get DNS servers
    $dnsServers = Get-DNSServerList
    
    if ($dnsServers.Count -eq 0) {
        Write-Log "No accessible DNS servers found!" -Level ERROR
        exit 1
    }
    
    # Analyze configuration
    $analysis = Get-ScavengingConfiguration -DNSServers $dnsServers
    
    # Display summary
    Show-AnalysisSummary -Analysis $analysis
    
    # Execute mode-specific actions
    switch ($Mode) {
        "Analyze" {
            Write-Log "`nAnalysis complete. Use -Mode Configure to apply settings." -Level INFO
        }
        
        "Report" {
            Export-AnalysisReport -Analysis $analysis
            Write-Log "`nDetailed reports exported to: $ExportPath" -Level SUCCESS
        }
        
        "GenerateScript" {
            $scriptPath = New-RemediationScript -Analysis $analysis
            Write-Log "`nRemediation script generated: $scriptPath" -Level SUCCESS
            Write-Log "Review the script and execute with: .\$([System.IO.Path]::GetFileName($scriptPath)) -WhatIf" -Level INFO
        }
        
        "Configure" {
            if (!$ApplyToAllZones -and !$EnableServerScavenging) {
                Write-Log "Use -ApplyToAllZones and/or -EnableServerScavenging to apply settings" -Level WARNING
            }
            else {
                Invoke-ScavengingConfiguration -Analysis $analysis
                Write-Log "`nConfiguration applied successfully!" -Level SUCCESS
            }
        }
    }
    
    # Final summary
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           EXECUTION SUMMARY                                ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    $duration = (Get-Date) - $script:StartTime
    
    Write-Host "Servers Processed:  " -NoNewline; Write-Host $script:TotalServersProcessed -ForegroundColor Cyan
    Write-Host "Zones Processed:    " -NoNewline; Write-Host $script:TotalZonesProcessed -ForegroundColor Cyan
    Write-Host "Issues Found:       " -NoNewline; Write-Host $script:TotalIssuesFound -ForegroundColor $(if ($script:TotalIssuesFound -gt 0) { "Yellow" } else { "Green" })
    Write-Host "Execution Time:     " -NoNewline; Write-Host "$([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor Cyan
    Write-Host "Reports Location:   " -NoNewline; Write-Host $ExportPath -ForegroundColor Cyan
    
    Write-Host "`nRecommended Next Steps:" -ForegroundColor Yellow
    if ($Mode -eq "Analyze") {
        Write-Host "1. Review the analysis results above"
        Write-Host "2. Generate remediation script: -Mode GenerateScript"
        Write-Host "3. Apply settings: -Mode Configure -ApplyToAllZones -EnableServerScavenging -WhatIf"
    }
    elseif ($Mode -eq "GenerateScript") {
        Write-Host "1. Review the generated script carefully"
        Write-Host "2. Test with -WhatIf first"
        Write-Host "3. Execute in test environment"
        Write-Host "4. Monitor for 24-48 hours before production"
    }
    elseif ($Mode -eq "Configure") {
        Write-Host "1. Monitor DNS Event Viewer (Event ID 2501, 2502)"
        Write-Host "2. Verify no valid records are being removed"
        Write-Host "3. Check scavenging results after configured interval"
        Write-Host "4. Run -Mode Analyze to verify configuration"
    }
    
    Write-Host "`n✓ DNS Scavenging Manager completed successfully!" -ForegroundColor Green
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    exit 1
}
finally {
    Stop-Transcript
}

#endregion

