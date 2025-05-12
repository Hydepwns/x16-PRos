#!/bin/bash

source "$(dirname "$0")/../utils/build_common.sh"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMGDIR="$PROJECT_ROOT/temp/img"
LOGDIR="$PROJECT_ROOT/temp/log"
LOGFILE="$LOGDIR/qemu_run.log"

mkdir -p "$LOGDIR"

log_phase "Running tests in QEMU"

# Directory tests
declare -a DIR_TESTS=(
  "fs/dir/test_dir_fill.bin"
  "fs/dir/test_dir_overflow.bin"
  "fs/dir/test_dir_delete.bin"
  "fs/dir/test_dir_attr.bin"
  "fs/dir/test_dir_edge.bin"
)
for bin in "${DIR_TESTS[@]}"; do
  cp "$IMGDIR/$bin" "$IMGDIR/test.img"
  timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/$(basename "$bin" .bin).out"
done

# FAT tests
declare -a FAT_TESTS=(
  "fs/fat/test_fat.bin"
  "fs/fat/test_fat_chain.bin"
  "fs/fat/test_fat_chain_validation.bin"
)
for bin in "${FAT_TESTS[@]}"; do
  cp "$IMGDIR/$bin" "$IMGDIR/test.img"
  timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/$(basename "$bin" .bin).out"
done

# File tests
declare -a FILE_TESTS=(
  "fs/file/test_file.bin"
  "fs/file/test_file_size.bin"
)
for bin in "${FILE_TESTS[@]}"; do
  cp "$IMGDIR/$bin" "$IMGDIR/test.img"
  timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/$(basename "$bin" .bin).out"
done

rm -f "$IMGDIR/test.img" 