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

# Read module and test configs from external files
MODULES=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  MODULES+=("$line")
done < "$PROJECT_ROOT/scripts/tests/modules.conf"

TESTS=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  TESTS+=("$line")
done < "$PROJECT_ROOT/scripts/tests/tests.conf"

# Assemble source files into object files
# echo "Assembling source files..." | tee -a "$LOGFILE"

# Data-driven module build config
# MODULES=(
#   "src=$PROJECT_ROOT/src/fs/dir/core.asm out=dir_core.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/src/fs/dir/list.asm out=dir_list.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/src/fs/dir/helpers.asm out=dir_helpers.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/src/fs/errors.asm out=errors.o macros='' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/src/fs/fat.asm out=fat.o macros='' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/src/fs/recovery.asm out=recovery.o macros='' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/src/fs/file.asm out=file.o macros='' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/src/lib/io.asm out=io.o macros='' includes='$PROJECT_ROOT'"
# )

log_phase "Building modules"
for entry in "${MODULES[@]}"; do
  eval $entry
  assemble_nasm "$src" "$OBJDIR/$out" elf "$macros" "$includes"
done

# Directory modules
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/core.asm" -o "$OBJDIR/dir_core.o"
check_error "Failed to assemble dir/core.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/list.asm" -o "$OBJDIR/dir_list.o"
check_error "Failed to assemble dir/list.asm"
nasm -f elf -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$PROJECT_ROOT/src/fs/dir/helpers.asm" -o "$OBJDIR/dir_helpers.o"
check_error "Failed to assemble dir/helpers.asm"

# Data-driven test build config
# TESTS=(
#   "src=$PROJECT_ROOT/tests/fs/dir/test_dir_consistency.asm out=test_dir_consistency.o macros='' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/fat/test_fat.asm out=test_fat.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/fat/test_fat_chain.asm out=test_fat_chain.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/file/test_file.asm out=test_file.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/file/test_file_size.asm out=test_file_size.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/fat/test_fat_chain_validation.asm out=test_fat_chain_validation.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/dir/test_dir_fill.asm out=test_dir_fill.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/dir/test_dir_overflow.asm out=test_dir_overflow.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/dir/test_dir_delete.asm out=test_dir_delete.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/dir/test_dir_attr.asm out=test_dir_attr.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
#   "src=$PROJECT_ROOT/tests/fs/dir/test_dir_edge.asm out=test_dir_edge.o macros='SECTOR_SIZE=512' includes='$PROJECT_ROOT'"
# )

log_phase "Building tests"
for entry in "${TESTS[@]}"; do
  eval $entry
  # Determine output subdirectory based on $out
  if [[ "$out" == test_fat* ]]; then
    outdir="$IMGDIR/fs/fat"
  elif [[ "$out" == test_file* ]]; then
    outdir="$IMGDIR/fs/file"
  else
    outdir="$IMGDIR/fs/dir"
  fi
  nasm -f bin -DSECTOR_SIZE=512 -I"$PROJECT_ROOT" "$src" -o "$outdir/$out"
done

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

# List of required modules for linking
MODULE_OBJS=(
  "$OBJDIR/errors.o"
  "$OBJDIR/fat.o"
  "$OBJDIR/recovery.o"
  "$OBJDIR/dir_core.o"
  "$OBJDIR/dir_list.o"
  "$OBJDIR/dir_helpers.o"
  "$OBJDIR/file.o"
  "$OBJDIR/io.o"
)

log_phase "Linking and objcopy"
for entry in "${TESTS[@]}"; do
  eval $entry
  test_obj="$OBJDIR/$out"
  test_name="${out%.o}"
  # Only link/objcopy if the output is an object file (ends with .o)
  if [[ "$out" == *.o ]]; then
    case $test_name in
      test_dir_consistency) bin_path="fs/dir/test_dir_consistency.bin" ;;
      test_fat) bin_path="fs/fat/test_fat.bin" ;;
      test_fat_chain) bin_path="fs/fat/test_fat_chain.bin" ;;
      test_file) bin_path="fs/file/test_file.bin" ;;
      test_file_size) bin_path="fs/file/test_file_size.bin" ;;
      test_fat_chain_validation) bin_path="fs/fat/test_fat_chain_validation.bin" ;;
      test_dir_fill) bin_path="fs/dir/test_dir_fill.bin" ;;
      test_dir_overflow) bin_path="fs/dir/test_dir_overflow.bin" ;;
      test_dir_delete) bin_path="fs/dir/test_dir_delete.bin" ;;
      test_dir_attr) bin_path="fs/dir/test_dir_attr.bin" ;;
      test_dir_edge) bin_path="fs/dir/test_dir_edge.bin" ;;
      *) bin_path="${test_name}.bin" ;;
    esac
    elf_path="$IMGDIR/$bin_path.elf"
    bin_path_full="$IMGDIR/$bin_path"
    link_obj "$test_obj ${MODULE_OBJS[*]}" "$elf_path"
    objcopy_bin "$elf_path" "$bin_path_full"
    rm -f "$elf_path"
  fi
  # If it's a .bin, it's already a flat binary and needs no further processing
  # (it was assembled in the previous step)
done

# Create test disk image
echo "Creating test disk image..."
rm -f "$IMGDIR/test.img"
truncate -s 1474560 "$IMGDIR/test.img"  # 2880 sectors * 512 bytes

# Run each test in QEMU
echo "Running tests in QEMU..."

log_phase "Running tests in QEMU"
# Directory tests
echo "Running directory tests..."
cp "$IMGDIR/fs/dir/test_dir_fill.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_dir_fill.out"

cp "$IMGDIR/fs/dir/test_dir_overflow.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_dir_overflow.out"

cp "$IMGDIR/fs/dir/test_dir_delete.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_dir_delete.out"

cp "$IMGDIR/fs/dir/test_dir_attr.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_dir_attr.out"

cp "$IMGDIR/fs/dir/test_dir_edge.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_dir_edge.out"

# FAT tests
echo "Running FAT tests..."
cp "$IMGDIR/fs/fat/test_fat.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_fat.out"

cp "$IMGDIR/fs/fat/test_fat_chain.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_fat_chain.out"

cp "$IMGDIR/fs/fat/test_fat_chain_validation.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_fat_chain_validation.out"

# File tests
echo "Running file tests..."
cp "$IMGDIR/fs/file/test_file.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_file.out"

cp "$IMGDIR/fs/file/test_file_size.bin" "$IMGDIR/test.img"
timeout 5 qemu-system-i386 -drive format=raw,file="$IMGDIR/test.img" -monitor none -display none -serial stdio -no-reboot -no-shutdown | tee "$LOGDIR/test_file_size.out"

# Clean up
echo "Cleaning up..."
rm -f "$IMGDIR/test.img"
rm -f "$IMGDIR/fs/dir/test_dir_consistency.bin"
rm -f "$IMGDIR/fs/fat/test_fat.bin" "$IMGDIR/fs/fat/test_fat_chain.bin" "$IMGDIR/fs/fat/test_fat_chain_validation.bin"
rm -f "$IMGDIR/fs/file/test_file.bin" "$IMGDIR/fs/file/test_file_size.bin"
rm -f "$IMGDIR/fs/dir/test_dir_fill.bin" "$IMGDIR/fs/dir/test_dir_overflow.bin" "$IMGDIR/fs/dir/test_dir_delete.bin" "$IMGDIR/fs/dir/test_dir_attr.bin" "$IMGDIR/fs/dir/test_dir_edge.bin"
rm -rf "$OBJDIR"

log_info "To run QEMU tests, use run_qemu_tests.sh"
