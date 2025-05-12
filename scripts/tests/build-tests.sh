#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

# Set build mode to test
set_build_mode test

OUTDIR="temp/"
OBJDIR="$OUTDIR/obj"
mkdir -p "$OUTDIR" "$OBJDIR"
check_error "Failed to create $OUTDIR directory"

# Assemble required modules
nasm -f elf src/fs/dir/core.asm -o "$OBJDIR/dir_core.o"
check_error "Failed to assemble dir/core.asm"
nasm -f elf src/fs/dir/list.asm -o "$OBJDIR/dir_list.o"
check_error "Failed to assemble dir/list.asm"
nasm -f elf src/fs/dir/helpers.asm -o "$OBJDIR/dir_helpers.o"
check_error "Failed to assemble dir/helpers.asm"

# Assemble test object files
nasm -f elf tests/fs/dir/test_dir.asm -o "$OBJDIR/test_dir.o"
check_error "Failed to assemble directory test program"
nasm -f elf tests/fs/fat/test_fat.asm -o "$OBJDIR/test_fat.o"
check_error "Failed to assemble FAT test program"
nasm -f elf tests/fs/file/test_file.asm -o "$OBJDIR/test_file.o"
check_error "Failed to assemble file test program"
nasm -f elf tests/fs/init/test_fs_init.asm -o "$OBJDIR/test_fs_init.o"
check_error "Failed to assemble filesystem initialization test program"

# Link and objcopy to .bin for each test (update as needed for dependencies)
ld -Ttext 0x7C00 -o "$OUTDIR/test_dir.elf" \
  "$OBJDIR/test_dir.o" \
  bin/obj/errors.o bin/obj/fat.o bin/obj/recovery.o \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  bin/obj/file.o bin/obj/io.o
objcopy -O binary "$OUTDIR/test_dir.elf" "$OUTDIR/test_dir.bin"

ld -Ttext 0x7C00 -o "$OUTDIR/test_fat.elf" \
  "$OBJDIR/test_fat.o" \
  bin/obj/errors.o bin/obj/fat.o bin/obj/recovery.o \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  bin/obj/file.o bin/obj/io.o
objcopy -O binary "$OUTDIR/test_fat.elf" "$OUTDIR/test_fat.bin"

ld -Ttext 0x7C00 -o "$OUTDIR/test_file.elf" \
  "$OBJDIR/test_file.o" \
  bin/obj/errors.o bin/obj/fat.o bin/obj/recovery.o \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  bin/obj/file.o bin/obj/io.o
objcopy -O binary "$OUTDIR/test_file.elf" "$OUTDIR/test_file.bin"

ld -Ttext 0x7C00 -o "$OUTDIR/test_fs_init.elf" \
  "$OBJDIR/test_fs_init.o" \
  bin/obj/errors.o bin/obj/fat.o bin/obj/recovery.o \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  bin/obj/file.o bin/obj/io.o
objcopy -O binary "$OUTDIR/test_fs_init.elf" "$OUTDIR/test_fs_init.bin"

rm -f "$OUTDIR"/*.elf

echo -e "${GREEN}All test binaries built in $OUTDIR${NC}"
