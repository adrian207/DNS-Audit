# Screenshots

Application screenshots and console output examples for DNS Master Audit.

## Screenshots Needed

### High Priority

1. **HTML Dashboard Main View**
   - Filename: `dashboard-main-view.png`
   - Shows: Executive summary, charts, data tables
   - Resolution: 1920x1080
   - How to capture: Run `.\DNS-Audit.ps1 -Mode Complete -EnableHTMLDashboard`, then screenshot the generated HTML

2. **Console Output During Audit**
   - Filename: `console-output-audit.png`
   - Shows: Progress indicators, parallel processing, summary
   - Resolution: 1280x720 or larger
   - How to capture: Run audit and capture terminal output

3. **Generated Reports Examples**
   - Filenames: 
     - `report-csv-sample.png`
     - `report-json-sample.png`
     - `report-html-sample.png`
   - Shows: Export file structure and content previews

### Medium Priority

4. **Configuration File Example**
   - Filename: `config-file-example.png`
   - Shows: Sample JSON configuration file

5. **Security Audit Results**
   - Filename: `security-audit-results.png`
   - Shows: CIS compliance dashboard or report

6. **PTR Validation Output**
   - Filename: `ptr-validation-output.png`
   - Shows: Missing PTR detection and auto-fix results

### Optional Enhancements

- **Before/After comparisons** for performance improvements
- **Error handling** examples
- **Teams/Slack notifications** screenshots
- **Multiple export formats** side-by-side

## Screenshot Guidelines

**Technical Specs:**
- Format: PNG (preferred) or JPG
- Resolution: 1920x1080 or 1280x720
- DPI: 72 (web-optimized)
- Max file size: 500KB (optimize if larger)

**Content Guidelines:**
- Use realistic but sanitized data (no sensitive information)
- Show complete UI elements (no cropping important parts)
- Use consistent terminal theme (prefer dark theme or PowerShell default)
- Include window chrome/borders if it helps context

**Annotations:**
- Add arrows or highlights for key features
- Use tools like Snagit, ShareX, or built-in annotation tools
- Keep annotations professional and minimal

## How to Capture

### Windows Built-in Tools
```powershell
# Snipping Tool
snippingtool

# Windows Key + Shift + S (Snip & Sketch)
# Then paste into Paint or image editor to save
```

### PowerShell Terminal
```powershell
# Run audit with output
.\DNS-Audit.ps1 -Mode Complete -EnableHTMLDashboard -Verbose

# Capture terminal window with Snipping Tool
# Or use ShareX for automated capture
```

### HTML Dashboard
1. Run audit to generate HTML
2. Open generated HTML in browser
3. Use F12 to adjust viewport if needed
4. Capture full page with browser screenshot extension or Snipping Tool

## Optimization

Before committing, optimize images:

```bash
# Using ImageMagick (if installed)
magick input.png -quality 85 output.png

# Using online tools (recommended)
# - TinyPNG: https://tinypng.com/
# - Squoosh: https://squoosh.app/
```

## Status

- [ ] dashboard-main-view.png
- [ ] console-output-audit.png
- [ ] report-csv-sample.png
- [ ] report-json-sample.png
- [ ] report-html-sample.png
- [ ] config-file-example.png
- [ ] security-audit-results.png
- [ ] ptr-validation-output.png
