#!/bin/bash
# Optimize PNG images in assets directory

ASSETS_DIR="assets/images"

echo "🖼️  Optimizing PNG images in $ASSETS_DIR..."
echo ""

# Check if pngquant is installed
if ! command -v pngquant &> /dev/null; then
    echo "❌ pngquant not found. Please install it first:"
    echo "   macOS: brew install pngquant"
    echo "   Linux: sudo apt-get install pngquant"
    exit 1
fi

# Count total files
total_files=$(find "$ASSETS_DIR" -name "*.png" -type f | wc -l | tr -d ' ')
if [ "$total_files" -eq 0 ]; then
    echo "✓ No PNG files found in $ASSETS_DIR"
    exit 0
fi

echo "Found $total_files PNG file(s) to optimize"
echo ""

# Track statistics
optimized_count=0
failed_count=0
total_saved=0

# Find and optimize all PNG files
find "$ASSETS_DIR" -name "*.png" -type f | while read file; do
    echo "Processing: $file"
    
    # Get original size
    original_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Optimize with pngquant (lossy but high quality)
    pngquant --quality=80-95 --ext .png --force "$file" 2>/dev/null
    
    # Check if optimization succeeded
    if [ $? -ne 0 ]; then
        echo "  ✗ Failed, restoring backup"
        mv "$file.backup" "$file"
        ((failed_count++))
    else
        # Get new size
        new_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
        saved=$((original_size - new_size))
        percentage=$((saved * 100 / original_size))
        
        echo "  ✓ Optimized: $original_size → $new_size bytes (saved $percentage%)"
        rm "$file.backup"
        ((optimized_count++))
        ((total_saved += saved))
    fi
    echo ""
done

echo "====================================="
echo "PNG Optimization Complete!"
echo "====================================="
echo "Optimized: $optimized_count files"
if [ $failed_count -gt 0 ]; then
    echo "Failed: $failed_count files"
fi
echo "Total saved: $(numfmt --to=iec-i --suffix=B $total_saved 2>/dev/null || echo $total_saved bytes)"
echo ""
