#!/bin/bash

# Get the absolute path of the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Build and run file system tests
echo "Building and running x16FS-Lite tests..."

# Create temporary directory for object files
mkdir -p "$PROJECT_ROOT/tests/obj"

# Assemble source files into object files
echo "Assembling source files..."

# Core modules
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/errors.asm" -o "$PROJECT_ROOT/tests/obj/errors.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/fat.asm" -o "$PROJECT_ROOT/tests/obj/fat.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/recovery.asm" -o "$PROJECT_ROOT/tests/obj/recovery.o"

# Directory modules
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/core.asm" -o "$PROJECT_ROOT/tests/obj/dir_core.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/list.asm" -o "$PROJECT_ROOT/tests/obj/dir_list.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/helpers.asm" -o "$PROJECT_ROOT/tests/obj/dir_helpers.o"

# File modules
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/file.asm" -o "$PROJECT_ROOT/tests/obj/file.o"

# Test framework
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/test_framework.asm" -o "$PROJECT_ROOT/tests/obj/test_framework.o"

# Assemble io.asm as object file (already done in src/lib/io.o, but ensure it's up to date)
cd "$PROJECT_ROOT" && nasm -f elf -Isrc/lib src/lib/io.asm -o src/lib/io.o && cd tests

# Test files (assemble as object files)
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/dir/test_dir.asm" -o "$PROJECT_ROOT/tests/obj/test_dir.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/dir/test_dir_consistency.asm" -o "$PROJECT_ROOT/tests/obj/test_dir_consistency.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat.asm" -o "$PROJECT_ROOT/tests/obj/test_fat.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/fat/test_fat_chain.asm" -o "$PROJECT_ROOT/tests/obj/test_fat_chain.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/file/test_file.asm" -o "$PROJECT_ROOT/tests/obj/test_file.o"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/tests/fs/file/test_file_size.asm" -o "$PROJECT_ROOT/tests/obj/test_file_size.o"

# Link each test with all required object files and io.o to produce .bin for QEMU
link_test() {
    TEST_OBJ=$1
    OUT_BIN=$2
    ld -e _start -static \
        "$PROJECT_ROOT/tests/obj/$TEST_OBJ" \
        "$PROJECT_ROOT/tests/obj/errors.o" \
        "$PROJECT_ROOT/tests/obj/fat.o" \
        "$PROJECT_ROOT/tests/obj/recovery.o" \
        "$PROJECT_ROOT/tests/obj/dir_core.o" \
        "$PROJECT_ROOT/tests/obj/dir_list.o" \
        "$PROJECT_ROOT/tests/obj/dir_helpers.o" \
        "$PROJECT_ROOT/tests/obj/file.o" \
        "$PROJECT_ROOT/tests/obj/test_framework.o" \
        "$PROJECT_ROOT/src/lib/io.o" \
        -o "$OUT_BIN.elf"
    objcopy -O binary "$OUT_BIN.elf" "$OUT_BIN"
    rm -f "$OUT_BIN.elf"
}

link_test test_dir.o fs/dir/test_dir.bin
link_test test_dir_consistency.o fs/dir/test_dir_consistency.bin
link_test test_fat.o fs/fat/test_fat.bin
link_test test_fat_chain.o fs/fat/test_fat_chain.bin
link_test test_file.o fs/file/test_file.bin
link_test test_file_size.o fs/file/test_file_size.bin

# Create test disk image
echo "Creating test disk image..."
cd "$PROJECT_ROOT/tests" || exit 1
rm -f test.img
touch test.img
truncate -s 1474560 test.img  # 2880 sectors * 512 bytes

# Run each test in QEMU
echo "Running tests in QEMU..."

# Directory tests
echo "Running directory tests..."
cp fs/dir/test_dir.bin test.img
qemu-system-i386 -drive format=raw,file=test.img -monitor none -display none -serial stdio

cp fs/dir/test_dir_consistency.bin test.img
qemu-system-i386 -drive format=raw,file=test.img -monitor none -display none -serial stdio

# FAT tests
echo "Running FAT tests..."
cp fs/fat/test_fat.bin test.img
qemu-system-i386 -drive format=raw,file=test.img -monitor none -display none -serial stdio

cp fs/fat/test_fat_chain.bin test.img
qemu-system-i386 -drive format=raw,file=test.img -monitor none -display none -serial stdio

# File tests
echo "Running file tests..."
cp fs/file/test_file.bin test.img
qemu-system-i386 -drive format=raw,file=test.img -monitor none -display none -serial stdio

cp fs/file/test_file_size.bin test.img
qemu-system-i386 -drive format=raw,file=test.img -monitor none -display none -serial stdio

# Clean up
echo "Cleaning up..."
rm -f test.img
rm -f fs/dir/test_dir.bin fs/dir/test_dir_consistency.bin
rm -f fs/fat/test_fat.bin fs/fat/test_fat_chain.bin
rm -f fs/file/test_file.bin fs/file/test_file_size.bin
rm -rf "$PROJECT_ROOT/tests/obj" 