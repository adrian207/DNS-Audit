################################################################################
# DNS Master Audit Script - INDEPENDENT EDITION
# Author: Adrian Johnson <adrian207@gmail.com>
# Created: 2025
# Version: 2.0 - Fully Self-Contained
# 
# Description: All-in-one DNS auditing tool - NO EXTERNAL DEPENDENCIES
#              1. DNS Inventory (server discovery)
#              2. DNS Health Check (service testing)
#              3. DNS Record Export (complete inventory)
#              4. DNS Site Audit (mismatch detection) - EMBEDDED
#              5. Complete Audit (all of the above)
# 
# Features: ALL functionality in ONE standalone script
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

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Inventory
Discovers all DNS servers in the domain

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode HealthCheck
Tests DNS service health on all domain controllers

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode RecordExport -ZoneFilter @("contoso.com")
Exports all records from contoso.com zone

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode SiteAudit -EnableAllFeatures
Runs comprehensive site mismatch audit with all features

.EXAMPLE
.\DNS-MasterAudit.ps1 -Mode Complete
Runs complete DNS audit: Inventory → Health → Export → Site Analysis

.NOTES
Version: 2.0 - Independent Edition (NO external dependencies!)
Author: Adrian Johnson <adrian207@gmail.com>
Self-Contained: All functionality embedded in this single script
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Operation mode")]
    [ValidateSet("Inventory", "HealthCheck", "RecordExport", "SiteAudit", "Complete")]
    [string]$Mode,
    
    [Parameter(HelpMessage="Export directory for all reports")]
    [string]$ExportPath = "C:\DNSAudit",
    
    [Parameter(HelpMessage="Filter specific zones")]
    [string[]]$ZoneFilter = @(),
    
    [Parameter(HelpMessage="Enable all advanced features for SiteAudit mode")]
    [switch]$EnableAllFeatures,
    
    [Parameter(HelpMessage="Credential for remote operations")]
    [PSCredential]$Credential,
    
    [Parameter(HelpMessage="Generate HTML report")]
    [switch]$GenerateHTML,
    
    [Parameter(HelpMessage="Send email notification")]
    [switch]$EnableEmailNotification,
    
    [Parameter(HelpMessage="SMTP server for email")]
    [string]$SMTPServer,
    
    [Parameter(HelpMessage="Email from address")]
    [string]$EmailFrom,
    
    [Parameter(HelpMessage="Email recipients")]
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
    
    $script:LogPath = Join-Path $Path "MasterAudit_${script:TimeStamp}.log"
    Start-Transcript -Path $script:LogPath -Append
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   DNS MASTER AUDIT - INDEPENDENT EDITION v$($script:Version)   ║" -ForegroundColor Cyan
    Write-Host "║   ✅ NO EXTERNAL DEPENDENCIES - Fully Self-Contained       ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

function Stop-MasterLogging {
    Stop-Transcript
    Write-Host "`nLog file: $script:LogPath" -ForegroundColor Green
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
        "ERROR"   { "Red" }
        "DEBUG"   { "Gray" }
        default   { "White" }
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
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 1: DNS SERVER INVENTORY                  │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    
    Write-AuditLog "Starting DNS server inventory..." -Level INFO
    
    try {
        $DomainControllers = Get-ADDomainController -Filter * | 
                            Select-Object Name, IPv4Address, Site, OperatingSystem
        
        Write-AuditLog "Found $($DomainControllers.Count) domain controllers" -Level SUCCESS
        
        $DNSServers = @()
        $index = 0
        
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
                
                $Zones = Get-DnsServerZone -ComputerName $DC.Name -ErrorAction SilentlyContinue
                
                $ServerInfo = [PSCustomObject]@{
                    ServerName = $DC.Name
                    IPAddress = $DC.IPv4Address
                    Site = $DC.Site
                    DNSServiceStatus = $DNSService.Status
                    ZoneCount = $Zones.Count
                    PrimaryZones = ($Zones | Where-Object {$_.ZoneType -eq "Primary"}).Count
                    SecondaryZones = ($Zones | Where-Object {$_.ZoneType -eq "Secondary"}).Count
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
        
        Write-Progress -Activity "Inventorying DNS Servers" -Completed
        
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
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 2: DNS HEALTH CHECK                      │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    
    Write-AuditLog "Starting DNS health check..." -Level INFO
    
    try {
        $DCs = Get-ADDomainController -Filter * | Select-Object Name
        $AllHealthResults = @()
        $index = 0
        
        foreach ($DC in $DCs) {
            $index++
            Write-Progress -Activity "Health Checking DNS Services" `
                          -Status "Testing $($DC.Name) ($index of $($DCs.Count))" `
                          -PercentComplete (($index / $DCs.Count) * 100)
            
            Write-AuditLog "Testing DNS on $($DC.Name)..." -Level INFO
            
            $HealthTests = @()
            
            # Test 1: DNS Service Status
            try {
                $DNSService = Get-Service -ComputerName $DC.Name -Name "DNS" -ErrorAction Stop
                $HealthTests += [PSCustomObject]@{
                    DCName = $DC.Name
                    TestName = "DNS Service Status"
                    Status = if ($DNSService.Status -eq "Running") { "PASS" } else { "FAIL" }
                    Details = "Service: $($DNSService.Status)"
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
            try {
                $Domain = (Get-ADDomain).DNSRoot
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
            
            $AllHealthResults += $HealthTests
            
            $PassCount = ($HealthTests | Where-Object {$_.Status -eq "PASS"}).Count
            $TotalTests = $HealthTests.Count
            Write-AuditLog "  $($DC.Name): $PassCount/$TotalTests tests passed" -Level $(if($PassCount -eq $TotalTests){"SUCCESS"}else{"WARNING"})
        }
        
        Write-Progress -Activity "Health Checking DNS Services" -Completed
        
        $OutputFile = Join-Path $ExportPath "DNS_HealthCheck_${script:TimeStamp}.csv"
        $AllHealthResults | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-AuditLog "Exported health check to: $OutputFile" -Level SUCCESS
        
        $TotalTests = $AllHealthResults.Count
        $PassedTests = ($AllHealthResults | Where-Object {$_.Status -eq "PASS"}).Count
        
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
    #>
    param(
        [string[]]$Zones = @()
    )
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 3: DNS RECORD EXPORT                     │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    
    Write-AuditLog "Starting DNS record export..." -Level INFO
    
    try {
        $DCs = Get-ADDomainController -Filter * | Select-Object -First 1 Name
        $DCName = $DCs[0].Name
        
        Write-AuditLog "Using DNS server: $DCName" -Level INFO
        
        $AllZones = Get-DnsServerZone -ComputerName $DCName
        
        if ($Zones.Count -gt 0) {
            $AllZones = $AllZones | Where-Object { $_.ZoneName -in $Zones }
            Write-AuditLog "Filtering to $($Zones.Count) specified zones" -Level INFO
        }
        
        Write-AuditLog "Exporting records from $($AllZones.Count) zones..." -Level INFO
        
        $AllRecords = @()
        $RecordTypes = @("A", "AAAA", "CNAME", "MX", "PTR", "SRV", "TXT", "NS")
        $zoneIndex = 0
        
        foreach ($Zone in $AllZones) {
            $zoneIndex++
            Write-Progress -Activity "Exporting DNS Records" `
                          -Status "Processing $($Zone.ZoneName) ($zoneIndex of $($AllZones.Count))" `
                          -PercentComplete (($zoneIndex / $AllZones.Count) * 100)
            
            try {
                $Records = Get-DnsServerResourceRecord -ComputerName $DCName `
                                                      -ZoneName $Zone.ZoneName `
                                                      -ErrorAction Stop
                
                foreach ($Record in $Records) {
                    if ($Record.RecordType -in $RecordTypes) {
                        $RecordData = switch ($Record.RecordType) {
                            "A"     { $Record.RecordData.IPv4Address.ToString() }
                            "AAAA"  { $Record.RecordData.IPv6Address.ToString() }
                            "CNAME" { $Record.RecordData.HostNameAlias }
                            "MX"    { "$($Record.RecordData.Preference) $($Record.RecordData.MailExchange)" }
                            "PTR"   { $Record.RecordData.PtrDomainName }
                            "SRV"   { "$($Record.RecordData.Priority) $($Record.RecordData.Weight) $($Record.RecordData.Port) $($Record.RecordData.DomainName)" }
                            "TXT"   { $Record.RecordData.DescriptiveText -join " " }
                            "NS"    { $Record.RecordData.NameServer }
                            default { "N/A" }
                        }
                        
                        $AllRecords += [PSCustomObject]@{
                            ZoneName = $Zone.ZoneName
                            RecordName = $Record.HostName
                            RecordType = $Record.RecordType
                            RecordData = $RecordData
                            TTL = $Record.TimeToLive.TotalSeconds
                            IsStatic = ($Record.TimeToLive.TotalSeconds -eq 0)
                            Timestamp = $Record.Timestamp
                            ExportDate = Get-Date
                        }
                    }
                }
                
                Write-AuditLog "  $($Zone.ZoneName): Exported $($Records.Count) records" -Level SUCCESS
            }
            catch {
                Write-AuditLog "  $($Zone.ZoneName): Failed - $($_.Exception.Message)" -Level WARNING
            }
        }
        
        Write-Progress -Activity "Exporting DNS Records" -Completed
        
        $OutputFile = Join-Path $ExportPath "DNS_RecordExport_${script:TimeStamp}.csv"
        $AllRecords | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-AuditLog "Exported $($AllRecords.Count) records to: $OutputFile" -Level SUCCESS
        
        return @{
            Records = $AllRecords
            ExportFile = $OutputFile
            Summary = "Exported $($AllRecords.Count) records from $($AllZones.Count) zones"
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

function Get-ADSiteSubnets {
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
                } else {
                    0
                }
            } catch {
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
                $SubnetParts = $SubnetString.Split('/')
                $NetworkIP = [System.Net.IPAddress]::Parse($SubnetParts[0])
                $PrefixLength = [int]$SubnetParts[1]
                
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
                $script:SkippedSubnets += $SubnetString
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
        {$_ -ge 98} { "Excellent" }
        {$_ -ge 95} { "Good" }
        {$_ -ge 90} { "Fair" }
        {$_ -ge 80} { "Poor" }
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
        [switch]$AllFeatures
    )
    
    Write-Host "`n┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  MODE 4: DNS SITE MISMATCH AUDIT (EMBEDDED)   │" -ForegroundColor Cyan
    Write-Host "│  ✅ Self-Contained - No Dependencies!         │" -ForegroundColor Green
    Write-Host "└─────────────────────────────────────────────────┘`n" -ForegroundColor Cyan
    
    Write-AuditLog "Starting embedded DNS site mismatch audit..." -Level INFO
    
    try {
        # Get AD site information
        $SiteData = Get-ADSiteSubnets -Credential $Credential
        if (!$SiteData) {
            throw "Cannot retrieve AD site information"
        }
        
        # Get domain controllers
        $DCs = Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, Site
        Write-AuditLog "Found $($DCs.Count) domain controllers" -Level SUCCESS
        
        $AllMismatches = @()
        $TotalRecordsScanned = 0
        $dcIndex = 0
        
        foreach ($DC in $DCs) {
            $dcIndex++
            Write-Progress -Activity "Scanning Domain Controllers for Site Mismatches" `
                          -Status "Processing $($DC.Name) ($dcIndex of $($DCs.Count))" `
                          -PercentComplete (($dcIndex / $DCs.Count) * 100)
            
            Write-AuditLog "Scanning DNS on $($DC.Name) (Site: $($DC.Site))..." -Level INFO
            
            try {
                # Get zones
                $Zones = Get-DnsServerZone -ComputerName $DC.Name
                
                if ($ZoneFilter.Count -gt 0) {
                    $Zones = $Zones | Where-Object { $_.ZoneName -in $ZoneFilter }
                }
                
                foreach ($Zone in $Zones) {
                    Write-Verbose "Processing zone: $($Zone.ZoneName)"
                    
                    try {
                        $Records = Get-DnsServerResourceRecord -ComputerName $DC.Name `
                                                              -ZoneName $Zone.ZoneName `
                                                              -RRType "A", "AAAA" `
                                                              -ErrorAction Stop
                        
                        foreach ($Record in $Records) {
                            $TotalRecordsScanned++
                            
                            # Get IP address
                            $IPAddress = if ($Record.RecordType -eq "A") { 
                                $Record.RecordData.IPv4Address.ToString() 
                            } elseif ($Record.RecordType -eq "AAAA") {
                                $Record.RecordData.IPv6Address.ToString() 
                            } else {
                                continue
                            }
                            
                            # Determine site for IP
                            $IPSite = Get-IPAddressSite -IPAddress $IPAddress -SiteSubnetMap $SiteData.SiteSubnetMap
                            
                            # Check for mismatch
                            if ($IPSite.SiteName -ne $DC.Site -and $IPSite.SiteName -ne "Unknown") {
                                $IsStatic = ($Record.TimeToLive.TotalSeconds -eq 0)
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
        
        Write-Progress -Activity "Scanning Domain Controllers" -Completed
        
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
            CriticalSeverity = ($UniqueMismatches | Where-Object Severity -eq 'Critical').Count
            HighSeverity = ($UniqueMismatches | Where-Object Severity -eq 'High').Count
            MediumSeverity = ($UniqueMismatches | Where-Object Severity -eq 'Medium').Count
            LowSeverity = ($UniqueMismatches | Where-Object Severity -eq 'Low').Count
            DCsScanned = $DCs.Count
            AuditDate = Get-Date
        }
        
        $StatsFile = Join-Path $ExportPath "DNS_Audit_Statistics_${script:TimeStamp}.csv"
        $Statistics | Export-Csv -Path $StatsFile -NoTypeInformation
        
        # Zone health scores if requested
        $ZoneHealthScores = @()
        if ($AllFeatures) {
            Write-AuditLog "Calculating zone health scores..." -Level INFO
            $ZoneStats = $UniqueMismatches | Group-Object ZoneName
            foreach ($zoneStat in $ZoneStats) {
                $zoneRecords = $AllMismatches | Where-Object {$_.ZoneName -eq $zoneStat.Name}
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
    
    Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                COMPLETE AUDIT MODE                    ║" -ForegroundColor Green
    Write-Host "║  Running All Modes: Inventory → Health → Export →    ║" -ForegroundColor Green
    Write-Host "║                   Site Audit                          ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    $CompleteStart = Get-Date
    
    # Mode 1: Inventory
    try {
        $script:AllResults.Inventory = Start-DNSInventory
    }
    catch {
        Write-AuditLog "Inventory phase failed, continuing..." -Level WARNING
    }
    
    # Mode 2: Health Check
    try {
        $script:AllResults.HealthCheck = Start-DNSHealthCheck
    }
    catch {
        Write-AuditLog "Health check phase failed, continuing..." -Level WARNING
    }
    
    # Mode 3: Record Export
    try {
        $script:AllResults.RecordExport = Start-DNSRecordExport -Zones $ZoneFilter
    }
    catch {
        Write-AuditLog "Record export phase failed, continuing..." -Level WARNING
    }
    
    # Mode 4: Site Audit
    try {
        $script:AllResults.SiteAudit = Start-DNSSiteAudit -AllFeatures:$EnableAllFeatures
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
        "Inventory"    { Start-DNSInventory }
        "HealthCheck"  { Start-DNSHealthCheck }
        "RecordExport" { Start-DNSRecordExport -Zones $ZoneFilter }
        "SiteAudit"    { Start-DNSSiteAudit -AllFeatures:$EnableAllFeatures }
        "Complete"     { Start-CompleteAudit }
    }
    
    # Email notification
    if ($EnableEmailNotification -and $SMTPServer -and $EmailFrom -and $EmailTo) {
        Write-AuditLog "Sending email notification..." -Level INFO
        
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
            Send-MailMessage -SmtpServer $SMTPServer `
                           -From $EmailFrom `
                           -To $EmailTo `
                           -Subject "DNS Master Audit Complete: $Mode" `
                           -Body $EmailBody `
                           -ErrorAction Stop
            Write-AuditLog "Email sent successfully" -Level SUCCESS
        }
        catch {
            Write-AuditLog "Email failed: $($_.Exception.Message)" -Level WARNING
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
}
catch {
    Write-AuditLog "FATAL ERROR: $($_.Exception.Message)" -Level ERROR
    Write-AuditLog $_.ScriptStackTrace -Level ERROR
    throw
}
finally {
    Stop-MasterLogging
}

#endregion
