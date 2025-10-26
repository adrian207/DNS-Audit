# Contributing to DNS Master Audit

> **Thank you for your interest in contributing!** We welcome contributions of all types: bug reports, feature requests, documentation improvements, and code contributions.

## Quick Start for Contributors

**Want to contribute?** Here's how:

1. **Report bugs or request features**: [Open an issue](https://github.com/adrian207/DNS-Audit/issues/new)
2. **Fix bugs or add features**: Fork → Create branch → Submit PR
3. **Improve documentation**: Documentation PRs are always welcome
4. **Share feedback**: Tell us how you use DNS Master Audit

## Ways to Contribute

### Report Issues

Found a bug? Have a feature idea? **[Create an issue](https://github.com/adrian207/DNS-Audit/issues/new)**.

**Good bug reports include:**
- Clear, descriptive title
- Steps to reproduce the problem
- Expected vs actual behavior
- PowerShell version and environment details
- Error messages and logs (redact sensitive data)
- Screenshots if applicable

**Good feature requests include:**
- Clear use case: what problem does it solve?
- Proposed solution or approach
- Any alternatives you've considered
- Impact on existing functionality

### Submit Code

#### Prerequisites

```powershell
# Required
- PowerShell 5.1+ (PowerShell 7.x recommended)
- Git
- Active Directory lab environment (for testing)

# Recommended
Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
```

#### Development Workflow

1. **Fork and clone**

```powershell
# Fork on GitHub, then clone
git clone https://github.com/YOUR-USERNAME/DNS-Audit.git
cd DNS-Audit
git remote add upstream https://github.com/adrian207/DNS-Audit.git
```

2. **Create a feature branch**

```powershell
git checkout -b feature/my-awesome-feature
# or
git checkout -b fix/issue-123
```

3. **Make your changes**
   - Write clear, readable code
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation as needed

4. **Test your changes**

```powershell
# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\DNS-MasterAudit.ps1 -Settings .\PSScriptAnalyzerSettings.psd1

# Run Pester tests
Invoke-Pester -Path .\Tests\ -Output Detailed

# Test manually in lab environment
.\DNS-MasterAudit.ps1 -Mode Inventory -Verbose
```

5. **Commit your changes**

```powershell
git add .
git commit -m "feat: add awesome new feature"
# or
git commit -m "fix: resolve issue #123"
```

**Commit message format:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions or changes
- `chore:` Maintenance tasks

6. **Push and create PR**

```powershell
git push origin feature/my-awesome-feature
```

Then open a pull request on GitHub.

### Improve Documentation

Documentation improvements are **highly valued**:

- Fix typos or unclear explanations
- Add examples for complex features
- Improve code comments
- Translate documentation (if multilingual)
- Create tutorials or guides

**Documentation files:**
- `README.md` - Main project overview
- `docs/*.md` - Detailed guides
- `CHANGELOG.md` - Version history
- Code comments - Inline documentation

## Coding Standards

### PowerShell Style Guide

**Follow these conventions:**

1. **Naming**
   - Functions: `Verb-Noun` format (e.g., `Get-DnsServerInfo`)
   - Variables: `$camelCase` (e.g., `$dnsServers`)
   - Constants: `$UPPER_CASE` (e.g., `$VERSION`)
   - Parameters: PascalCase (e.g., `-EnableParallel`)

2. **Formatting**
   - Indent with 4 spaces (no tabs)
   - Opening braces on same line
   - Use meaningful variable names
   - Limit lines to 120 characters when practical

3. **Comments**
   ```powershell
   # Single-line comments for quick explanations
   
   <#
   .SYNOPSIS
   Multi-line comments for function documentation
   #>
   ```

4. **Error Handling**
   ```powershell
   try {
       # Risky operation
   }
   catch {
       Write-Error "Clear error message: $_"
       # Handle or rethrow
   }
   ```

### Code Quality

**All contributions must:**
- ✅ Pass PSScriptAnalyzer with no errors
- ✅ Include tests for new functionality (when applicable)
- ✅ Maintain backward compatibility (or document breaking changes)
- ✅ Include comment-based help for new functions
- ✅ Work on PowerShell 5.1 and 7.x

**Run quality checks:**

```powershell
# Linting
Invoke-ScriptAnalyzer -Path .\DNS-MasterAudit.ps1 -Settings .\PSScriptAnalyzerSettings.psd1

# Testing
Invoke-Pester -Path .\Tests\ -Output Detailed

# Code coverage (optional)
$config = New-PesterConfiguration
$config.Run.Path = '.\Tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\DNS-MasterAudit.ps1'
Invoke-Pester -Configuration $config
```

## Testing Guidelines

### Unit Tests

**When adding new functions**, include Pester tests:

```powershell
Describe "Get-MyNewFunction" {
    Context "When given valid input" {
        It "Returns expected output" {
            $result = Get-MyNewFunction -Parameter "value"
            $result | Should -Be "expected"
        }
    }
    
    Context "When given invalid input" {
        It "Throws an error" {
            { Get-MyNewFunction -Parameter $null } | Should -Throw
        }
    }
}
```

### Integration Testing

**Test in a lab environment:**
1. Set up test Active Directory environment
2. Create test DNS zones and records
3. Run full audit: `.\DNS-MasterAudit.ps1 -Mode Complete -Verbose`
4. Verify output files and logs
5. Test edge cases (empty zones, unreachable servers, etc.)

## Pull Request Process

### PR Checklist

Before submitting your PR, ensure:

- [ ] Code follows style guidelines
- [ ] PSScriptAnalyzer passes with no errors
- [ ] Tests pass (if applicable)
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated (under "Unreleased" section)
- [ ] Commit messages are clear and descriptive
- [ ] PR description explains what and why

### PR Template

Your PR should include:

**Title:** Clear, concise description
- `feat: Add parallel processing support`
- `fix: Resolve DNS query timeout issue #123`
- `docs: Update installation guide`

**Description:**
```markdown
## Changes
- Describe what changed
- List key modifications

## Motivation
- Why is this change needed?
- What problem does it solve?

## Testing
- How did you test this?
- What environments were tested?

## Breaking Changes
- Any breaking changes?
- Migration guide if needed
```

### Review Process

1. **Automated checks** run on all PRs (PSScriptAnalyzer, tests)
2. **Maintainer review** - we'll review code and provide feedback
3. **Iteration** - address feedback, update PR
4. **Approval** - once approved, we'll merge
5. **Release** - included in next version

**Response times:**
- Initial review: 2-5 days
- Feedback response: Best effort
- We appreciate patience! This is maintained by volunteers.

## Development Setup

### Local Environment

```powershell
# 1. Clone repository
git clone https://github.com/adrian207/DNS-Audit.git
cd DNS-Audit

# 2. Install development dependencies
Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser -Force
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force

# 3. Verify installation
Get-Module -ListAvailable Pester, PSScriptAnalyzer

# 4. Run tests
Invoke-Pester -Path .\Tests\

# 5. Run linter
Invoke-ScriptAnalyzer -Path .\DNS-MasterAudit.ps1
```

### Lab Environment (Recommended)

**For testing DNS-related changes:**

Set up a test AD/DNS environment:
- 2-3 domain controllers (VMs)
- Multiple DNS zones (forward and reverse)
- Test records (A, AAAA, PTR, CNAME, etc.)
- Active Directory integrated zones
- Consider using Hyper-V, VMware, or cloud VMs

## Code of Conduct

### Our Standards

We are committed to providing a welcoming and inspiring community for all.

**Expected behavior:**
- ✅ Be respectful and inclusive
- ✅ Welcome newcomers and help them learn
- ✅ Give and receive constructive feedback gracefully
- ✅ Focus on what's best for the community
- ✅ Show empathy towards others

**Unacceptable behavior:**
- ❌ Harassment, discrimination, or derogatory comments
- ❌ Personal attacks or trolling
- ❌ Public or private harassment
- ❌ Publishing others' private information
- ❌ Other conduct inappropriate in a professional setting

### Enforcement

Instances of unacceptable behavior may be reported to adrian207@gmail.com. All complaints will be reviewed and investigated promptly and fairly.

Project maintainers have the right to remove, edit, or reject comments, commits, code, issues, and other contributions that are not aligned with this Code of Conduct.

## Recognition

### Contributors

All contributors are recognized in our:
- [CHANGELOG.md](CHANGELOG.md) for specific contributions
- GitHub contributors page
- Release notes for major contributions

### Hall of Fame

Significant contributors may be featured in our documentation with:
- Name recognition
- Link to GitHub profile
- Optional: area of contribution

## Questions?

- 📧 **Email**: adrian207@gmail.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/adrian207/DNS-Audit/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/adrian207/DNS-Audit/discussions)

## License

By contributing, you agree that your contributions will be licensed under the same [MIT License](LICENSE) that covers this project.

---

**Thank you for contributing to DNS Master Audit!** 🎉

Your contributions help make DNS management easier for Windows administrators worldwide.
