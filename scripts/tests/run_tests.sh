#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

# Get the absolute path of the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Set build mode to test (default for this script)
set_build_mode test

echo -e "${GREEN}Build mode: $BUILD_MODE${NC}"

# Build and run file system tests
echo "Building and running x16FS-Lite tests..."

# Create temporary directory for object files
mkdir -p "$PROJECT_ROOT/temp/obj"

# Assemble source files into object files
echo "Assembling source files..."

# Directory modules
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/core.asm" -o "$PROJECT_ROOT/temp/obj/dir_core.o"
check_error "Failed to assemble dir/core.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/list.asm" -o "$PROJECT_ROOT/temp/obj/dir_list.o"
check_error "Failed to assemble dir/list.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/helpers.asm" -o "$PROJECT_ROOT/temp/obj/dir_helpers.o"
check_error "Failed to assemble dir/helpers.asm"

# Test files (assemble as object files)
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/dir/test_dir.asm" -o "$PROJECT_ROOT/temp/obj/test_dir.o"
check_error "Failed to assemble test_dir.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/dir/test_dir_consistency.asm" -o "$PROJECT_ROOT/temp/obj/test_dir_consistency.o"
check_error "Failed to assemble test_dir_consistency.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat.asm" -o "$PROJECT_ROOT/temp/obj/test_fat.o"
check_error "Failed to assemble test_fat.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat_chain.asm" -o "$PROJECT_ROOT/temp/obj/test_fat_chain.o"
check_error "Failed to assemble test_fat_chain.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/file/test_file.asm" -o "$PROJECT_ROOT/temp/obj/test_file.o"
check_error "Failed to assemble test_file.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/file/test_file_size.asm" -o "$PROJECT_ROOT/temp/obj/test_file_size.o"
check_error "Failed to assemble test_file_size.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat_chain_validation.asm" -o "$PROJECT_ROOT/temp/obj/test_fat_chain_validation.o"
check_error "Failed to assemble test_fat_chain_validation.asm"

# Link each test with all required object files and io.o to produce .bin for QEMU
link_test() {
    TEST_OBJ=$1
    OUT_BIN=$2
    x86_64-elf-ld -e _start -static \
        "$PROJECT_ROOT/temp/obj/$TEST_OBJ" \
        "$PROJECT_ROOT/bin/obj/errors.o" \
        "$PROJECT_ROOT/bin/obj/fat.o" \
        "$PROJECT_ROOT/bin/obj/recovery.o" \
        "$PROJECT_ROOT/temp/obj/dir_core.o" \
        "$PROJECT_ROOT/temp/obj/dir_list.o" \
        "$PROJECT_ROOT/temp/obj/dir_helpers.o" \
        "$PROJECT_ROOT/bin/obj/file.o" \
        "$PROJECT_ROOT/bin/obj/io.o" \
        -o "$PROJECT_ROOT/temp/$OUT_BIN.elf"
    check_error "Failed to link $OUT_BIN.elf"
    x86_64-elf-objcopy -O binary "$PROJECT_ROOT/temp/$OUT_BIN.elf" "$PROJECT_ROOT/temp/$OUT_BIN"
    check_error "Failed to objcopy $OUT_BIN"
    rm -f "$PROJECT_ROOT/temp/$OUT_BIN.elf"
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
cd "$PROJECT_ROOT/temp" || exit 1
rm -f "$PROJECT_ROOT/temp/test.img"
mkdir -p "$PROJECT_ROOT/temp/fs/dir" "$PROJECT_ROOT/temp/fs/fat" "$PROJECT_ROOT/temp/fs/file"
truncate -s 1474560 "$PROJECT_ROOT/temp/test.img"  # 2880 sectors * 512 bytes

# Run each test in QEMU
echo "Running tests in QEMU..."

# Directory tests
echo "Running directory tests..."
cp "$PROJECT_ROOT/temp/fs/dir/test_dir.bin" "$PROJECT_ROOT/temp/test.img"
qemu-system-i386 -drive format=raw,file="$PROJECT_ROOT/temp/test.img" -monitor none -display none -serial stdio | tee "$PROJECT_ROOT/temp/fs/dir/test_dir.out"

cp "$PROJECT_ROOT/temp/fs/dir/test_dir_consistency.bin" "$PROJECT_ROOT/temp/test.img"
qemu-system-i386 -drive format=raw,file="$PROJECT_ROOT/temp/test.img" -monitor none -display none -serial stdio | tee "$PROJECT_ROOT/temp/fs/dir/test_dir_consistency.out"

# FAT tests
echo "Running FAT tests..."
cp "$PROJECT_ROOT/temp/fs/fat/test_fat.bin" "$PROJECT_ROOT/temp/test.img"
qemu-system-i386 -drive format=raw,file="$PROJECT_ROOT/temp/test.img" -monitor none -display none -serial stdio | tee "$PROJECT_ROOT/temp/fs/fat/test_fat.out"

cp "$PROJECT_ROOT/temp/fs/fat/test_fat_chain.bin" "$PROJECT_ROOT/temp/test.img"
qemu-system-i386 -drive format=raw,file="$PROJECT_ROOT/temp/test.img" -monitor none -display none -serial stdio | tee "$PROJECT_ROOT/temp/fs/fat/test_fat_chain.out"

cp "$PROJECT_ROOT/temp/fs/fat/test_fat_chain_validation.bin" "$PROJECT_ROOT/temp/test.img"
qemu-system-i386 -drive format=raw,file="$PROJECT_ROOT/temp/test.img" -monitor none -display none -serial stdio | tee "$PROJECT_ROOT/temp/fs/fat/test_fat_chain_validation.out"

# File tests
echo "Running file tests..."
cp "$PROJECT_ROOT/temp/fs/file/test_file.bin" "$PROJECT_ROOT/temp/test.img"
qemu-system-i386 -drive format=raw,file="$PROJECT_ROOT/temp/test.img" -monitor none -display none -serial stdio | tee "$PROJECT_ROOT/temp/fs/file/test_file.out"

cp "$PROJECT_ROOT/temp/fs/file/test_file_size.bin" "$PROJECT_ROOT/temp/test.img"
qemu-system-i386 -drive format=raw,file="$PROJECT_ROOT/temp/test.img" -monitor none -display none -serial stdio | tee "$PROJECT_ROOT/temp/fs/file/test_file_size.out"

# Clean up
echo "Cleaning up..."
rm -f "$PROJECT_ROOT/temp/test.img"
rm -f "$PROJECT_ROOT/temp/fs/dir/test_dir.bin" "$PROJECT_ROOT/temp/fs/dir/test_dir_consistency.bin"
rm -f "$PROJECT_ROOT/temp/fs/fat/test_fat.bin" "$PROJECT_ROOT/temp/fs/fat/test_fat_chain.bin" "$PROJECT_ROOT/temp/fs/fat/test_fat_chain_validation.bin"
rm -f "$PROJECT_ROOT/temp/fs/file/test_file.bin" "$PROJECT_ROOT/temp/fs/file/test_file_size.bin"
rm -rf "$PROJECT_ROOT/temp/obj"
