#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

# Set build mode to test
set_build_mode test

OUTDIR="temp/"
OBJDIR="$OUTDIR/bin/obj"
IMGDIR="$OUTDIR/img"
LOGDIR="$OUTDIR/log"
FSDIR="$OUTDIR/fs/dir"
FSFAT="$OUTDIR/fs/fat"
FSFILE="$OUTDIR/fs/file"

mkdir -p "$OUTDIR" "$OBJDIR" "$IMGDIR" "$LOGDIR" "$FSDIR" "$FSFAT" "$FSFILE"
check_error "Failed to create output directories"

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
ld -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_dir.elf" \
  "$OBJDIR/test_dir.o" \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  "$OBJDIR/test_file.o" \
  "$OBJDIR/test_fat.o" \
  temp/bin/obj/errors.o temp/bin/obj/fat.o temp/bin/obj/recovery.o \
  temp/bin/obj/file.o temp/bin/obj/io.o
objcopy -O binary "$OBJDIR/test_dir.elf" "$FSDIR/test_dir.bin"

ld -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_fat.elf" \
  "$OBJDIR/test_fat.o" \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  temp/bin/obj/errors.o temp/bin/obj/fat.o temp/bin/obj/recovery.o \
  temp/bin/obj/file.o temp/bin/obj/io.o
objcopy -O binary "$OBJDIR/test_fat.elf" "$FSFAT/test_fat.bin"

ld -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_file.elf" \
  "$OBJDIR/test_file.o" \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  temp/bin/obj/errors.o temp/bin/obj/fat.o temp/bin/obj/recovery.o \
  temp/bin/obj/file.o temp/bin/obj/io.o
objcopy -O binary "$OBJDIR/test_file.elf" "$FSFILE/test_file.bin"

ld -m elf_i386 -Ttext 0x7C00 -o "$OBJDIR/test_fs_init.elf" \
  "$OBJDIR/test_fs_init.o" \
  "$OBJDIR/dir_core.o" "$OBJDIR/dir_list.o" "$OBJDIR/dir_helpers.o" \
  temp/bin/obj/errors.o temp/bin/obj/fat.o temp/bin/obj/recovery.o \
  temp/bin/obj/file.o temp/bin/obj/io.o
objcopy -O binary "$OBJDIR/test_fs_init.elf" "$FSDIR/test_fs_init.bin"

rm -f "$OBJDIR"/*.elf

echo -e "${GREEN}All test binaries built in $OUTDIR${NC}"

# Assemble additional modules
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
