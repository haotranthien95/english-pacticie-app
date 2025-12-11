# Asset Optimization Guide

This document provides guidelines and scripts for optimizing images, icons, and other assets in the English Learning mobile app.

---

## Asset Organization

```
assets/
├── images/                 # General images (illustrations, backgrounds)
│   ├── logo.png           # App logo (multiple sizes)
│   ├── onboarding/        # Onboarding screen images
│   └── placeholders/      # Placeholder images
├── icons/                  # Custom icons (if not using Icon fonts)
│   ├── navigation/        # Bottom navigation icons
│   └── actions/           # Action icons
└── audio/                  # Audio assets (if any offline audio)
    └── samples/           # Sample audio files
```

---

## Image Optimization Guidelines

### Size Targets

| Asset Type | Max Size | Format | Notes |
|-----------|----------|--------|-------|
| App Logo | 50 KB | PNG/WebP | Transparent background |
| Icons | 10 KB each | PNG/SVG | Vector preferred |
| Illustrations | 100 KB | WebP/PNG | Use WebP for better compression |
| Backgrounds | 150 KB | WebP/JPG | Consider gradients over images |
| Thumbnails | 20 KB | WebP/JPG | Low resolution acceptable |

### Resolution Guidelines

**Android**:
- ldpi (120dpi): 0.75x
- mdpi (160dpi): 1.0x (baseline)
- hdpi (240dpi): 1.5x
- xhdpi (320dpi): 2.0x
- xxhdpi (480dpi): 3.0x
- xxxhdpi (640dpi): 4.0x

**iOS**:
- 1x: Standard resolution
- 2x: Retina displays
- 3x: iPhone Plus, Pro models

**Naming Convention**:
```
logo.png          # 1x (baseline)
logo@2x.png       # 2x
logo@3x.png       # 3x
```

---

## Optimization Tools

### Install Required Tools

**macOS**:
```bash
# Install image optimization tools
brew install pngquant
brew install jpegoptim
brew install webp

# Install ImageMagick for resizing
brew install imagemagick
```

**Linux (Ubuntu/Debian)**:
```bash
sudo apt-get install pngquant jpegoptim webp imagemagick
```

**Windows**:
- Download tools from official websites
- Or use Chocolatey: `choco install pngquant jpegoptim webp imagemagick`

---

## Optimization Scripts

### 1. PNG Optimization

```bash
#!/bin/bash
# optimize_png.sh - Optimize PNG images

ASSETS_DIR="assets/images"

echo "Optimizing PNG images in $ASSETS_DIR..."

# Find and optimize all PNG files
find "$ASSETS_DIR" -name "*.png" -type f | while read file; do
    echo "Optimizing: $file"
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Optimize with pngquant (lossy but high quality)
    pngquant --quality=80-95 --ext .png --force "$file"
    
    # If optimization failed, restore backup
    if [ $? -ne 0 ]; then
        echo "  ✗ Failed, restoring backup"
        mv "$file.backup" "$file"
    else
        echo "  ✓ Optimized"
        rm "$file.backup"
    fi
done

echo "PNG optimization complete!"
```

### 2. JPEG Optimization

```bash
#!/bin/bash
# optimize_jpeg.sh - Optimize JPEG images

ASSETS_DIR="assets/images"

echo "Optimizing JPEG images in $ASSETS_DIR..."

find "$ASSETS_DIR" \( -name "*.jpg" -o -name "*.jpeg" \) -type f | while read file; do
    echo "Optimizing: $file"
    
    # Optimize with jpegoptim
    jpegoptim --max=85 --strip-all --preserve --totals "$file"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Optimized"
    else
        echo "  ✗ Failed"
    fi
done

echo "JPEG optimization complete!"
```

### 3. Convert to WebP

```bash
#!/bin/bash
# convert_to_webp.sh - Convert images to WebP format

ASSETS_DIR="assets/images"

echo "Converting images to WebP in $ASSETS_DIR..."

# Convert PNG files
find "$ASSETS_DIR" -name "*.png" -type f | while read file; do
    output="${file%.png}.webp"
    
    # Skip if WebP already exists
    if [ -f "$output" ]; then
        echo "Skipping (exists): $output"
        continue
    fi
    
    echo "Converting: $file -> $output"
    cwebp -q 80 "$file" -o "$output"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Converted"
        
        # Compare sizes
        original_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
        webp_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output")
        saved=$((original_size - webp_size))
        percentage=$((saved * 100 / original_size))
        
        echo "  Saved: $saved bytes ($percentage%)"
    else
        echo "  ✗ Failed"
    fi
done

# Convert JPEG files
find "$ASSETS_DIR" \( -name "*.jpg" -o -name "*.jpeg" \) -type f | while read file; do
    output="${file%.*}.webp"
    
    if [ -f "$output" ]; then
        echo "Skipping (exists): $output"
        continue
    fi
    
    echo "Converting: $file -> $output"
    cwebp -q 85 "$file" -o "$output"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Converted"
    else
        echo "  ✗ Failed"
    fi
done

echo "WebP conversion complete!"
```

### 4. Generate Multiple Resolutions

```bash
#!/bin/bash
# generate_resolutions.sh - Generate 1x, 2x, 3x versions

INPUT_FILE="$1"
BASE_NAME="${INPUT_FILE%.*}"
EXTENSION="${INPUT_FILE##*.}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: ./generate_resolutions.sh <image-file>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

echo "Generating resolutions for: $INPUT_FILE"

# Get original dimensions
ORIGINAL_WIDTH=$(identify -format "%w" "$INPUT_FILE")
ORIGINAL_HEIGHT=$(identify -format "%h" "$INPUT_FILE")

echo "Original size: ${ORIGINAL_WIDTH}x${ORIGINAL_HEIGHT}"

# Assume input is @3x (highest resolution)
# Generate @2x (66.67% of @3x)
WIDTH_2X=$((ORIGINAL_WIDTH * 2 / 3))
HEIGHT_2X=$((ORIGINAL_HEIGHT * 2 / 3))
OUTPUT_2X="${BASE_NAME}@2x.${EXTENSION}"

echo "Generating @2x: ${WIDTH_2X}x${HEIGHT_2X}"
convert "$INPUT_FILE" -resize "${WIDTH_2X}x${HEIGHT_2X}" "$OUTPUT_2X"

# Generate @1x (33.33% of @3x)
WIDTH_1X=$((ORIGINAL_WIDTH / 3))
HEIGHT_1X=$((ORIGINAL_HEIGHT / 3))
OUTPUT_1X="${BASE_NAME}.${EXTENSION}"

echo "Generating @1x: ${WIDTH_1X}x${HEIGHT_1X}"
convert "$INPUT_FILE" -resize "${WIDTH_1X}x${HEIGHT_1X}" "$OUTPUT_1X"

# Rename original to @3x
OUTPUT_3X="${BASE_NAME}@3x.${EXTENSION}"
if [ "$INPUT_FILE" != "$OUTPUT_3X" ]; then
    mv "$INPUT_FILE" "$OUTPUT_3X"
    echo "Renamed original to: $OUTPUT_3X"
fi

echo "✓ Resolution generation complete!"
echo "  - $OUTPUT_1X"
echo "  - $OUTPUT_2X"
echo "  - $OUTPUT_3X"
```

### 5. Analyze Asset Sizes

```bash
#!/bin/bash
# analyze_assets.sh - Analyze asset sizes and identify large files

ASSETS_DIR="assets"
SIZE_THRESHOLD=100000  # 100 KB

echo "====================================="
echo "Asset Size Analysis"
echo "====================================="
echo ""

# Total size
echo "📊 Total Assets Size:"
du -sh "$ASSETS_DIR"
echo ""

# By type
echo "📊 Size by Type:"
echo "PNG files:"
find "$ASSETS_DIR" -name "*.png" -type f -exec du -ch {} + | grep total
echo ""

echo "JPEG files:"
find "$ASSETS_DIR" \( -name "*.jpg" -o -name "*.jpeg" \) -type f -exec du -ch {} + | grep total
echo ""

echo "WebP files:"
find "$ASSETS_DIR" -name "*.webp" -type f -exec du -ch {} + | grep total
echo ""

# Large files
echo "⚠️  Large Files (> 100 KB):"
find "$ASSETS_DIR" -type f -size +${SIZE_THRESHOLD}c | while read file; do
    size=$(du -h "$file" | cut -f1)
    echo "  $size - $file"
done
echo ""

# File count
echo "📈 File Counts:"
echo "  PNG:  $(find "$ASSETS_DIR" -name "*.png" -type f | wc -l)"
echo "  JPEG: $(find "$ASSETS_DIR" \( -name "*.jpg" -o -name "*.jpeg" \) -type f | wc -l)"
echo "  WebP: $(find "$ASSETS_DIR" -name "*.webp" -type f | wc -l)"
echo "  SVG:  $(find "$ASSETS_DIR" -name "*.svg" -type f | wc -l)"
echo ""

echo "====================================="
```

---

## Optimization Workflow

### For New Assets

1. **Design at highest resolution** (@3x for mobile)
2. **Export from design tool** (Figma, Sketch, Adobe XD)
3. **Generate multiple resolutions**:
   ```bash
   ./scripts/generate_resolutions.sh assets/images/new-image.png
   ```
4. **Optimize each version**:
   ```bash
   ./scripts/optimize_png.sh
   ```
5. **Consider WebP conversion**:
   ```bash
   ./scripts/convert_to_webp.sh
   ```
6. **Analyze results**:
   ```bash
   ./scripts/analyze_assets.sh
   ```
7. **Update pubspec.yaml** if needed
8. **Test on device** to ensure quality

### For Existing Assets

1. **Run analysis**:
   ```bash
   ./scripts/analyze_assets.sh
   ```
2. **Identify optimization opportunities**
3. **Back up assets**:
   ```bash
   cp -r assets assets_backup
   ```
4. **Run optimization**:
   ```bash
   ./scripts/optimize_png.sh
   ./scripts/optimize_jpeg.sh
   ```
5. **Compare before/after**
6. **Test on device**
7. **Commit optimized assets**

---

## Best Practices

### 1. Use Vector Graphics When Possible

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/icons/
  
# Use flutter_svg package for SVG icons
dependencies:
  flutter_svg: ^2.0.9
```

```dart
// Usage
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/logo.svg',
  width: 48,
  height: 48,
  colorFilter: ColorFilter.mode(Colors.blue, BlendMode.srcIn),
)
```

### 2. Use Icon Fonts

```dart
// Prefer Material Icons or custom icon fonts over PNG icons
Icon(Icons.home, size: 24)  // Scalable, small file size
```

### 3. Lazy Load Images

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 400,  // Resize for memory efficiency
)
```

### 4. Use AssetBundle Efficiently

```dart
// Load images with specific resolution
Image.asset(
  'assets/images/logo.png',
  // Flutter automatically picks @2x or @3x based on device
)
```

### 5. Progressive Loading

```dart
// For large images, use progressive loading
Image.network(
  url,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator(
      value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded /
              loadingProgress.expectedTotalBytes!
          : null,
    );
  },
)
```

---

## App Size Optimization

### Analyze App Size

```bash
# Build release APK
flutter build apk --release --analyze-size

# View size breakdown
flutter build apk --release --target-platform android-arm64 --analyze-size
```

### Reduce App Size

1. **Enable code shrinking** (already configured in release build)
2. **Use WebP instead of PNG/JPEG**
3. **Remove unused assets**:
   ```bash
   # Find unused assets (requires asset_usage_detector)
   dart pub global activate asset_usage_detector
   dart pub global run asset_usage_detector:main
   ```
4. **Split APKs by architecture**:
   ```bash
   flutter build apk --split-per-abi
   ```
5. **Use app bundles** (Android):
   ```bash
   flutter build appbundle
   ```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/asset-check.yml
name: Asset Optimization Check
on: [pull_request]

jobs:
  check-assets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install optimization tools
        run: |
          sudo apt-get update
          sudo apt-get install -y pngquant jpegoptim webp
      
      - name: Check for large assets
        run: |
          find apps/mobile/assets -type f -size +100k
          if [ $? -eq 0 ]; then
            echo "⚠️ Warning: Found assets larger than 100KB"
          fi
      
      - name: Analyze total asset size
        run: |
          cd apps/mobile
          bash scripts/analyze_assets.sh
```

---

## Maintenance Checklist

### Weekly
- [ ] Review new assets added
- [ ] Ensure proper naming conventions
- [ ] Check for duplicate assets

### Monthly
- [ ] Run asset size analysis
- [ ] Identify optimization opportunities
- [ ] Update optimization scripts if needed

### Before Release
- [ ] Run full asset optimization
- [ ] Test optimized assets on devices
- [ ] Verify app size meets targets
- [ ] Check image quality on various screens
- [ ] Ensure all resolutions generated

---

## Asset Guidelines Summary

✅ **DO**:
- Use WebP format for photos and complex images
- Use PNG for images requiring transparency
- Use SVG for simple icons and graphics
- Provide @1x, @2x, @3x resolutions
- Compress all images before committing
- Keep asset sizes under recommended limits
- Use descriptive file names
- Organize assets in logical folders

❌ **DON'T**:
- Commit unoptimized images
- Use unnecessarily high resolutions
- Include unused assets
- Use large PNGs when JPEG/WebP would work
- Forget to test on actual devices
- Use inconsistent naming conventions
- Store temporary/backup files in assets

---

**Last Updated**: December 11, 2025  
**Next Review**: Before production release
