#!/bin/bash
# make_loader_disk.sh
# Usage: ./make_loader_disk.sh <test_binary> <num_sectors> <output_disk_image>
# Builds a bootable disk image with loader (sector 0) and test (sectors 1+).
# - <test_binary>: path to test binary
# - <num_sectors>: number of 512-byte sectors to load (must cover test size)
# - <output_disk_image>: output disk image file

set -e

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <test_binary> <num_sectors> <output_disk_image>"
  exit 1
fi

TEST_BIN="$1"
SECTORS="$2"
DISK_IMG="$3"
SCRIPT_DIR="$(dirname "$0")"
LOADER_SRC="$SCRIPT_DIR/loader.asm"
LOADER_BIN="$SCRIPT_DIR/loader.bin"

# Assemble loader with correct SECTOR_COUNT
nasm -DSECTOR_COUNT="$SECTORS" -f bin "$LOADER_SRC" -o "$LOADER_BIN"

# Pad test binary to a multiple of 512 bytes
PADDED_TEST_BIN="$TEST_BIN.padded"
cp "$TEST_BIN" "$PADDED_TEST_BIN"
TEST_SIZE=$(stat -c %s "$PADDED_TEST_BIN" 2>/dev/null || stat -f %z "$PADDED_TEST_BIN")
PAD_SIZE=$(( ( ( (TEST_SIZE + 511) / 512 ) * 512 ) - TEST_SIZE ))
if [ "$PAD_SIZE" -gt 0 ]; then
  dd if=/dev/zero bs=1 count=$PAD_SIZE >> "$PADDED_TEST_BIN" 2>/dev/null
fi

# Check padded size matches requested sectors
PADDED_SIZE=$(stat -c %s "$PADDED_TEST_BIN" 2>/dev/null || stat -f %z "$PADDED_TEST_BIN")
REQUIRED_SIZE=$(( SECTORS * 512 ))
if [ "$PADDED_SIZE" -gt "$REQUIRED_SIZE" ]; then
  echo "Error: Test binary ($PADDED_SIZE bytes) is larger than $SECTORS sectors ($REQUIRED_SIZE bytes)" >&2
  rm -f "$LOADER_BIN" "$PADDED_TEST_BIN"
  exit 2
fi
# Pad to exactly SECTORS*512
if [ "$PADDED_SIZE" -lt "$REQUIRED_SIZE" ]; then
  dd if=/dev/zero bs=1 count=$((REQUIRED_SIZE - PADDED_SIZE)) >> "$PADDED_TEST_BIN" 2>/dev/null
fi

# Create disk image: loader (512 bytes) + padded test
cat "$LOADER_BIN" "$PADDED_TEST_BIN" > "$DISK_IMG"

# Clean up
rm -f "$LOADER_BIN" "$PADDED_TEST_BIN"

echo "Disk image created: $DISK_IMG (loader + $SECTORS sectors test)"
