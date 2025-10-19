# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 2.5.x   | :white_check_mark: |
| 2.2.x   | :white_check_mark: |
| 2.1.x   | :white_check_mark: |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

---

## Reporting a Vulnerability

We take the security of DNS Master Audit seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### 📧 **How to Report**

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please email security reports to:

**📬 adrian207@gmail.com**

**Subject Line:** `[SECURITY] DNS-Audit Vulnerability Report`

### 📝 **What to Include**

Please include as much of the following information as possible:

1. **Type of issue** (e.g., credential exposure, command injection, path traversal, etc.)
2. **Full paths** of source file(s) related to the manifestation of the issue
3. **Location** of the affected source code (tag/branch/commit or direct URL)
4. **Step-by-step instructions** to reproduce the issue
5. **Proof-of-concept or exploit code** (if possible)
6. **Impact** of the issue, including how an attacker might exploit it
7. **Your contact information** (name, email, GitHub username)

### ⏱️ **Response Timeline**

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Depends on severity (see below)

| Severity | Fix Timeline | Disclosure |
|----------|--------------|------------|
| **Critical** | 1-3 days | Coordinated after patch |
| **High** | 1-2 weeks | Coordinated after patch |
| **Medium** | 2-4 weeks | Coordinated after patch |
| **Low** | Next release | Standard release notes |

### 🏆 **Recognition**

We appreciate your efforts to responsibly disclose your findings. Contributors who report valid security issues will be:

- Acknowledged in the CHANGELOG (with permission)
- Listed in the SECURITY-HALL-OF-FAME.md (optional)
- Invited to collaborate on the fix (optional)

---

## Security Best Practices

### 🔐 **For Users**

When using DNS Master Audit in production environments:

1. **Credentials**
   - Use dedicated service accounts with minimum required permissions
   - Never hardcode credentials in scripts
   - Consider using Windows Credential Manager integration
   - Rotate credentials regularly

2. **Network Security**
   - Run audits from secure management VLANs
   - Use firewall rules to restrict DC access
   - Enable SMB signing and encryption
   - Use HTTPS webhooks only (Teams, Slack)

3. **Data Protection**
   - Enable `-RedactSensitiveData` for shared reports
   - Restrict access to export directories
   - Use encrypted storage for baseline files
   - Review logs before sharing externally

4. **Execution**
   - Validate script integrity before execution
   - Use code signing when possible
   - Run with least privilege (no Domain Admin required for audits)
   - Enable PowerShell constrained language mode if needed

5. **Updates**
   - Keep PowerShell updated (5.1+ or 7.x)
   - Apply Windows updates regularly
   - Update RSAT modules monthly
   - Check for script updates weekly

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

