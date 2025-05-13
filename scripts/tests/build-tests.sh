#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

# Set build mode to test
set_build_mode test

OUTDIR="temp/"
OBJDIR="$OUTDIR/bin/obj"
IMGDIR="temp/img"
LOGDIR="$OUTDIR/log"
FSDIR="$IMGDIR/fs/dir"
FSFAT="$IMGDIR/fs/fat"
FSFILE="$IMGDIR/fs/file"

# Ensure all output directories exist
mkdir -p "$OUTDIR" "$OBJDIR" "$IMGDIR" "$LOGDIR" "$FSDIR" "$FSFAT" "$FSFILE" "$IMGDIR/fs/dir" "$IMGDIR/fs/fat" "$IMGDIR/fs/file"
check_error "Failed to create output directories"

# Assemble required modules
nasm -f elf src/fs/dir/core.asm -o "$OBJDIR/dir_core.o"
check_error "Failed to assemble dir/core.asm"
nasm -f elf src/fs/dir/list.asm -o "$OBJDIR/dir_list.o"
check_error "Failed to assemble dir/list.asm"
nasm -f elf src/fs/dir/helpers.asm -o "$OBJDIR/dir_helpers.o"
check_error "Failed to assemble dir/helpers.asm"
nasm -f elf src/fs/dir/ops.asm -o "$OBJDIR/dir_ops.o"
check_error "Failed to assemble dir/ops.asm"

# Assemble additional modules (moved up)
nasm -f elf src/fs/errors.asm -o temp/bin/obj/errors.o
check_error "Failed to assemble errors.asm"
nasm -f elf src/fs/fat.asm -o temp/bin/obj/fat.o
check_error "Failed to assemble fat.asm"
nasm -f elf src/fs/recovery.asm -o temp/bin/obj/recovery.o
check_error "Failed to assemble recovery.asm"
nasm -f elf src/fs/file.asm -o temp/bin/obj/file.o
check_error "Failed to assemble file.asm"
nasm -f elf src/lib/io.asm -o temp/bin/obj/io.o
check_error "Failed to assemble io.asm"

# Assemble test object files
# nasm -f elf tests/fs/dir/test_dir.asm -o "$OBJDIR/test_dir.o"
# check_error "Failed to assemble directory test program"
nasm -f bin tests/fs/fat/test_fat.asm -o "$FSFAT/test_fat.bin"
check_error "Failed to assemble FAT test program"
nasm -f bin tests/fs/file/test_file.asm -o "$FSFILE/test_file.bin"
check_error "Failed to assemble file test program"
nasm -f elf tests/fs/init/test_fs_init.asm -o "$OBJDIR/test_fs_init.o"
check_error "Failed to assemble filesystem initialization test program"

# DEBUG: Print info before assembling test_dir_fill_clean.asm
pwd
ls -l tests/fs/dir/test_dir_fill_clean.asm
file tests/fs/dir/test_dir_fill_clean.asm
echo "Running: nasm -f bin tests/fs/dir/test_dir_fill_clean.asm -o $FSDIR/test_dir_fill_clean.bin"

nasm -f bin tests/fs/dir/test_dir_fill_clean.asm -o "$FSDIR/test_dir_fill_clean.bin"
check_error "Failed to assemble directory fill test program"

# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_fill_clean.elf" \
#   "$OBJDIR/test_dir_fill_clean.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_fill_clean.elf" "$FSDIR/test_dir_fill_clean.bin"
# scripts/utils/make_boot_sector.sh "$FSDIR/test_dir_fill_clean.bin" "$FSDIR/test_dir_fill_clean.bin"

nasm -f bin tests/fs/dir/test_dir_overflow.asm -o "$FSDIR/test_dir_overflow.bin"
check_error "Failed to assemble directory overflow test program"

# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_overflow.elf" \
#   "$OBJDIR/test_dir_overflow.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_overflow.elf" "$FSDIR/test_dir_overflow.bin"
# scripts/utils/make_boot_sector.sh "$FSDIR/test_dir_overflow.bin" "$FSDIR/test_dir_overflow.bin"

# Assemble test_dir_delete as a flat binary
nasm -f bin tests/fs/dir/test_dir_delete.asm -o "$FSDIR/test_dir_delete.bin"
check_error "Failed to assemble directory delete test program"

# Assemble test_dir_attr as a flat binary
nasm -f bin tests/fs/dir/test_dir_attr.asm -o "$FSDIR/test_dir_attr.bin"
check_error "Failed to assemble directory attribute test program"

# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_attr.elf" \
#   "$OBJDIR/test_dir_attr.o" \
#   "$OBJDIR/dir_core.o" "$OBJDIR/dir_helpers.o" "$OBJDIR/dir_ops.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_attr.elf" "$FSDIR/test_dir_attr.bin"
# scripts/utils/make_boot_sector.sh "$FSDIR/test_dir_attr.bin" "$FSDIR/test_dir_attr.bin"

# nasm -f elf tests/fs/dir/test_dir_edge.asm -o "$OBJDIR/test_dir_edge.o"
# check_error "Failed to assemble directory edge case test program"
# nasm -f elf tests/fs/dir/test_dir_consistency.asm -o "$OBJDIR/test_dir_consistency.o"
# check_error "Failed to assemble directory consistency test program"

LD=x86_64-elf-ld
OBJCOPY=x86_64-elf-objcopy

# Link and objcopy to .bin for each test (only one test object per binary)
# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir.elf" \
#   "$OBJDIR/test_dir.o" \
#   "$OBJDIR/dir_core.o" "$OBJDIR/dir_helpers.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir.elf" "$FSDIR/test_dir.bin"

# Remove linker and objcopy for test_fat (already a flat binary)
# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_fat.elf" \
#   "$OBJDIR/test_fat.o" \
#   "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" "$OBJDIR/dir_ops.o" \
#   temp/bin/obj/errors.o temp/bin/obj/fat.o temp/bin/obj/recovery.o \
#   temp/bin/obj/file.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_fat.elf" "$FSFAT/test_fat.bin"

$LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_fs_init.elf" \
  "$OBJDIR/test_fs_init.o" \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" "$OBJDIR/dir_ops.o" \
  temp/bin/obj/errors.o temp/bin/obj/fat.o temp/bin/obj/recovery.o \
  temp/bin/obj/file.o temp/bin/obj/io.o
$OBJCOPY -O binary "$OBJDIR/test_fs_init.elf" "$FSDIR/test_fs_init.bin"

# Standalone directory tests (do NOT link core dir objects)
# Note: test_dir_fill is commented out, assuming it's handled elsewhere or deprecated
# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_fill.elf" \
#   "$OBJDIR/test_dir_fill.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_fill.elf" "$FSDIR/test_dir_fill.bin"
# scripts/utils/make_boot_sector.sh "$FSDIR/test_dir_fill.bin" "$FSDIR/test_dir_fill.bin"

# Remove linker/objcopy for test_dir_delete (already a flat binary)
# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_delete.elf" \
#   "$OBJDIR/test_dir_delete.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_delete.elf" "$FSDIR/test_dir_delete.bin"
# scripts/utils/make_boot_sector.sh "$FSDIR/test_dir_delete.bin" "$FSDIR/test_dir_delete.bin"

# Assemble test_dir_edge as a flat binary
nasm -f bin tests/fs/dir/test_dir_edge.asm -o "$FSDIR/test_dir_edge.bin"
check_error "Failed to assemble directory edge case test program"

# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_edge.elf" \
#   "$OBJDIR/test_dir_edge.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_edge.elf" "$FSDIR/test_dir_edge.bin"
# scripts/utils/make_boot_sector.sh "$FSDIR/test_dir_edge.bin" "$FSDIR/test_dir_edge.bin"

# Assemble test_dir_consistency as a flat binary
nasm -f bin tests/fs/dir/test_dir_consistency.asm -o "$FSDIR/test_dir_consistency.bin"
check_error "Failed to assemble directory consistency test program"

# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_consistency.elf" \
#   "$OBJDIR/test_dir_consistency.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_consistency.elf" "$FSDIR/test_dir_consistency.bin"
# scripts/utils/make_boot_sector.sh "$FSDIR/test_dir_consistency.bin" "$FSDIR/test_dir_consistency.bin"

# Integration test: test_dir_attr (link with core dir objects)
# $LD -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir_attr.elf" \
#   "$OBJDIR/test_dir_attr.o" \
#   "$OBJDIR/dir_core.o" "$OBJDIR/dir_helpers.o" "$OBJDIR/dir_ops.o" \
#   temp/bin/obj/errors.o temp/bin/obj/io.o
# $OBJCOPY -O binary "$OBJDIR/test_dir_attr.elf" "$FSDIR/test_dir_attr.bin"

rm -f "$OBJDIR"/*.elf

echo -e "${GREEN}All test binaries built in $OUTDIR${NC}"
