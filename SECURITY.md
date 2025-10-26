# Security Policy

> **Security is critical.** We take security vulnerabilities seriously and respond quickly to reports.

## Reporting a Vulnerability

### How to Report (DO THIS FIRST)

**Found a security issue?** Report it privately to:

📧 **adrian207@gmail.com**

**Subject**: `[SECURITY] DNS-Audit Vulnerability Report`

**⚠️ DO NOT report security vulnerabilities through public GitHub issues.**

### What to Include

Please provide as much detail as possible:

1. **Vulnerability type** (e.g., credential exposure, command injection, privilege escalation)
2. **Affected files/components** with specific line numbers if possible
3. **Reproduction steps** - detailed instructions to reproduce the issue
4. **Proof of concept** - code or commands demonstrating the vulnerability
5. **Impact assessment** - what an attacker could do with this vulnerability
6. **Suggested fix** (optional but appreciated)
7. **Your contact information** for follow-up questions

### Response Timeline

| Stage | Timeline |
|-------|----------|
| **Initial acknowledgment** | Within 48 hours |
| **Detailed response** | Within 7 days |
| **Fix deployment** | Depends on severity (see below) |

### Fix Timeline by Severity

| Severity | Description | Fix Target | Example |
|----------|-------------|------------|---------|
| **Critical** | Remote code execution, privilege escalation | 1-3 days | Command injection in remote execution |
| **High** | Authentication bypass, credential exposure | 1-2 weeks | Hardcoded credentials, insecure storage |
| **Medium** | Information disclosure, DoS | 2-4 weeks | Excessive logging of sensitive data |
| **Low** | Minor security issues | Next release | Missing input validation (low impact) |

## Supported Versions

We provide security updates for the following versions:

| Version | Status | Support |
|---------|--------|---------|
| 3.2.x | ✅ **Current** | Full support |
| 3.0.x - 3.1.x | ✅ Supported | Security fixes only |
| 2.5.x - 2.9.x | ✅ Supported | Critical fixes only |
| 2.0.x - 2.4.x | ⚠️ Limited | Critical issues only |
| < 2.0 | ❌ Unsupported | Please upgrade |

**Recommendation**: Always use the latest version for best security and features.

## Security Best Practices

### For Users and Administrators

#### 1. Credential Management

**Do:**
- ✅ Use dedicated service accounts with minimum required permissions
- ✅ Use Windows Credential Manager for storing credentials
- ✅ Rotate credentials regularly (every 90 days)
- ✅ Use `Get-Credential` for interactive sessions
- ✅ Consider Azure Key Vault for enterprise deployments

**Don't:**
- ❌ Never hardcode credentials in scripts
- ❌ Never commit credentials to version control
- ❌ Never share credentials in documentation or logs
- ❌ Never use Domain Admin unless absolutely necessary

**Example - Secure credential usage:**

```powershell
# Good: Use Credential Manager
$cred = Get-StoredCredential -Target "DNS-Audit-Service"

# Good: Interactive prompt
$cred = Get-Credential -Message "Enter DNS Administrator credentials"

# Good: Use least-privilege account
.\DNS-Audit.ps1 -Mode Complete -Credential $cred

# Bad: Hardcoded (NEVER DO THIS)
$password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force  # ❌ NEVER
```

#### 2. Execution Security

**Do:**
- ✅ Validate script integrity before execution
- ✅ Use code signing when possible
- ✅ Run from secure, restricted directories
- ✅ Enable PowerShell logging and auditing
- ✅ Use PowerShell execution policy appropriately
- ✅ Run with least privilege (DNS Admins read-only, not Domain Admin)

**Don't:**
- ❌ Don't run unknown scripts as Administrator
- ❌ Don't disable execution policy globally
- ❌ Don't bypass security warnings without verification

**Example - Secure execution:**

```powershell
# Verify script integrity
Get-FileHash .\DNS-Audit.ps1 -Algorithm SHA256
Get-AuthenticodeSignature .\DNS-Audit.ps1

# Unblock after verification
Unblock-File .\DNS-Audit.ps1

# Run with appropriate permissions (not Domain Admin)
.\DNS-Audit.ps1 -Mode Complete -Credential $dnsReadOnlyCred
```

#### 3. Network Security

**Do:**
- ✅ Run audits from secure management VLANs
- ✅ Use firewall rules to restrict DC access
- ✅ Enable SMB signing and encryption
- ✅ Use HTTPS webhooks only (Teams, Slack)
- ✅ Restrict DNS query sources if possible
- ✅ Use IPsec for DC communication if required

**Firewall rules needed:**

```powershell
# DNS Queries
New-NetFirewallRule -DisplayName "DNS Audit - DNS" -Direction Outbound -Protocol UDP -RemotePort 53

# WinRM (if using remote PowerShell)
New-NetFirewallRule -DisplayName "DNS Audit - WinRM" -Direction Outbound -Protocol TCP -RemotePort 5985,5986

# LDAP (for AD queries)
New-NetFirewallRule -DisplayName "DNS Audit - LDAP" -Direction Outbound -Protocol TCP -RemotePort 389,636
```

#### 4. Data Protection

**Do:**
- ✅ Redact sensitive data in shared reports
- ✅ Encrypt export files if containing sensitive data
- ✅ Restrict access to output directories
- ✅ Use secure storage for baseline files
- ✅ Review logs before sharing externally
- ✅ Delete old exports and logs regularly

**Example - Secure data handling:**

```powershell
# Use redaction for shared reports
.\DNS-Audit.ps1 -Mode Complete -RedactSensitiveData

# Encrypt sensitive exports
$exports = Get-ChildItem C:\DNSAudit\*.csv
$exports | ForEach-Object {
    Protect-CmsMessage -To "CN=DNSAuditRecipient" -Path $_.FullName -OutFile "$($_.FullName).encrypted"
    Remove-Item $_.FullName -Force
}

# Set restrictive permissions
$acl = Get-Acl C:\DNSAudit
$acl.SetAccessRuleProtection($true, $false)
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
    "DOMAIN\DNS-Admins", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
)))
Set-Acl C:\DNSAudit $acl
```

#### 5. Integration Security

**Do:**
- ✅ Use webhook secrets/tokens when available
- ✅ Validate SSL/TLS certificates
- ✅ Use HTTPS for all webhook endpoints
- ✅ Rotate webhook URLs periodically
- ✅ Monitor webhook activity for anomalies
- ✅ Use SIEM integration with TLS

**Example - Secure webhook usage:**

```powershell
# Store webhook URL securely (not in script)
$webhookUrl = Get-Content C:\SecureConfig\teams-webhook.txt -Raw

# Use HTTPS only
if ($webhookUrl -notmatch '^https://') {
    Write-Error "Only HTTPS webhooks allowed"
    exit 1
}

.\DNS-Audit.ps1 -Mode Complete -TeamsWebhook $webhookUrl
```

#### 6. Logging and Auditing

**Do:**
- ✅ Enable PowerShell transcription logging
- ✅ Enable script block logging for PowerShell
- ✅ Review audit logs regularly
- ✅ Forward logs to SIEM
- ✅ Monitor for suspicious activity
- ✅ Retain logs per compliance requirements

**Example - Enable logging:**

```powershell
# Enable PowerShell logging (via GPO recommended)
# HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription" `
    -Name "EnableTranscripting" -Value 1

# Enable script block logging
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -Name "EnableScriptBlockLogging" -Value 1
```

### For Developers

If you're modifying or extending DNS Master Audit:

**Do:**
- ✅ Validate all user input
- ✅ Use parameterized queries for any database operations
- ✅ Sanitize file paths to prevent path traversal
- ✅ Handle errors securely (don't expose sensitive info)
- ✅ Use `ConvertTo-SecureString` for passwords
- ✅ Review code for injection vulnerabilities
- ✅ Test with PSScriptAnalyzer security rules

**Don't:**
- ❌ Never use `Invoke-Expression` with user input
- ❌ Never construct commands from untrusted input
- ❌ Never log credentials or sensitive data
- ❌ Never trust user input without validation

**Example - Secure coding:**

```powershell
# Bad: Command injection vulnerability
$zoneName = $UserInput
Invoke-Expression "Get-DnsServerZone -Name $zoneName"  # ❌ DANGEROUS

# Good: Parameterized and validated
$zoneName = $UserInput
if ($zoneName -notmatch '^[a-zA-Z0-9.-]+$') {
    throw "Invalid zone name format"
}
Get-DnsServerZone -Name $zoneName  # ✅ SAFE
```

## Known Security Considerations

### Current Security Features

✅ **Read-only by default**: Audit modes don't modify DNS
✅ **WhatIf support**: Preview changes before applying
✅ **Credential isolation**: Never stores credentials
✅ **Audit logging**: All operations logged
✅ **Input validation**: Parameters validated before use
✅ **Error handling**: Secure error messages without info disclosure

### Potential Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Credential exposure in logs** | High | Logs are sanitized, use `-Verbose` carefully |
| **Unauthorized access to exports** | Medium | Set restrictive NTFS permissions on output directories |
| **DNS query visibility** | Low | Use encrypted channels (DNSSEC, IPsec) if required |
| **Webhook URL exposure** | Medium | Store in secure configuration, use secrets management |
| **Audit data exfiltration** | Medium | Monitor network traffic, use DLP tools |

## Security Testing

We regularly perform:

- **Static code analysis** with PSScriptAnalyzer
- **Dependency scanning** for PowerShell modules
- **Manual security reviews** of critical functions
- **Community security feedback** integration

**Want to help?** Run security analysis:

```powershell
# Run PSScriptAnalyzer with security rules
Invoke-ScriptAnalyzer -Path .\DNS-Audit.ps1 -Settings .\PSScriptAnalyzerSettings.psd1 -Severity Error,Warning

# Review for common vulnerabilities
Select-String -Path .\DNS-Audit.ps1 -Pattern "Invoke-Expression|ConvertTo-SecureString -AsPlainText|Write-Verbose \$cred"
```

## Recognition

We appreciate responsible disclosure. Security researchers who report valid vulnerabilities will be:

- ✅ Acknowledged in [CHANGELOG.md](CHANGELOG.md) (with permission)
- ✅ Credited in release notes
- ✅ Invited to collaborate on the fix (optional)
- ✅ Added to our Security Hall of Fame (optional)

**Hall of Fame** (security researchers who have helped):
- *No vulnerabilities reported yet - help us improve security!*

## Contact

**Security issues**: adrian207@gmail.com  
**General support**: [GitHub Issues](https://github.com/adrian207/DNS-Audit/issues)

---

**Last reviewed**: October 26, 2025  
**Policy version**: 1.1

### 🛡️ **For Developers**

When contributing to DNS Master Audit:

1. **Input Validation**
   - Validate all user inputs
   - Sanitize file paths to prevent traversal
   - Validate webhook URLs (HTTPS only)
   - Escape regex patterns properly

2. **Credential Handling**
   - Never log credentials
   - Use `PSCredential` objects, not plaintext
   - Clear sensitive variables after use
   - Implement secure credential storage

3. **Code Quality**
   - Run PSScriptAnalyzer before commits
   - Use `[ValidateSet]` for parameters
   - Implement proper error handling
   - Add security-focused unit tests

4. **Dependencies**
   - Minimize external dependencies
   - Audit any new module requirements
   - Document security implications
   - Use built-in PowerShell features when possible

---

## Known Security Considerations

### ⚠️ **Current Limitations**

1. **Administrative Shares (C$)**
   - Cross-site authentication detection requires access to `\\DC\C$\Windows\debug\netlogon.log`
   - **Mitigation:** Use dedicated service account with restricted access
   - **Future:** Add option for agent-based log collection

2. **Webhook Security**
   - Webhooks transmit data to external services
   - **Mitigation:** Use HTTPS only, validate SSL certificates
   - **Future:** Add webhook payload encryption

3. **Transcript Logging**
   - May contain sensitive information in plain text
   - **Mitigation:** Use `-NoTranscript` or restrict log file access
   - **Future:** Add encrypted logging option

4. **Parallel Processing**
   - Multiple concurrent connections increase attack surface
   - **Mitigation:** Use `-MaxDegreeOfParallelism` to limit concurrency
   - **Future:** Add connection rate limiting

5. **Remediation Scripts**
   - Generated scripts execute with user's permissions
   - **Mitigation:** Always review scripts before execution
   - **Future:** Add sandbox execution option

### ✅ **Security Features**

1. **Minimal Permissions**
   - Read-only AD access sufficient for most audits
   - No Domain Admin required for audit operations
   - Explicit `-WhatIf` support for configuration changes

2. **Audit Trail**
   - Full transcript logging of all operations
   - Timestamped audit logs
   - Syslog/SIEM integration for monitoring

3. **Input Validation**
   - Parameter validation with `[ValidateSet]`, `[ValidateRange]`
   - Path validation to prevent traversal
   - Regex pattern validation

4. **Error Handling**
   - Comprehensive try/catch blocks
   - Graceful failure without exposing sensitive data
   - Detailed error logging for troubleshooting

---

## Security-Related Configuration

### 🔧 **Recommended Settings**

```powershell
# Production-ready secure configuration
.\DNS-MasterAudit.ps1 -Mode Complete `
    -UseCredentialManager `              # Secure credential storage
    -CredentialName "DNS-Audit-Prod" `
    -RedactSensitiveData `               # Anonymize reports
    -NoTranscript `                      # Disable logging if required
    -EnableAuditSigning `                # Sign audit logs
    -TeamsWebhook "https://..." `        # HTTPS webhook only
    -SyslogServer "siem.contoso.com" `   # Forward to SIEM
    -ExportPath "D:\SecureAudits" `      # Encrypted volume
    -MaxDegreeOfParallelism 5            # Limit concurrency
```

### 🚫 **Avoid These Configurations**

```powershell
# INSECURE - Do NOT use in production
.\DNS-MasterAudit.ps1 -Mode Complete `
    -Credential (Get-Credential) `       # ❌ Interactive prompt exposes creds
    -TeamsWebhook "http://..." `         # ❌ HTTP not secure
    -AutoFix `                           # ❌ Automatic changes without review
    -Force                               # ❌ Skips safety prompts
```

---

## Compliance

DNS Master Audit is designed to support compliance with:

- ✅ **NIST Cybersecurity Framework**
- ✅ **CIS Controls** (Network Monitoring, Asset Management)
- ✅ **ISO 27001** (Access Control, Logging)
- ✅ **SOC 2** (Monitoring, Change Management)

### 📋 **Compliance Modes (Roadmap)**

```powershell
-ComplianceMode "HIPAA"      # Healthcare data protection
-ComplianceMode "PCI-DSS"    # Payment card industry
-ComplianceMode "GDPR"       # EU data protection
-ComplianceMode "FedRAMP"    # US federal government
```

---

## Security Roadmap

### 🔮 **Planned Security Enhancements**

| Feature | Priority | ETA |
|---------|----------|-----|
| Windows Credential Manager integration | High | v2.6 |
| Encrypted audit logging | High | v2.6 |
| Certificate pinning for webhooks | Medium | v2.7 |
| Sensitive data redaction engine | High | v2.6 |
| Agent-based log collection | Low | v3.0 |
| Webhook payload encryption | Medium | v2.7 |
| Sandbox execution for remediation | Low | v3.0 |
| Multi-factor authentication support | Medium | v2.8 |

---

## Contact

- **Security Issues:** adrian207@gmail.com
- **General Support:** [GitHub Issues](https://github.com/adrian207/DNS-Audit/issues)
- **Documentation:** [User Guide](docs/USER-GUIDE.md)

---

## Acknowledgments

We thank the security research community for helping keep DNS Master Audit secure.

**Hall of Fame:** See [SECURITY-HALL-OF-FAME.md](SECURITY-HALL-OF-FAME.md) (future)

---

**Last Updated:** 2025-10-19  
**Author:** Adrian Johnson <adrian207@gmail.com>

