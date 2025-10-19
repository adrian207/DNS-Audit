# Changelog

All notable changes to DNS Master Audit and DNS Scavenging Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive upgrade in progress (security, performance, documentation)

---

## [2.5.1] - 2025-10-19

### Added
- **Cross-Site Authentication Detection**: Scans netlogon.log for NO_CLIENT_SITE warnings
- Identifies clients authenticating outside their proper AD site
- Detects missing AD subnets causing cross-site authentication
- Generates remediation commands for subnet additions
- Exports cross-site issues and missing subnets reports

### Changed
- Enhanced Diagnostics mode with `-CheckCrossSiteAuth` parameter
- Updated credential parameter documentation for cross-site scenarios

### Fixed
- None

---

## [2.5.0] - 2025-10-19

### Added
- **Teams Webhook Integration** in DNS Scavenging Manager
- Color-coded Teams notifications (Success/Warning/Error)
- Automatic notifications on success and failure with statistics
- New parameter: `-TeamsWebhook` for Microsoft Teams integration

---

## [2.5.0] - 2025-10-19 - Enterprise Edition Release

### Added
- **Mode 8: Advanced Analytics**
  - Stale record detection with configurable thresholds (default: 90 days)
  - Duplicate IP address detection across zones
  - PTR record validation (forward/reverse DNS consistency)
  - Automatic remediation command generation

- **Mode 9: Security Audit**
  - DNSSEC validation and signing status checks
  - Zone transfer security auditing
  - Dynamic update security assessment
  - Insecure configuration detection

- **Mode 10: Enhanced Diagnostics**
  - DNS query performance testing with configurable iterations
  - AD replication lag monitoring and alerting
  - Per-server performance statistics
  - Automatic slow server detection

- **Enterprise Integration**
  - Microsoft Teams webhook notifications
  - Slack webhook integration
  - Syslog/SIEM forwarding (RFC 5424 compliant)
  - Real-time audit result delivery

- **Remediation Engine**
  - Automatic PowerShell remediation script generation
  - Per-issue command collection with descriptions
  - User confirmation before execution
  - Success/failure tracking

- **Configuration Management**
  - JSON-based configuration profiles
  - Template-driven repeatable audits
  - Parameter override from profile files

### Changed
- Version bumped to 2.5 - Enterprise Edition
- Enhanced error handling across all new features
- Updated script header and documentation

---

## [2.2.0] - 2025-10-19

### Added
- **Parallel Processing Engine**
  - PowerShell runspace pools for true parallelism
  - 5-10x faster DC queries in large environments
  - Configurable throttle (1-20 concurrent operations)
  - Per-thread error handling
  - New parameters: `-EnableParallelProcessing`, `-MaxDegreeOfParallelism`

- **Enhanced DNS Inventory**
  - Parallel execution support
  - Performance improvements for large environments

- **Enhanced DNS Health Check**
  - Parallel execution support
  - Concurrent DC testing

### Changed
- Version bumped to 2.2 - Parallel Processing Edition
- Updated all documentation to reflect parallel processing capabilities

### Performance
- Average speedup: 5-10x for environments with 10+ DCs
- Tested up to 50 concurrent domain controllers

---

## [2.1.0] - 2025-10-19

### Added
- **Multiple Export Formats**
  - HTML: Interactive tables with search and sort
  - JSON: API-friendly format for automation
  - Excel: Formatted workbooks (requires ImportExcel module)
  - CSV: Universal data format (default)
  - New parameter: `-ExportFormat` with values: CSV, HTML, JSON, Excel, All

- **Baseline Mode (Mode 6)**
  - Create DNS configuration snapshots
  - JSON-based baseline storage
  - Full inventory and health check capture

- **Compare Mode (Mode 7)**
  - Compare current state to baseline
  - Detect configuration drift
  - Identify new/removed servers
  - Track health status changes

### Changed
- Version bumped to 2.1 - Enhanced Export Edition
- Enhanced Export-AuditData function with format support
- Updated all export calls to support multiple formats

---

## [2.0.0] - 2025-10-18

### Added
- **DNS Scavenging Manager** (New standalone script)
  - Analyze mode: Audit current scavenging configuration
  - Configure mode: Apply scavenging settings
  - Report mode: Generate detailed reports
  - GenerateScript mode: Create PowerShell remediation scripts
  - Single master scavenger enforcement (Microsoft best practice)
  - 3-day aggressive cleanup option
  - Zone exclusion support

### Changed
- Reorganized project structure (docs/, archive/ folders)
- Moved legacy scripts to archive/
- Consolidated documentation in docs/ folder

---

## [1.0.0] - 2025-10-17

### Added
- **Mode 1: DNS Inventory**
  - Server discovery and cataloging
  - Zone counting and classification

- **Mode 2: DNS Health Check**
  - Service status testing
  - Zone accessibility validation
  - DNS resolution testing

- **Mode 3: DNS Record Export**
  - Complete DNS record extraction
  - Support for A, AAAA, CNAME, MX, PTR, SRV, TXT, NS records
  - Zone filtering support

- **Mode 4: DNS Site Audit**
  - AD site mismatch detection
  - Severity classification (Critical, High, Medium, Low)
  - Site/subnet analysis

- **Mode 5: Complete Audit**
  - All modes in sequence
  - Consolidated reporting

### Initial Features
- PowerShell 5.1+ and 7.x support
- RSAT module integration (ActiveDirectory, DnsServer)
- CSV export functionality
- Transcript logging
- Email notifications (legacy Send-MailMessage)
- Cross-platform compatibility

---

## Version History Summary

| Version | Date | Description |
|---------|------|-------------|
| **2.5.1** | 2025-10-19 | Cross-site authentication detection |
| **2.5.0** | 2025-10-19 | Enterprise Edition (Analytics, Security, Diagnostics) |
| **2.2.0** | 2025-10-19 | Parallel Processing Engine |
| **2.1.0** | 2025-10-19 | Multiple Export Formats + Baseline/Compare |
| **2.0.0** | 2025-10-18 | DNS Scavenging Manager |
| **1.0.0** | 2025-10-17 | Initial Release (5 Audit Modes) |

---

## Authors

**Adrian Johnson** <adrian207@gmail.com>

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

