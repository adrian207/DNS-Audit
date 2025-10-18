# DNS-MasterAudit Tests

This directory contains Pester tests for the DNS-MasterAudit.ps1 script.

## Prerequisites

- PowerShell 5.1 or later (PowerShell 7.x recommended)
- Pester 5.0 or later

Install Pester:
```powershell
Install-Module -Name Pester -Force -Scope CurrentUser -MinimumVersion 5.0
```

## Running Tests

### Run all tests
```powershell
Invoke-Pester -Path .\Tests
```

### Run with detailed output
```powershell
Invoke-Pester -Path .\Tests -Output Detailed
```

### Run with code coverage
```powershell
$config = New-PesterConfiguration
$config.Run.Path = '.\Tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\DNS-MasterAudit.ps1'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

### Run specific test suite
```powershell
Invoke-Pester -Path .\Tests\DNS-MasterAudit.Tests.ps1
```

## Test Coverage

### 1. Get-IPAddressSite Tests
Tests the subnet mask matching logic for both IPv4 and IPv6:

- **IPv4 Tests**: 
  - Exact subnet matches (/8, /24, /23, /25)
  - Subnet boundary tests
  - Split subnet masks (/25 boundaries)
  - No matching subnet scenarios
  - Invalid IP address handling

- **IPv6 Tests**:
  - IPv6 subnet matching (/32, /48, /10)
  - Link-local addresses
  - Boundary tests

- **Edge Cases**:
  - Invalid subnet formats (missing prefix, invalid prefix)
  - Out-of-bounds prefix lengths (IPv4: 0-32, IPv6: 0-128)
  - Malformed subnet strings
  - Validation of skipped subnets tracking

### 2. Get-MismatchSeverity Tests
Tests the severity calculation matrix:

- **Critical**: Static A record in wrong site (non-Unknown)
- **High**: Dynamic A record OR Static AAAA record
- **Medium**: Dynamic AAAA record OR Unknown IP site
- **Low**: All other scenarios

Comprehensive matrix testing for all combinations of:
- Record type (A, AAAA)
- Static/Dynamic status
- Known/Unknown IP site

### 3. Static Record Detection Tests
Tests the timestamp-based predicate (Fix #1):

- Records with `null` timestamp = Static
- Records with epoch timestamp (1601-01-01) = Static
- Records with non-zero timestamp = Dynamic
- **Verification**: TTL=0 does NOT indicate static (TTL is independent)
- Edge cases with TTL=0 on static records

### 4. Integration Tests
Tests function composition and realistic scenarios:

- Combining site lookup with severity calculation
- Handling Unknown sites gracefully
- End-to-end workflow validation

## Test Structure

Each test follows the Pester 5 syntax:
```powershell
Describe "Component" {
    BeforeAll {
        # Setup
    }
    
    Context "Specific scenario" {
        It "Should do something" {
            # Arrange
            # Act
            # Assert
        }
    }
}
```

## CI/CD Integration

Tests run automatically on every push/PR via GitHub Actions:
- **PowerShell 5.1**: Windows Server 2019/2022 compatibility
- **PowerShell 7.4**: Modern PowerShell cross-platform

See `.github/workflows/pwsh-ci.yml` for the full workflow.

## Expected Test Results

All tests should pass with:
- ✅ IPv4 subnet matching (exact, boundary, split masks)
- ✅ IPv6 subnet matching (various prefix lengths)
- ✅ Edge case handling (invalid formats, out-of-bounds)
- ✅ Severity matrix (all combinations)
- ✅ Static detection (timestamp-based, TTL-independent)
- ✅ Integration scenarios

## Adding New Tests

When adding new functionality:

1. Create tests FIRST (TDD approach)
2. Use descriptive `It` statements
3. Test happy path AND edge cases
4. Mock external dependencies (AD, DNS cmdlets)
5. Keep tests isolated and independent

Example:
```powershell
Describe "New-Function" {
    Context "When condition X" {
        It "Should return expected result" {
            $result = New-Function -Param 'value'
            $result | Should -Be 'expected'
        }
        
        It "Should handle error Y" {
            { New-Function -Param 'bad' } | Should -Throw
        }
    }
}
```

## Troubleshooting

### Tests fail with "Cannot dot-source"
Ensure the script path is correct:
```powershell
. $PSScriptRoot\..\DNS-MasterAudit.ps1
```

### Mock errors
Pester 5 requires `Mock` calls to be inside `BeforeAll` blocks.

### Module not found
Install required modules:
```powershell
Install-Module Pester -Force -Scope CurrentUser -MinimumVersion 5.0
Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
```

