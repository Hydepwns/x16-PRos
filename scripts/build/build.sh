#!/bin/bash

# Source shared build utilities
source "$(dirname "$0")/../utils/build_common.sh"

GREEN='\033[32m'
NC='\033[0m'

LOGO='
██╗  ██╗ ██╗ ██████╗       ██████╗ ██████╗  ██████╗ ███████╗
╚██╗██╔╝███║██╔════╝       ██╔══██╗██╔══██╗██╔═══██╗██╔════╝
 ╚███╔╝ ╚██║███████╗ █████╗██████╔╝██████╔╝██║   ██║███████╗
 ██╔██╗  ██║██╔═══██╗╚════╝██╔═══╝ ██╔══██╗██║   ██║╚════██║
██╔╝ ██╗ ██║╚██████╔╝      ██║     ██║  ██║╚██████╔╝███████║
╚═╝  ╚═╝ ╚═╝ ╚═════╝       ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
____________________________________________________________
'

# Toolchain checks
if ! command -v nasm &> /dev/null
then
    echo "nasm could not be found, please install it."
    exit
fi

if ! command -v x86_64-elf-ld &> /dev/null
then
    echo "x86_64-elf-ld could not be found, please install the corresponding binutils."
    # On Debian/Ubuntu: sudo apt-get install binutils-elf-x86-64
    # On Fedora: sudo dnf install binutils-x86_64-elf
    # On Arch: sudo pacman -S x86_64-elf-binutils
    # For macOS with Homebrew: brew install x86_64-elf-binutils
    exit
fi

# Set build mode to release (default for this script)
set_build_mode release

echo -e "${GREEN}Build mode: $BUILD_MODE${NC}"

RELDIR="release"
BINDIR="$RELDIR/bin"
OBJDIR="$BINDIR/obj"
IMGDIR="$RELDIR/img"
LOGDIR="$RELDIR/log"

# Create output directories
mkdir -p "$BINDIR" "$OBJDIR" "$IMGDIR" "$LOGDIR"

# Compile the bootloader
nasm -f bin src/core/boot.asm -o "$BINDIR/boot.bin"

# Compile the kernel and programs
nasm -f bin -Isrc/lib/ src/core/kernel.asm -o "$BINDIR/kernel.bin"
nasm -f bin -Isrc/lib/ src/apps/write.asm -o "$BINDIR/write.bin"
nasm -f bin -Isrc/lib/ src/apps/brainf.asm -o "$BINDIR/brainf.bin"
nasm -f bin -Isrc/lib/ src/apps/barchart.asm -o "$BINDIR/barchart.bin"
nasm -f bin -Isrc/lib/ src/apps/snake.asm -o "$BINDIR/snake.bin"
nasm -f bin -Isrc/lib/ src/apps/calc.asm -o "$BINDIR/calc.bin"

# Compile file system components to ELF objects
nasm -f elf32 -Isrc/lib/ src/lib/io.asm -o "$OBJDIR/io.o"
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/errors.asm -o "$OBJDIR/errors.o"
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/fat.asm -o "$OBJDIR/fat.o"
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/file.asm -o "$OBJDIR/file.o"
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/recovery.asm -o "$OBJDIR/recovery.o"

# Link file system components into fs.bin
x86_64-elf-ld -T src/link.ld -o "$BINDIR/fs.bin" "$OBJDIR/io.o" "$OBJDIR/errors.o" "$OBJDIR/fat.o" "$OBJDIR/file.o" "$OBJDIR/recovery.o"

# Create a disk image
# 2880 sectors for 1.44MB floppy
DDIMG="$IMGDIR/x16pros.img"
dd if=/dev/zero of="$DDIMG" bs=512 count=2880

# Write components to disk image
# Boot sector
dd if="$BINDIR/boot.bin" of="$DDIMG" conv=notrunc
# File system (fs.bin) at sector 1
dd if="$BINDIR/fs.bin" of="$DDIMG" bs=512 seek=1 conv=notrunc
# Kernel at sector 9
dd if="$BINDIR/kernel.bin" of="$DDIMG" bs=512 seek=9 conv=notrunc
# Applications at subsequent sectors
# (adjust seek as needed)
dd if="$BINDIR/write.bin" of="$DDIMG" bs=512 seek=10 conv=notrunc
dd if="$BINDIR/brainf.bin" of="$DDIMG" bs=512 seek=13 conv=notrunc
dd if="$BINDIR/barchart.bin" of="$DDIMG" bs=512 seek=16 conv=notrunc
dd if="$BINDIR/snake.bin" of="$DDIMG" bs=512 seek=18 conv=notrunc
dd if="$BINDIR/calc.bin" of="$DDIMG" bs=512 seek=20 conv=notrunc

echo -e "${GREEN}Done.${NC}"

echo -e "${GREEN}${LOGO}${NC}"

echo -e "${GREEN}Launching QEMU...${NC}"
qemu-system-i386 -hda "$DDIMG" -m 128M -serial stdio

echo -e "${GREEN}Compiling the kernel core modules as ELF objects${NC}"
# List of core modules (relative to src/core/)
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
    nasm -f elf32 "$srcfile" -o "$objfile"
    KERNEL_OBJS="$KERNEL_OBJS $objfile"
done

echo -e "${GREEN}Linking all core modules into a single kernel.bin${NC}"
x86_64-elf-ld -T src/link.ld -o "$BINDIR/kernel.bin" "$KERNEL_OBJS" "$OBJDIR/io.o"

# Extract KERNEL_START_SECTOR from src/lib/constants.inc
KERNEL_START_SECTOR=$(grep -E '^KERNEL_START_SECTOR' src/lib/constants.inc | awk '{print $3}')
if [[ -z "$KERNEL_START_SECTOR" ]]; then
    echo "Could not extract KERNEL_START_SECTOR from src/lib/constants.inc"
    exit 1
fi

# Detect OS and set correct stat command for file size
UNAME=$(uname)
if [[ "$UNAME" == "Darwin" ]]; then
    STAT_CMD='stat -f%z'
else
    STAT_CMD='stat -c %s'
fi

# Calculate kernel size in sectors (512 bytes per sector)
KERNEL_BIN="$BINDIR/kernel.bin"
KERNEL_SIZE_BYTES=$($STAT_CMD "$KERNEL_BIN")
KERNEL_SIZE_SECTORS=$(( (KERNEL_SIZE_BYTES + 511) / 512 ))
APP_START_SECTOR=$((KERNEL_START_SECTOR + KERNEL_SIZE_SECTORS))

# Write kernel.bin to the disk image at the extracted sector
# (overwrites previous hardcoded sector)
dd if="$KERNEL_BIN" of="$DDIMG" bs=512 seek=$KERNEL_START_SECTOR conv=notrunc

# Place apps after the kernel, starting at APP_START_SECTOR
APPS=(
  "write"
  "brainf"
  "barchart"
  "snake"
  "calc"
)

CURRENT_SECTOR=$APP_START_SECTOR

for APP in "${APPS[@]}"; do
    APP_BIN="$BINDIR/${APP}.bin"
    dd if="$APP_BIN" of="$DDIMG" bs=512 seek=$CURRENT_SECTOR conv=notrunc

    APP_SIZE_BYTES=$($STAT_CMD "$APP_BIN")
    APP_SIZE_SECTORS=$(( (APP_SIZE_BYTES + 511) / 512 ))

    CURRENT_SECTOR=$((CURRENT_SECTOR + APP_SIZE_SECTORS))
done
