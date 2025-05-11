#!/bin/bash

# Colors for output
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

# Default values
DEFAULT_SECTORS=2880
DEFAULT_SECTOR_SIZE=512
VALID_SECTOR_SIZES=(256 512 1024 2048 4096)
VALID_DISK_FORMATS=("floppy360" "floppy720" "floppy144" "floppy288" "hdd")

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

# Function to validate disk format
validate_disk_format() {
    local format=$1
    local valid=0
    
    for valid_format in "${VALID_DISK_FORMATS[@]}"; do
        if [ "$format" = "$valid_format" ]; then
            valid=1
            break
        fi
    done
    
    if [ $valid -eq 0 ]; then
        echo -e "${RED}Error: Invalid disk format '$format'${NC}"
        echo -e "${YELLOW}Valid formats are: ${VALID_DISK_FORMATS[*]}${NC}"
        exit 1
    fi
}

# Function to get disk parameters from format
get_disk_params() {
    local format=$1
    case "$format" in
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
    esac
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -s, --size SIZE     Disk size in sectors (default: 2880 for 1.44MB)"
    echo "  -z, --sector SIZE   Sector size in bytes (default: 512)"
    echo "  -f, --format TYPE   Predefined disk format:"
    echo "                      floppy360  (360KB, 720 sectors)"
    echo "                      floppy720  (720KB, 1440 sectors)"
    echo "                      floppy144  (1.44MB, 2880 sectors)"
    echo "                      floppy288  (2.88MB, 5760 sectors)"
    echo "                      hdd        (10MB, 20480 sectors)"
    echo "  -c, --clean         Clean build artifacts before building"
    echo "  -v, --verbose       Enable verbose output"
    echo "  -t, --test          Run tests after building"
    echo "  -h, --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Create 1.44MB floppy image (512-byte sectors)"
    echo "  $0 -f floppy360       # Create 360KB floppy image"
    echo "  $0 -s 4096 -z 1024    # Create 4MB image with 1KB sectors"
    echo "  $0 -v -t              # Build with verbose output and run tests"
}

# Function to run tests
run_tests() {
    echo -e "${BLUE}Running tests...${NC}"
    if [ -f "tests/run_tests.sh" ]; then
        ./tests/run_tests.sh
        check_error "Tests failed"
    else
        echo -e "${YELLOW}Warning: Test script not found${NC}"
    fi
}

# Parse command line arguments
DISK_SECTORS=$DEFAULT_SECTORS
SECTOR_SIZE=$DEFAULT_SECTOR_SIZE
CLEAN_BUILD=0
VERBOSE=0
RUN_TESTS=0
DISK_FORMAT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--size)
            DISK_SECTORS="$2"
            shift 2
            ;;
        -z|--sector)
            SECTOR_SIZE="$2"
            validate_sector_size "$SECTOR_SIZE"
            shift 2
            ;;
        -f|--format)
            DISK_FORMAT="$2"
            validate_disk_format "$DISK_FORMAT"
            get_disk_params "$DISK_FORMAT"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -t|--test)
            RUN_TESTS=1
            shift
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

# Check required commands
echo -e "${GREEN}Checking required tools...${NC}"
check_command nasm
check_command x86_64-elf-gcc
check_command x86_64-elf-ld

# Clean build artifacts if requested
if [ $CLEAN_BUILD -eq 1 ]; then
    echo -e "${GREEN}Cleaning build artifacts...${NC}"
    rm -rf bin/*
    rm -rf disk_img/*
fi

# Check source files
echo -e "${GREEN}Checking source files...${NC}"
check_file "src/core/boot.asm"
check_file "src/fs/fat.asm"
# check_file "src/fs/dir.asm"  # Aggregator module, not built directly
check_file "src/fs/file.asm"
check_file "src/fs/errors.asm"
check_file "src/fs/recovery.asm"
check_file "src/lib/io.asm"
check_file "src/link.ld"

# Create necessary directories
echo -e "${GREEN}Creating directories...${NC}"
mkdir -p bin
check_error "Failed to create bin directory"
mkdir -p disk_img
check_error "Failed to create disk_img directory"

# Check directory permissions
check_dir_writable "bin"
check_dir_writable "disk_img"

# Build the boot sector
echo -e "${GREEN}Building boot sector...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "nasm -f bin src/core/boot.asm -o bin/boot.bin"
fi
nasm -f bin src/core/boot.asm -o bin/boot.bin
check_error "Failed to build boot sector"

# Build the IO library
echo -e "${GREEN}Building IO library...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "nasm -f elf32 src/lib/io.asm -o bin/io.o"
fi
nasm -f elf32 src/lib/io.asm -o bin/io.o
check_error "Failed to build IO library"

# Build the file system components
echo -e "${GREEN}Building file system components...${NC}"

# Build errors module first
if [ $VERBOSE -eq 1 ]; then
    echo "nasm -f elf32 src/fs/errors.asm -o bin/errors.o"
fi
nasm -f elf32 src/fs/errors.asm -o bin/errors.o
check_error "Failed to build errors module"

# Build other components
for component in fat dir file recovery; do
    if [ "$component" = "dir" ]; then
        continue
    fi
    if [ $VERBOSE -eq 1 ]; then
        echo "nasm -f elf32 src/fs/${component}.asm -o bin/${component}.o"
    fi
    nasm -f elf32 src/fs/${component}.asm -o bin/${component}.o
    check_error "Failed to build ${component} module"
done

# Link components
echo -e "${GREEN}Linking components...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "x86_64-elf-ld -T link.ld -o bin/fs.bin bin/errors.o bin/fat.o bin/file.o bin/recovery.o"
fi
x86_64-elf-ld -T link.ld -o bin/fs.bin bin/errors.o bin/fat.o bin/file.o bin/recovery.o
check_error "Failed to link components"

# Create disk image
echo -e "${GREEN}Creating disk image...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "dd if=/dev/zero of=disk_img/fs.img bs=$SECTOR_SIZE count=$DISK_SECTORS"
fi
dd if=/dev/zero of=disk_img/fs.img bs="$SECTOR_SIZE" count="$DISK_SECTORS"
check_error "Failed to create disk image"

# Write boot sector
if [ $VERBOSE -eq 1 ]; then
    echo "dd if=bin/boot.bin of=disk_img/fs.img conv=notrunc"
fi
dd if=bin/boot.bin of=disk_img/fs.img conv=notrunc
check_error "Failed to write boot sector"

# Write file system
if [ $VERBOSE -eq 1 ]; then
    echo "dd if=bin/fs.bin of=disk_img/fs.img bs=$SECTOR_SIZE seek=1 conv=notrunc"
fi
dd if=bin/fs.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=1 conv=notrunc
check_error "Failed to write file system"

# Build core modules
echo -e "${GREEN}Building core modules...${NC}"

# Build CPU module
nasm -f bin src/core/services/cpu.asm -o bin/cpu.bin
check_error "Failed to build CPU module"

# Build loader module
nasm -f bin src/core/services/loader.asm -o bin/loader.bin
check_error "Failed to build loader module"

# Build services module
nasm -f bin src/core/services/services.asm -o bin/services.bin
check_error "Failed to build services module"

# Build shell module
nasm -f bin src/core/shell/shell.asm -o bin/shell.bin
check_error "Failed to build shell module"

# Build memory management module
nasm -f bin src/core/memory/memory.asm -o bin/memory.bin
check_error "Failed to build memory management module"

# Build interrupt handling module
nasm -f bin src/core/interrupts/interrupts.asm -o bin/interrupts.bin
check_error "Failed to build interrupt handling module"

# Build process management module
nasm -f bin src/core/process/process.asm -o bin/process.bin
check_error "Failed to build process management module"

# Build kernel
nasm -f bin src/core/kernel.asm -o bin/kernel.bin
check_error "Failed to build kernel"

# Write core modules to disk image
echo -e "${GREEN}Writing core modules to disk image...${NC}"

# Write CPU module to sector 2
dd if=bin/cpu.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=2 conv=notrunc
check_error "Failed to write CPU module"

# Write loader module to sector 3
dd if=bin/loader.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=3 conv=notrunc
check_error "Failed to write loader module"

# Write services module to sector 4
dd if=bin/services.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=4 conv=notrunc
check_error "Failed to write services module"

# Write shell module to sector 5
dd if=bin/shell.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=5 conv=notrunc
check_error "Failed to write shell module"

# Write memory management module to sector 6
dd if=bin/memory.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=6 conv=notrunc
check_error "Failed to write memory management module"

# Write interrupt handling module to sector 7
dd if=bin/interrupts.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=7 conv=notrunc
check_error "Failed to write interrupt handling module"

# Write process management module to sector 8
dd if=bin/process.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=8 conv=notrunc
check_error "Failed to write process management module"

# Write kernel to sector 9
dd if=bin/kernel.bin of=disk_img/fs.img bs="$SECTOR_SIZE" seek=9 conv=notrunc
check_error "Failed to write kernel"

# Run tests if requested
if [ $RUN_TESTS -eq 1 ]; then
    run_tests
fi

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}Disk image created at: disk_img/fs.img${NC}"
echo -e "${GREEN}Disk size: $((DISK_SECTORS * SECTOR_SIZE)) bytes${NC}"
echo -e "${GREEN}Sector size: $SECTOR_SIZE bytes${NC}"
if [ ! -z "$DISK_FORMAT" ]; then
    echo -e "${GREEN}Disk format: $DISK_FORMAT${NC}"
fi 