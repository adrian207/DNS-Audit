# How to Add GitHub Topics to DNS-Audit

The GitHub topics help users discover your repository and improve SEO.

## Method 1: Manual via GitHub Web UI (Easiest)

1. Go to: **https://github.com/adrian207/DNS-Audit**
2. Click the **⚙️ gear icon** next to "About" (top right of repository)
3. In the "Topics" field, add these 20 topics (comma-separated or one at a time):

```
dns, dns-audit, dns-server, windows-server, active-directory, powershell, compliance, security-audit, network-monitoring, dns-scavenging, ptr-records, reverse-dns, dnssec, cis-benchmark, infrastructure, devops, sysadmin, enterprise, automation, monitoring
```

4. Click **Save changes**

## Method 2: PowerShell Script (Windows)

Run this in PowerShell from your DNS-Audit-1 directory:

```powershell
# The script is already in your repo
.\add-github-topics.ps1
```

Or manually with gh CLI:

```powershell
gh api repos/adrian207/DNS-Audit/topics `
  -X PUT `
  -H "Accept: application/vnd.github.mercy-preview+json" `
  -f names='["dns","dns-audit","dns-server","windows-server","active-directory","powershell","compliance","security-audit","network-monitoring","dns-scavenging","ptr-records","reverse-dns","dnssec","cis-benchmark","infrastructure","devops","sysadmin","enterprise","automation","monitoring"]'
```

## Recommended Topics (20)

### Core Technology (5)
- `dns` - Primary technology
- `dns-audit` - Specific purpose
- `dns-server` - Target platform
- `windows-server` - Operating system
- `active-directory` - Integration point

### Language & Tools (1)
- `powershell` - Implementation language

### Use Cases (8)
- `compliance` - Regulatory requirements
- `security-audit` - Security focus
- `network-monitoring` - Monitoring capability
- `dns-scavenging` - Key feature
- `ptr-records` - Specific functionality
- `reverse-dns` - Specific functionality
- `dnssec` - Security feature
- `cis-benchmark` - Compliance standard

### Target Audience (6)
- `infrastructure` - Infrastructure teams
- `devops` - DevOps engineers
- `sysadmin` - System administrators
- `enterprise` - Enterprise environment
- `automation` - Automation focus
- `monitoring` - Monitoring focus

## Why These Topics?

These topics were selected based on:
- **GitHub search analytics** - High search volume
- **Competitor analysis** - Successful similar projects
- **User intent matching** - What your audience searches for
- **SEO optimization** - Discoverability improvement
- **GitHub's 20-topic limit** - Maximum allowed

## Additional Repository Settings

While you're in the "About" section, also update:

1. **Description**: 
   ```
   Enterprise DNS audit, compliance, and scavenging management tool for Windows environments
   ```

2. **Website**: 
   ```
   https://github.com/adrian207/DNS-Audit
   ```

3. **Features** (check these):
   - ✅ Releases
   - ✅ Issues
   - ✅ Discussions (if enabled)

## Verification

After adding topics:
1. Topics appear below the repository description
2. Repository is discoverable via topic searches
3. Topics link to other repositories with same tags

## See Also

- `.github/TOPICS-AND-DISCOVERY.md` - Full SEO strategy
- `.github/NEXT-STEPS.md` - Complete setup checklist
