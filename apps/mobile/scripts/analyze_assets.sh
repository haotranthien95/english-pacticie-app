#!/bin/bash
# Analyze asset sizes and identify optimization opportunities

ASSETS_DIR="assets"
SIZE_THRESHOLD=100000  # 100 KB in bytes

echo "====================================="
echo "📊 Asset Size Analysis"
echo "====================================="
echo ""

# Check if assets directory exists
if [ ! -d "$ASSETS_DIR" ]; then
    echo "❌ Assets directory not found: $ASSETS_DIR"
    exit 1
fi

# Total size
echo "📦 Total Assets Size:"
total_size=$(du -sh "$ASSETS_DIR" 2>/dev/null | cut -f1)
echo "   $total_size"
echo ""

# Size by type
echo "📊 Size by File Type:"

png_size=$(find "$ASSETS_DIR" -name "*.png" -type f -exec du -ch {} + 2>/dev/null | grep total | cut -f1)
png_count=$(find "$ASSETS_DIR" -name "*.png" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$png_count" -gt 0 ]; then
    echo "   PNG:  $png_size ($png_count files)"
else
    echo "   PNG:  0 B (0 files)"
fi

jpeg_size=$(find "$ASSETS_DIR" \( -name "*.jpg" -o -name "*.jpeg" \) -type f -exec du -ch {} + 2>/dev/null | grep total | cut -f1)
jpeg_count=$(find "$ASSETS_DIR" \( -name "*.jpg" -o -name "*.jpeg" \) -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$jpeg_count" -gt 0 ]; then
    echo "   JPEG: $jpeg_size ($jpeg_count files)"
else
    echo "   JPEG: 0 B (0 files)"
fi

webp_size=$(find "$ASSETS_DIR" -name "*.webp" -type f -exec du -ch {} + 2>/dev/null | grep total | cut -f1)
webp_count=$(find "$ASSETS_DIR" -name "*.webp" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$webp_count" -gt 0 ]; then
    echo "   WebP: $webp_size ($webp_count files)"
else
    echo "   WebP: 0 B (0 files)"
fi

svg_count=$(find "$ASSETS_DIR" -name "*.svg" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$svg_count" -gt 0 ]; then
    svg_size=$(find "$ASSETS_DIR" -name "*.svg" -type f -exec du -ch {} + 2>/dev/null | grep total | cut -f1)
    echo "   SVG:  $svg_size ($svg_count files)"
else
    echo "   SVG:  0 B (0 files)"
fi

echo ""

# Large files warning
echo "⚠️  Large Files (> 100 KB):"
large_files=$(find "$ASSETS_DIR" -type f -size +${SIZE_THRESHOLD}c 2>/dev/null)

if [ -z "$large_files" ]; then
    echo "   ✓ No large files found"
else
    echo "$large_files" | while read file; do
        size=$(du -h "$file" | cut -f1)
        echo "   $size - $file"
    done
fi
echo ""

# File count summary
total_images=$((png_count + jpeg_count + webp_count))
echo "📈 Summary:"
echo "   Total image files: $total_images"
echo "   PNG:  $png_count"
echo "   JPEG: $jpeg_count"
echo "   WebP: $webp_count"
echo "   SVG:  $svg_count"
echo ""

# Recommendations
echo "💡 Recommendations:"

if [ "$png_count" -gt 0 ] && [ "$webp_count" -eq 0 ]; then
    echo "   • Consider converting PNG files to WebP for better compression"
fi

if [ "$jpeg_count" -gt 0 ]; then
    echo "   • Run JPEG optimization: ./scripts/optimize_jpeg.sh"
fi

if [ "$png_count" -gt 0 ]; then
    echo "   • Run PNG optimization: ./scripts/optimize_png.sh"
fi

if [ -n "$large_files" ]; then
    echo "   • Optimize large files identified above"
fi

if [ "$total_images" -eq 0 ]; then
    echo "   • No image assets found - this is normal if using remote images only"
fi

echo ""
echo "====================================="
