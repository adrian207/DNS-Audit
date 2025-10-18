# GitHub Actions Workflows

This directory contains CI/CD workflows for the DNS-MasterAudit project.

## pwsh-ci.yml

Continuous Integration workflow that runs on every push and pull request.

### Jobs

#### 1. lint-and-test
Runs on Windows with both PowerShell 5.1 and 7.4 to ensure compatibility.

**Matrix Strategy:**
- OS: windows-latest
- PowerShell: 5.1 (Windows PowerShell), 7.4 (PowerShell Core)

**Steps:**
1. Checkout repository
2. Setup PowerShell 7.x (if matrix version is 7.4)
3. Display PowerShell version
4. Install PSScriptAnalyzer
5. Install Pester 5.x
6. Run PSScriptAnalyzer with custom settings
7. Run Pester tests with detailed output
8. Upload test results as artifacts
9. Publish test results to PR

**PSScriptAnalyzer Rules:**
- Uses `PSScriptAnalyzerSettings.psd1` for configuration
- Fails on Error severity
- Warns on Warning severity
- Success on Information or no issues

**Pester Configuration:**
- Runs all tests in `.\Tests` directory
- Generates NUnit XML test results
- Detailed output verbosity
- Exit on test failures

#### 2. validate-syntax
Quick syntax validation for all PowerShell files.

**Steps:**
1. Checkout repository
2. Validate all .ps1 files using PSParser
3. Fails if any syntax errors found

### Triggers

- **Push**: On branches `main` or `master`
- **Pull Request**: On branches `main` or `master`
- **Manual**: Via workflow_dispatch

### Status Badges

Add to your README.md:

```markdown
![PowerShell CI](https://github.com/YOUR_USERNAME/DNS-Audit-1/workflows/PowerShell%20CI/badge.svg)
```

### Local Testing

Before pushing, run locally:

```powershell
# PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\DNS-MasterAudit.ps1 -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse

# Pester Tests
Invoke-Pester -Path .\Tests -Output Detailed
```

### Troubleshooting

#### Workflow fails on PSScriptAnalyzer
Check the rules in `PSScriptAnalyzerSettings.psd1`. You can exclude specific rules:
```powershell
ExcludeRules = @('PSAvoidUsingWriteHost')
```

#### Tests fail on PowerShell 5.1 but pass on 7.x
Check for:
- Different behavior in .NET Framework vs .NET Core
- Different default parameter values
- Different module versions
- Use `$PSVersionTable` to debug

#### Module installation fails
The workflow uses `-Force` and `-Scope CurrentUser` to avoid permission issues.
If it still fails, check the GitHub Actions runner status.

### Future Enhancements

Potential additions:
- Code coverage reporting (Codecov/Coveralls)
- Performance benchmarking
- Multi-OS testing (Linux, macOS with PowerShell 7)
- Release automation
- Changelog generation
- Security scanning (DevSkim, Credential Scanner)

