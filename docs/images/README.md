# Visual Assets

This directory contains all visual assets for DNS Master Audit documentation.

## Directory Structure

```
images/
├── architecture/     # System architecture and component diagrams
├── screenshots/      # Application screenshots and console output
├── diagrams/         # Workflow, feature maps, and other diagrams
└── logos/           # Project logos and branding assets
```

## File Naming Conventions

Use kebab-case with descriptive names:
- `system-architecture.png`
- `dashboard-main-view.png`
- `workflow-complete-audit.png`
- `logo-main.png`

## Image Specifications

### Screenshots
- **Format**: PNG (with transparency) or JPG
- **Resolution**: 1920x1080 or 1280x720
- **Max file size**: 500KB (optimize before committing)
- **DPI**: 72 for web, 150+ for print documentation

### Diagrams
- **Format**: PNG or SVG (prefer SVG for scalability)
- **Resolution**: Minimum 1280x720
- **Background**: Transparent or white
- **Export from**: Draw.io, Mermaid, Lucidchart, Excalidraw

### Logos
- **Formats needed**:
  - `logo.png` - Full color (512x512px)
  - `logo-dark.png` - Dark mode version
  - `logo-small.png` - Favicon sizes (32x32, 64x64)
  - `logo.svg` - Vector version (preferred)

## Adding New Images

1. **Optimize images** before committing:
   ```bash
   # Using ImageMagick (if available)
   convert input.png -quality 85 -resize 1920x1080 output.png
   
   # Or use online tools:
   # - TinyPNG: https://tinypng.com/
   # - Squoosh: https://squoosh.app/
   ```

2. **Place in appropriate directory**:
   - System/component diagrams → `architecture/`
   - UI screenshots → `screenshots/`
   - Process/workflow diagrams → `diagrams/`
   - Branding → `logos/`

3. **Update documentation** that references the image

4. **Commit with descriptive message**:
   ```bash
   git add docs/images/
   git commit -m "docs: add system architecture diagram"
   ```

## Current Assets

### Priority Assets Needed

1. **Architecture Diagrams** (High Priority)
   - [ ] System architecture overview
   - [ ] Component relationships
   - [ ] Data flow diagram

2. **Screenshots** (High Priority)
   - [ ] HTML dashboard main view
   - [ ] Console output during audit
   - [ ] Generated reports examples
   - [ ] Configuration file example

3. **Workflow Diagrams** (Medium Priority)
   - [ ] Complete audit workflow
   - [ ] Parallel processing flow
   - [ ] Security audit process

4. **Social/Branding** (Low Priority)
   - [ ] Social preview image (1280x640)
   - [ ] Repository logo
   - [ ] Favicon

## Design Guidelines

**Color Palette:**
- Primary: `#0078D4` (Microsoft Blue)
- Secondary: `#107C10` (Success Green)
- Warning: `#FF8C00` (Orange)
- Error: `#D13438` (Red)
- Neutral: `#605E5C` (Gray)

**Typography:**
- Headings: Segoe UI Bold or Arial Bold
- Body: Segoe UI or Arial
- Code: Consolas or Courier New

See `.github/VISUAL-DOCUMENTATION-GUIDE.md` for complete design specifications.

## Tools & Resources

**Diagram Creation:**
- [Draw.io](https://app.diagrams.net/) - Free, web-based
- [Excalidraw](https://excalidraw.com/) - Hand-drawn style
- [Mermaid](https://mermaid.js.org/) - Code-based (renders in GitHub)

**Screenshot Tools:**
- Windows Snipping Tool / Snip & Sketch
- [ShareX](https://getsharex.com/) - Advanced screenshot tool
- [Greenshot](https://getgreenshot.org/) - With annotations

**Image Optimization:**
- [TinyPNG](https://tinypng.com/)
- [Squoosh](https://squoosh.app/)
- [ImageOptim](https://imageoptim.com/) (macOS)

## Questions?

See `.github/VISUAL-DOCUMENTATION-GUIDE.md` or contact adrian207@gmail.com.
