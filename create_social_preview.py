#!/usr/bin/env python3
"""
Generate GitHub social preview image for DNS Master Audit
Specifications: 1280x640px, professional design
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Image dimensions (GitHub social preview standard)
WIDTH = 1280
HEIGHT = 640

# Color scheme (Microsoft-inspired professional)
BG_COLOR = "#0078D4"  # Microsoft blue
ACCENT_COLOR = "#FFFFFF"
TEXT_PRIMARY = "#FFFFFF"
TEXT_SECONDARY = "#E3F2FD"
GRADIENT_TOP = "#005A9E"
GRADIENT_BOTTOM = "#0078D4"

# Create image with gradient background
img = Image.new('RGB', (WIDTH, HEIGHT), BG_COLOR)
draw = ImageDraw.Draw(img)

# Create gradient effect
for y in range(HEIGHT):
    # Calculate color transition
    ratio = y / HEIGHT
    r1, g1, b1 = 0, 90, 158  # GRADIENT_TOP
    r2, g2, b2 = 0, 120, 212  # GRADIENT_BOTTOM
    
    r = int(r1 + (r2 - r1) * ratio)
    g = int(g1 + (g2 - g1) * ratio)
    b = int(b1 + (b2 - b1) * ratio)
    
    draw.rectangle([(0, y), (WIDTH, y + 1)], fill=(r, g, b))

# Try to load fonts, fallback to default if not available
try:
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 90)
    font_tagline = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 42)
    font_features = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32)
    font_tech = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 28)
except:
    # Fallback to default font
    font_title = ImageFont.load_default()
    font_tagline = ImageFont.load_default()
    font_features = ImageFont.load_default()
    font_tech = ImageFont.load_default()

# Add decorative elements
# Top accent bar
draw.rectangle([(0, 0), (WIDTH, 8)], fill="#107C10")  # Microsoft green

# Bottom accent bar
draw.rectangle([(0, HEIGHT-8), (WIDTH, HEIGHT)], fill="#107C10")

# Decorative side element
draw.rectangle([(0, 0), (12, HEIGHT)], fill="#FF8C00")  # Microsoft orange

# Main content positioning
title_y = 150
tagline_y = 260
features_y = 350
tech_y = 520

# Title
title = "DNS Master Audit"
# Get text bounding box for centering
bbox = draw.textbbox((0, 0), title, font=font_title)
title_width = bbox[2] - bbox[0]
title_x = (WIDTH - title_width) // 2
draw.text((title_x, title_y), title, font=font_title, fill=TEXT_PRIMARY)

# Tagline
tagline = "Enterprise DNS Auditing & Management"
bbox = draw.textbbox((0, 0), tagline, font=font_tagline)
tagline_width = bbox[2] - bbox[0]
tagline_x = (WIDTH - tagline_width) // 2
draw.text((tagline_x, tagline_y), tagline, font=font_tagline, fill=TEXT_SECONDARY)

# Features (with bullet points)
features = "⚡ Parallel Processing  •  🔒 Security Audits  •  📊 Interactive Dashboards"
bbox = draw.textbbox((0, 0), features, font=font_features)
features_width = bbox[2] - bbox[0]
features_x = (WIDTH - features_width) // 2
draw.text((features_x, features_y), features, font=font_features, fill=TEXT_PRIMARY)

# Technology stack
tech_stack = "PowerShell  |  Windows Server  |  Active Directory"
bbox = draw.textbbox((0, 0), tech_stack, font=font_tech)
tech_width = bbox[2] - bbox[0]
tech_x = (WIDTH - tech_width) // 2
draw.text((tech_x, tech_y), tech_stack, font=font_tech, fill=TEXT_SECONDARY)

# Add decorative corner elements
corner_size = 60
corner_color = "#FFFFFF"
corner_alpha = 50

# Top right corner decoration
draw.line([(WIDTH-corner_size, 20), (WIDTH-20, 20)], fill=corner_color, width=3)
draw.line([(WIDTH-20, 20), (WIDTH-20, corner_size)], fill=corner_color, width=3)

# Bottom left corner decoration
draw.line([(20, HEIGHT-corner_size), (20, HEIGHT-20)], fill=corner_color, width=3)
draw.line([(20, HEIGHT-20), (corner_size, HEIGHT-20)], fill=corner_color, width=3)

# Save the image
output_path = "/workspaces/DNS-Audit/docs/images/social-preview.png"
img.save(output_path, "PNG", optimize=True, quality=95)

print(f"✅ Social preview image created successfully!")
print(f"📍 Location: {output_path}")
print(f"📐 Dimensions: {WIDTH}x{HEIGHT}px")
print(f"💾 File size: {os.path.getsize(output_path) / 1024:.1f} KB")
print(f"\n📋 Next steps:")
print(f"1. Review the image: $BROWSER file://{output_path}")
print(f"2. Go to: https://github.com/adrian207/DNS-Audit/settings")
print(f"3. Scroll to 'Social preview' section")
print(f"4. Click 'Edit' and upload: docs/images/social-preview.png")
