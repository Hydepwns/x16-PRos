#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

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

# Set build mode to release (default for this script)
set_build_mode release

echo -e "${GREEN}Build mode: $BUILD_MODE${NC}"

# Set output directories for release mode
RELDIR="release"
BINDIR="$RELDIR/bin"
OBJDIR="$BINDIR/obj"
IMGDIR="$RELDIR/img"
LOGDIR="$RELDIR/log"

# Create necessary directories
mkdir -p "$BINDIR" "$OBJDIR" "$IMGDIR" "$LOGDIR"

# Build the boot sector
echo -e "${GREEN}Building boot sector...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "nasm -f bin src/core/boot.asm -o $BINDIR/boot.bin"
fi
nasm -f bin src/core/boot.asm -o "$BINDIR/boot.bin"
check_error "Failed to build boot sector"

# Build the IO library
echo -e "${GREEN}Building IO library...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "nasm -f elf32 src/lib/io.asm -o $OBJDIR/io.o"
fi
nasm -f elf32 src/lib/io.asm -o "$OBJDIR/io.o"
check_error "Failed to build IO library"

# Build the file system components
echo -e "${GREEN}Building file system components...${NC}"

# Build errors module first
if [ $VERBOSE -eq 1 ]; then
    echo "nasm -f elf32 src/fs/errors.asm -o $OBJDIR/errors.o"
fi
nasm -f elf32 src/fs/errors.asm -o "$OBJDIR/errors.o"
check_error "Failed to build errors module"

# Build other file system components
FS_LINK_OBJS="$OBJDIR/io.o $OBJDIR/errors.o"
for component in "fat" "file" "recovery"; do
    if [ "$component" = "dir" ]; then
        continue
    fi

    if [ $VERBOSE -eq 1 ]; then
        echo "nasm -f elf32 src/fs/${component}.asm -o $OBJDIR/${component}.o"
    fi
    nasm -f elf32 src/fs/${component}.asm -o "$OBJDIR/${component}.o"
    check_error "Failed to build ${component} module"
    FS_LINK_OBJS="$FS_LINK_OBJS $OBJDIR/${component}.o"
done

# Link file system components
echo -e "${GREEN}Linking file system components...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "x86_64-elf-ld -T src/link.ld -o $BINDIR/fs.bin ${FS_LINK_OBJS}"
fi
x86_64-elf-ld -T src/link.ld -o "$BINDIR/fs.bin" "$FS_LINK_OBJS"
check_error "Failed to link file system components"

# Create disk image
echo -e "${GREEN}Creating disk image...${NC}"
if [ $VERBOSE -eq 1 ]; then
    echo "dd if=/dev/zero of=$IMGDIR/x16pros.img bs=$SECTOR_SIZE count=$DISK_SECTORS"
fi
dd if=/dev/zero of="$IMGDIR/x16pros.img" bs="$SECTOR_SIZE" count="$DISK_SECTORS"
check_error "Failed to create disk image"

# Write boot sector
if [ $VERBOSE -eq 1 ]; then
    echo "dd if=$BINDIR/boot.bin of=$IMGDIR/x16pros.img conv=notrunc"
fi
dd if="$BINDIR/boot.bin" of="$IMGDIR/x16pros.img" conv=notrunc
check_error "Failed to write boot sector"

# Write with file system
if [ $VERBOSE -eq 1 ]; then
    echo "dd if=$BINDIR/fs.bin of=$IMGDIR/x16pros.img bs=$SECTOR_SIZE seek=1 conv=notrunc"
fi
dd if="$BINDIR/fs.bin" of="$IMGDIR/x16pros.img" bs="$SECTOR_SIZE" seek=1 conv=notrunc
check_error "Failed to write file system"

# Build core modules as ELF objects
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
    objfile="$OBJDIR/${name}.o"
    srcfile="src/core/${module}.asm"
    if [ $VERBOSE -eq 1 ]; then
        echo "nasm -f elf32 $srcfile -o $objfile"
    fi
    nasm -f elf32 "$srcfile" -o "$objfile"
    check_error "Failed to build $name object file"
    KERNEL_OBJS="$KERNEL_OBJS $objfile"
done

# Link all core modules into a single kernel.bin
if [ $VERBOSE -eq 1 ]; then
    echo "x86_64-elf-ld -T src/link.ld -o $BINDIR/kernel.bin $KERNEL_OBJS $OBJDIR/io.o"
fi
x86_64-elf-ld -T src/link.ld -o "$BINDIR/kernel.bin" $KERNEL_OBJS $OBJDIR/io.o
check_error "Failed to link kernel binary"

# Write kernel.bin to the disk image (e.g., sector 9)
if [ $VERBOSE -eq 1 ]; then
    echo "dd if=$BINDIR/kernel.bin of=$IMGDIR/x16pros.img bs=$SECTOR_SIZE seek=9 conv=notrunc"
fi
dd if="$BINDIR/kernel.bin" of="$IMGDIR/x16pros.img" bs="$SECTOR_SIZE" seek=9 conv=notrunc
check_error "Failed to write kernel"

# Run tests if requested
if [ $RUN_TESTS -eq 1 ]; then
    run_tests
fi

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}Disk image created at: $IMGDIR/x16pros.img${NC}"
echo -e "${GREEN}Disk size: $((DISK_SECTORS * SECTOR_SIZE)) bytes${NC}"
echo -e "${GREEN}Sector size: $SECTOR_SIZE bytes${NC}"
if [ ! -z "$DISK_FORMAT" ]; then
    echo -e "${GREEN}Disk format: $DISK_FORMAT${NC}"
fi 