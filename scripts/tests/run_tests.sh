#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

# Get the absolute path of the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Set build mode to test (default for this script)
set_build_mode test

echo -e "${GREEN}Build mode: $BUILD_MODE${NC}"
LOGDIR="$PROJECT_ROOT/temp/log"
LOGFILE="$LOGDIR/test_run.log"
IMGDIR="$PROJECT_ROOT/temp/img"
OBJDIR="$PROJECT_ROOT/temp/bin/obj"
FSDIR="$PROJECT_ROOT/temp/fs/dir"
FSFAT="$PROJECT_ROOT/temp/fs/fat"
FSFILE="$PROJECT_ROOT/temp/fs/file"

# Create necessary directories
mkdir -p "$OBJDIR" "$LOGDIR" "$IMGDIR" "$FSDIR" "$FSFAT" "$FSFILE"

# Build and run file system tests
echo "Building and running x16FS-Lite tests..." | tee "$LOGFILE"

# Assemble source files into object files
echo "Assembling source files..." | tee -a "$LOGFILE"

# Directory modules
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/core.asm" -o "$OBJDIR/dir_core.o"
check_error "Failed to assemble dir/core.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/list.asm" -o "$OBJDIR/dir_list.o"
check_error "Failed to assemble dir/list.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/helpers.asm" -o "$OBJDIR/dir_helpers.o"
check_error "Failed to assemble dir/helpers.asm"

# Test files (assemble as object files)
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/dir/test_dir.asm" -o "$OBJDIR/test_dir.o"
check_error "Failed to assemble test_dir.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/dir/test_dir_consistency.asm" -o "$OBJDIR/test_dir_consistency.o"
check_error "Failed to assemble test_dir_consistency.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat.asm" -o "$OBJDIR/test_fat.o"
check_error "Failed to assemble test_fat.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat_chain.asm" -o "$OBJDIR/test_fat_chain.o"
check_error "Failed to assemble test_fat_chain.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/file/test_file.asm" -o "$OBJDIR/test_file.o"
check_error "Failed to assemble test_file.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/file/test_file_size.asm" -o "$OBJDIR/test_file_size.o"
check_error "Failed to assemble test_file_size.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat_chain_validation.asm" -o "$OBJDIR/test_fat_chain_validation.o"
check_error "Failed to assemble test_fat_chain_validation.asm"

# Assemble required modules for linking
nasm -f elf -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/errors.asm" -o "$OBJDIR/errors.o"
check_error "Failed to assemble errors.asm"
nasm -f elf -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/fat.asm" -o "$OBJDIR/fat.o"
check_error "Failed to assemble fat.asm"
nasm -f elf -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/recovery.asm" -o "$OBJDIR/recovery.o"
check_error "Failed to assemble recovery.asm"
nasm -f elf -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/file.asm" -o "$OBJDIR/file.o"
check_error "Failed to assemble file.asm"
nasm -f elf -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/lib/io.asm" -o "$OBJDIR/io.o"
check_error "Failed to assemble io.asm"

# Link each test with all required object files and io.o to produce .bin for QEMU
link_test() {
    TEST_OBJ=$1
    OUT_BIN=$2
    x86_64-elf-ld -m elf_i386 -e _start -static \
        "$OBJDIR/$TEST_OBJ" \
        "$OBJDIR/errors.o" \
        "$OBJDIR/fat.o" \
        "$OBJDIR/recovery.o" \
        "$OBJDIR/dir_core.o" \
        "$OBJDIR/dir_list.o" \
        "$OBJDIR/dir_helpers.o" \
        "$OBJDIR/file.o" \
        "$OBJDIR/io.o" \
        -o "$IMGDIR/$OUT_BIN.elf"
    check_error "Failed to link $OUT_BIN.elf"
    x86_64-elf-objcopy -O binary "$IMGDIR/$OUT_BIN.elf" "$IMGDIR/$OUT_BIN"
    check_error "Failed to objcopy $OUT_BIN"
    rm -f "$IMGDIR/$OUT_BIN.elf"
}

link_test test_dir.o fs/dir/test_dir.bin
link_test test_dir_consistency.o fs/dir/test_dir_consistency.bin
link_test test_fat.o fs/fat/test_fat.bin
link_test test_fat_chain.o fs/fat/test_fat_chain.bin
link_test test_file.o fs/file/test_file.bin
link_test test_file_size.o fs/file/test_file_size.bin
link_test test_fat_chain_validation.o fs/fat/test_fat_chain_validation.bin

# Create test disk image
echo "Creating test disk image..."
rm -f "$IMGDIR/test.img"
truncate -s 1474560 "$IMGDIR/test.img"  # 2880 sectors * 512 bytes

# Run each test in QEMU
echo "Running tests in QEMU..."

# Directory tests
echo "Running directory tests..."
cp "$IMGDIR/fs/dir/test_dir.bin" "$IMGDIR/test.img"
qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio | tee "$LOGDIR/test_dir.out"

cp "$IMGDIR/fs/dir/test_dir_consistency.bin" "$IMGDIR/test.img"
qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio | tee "$LOGDIR/test_dir_consistency.out"

# FAT tests
echo "Running FAT tests..."
cp "$IMGDIR/fs/fat/test_fat.bin" "$IMGDIR/test.img"
qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio | tee "$LOGDIR/test_fat.out"

cp "$IMGDIR/fs/fat/test_fat_chain.bin" "$IMGDIR/test.img"
qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio | tee "$LOGDIR/test_fat_chain.out"

cp "$IMGDIR/fs/fat/test_fat_chain_validation.bin" "$IMGDIR/test.img"
qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio | tee "$LOGDIR/test_fat_chain_validation.out"

# File tests
echo "Running file tests..."
cp "$IMGDIR/fs/file/test_file.bin" "$IMGDIR/test.img"
qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio | tee "$LOGDIR/test_file.out"

cp "$IMGDIR/fs/file/test_file_size.bin" "$IMGDIR/test.img"
qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio | tee "$LOGDIR/test_file_size.out"

# Clean up
echo "Cleaning up..."
rm -f "$IMGDIR/test.img"
rm -f "$IMGDIR/fs/dir/test_dir.bin" "$IMGDIR/fs/dir/test_dir_consistency.bin"
rm -f "$IMGDIR/fs/fat/test_fat.bin" "$IMGDIR/fs/fat/test_fat_chain.bin" "$IMGDIR/fs/fat/test_fat_chain_validation.bin"
rm -f "$IMGDIR/fs/file/test_file.bin" "$IMGDIR/fs/file/test_file_size.bin"
rm -rf "$OBJDIR"
