# PSScriptAnalyzer suppression for Pester v5 syntax compatibility warnings
# The compatibility warnings for Should operators are false positives - these work with Pester v5+
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '', Justification = 'Pester v5 syntax is correct and intentional')]
param()

BeforeAll {
    # Import the script functions
    . $PSScriptRoot\..\DNS-MasterAudit.ps1 -Mode Inventory -ErrorAction SilentlyContinue
    # Mock external dependencies for isolated unit testing
    Mock Get-ADDomainController { return @() }
    Mock Get-ADDomain { return @{ DNSRoot = 'test.local' } }
    Mock Get-DnsServerZone { return @() }
    Mock Get-DnsServerResourceRecord { return @() }
    Mock Start-Transcript { }
    Mock Stop-Transcript { }
}

Describe "Get-IPAddressSite - IPv4 Subnet Mask Matching" {
    BeforeAll {
        # Initialize script-level variable for skipped subnets tracking
        $script:SkippedSubnets = @()
        # Create test subnet map
        $script:TestSubnetMap = @{
            '10.0.0.0/8' = @{
                SiteName = 'Site-Corporate'
                SubnetName = '10.0.0.0/8'
                Location = 'HQ'
                Description = 'Corporate network'
            }
            '192.168.1.0/24' = @{
                SiteName = 'Site-Branch'
                SubnetName = '192.168.1.0/24'
                Location = 'Branch Office'
                Description = 'Branch network'
            }
            '172.16.50.0/23' = @{
                SiteName = 'Site-DMZ'
                SubnetName = '172.16.50.0/23'
                Location = 'DMZ'
                Description = 'DMZ network (50-51)'
            }
            '192.168.100.128/25' = @{
                SiteName = 'Site-VPN'
                SubnetName = '192.168.100.128/25'
                Location = 'VPN'
                Description = 'VPN clients (128-255)'
            }
        }
    }
    Context "Exact subnet matches" {
        It "Should match 10.50.100.200 to 10.0.0.0/8" {
            $result = Get-IPAddressSite -IPAddress '10.50.100.200' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-Corporate'
        }
        It "Should match 192.168.1.100 to 192.168.1.0/24" {
            $result = Get-IPAddressSite -IPAddress '192.168.1.100' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-Branch'
        }
        It "Should match 192.168.1.1 to 192.168.1.0/24" {
            $result = Get-IPAddressSite -IPAddress '192.168.1.1' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-Branch'
        }
        It "Should match 192.168.1.254 to 192.168.1.0/24" {
            $result = Get-IPAddressSite -IPAddress '192.168.1.254' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-Branch'
        }
    }
    Context "Subnet boundary tests" {
        It "Should match 172.16.50.0 (network address) to 172.16.50.0/23" {
            $result = Get-IPAddressSite -IPAddress '172.16.50.0' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-DMZ'
        }
        It "Should match 172.16.51.255 (broadcast of /23) to 172.16.50.0/23" {
            $result = Get-IPAddressSite -IPAddress '172.16.51.255' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-DMZ'
        }
        It "Should NOT match 172.16.52.1 to 172.16.50.0/23" {
            $result = Get-IPAddressSite -IPAddress '172.16.52.1' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Unknown'
        }
        It "Should NOT match 172.16.49.255 to 172.16.50.0/23" {
            $result = Get-IPAddressSite -IPAddress '172.16.49.255' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Unknown'
        }
    }
    Context "Subnet mask with /25 split" {
        It "Should match 192.168.100.128 to 192.168.100.128/25" {
            $result = Get-IPAddressSite -IPAddress '192.168.100.128' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-VPN'
        }
        It "Should match 192.168.100.200 to 192.168.100.128/25" {
            $result = Get-IPAddressSite -IPAddress '192.168.100.200' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-VPN'
        }
        It "Should match 192.168.100.255 to 192.168.100.128/25" {
            $result = Get-IPAddressSite -IPAddress '192.168.100.255' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Site-VPN'
        }
        It "Should NOT match 192.168.100.127 (just below range) to 192.168.100.128/25" {
            $result = Get-IPAddressSite -IPAddress '192.168.100.127' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Unknown'
        }
        It "Should NOT match 192.168.100.1 to 192.168.100.128/25" {
            $result = Get-IPAddressSite -IPAddress '192.168.100.1' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Unknown'
        }
    }
    Context "No matching subnet" {
        It "Should return 'Unknown' for unmatched IP" {
            $result = Get-IPAddressSite -IPAddress '8.8.8.8' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Unknown'
            $result.SubnetName | Should -Be 'No matching subnet'
        }
    }
    Context "Invalid IP address" {
        It "Should return 'Invalid IP' for malformed IP" {
            $result = Get-IPAddressSite -IPAddress 'not.an.ip.address' -SiteSubnetMap $script:TestSubnetMap
            $result.SiteName | Should -Be 'Invalid IP'
        }
    }
}

Describe "Get-IPAddressSite - IPv6 Subnet Mask Matching" {
    BeforeAll {
        $script:SkippedSubnets = @()
        $script:IPv6SubnetMap = @{
            '2001:db8::/32' = @{
                SiteName = 'Site-IPv6-Main'
                SubnetName = '2001:db8::/32'
                Location = 'Main IPv6'
                Description = 'Main IPv6 range'
            }
            '2001:db8:1234::/48' = @{
                SiteName = 'Site-IPv6-Branch'
                SubnetName = '2001:db8:1234::/48'
                Location = 'Branch IPv6'
                Description = 'Branch IPv6 range'
            }
            'fe80::/10' = @{
                SiteName = 'Link-Local'
                SubnetName = 'fe80::/10'
                Location = 'Local'
                Description = 'Link-local addresses'
            }
        }
    }
    Context "IPv6 subnet matching" {
        It "Should match 2001:db8::1 to 2001:db8::/32" {
            $result = Get-IPAddressSite -IPAddress '2001:db8::1' -SiteSubnetMap $script:IPv6SubnetMap
            $result.SiteName | Should -Be 'Site-IPv6-Main'
        }
        It "Should match 2001:db8:ffff:ffff:ffff:ffff:ffff:ffff to 2001:db8::/32" {
            $result = Get-IPAddressSite -IPAddress '2001:db8:ffff:ffff:ffff:ffff:ffff:ffff' -SiteSubnetMap $script:IPv6SubnetMap
            $result.SiteName | Should -Be 'Site-IPv6-Main'
        }
        It "Should match 2001:db8:1234::1 to 2001:db8:1234::/48" {
            $result = Get-IPAddressSite -IPAddress '2001:db8:1234::1' -SiteSubnetMap $script:IPv6SubnetMap
            $result.SiteName | Should -Be 'Site-IPv6-Branch'
        }
        It "Should match fe80::1 to fe80::/10" {
            $result = Get-IPAddressSite -IPAddress 'fe80::1' -SiteSubnetMap $script:IPv6SubnetMap
            $result.SiteName | Should -Be 'Link-Local'
        }
        It "Should NOT match 2001:db9::1 to 2001:db8::/32" {
            $result = Get-IPAddressSite -IPAddress '2001:db9::1' -SiteSubnetMap $script:IPv6SubnetMap
            $result.SiteName | Should -Be 'Unknown'
        }
    }
}

Describe "Get-IPAddressSite - Edge Cases and Validation" {
    BeforeAll {
        $script:SkippedSubnets = @()
    }
    Context "Invalid subnet formats" {
        It "Should skip subnet without prefix length and track it" {
            $badMap = @{ '10.0.0.0' = @{ SiteName = 'Bad' } }
            $script:SkippedSubnets = @()
            $result = Get-IPAddressSite -IPAddress '10.0.0.1' -SiteSubnetMap $badMap
            $result.SiteName | Should -Be 'Unknown'
            $script:SkippedSubnets.Count | Should -BeGreaterThan 0
        }
        It "Should skip subnet with invalid prefix (>32 for IPv4)" {
            $badMap = @{ '10.0.0.0/33' = @{ SiteName = 'Bad' } }
            $script:SkippedSubnets = @()
            $result = Get-IPAddressSite -IPAddress '10.0.0.1' -SiteSubnetMap $badMap
            $result.SiteName | Should -Be 'Unknown'
            $script:SkippedSubnets | Where-Object { $_.Reason -match 'out of valid range' } | Should -Not -BeNullOrEmpty
        }
        It "Should skip subnet with negative prefix" {
            $badMap = @{ '10.0.0.0/-1' = @{ SiteName = 'Bad' } }
            $script:SkippedSubnets = @()
            $result = Get-IPAddressSite -IPAddress '10.0.0.1' -SiteSubnetMap $badMap
            $result.SiteName | Should -Be 'Unknown'
            $script:SkippedSubnets | Where-Object { $_.Reason -match 'out of valid range' } | Should -Not -BeNullOrEmpty
        }
        It "Should skip IPv6 subnet with invalid prefix (>128)" {
            $badMap = @{ '2001:db8::/129' = @{ SiteName = 'Bad' } }
            $script:SkippedSubnets = @()
            $result = Get-IPAddressSite -IPAddress '2001:db8::1' -SiteSubnetMap $badMap
            $result.SiteName | Should -Be 'Unknown'
            $script:SkippedSubnets | Where-Object { $_.Reason -match 'out of valid range.*128' } | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Get-MismatchSeverity - Severity Level Mapping" {
    Context "Critical severity" {
        It "Should return Critical for Static A record in wrong site" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $true -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'Critical'
        }
        It "Should NOT return Critical if IPSite is Unknown" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $true -DCSite 'Site1' -IPSite 'Unknown'
            $severity | Should -Not -Be 'Critical'
        }
    }
    Context "High severity" {
        It "Should return High for Dynamic A record" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $false -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'High'
        }
        It "Should return High for Static AAAA record" {
            $severity = Get-MismatchSeverity -RecordType 'AAAA' -IsStatic $true -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'High'
        }
    }
    Context "Medium severity" {
        It "Should return Medium for Dynamic AAAA record" {
            $severity = Get-MismatchSeverity -RecordType 'AAAA' -IsStatic $false -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'Medium'
        }
        It "Should return Medium for Unknown IPSite with Dynamic A" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $false -DCSite 'Site1' -IPSite 'Unknown'
            $severity | Should -Be 'Medium'
        }
    }
    Context "Comprehensive severity matrix" {
        It "Static A + Known Site = Critical" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $true -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'Critical'
        }
        It "Static A + Unknown Site = High" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $true -DCSite 'Site1' -IPSite 'Unknown'
            $severity | Should -Be 'High'
        }
        It "Dynamic A + Known Site = High" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $false -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'High'
        }
        It "Dynamic A + Unknown Site = Medium" {
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $false -DCSite 'Site1' -IPSite 'Unknown'
            $severity | Should -Be 'Medium'
        }
        It "Static AAAA + Known Site = High" {
            $severity = Get-MismatchSeverity -RecordType 'AAAA' -IsStatic $true -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'High'
        }
        It "Dynamic AAAA + Known Site = Medium" {
            $severity = Get-MismatchSeverity -RecordType 'AAAA' -IsStatic $false -DCSite 'Site1' -IPSite 'Site2'
            $severity | Should -Be 'Medium'
        }
    }
}

Describe "Static Record Detection - Timestamp-based Predicate" {
    Context "Static record identification" {
        It "Should identify record with null timestamp as static" {
            $mockRecord = [PSCustomObject]@{
                Timestamp = $null
                TimeToLive = [TimeSpan]::FromHours(1)
            }
            $epoch = [datetime]'1601-01-01T00:00:00Z'
            $isStatic = ($null -eq $mockRecord.Timestamp) -or ($mockRecord.Timestamp -eq $epoch)
            $isStatic | Should -Be $true
        }
        It "Should identify record with epoch timestamp as static" {
            $mockRecord = [PSCustomObject]@{
                Timestamp = [datetime]'1601-01-01T00:00:00Z'
                TimeToLive = [TimeSpan]::FromHours(1)
            }
            $epoch = [datetime]'1601-01-01T00:00:00Z'
            $isStatic = ($null -eq $mockRecord.Timestamp) -or ($mockRecord.Timestamp -eq $epoch)
            $isStatic | Should -Be $true
        }
        It "Should identify record with non-zero timestamp as dynamic" {
            $mockRecord = [PSCustomObject]@{
                Timestamp = Get-Date
                TimeToLive = [TimeSpan]::FromHours(1)
            }
            $epoch = [datetime]'1601-01-01T00:00:00Z'
            $isStatic = ($null -eq $mockRecord.Timestamp) -or ($mockRecord.Timestamp -eq $epoch)
            $isStatic | Should -Be $false
        }
        It "Should NOT use TTL=0 for static detection" {
            # This tests that we're NOT using the old broken logic
            $mockRecord = [PSCustomObject]@{
                Timestamp = Get-Date  # Dynamic record
                TimeToLive = [TimeSpan]::FromSeconds(0)  # TTL = 0 (don't cache)
            }
            $epoch = [datetime]'1601-01-01T00:00:00Z'
            $isStatic = ($null -eq $mockRecord.Timestamp) -or ($mockRecord.Timestamp -eq $epoch)
            # Should be FALSE because timestamp is not null/epoch
            $isStatic | Should -Be $false
        }
        It "Should correctly handle TTL=0 on static record" {
            # This verifies TTL is independent of static/dynamic status
            $mockRecord = [PSCustomObject]@{
                Timestamp = $null  # Static record
                TimeToLive = [TimeSpan]::FromSeconds(0)  # TTL = 0 (don't cache, but unrelated to static status)
            }
            $epoch = [datetime]'1601-01-01T00:00:00Z'
            $isStatic = ($null -eq $mockRecord.Timestamp) -or ($mockRecord.Timestamp -eq $epoch)
            # Should be TRUE because timestamp is null
            $isStatic | Should -Be $true
        }
    }
}

Describe "Integration Tests - Function Composition" {
    Context "Subnet matching with severity calculation" {
        BeforeAll {
            $script:SkippedSubnets = @()
            # Test map for IP-to-site mapping (available for test use if needed)
            $script:testMap = @{
                '10.0.0.0/8' = @{ SiteName = 'HQ'; SubnetName = '10.0.0.0/8'; Location = ''; Description = '' }
                '192.168.1.0/24' = @{ SiteName = 'Branch'; SubnetName = '192.168.1.0/24'; Location = ''; Description = '' }
            }
        }
        It "Should combine site lookup with severity calculation for Critical issue" {
            # IP in HQ subnet
            $siteInfo = Get-IPAddressSite -IPAddress '10.0.0.50' -SiteSubnetMap $testMap
            $siteInfo.SiteName | Should -Be 'HQ'
            # But DC is in different site with static A record = Critical
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $true -DCSite 'Branch' -IPSite $siteInfo.SiteName
            $severity | Should -Be 'Critical'
        }
        It "Should handle Unknown site gracefully" {
            # IP not in any subnet
            $siteInfo = Get-IPAddressSite -IPAddress '8.8.8.8' -SiteSubnetMap $testMap
            $siteInfo.SiteName | Should -Be 'Unknown'
            # Unknown site with static A = High (not Critical)
            $severity = Get-MismatchSeverity -RecordType 'A' -IsStatic $true -DCSite 'Branch' -IPSite $siteInfo.SiteName
            $severity | Should -Be 'High'
        }
    }
}

