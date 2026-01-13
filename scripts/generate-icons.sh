#!/bin/bash

# Generate placeholder icons for LastReboot
# Replace these with proper icons for production

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="${SCRIPT_DIR}/../LastReboot/LastReboot/Assets.xcassets/AppIcon.appiconset"

# Create a simple colored placeholder icon using macOS built-in tools
# For production, replace these with properly designed icons

create_icon() {
    local size=$1
    local output="${ICONS_DIR}/icon-${size}x${size}.png"

    # Create a simple colored PNG using Python (available on macOS)
    python3 << EOF
import struct
import zlib

def create_png(width, height, r, g, b):
    def chunk(chunk_type, data):
        chunk_len = len(data)
        chunk = chunk_type + data
        checksum = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', chunk_len) + chunk + struct.pack('>I', checksum)

    def png_chunk(data):
        return chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) + \
               chunk(b'IDAT', zlib.compress(data)) + \
               chunk(b'IEND', b'')

    # PNG signature
    signature = b'\x89PNG\r\n\x1a\n'

    # Image data (RGB)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter byte
        for x in range(width):
            raw_data += bytes([r, g, b])

    return signature + png_chunk(raw_data)

# Dark gray clock icon background (54, 57, 63)
data = create_png(512, 512, 54, 57, 63)
with open('${output}', 'wb') as f:
    f.write(data)

print(f'Created ${output}')
EOF
}

# Create placeholder icons for all sizes
echo "Generating placeholder icons..."

for size in 16 32 128 256 512; do
    create_icon $size
done

echo ""
echo "Generated placeholder icons."
echo "WARNING: These are simple colored placeholders."
echo "For production, replace with properly designed app icons."
echo ""
echo "Icon design guidelines:"
echo "  - Use a 1024x1024 master icon"
echo "  - Export at 16, 32, 128, 256, 512 (1x and 2x for macOS)"
echo "  - Use PNG format with transparency"
echo "  - Tools: Sketch, Figma, Photoshop, or https://icon.kitchen"
