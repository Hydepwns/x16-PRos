#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

# Colors for output
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NC='\033[0m'

# Default values
DEFAULT_SECTORS=2880
DEFAULT_SECTOR_SIZE=512
VALID_SECTOR_SIZES=(256 512 1024 2048 4096)

# Function to check if a command succeeded
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: Required command '$1' not found${NC}"
        echo -e "${YELLOW}Please install $1 and try again${NC}"
        exit 1
    fi
}

# Function to check if a file exists and is readable
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}Error: Required file '$1' not found${NC}"
        exit 1
    fi
    if [ ! -r "$1" ]; then
        echo -e "${RED}Error: Cannot read file '$1'${NC}"
        exit 1
    fi
}

# Function to check if a directory is writable
check_dir_writable() {
    if [ ! -w "$1" ]; then
        echo -e "${RED}Error: Cannot write to directory '$1'${NC}"
        exit 1
    fi
}

# Function to validate binary size
validate_binary_size() {
    local file=$1
    local expected=$2
    local actual
    actual=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    
    if [ "$actual" -ne "$expected" ]; then
        echo -e "${RED}Error: Invalid binary size for '$file'${NC}"
        echo -e "${YELLOW}Expected: $expected bytes${NC}"
        echo -e "${YELLOW}Actual: $actual bytes${NC}"
        exit 1
    fi
}

# Function to validate sector size
validate_sector_size() {
    local size=$1
    local valid=0
    
    for valid_size in "${VALID_SECTOR_SIZES[@]}"; do
        if [ "$size" -eq "$valid_size" ]; then
            valid=1
            break
        fi
    done
    
    if [ $valid -eq 0 ]; then
        echo -e "${RED}Error: Invalid sector size '$size'${NC}"
        echo -e "${YELLOW}Valid sector sizes are: ${VALID_SECTOR_SIZES[*]}${NC}"
        exit 1
    fi
}

# Function to check sector size compatibility
check_sector_size_compatibility() {
    local size=$1
    local file=$2
    
    # Check if file contains sector size dependent code
    if grep -q "SECTOR_SIZE" "$file"; then
        # Check if file has proper sector size validation
        if ! grep -q "%if.*SECTOR_SIZE.*%endif" "$file"; then
            echo -e "${YELLOW}Warning: File '$file' uses SECTOR_SIZE but may not handle it properly${NC}"
        fi
    fi
    
    # Check for hardcoded sector sizes
    if grep -q "512" "$file" && [ "$size" -ne 512 ]; then
        echo -e "${YELLOW}Warning: File '$file' contains hardcoded 512-byte sector references${NC}"
    fi
    
    # Check for sector-aligned structures
    if grep -q "times.*db 0" "$file"; then
        echo -e "${YELLOW}Warning: File '$file' may have sector-aligned structures that need updating${NC}"
    fi
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -s, --size SIZE     Disk size in sectors (default: 2880 for 1.44MB)"
    echo "  -b, --bytes SIZE    Disk size in bytes (overrides sectors)"
    echo "  -z, --sector SIZE   Sector size in bytes (default: 512)"
    echo "                      Valid sizes: ${VALID_SECTOR_SIZES[*]}"
    echo "  -t, --type TYPE     Predefined disk type:"
    echo "                      floppy360  (360KB, 720 sectors)"
    echo "                      floppy720  (720KB, 1440 sectors)"
    echo "                      floppy144  (1.44MB, 2880 sectors)"
    echo "                      floppy288  (2.88MB, 5760 sectors)"
    echo "                      hdd        (10MB, 20480 sectors)"
    echo "  -m, --mode MODE      Build mode: 'release' (default) or 'test'"
    echo "  -h, --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Create 1.44MB floppy image (512-byte sectors)"
    echo "  $0 -t floppy360       # Create 360KB floppy image"
    echo "  $0 -s 4096 -z 1024    # Create 4MB image with 1KB sectors"
    echo "  $0 -b 1048576 -z 2048 # Create 1MB image with 2KB sectors"
}

# Parse command line arguments
DISK_SECTORS=$DEFAULT_SECTORS
DISK_BYTES=""
SECTOR_SIZE=$DEFAULT_SECTOR_SIZE

# Add variable for build mode
default_build_mode=release
BUILD_MODE="$default_build_mode"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--size)
            DISK_SECTORS="$2"
            shift 2
            ;;
        -b|--bytes)
            DISK_BYTES="$2"
            shift 2
            ;;
        -z|--sector)
            SECTOR_SIZE="$2"
            validate_sector_size "$SECTOR_SIZE"
            shift 2
            ;;
        -t|--type)
            case "$2" in
                floppy360)
                    DISK_SECTORS=720
                    ;;
                floppy720)
                    DISK_SECTORS=1440
                    ;;
                floppy144)
                    DISK_SECTORS=2880
                    ;;
                floppy288)
                    DISK_SECTORS=5760
                    ;;
                hdd)
                    DISK_SECTORS=20480
                    ;;
                *)
                    echo -e "${RED}Error: Unknown disk type '$2'${NC}"
                    show_usage
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -m|--mode)
            BUILD_MODE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Calculate disk size in bytes if specified
if [ ! -z "$DISK_BYTES" ]; then
    DISK_SECTORS=$((DISK_BYTES / SECTOR_SIZE))
    if [ $((DISK_BYTES % SECTOR_SIZE)) -ne 0 ]; then
        echo -e "${YELLOW}Warning: Disk size not aligned to sector size, rounding up${NC}"
        DISK_SECTORS=$((DISK_SECTORS + 1))
    fi
fi

# Validate minimum disk size based on sector size
MIN_SECTORS=$((2880 * DEFAULT_SECTOR_SIZE / SECTOR_SIZE))
if [ "$DISK_SECTORS" -lt "$MIN_SECTORS" ]; then
    echo -e "${YELLOW}Warning: Disk size smaller than recommended minimum ($MIN_SECTORS sectors)${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check required commands
echo -e "${GREEN}Checking required tools...${NC}"
check_command nasm
check_command dd
check_command qemu-system-i386

# Check source files
echo -e "${GREEN}Checking source files...${NC}"
check_file "src/core/boot.asm"
check_file "src/fs/fat.asm"
check_file "src/fs/file.asm"
check_file "src/fs/errors.asm"
check_file "src/fs/recovery.asm"
check_file "tests/fs/fat/test_fat.asm"
check_file "tests/fs/file/test_file.asm"
check_file "tests/fs/init/test_fs_init.asm"

# Check sector size compatibility
echo -e "${GREEN}Checking sector size compatibility...${NC}"
check_sector_size_compatibility "$SECTOR_SIZE" "src/core/boot.asm"
check_sector_size_compatibility "$SECTOR_SIZE" "src/fs/fat.asm"
check_sector_size_compatibility "$SECTOR_SIZE" "src/fs/file.asm"
check_sector_size_compatibility "$SECTOR_SIZE" "src/fs/errors.asm"
check_sector_size_compatibility "$SECTOR_SIZE" "src/fs/recovery.asm"
check_sector_size_compatibility "$SECTOR_SIZE" "tests/fs/fat/test_fat.asm"
check_sector_size_compatibility "$SECTOR_SIZE" "tests/fs/file/test_file.asm"
check_sector_size_compatibility "$SECTOR_SIZE" "tests/fs/init/test_fs_init.asm"

# Set output directories based on build mode
if [ "$BUILD_MODE" = "test" ]; then
    OUTDIR="temp/bin"
    IMGDIR="temp/img"
else
    OUTDIR="release/bin"
    IMGDIR="release/img"
fi

echo -e "${GREEN}Creating directories...${NC}"
mkdir -p "$OUTDIR"
check_error "Failed to create $OUTDIR directory"
mkdir -p "$IMGDIR"
check_error "Failed to create $IMGDIR directory"

# Check directory permissions
check_dir_writable "$OUTDIR"
check_dir_writable "$IMGDIR"

echo -e "${GREEN}Building x16FS-Lite...${NC}"
echo -e "${GREEN}Disk size: $((DISK_SECTORS * SECTOR_SIZE)) bytes ($DISK_SECTORS sectors)${NC}"
echo -e "${GREEN}Sector size: $SECTOR_SIZE bytes${NC}"

# Set build mode based on argument (default is release)
set_build_mode "$BUILD_MODE"

echo -e "${GREEN}Build mode: $BUILD_MODE${NC}"

# Assemble boot sector as flat binary
nasm -f bin src/core/boot.asm -o "$OUTDIR/boot.bin"
check_error "Failed to assemble boot sector"
validate_binary_size "$OUTDIR/boot.bin" "$SECTOR_SIZE"

# Assemble IO library as ELF object
nasm -f elf32 src/lib/io.asm -o "$OUTDIR/io.o"
check_error "Failed to assemble IO library"

# Assemble error handling as ELF object
nasm -f elf32 src/fs/errors.asm -o "$OUTDIR/errors.o"
check_error "Failed to assemble error handling"

# Assemble FAT, file, and recovery as ELF objects
nasm -f elf32 src/fs/fat.asm -o "$OUTDIR/fat.o"
check_error "Failed to assemble FAT implementation"
nasm -f elf32 src/fs/file.asm -o "$OUTDIR/file.o"
check_error "Failed to assemble file operations"
nasm -f elf32 src/fs/recovery.asm -o "$OUTDIR/recovery.o"
check_error "Failed to assemble recovery mechanisms"

# Assemble directory core as ELF object
nasm -f elf32 src/fs/dir/core.asm -o "$OUTDIR/dir.o"
check_error "Failed to assemble directory core"

# Link fs.bin from all fs objects
(cd "$OUTDIR" && x86_64-elf-ld -T ../../src/link.ld -o fs.bin io.o errors.o fat.o file.o recovery.o dir.o)
check_error "Failed to link fs.bin"

# Write boot sector at sector 0
# Write fs.bin at sector 1
# Remove old per-module .bin writing for fat, file, recovery, errors

dd if="$OUTDIR/boot.bin" of="$IMGDIR/x16fs.img" conv=notrunc 2>/dev/null
check_error "Failed to write boot sector"
dd if="$OUTDIR/fs.bin" of="$IMGDIR/x16fs.img" bs="$SECTOR_SIZE" seek=1 conv=notrunc 2>/dev/null
check_error "Failed to write file system"

# Remove old per-module .bin creation and writing for fat, file, recovery, errors
# (Do not write dir.bin, file.bin, errors.bin, recovery.bin, fat.bin individually)

# Verify disk image integrity
echo -e "${GREEN}Verifying disk image integrity...${NC}"
if ! dd if="$IMGDIR/x16fs.img" bs="$SECTOR_SIZE" count=1 2>/dev/null | grep -q "FS"; then
    echo -e "${RED}Error: Invalid boot sector signature${NC}"
    exit 1
fi

# --- KERNEL BUILD AND WRITE STEPS (added) ---

# Assemble core kernel modules as ELF objects
CORE_MODULES=(
  "services/cpu"
  "services/loader"
  "services/services"
  "shell/shell"
  "memory/memory"
  "interrupts/interrupts"
  "process/process"
  "kernel"
)
KERNEL_OBJS=""
for module in "${CORE_MODULES[@]}"; do
    name=$(basename "$module")
    objfile="${name}.o"
    srcfile="src/core/${module}.asm"
    nasm -f elf32 "$srcfile" -o "$OUTDIR/$objfile"
    check_error "Failed to assemble $name object file"
    KERNEL_OBJS="$KERNEL_OBJS $objfile"
done

# Link all core modules into a single kernel.bin (plus io.o and errors.o)
(cd "$OUTDIR" && x86_64-elf-ld -T ../../src/link.ld -o kernel.bin $KERNEL_OBJS io.o errors.o)
check_error "Failed to link kernel binary"

# NOTE: KERNEL_START_SECTOR is defined in src/lib/constants.inc and must match this value
# Write kernel.bin to the disk image at sector 10
dd if="$OUTDIR/kernel.bin" of="$IMGDIR/x16fs.img" bs="$SECTOR_SIZE" seek=10 conv=notrunc 2>/dev/null
check_error "Failed to write kernel"
# --- END KERNEL STEPS ---

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}Disk image created at: $IMGDIR/x16fs.img${NC}"
echo -e "${GREEN}Disk size: $((DISK_SECTORS * SECTOR_SIZE)) bytes ($DISK_SECTORS sectors)${NC}"
echo -e "${GREEN}Sector size: $SECTOR_SIZE bytes${NC}"

# Ask if user wants to run in QEMU
read -p "Run image in QEMU? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${GREEN}Launching QEMU...${NC}"
    qemu-system-i386 -hda "$IMGDIR/x16fs.img" -m 128M -serial stdio
fi 