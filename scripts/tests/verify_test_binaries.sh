#!/bin/bash

# List of expected test binaries (relative to temp/img/)
expected_bins=(
  "fs/dir/test_dir_fill.bin"
  "fs/dir/test_dir_overflow.bin"
  "fs/dir/test_dir_delete.bin"
  "fs/dir/test_dir_attr.bin"
  "fs/dir/test_dir_edge.bin"
  "fs/dir/test_dir_consistency.bin"
  "fs/fat/test_fat.bin"
  "fs/fat/test_fat_chain.bin"
  "fs/fat/test_fat_chain_validation.bin"
  "fs/file/test_file.bin"
  "fs/file/test_file_size.bin"
)

IMGDIR="temp/img"
missing=0

echo "Verifying test binaries in $IMGDIR..."

for bin in "${expected_bins[@]}"; do
  if [ ! -f "$IMGDIR/$bin" ]; then
    echo "❌ Missing: $IMGDIR/$bin"
    missing=1
  else
    echo "✅ Found:   $IMGDIR/$bin"
  fi
done

if [ $missing -eq 0 ]; then
  echo "All expected test binaries are present."
  exit 0
else
  echo "Some test binaries are missing!"
  exit 1
fi 