#!/bin/bash
# make_boot_sector.sh
# Usage: ./make_boot_sector.sh <input_binary> <output_boot_sector>
# Pads <input_binary> to 510 bytes, appends 0x55AA, and writes to <output_boot_sector>.
# Result is a 512-byte boot sector image suitable for QEMU or real hardware.

set -e

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_binary> <output_boot_sector>"
  exit 1
fi

INFILE="$1"
OUTFILE="$2"

# Pad or truncate to 510 bytes
truncate -s 510 "$OUTFILE"
dd if="$INFILE" of="$OUTFILE" bs=1 count=510 conv=notrunc 2>/dev/null || true

# Append 0x55AA signature
printf '\x55\xAA' >> "$OUTFILE"

# Check result
SIZE=$(stat -c %s "$OUTFILE" 2>/dev/null || stat -f %z "$OUTFILE")
if [ "$SIZE" -ne 512 ]; then
  echo "Error: Output is not 512 bytes (got $SIZE bytes)" >&2
  exit 2
fi

echo "Boot sector image created: $OUTFILE (512 bytes)" 