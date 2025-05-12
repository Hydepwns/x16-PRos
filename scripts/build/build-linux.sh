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

# Example: set output directory based on build mode
if [ "$BUILD_MODE" = "test" ]; then
    OUTDIR="temp/bin"
else
    OUTDIR="release/bin"
fi

echo -e "${GREEN}Creating output directories${NC}"
mkdir -p release/bin
mkdir -p release/img

echo -e "${GREEN}Compiling the bootloader${NC}"
nasm -f bin src/core/boot.asm -o release/bin/boot.bin

echo -e "${GREEN}Compiling the kernel and programs${NC}"
nasm -f bin -Isrc/lib/ src/core/kernel.asm -o release/bin/kernel.bin
nasm -f bin -Isrc/lib/ src/apps/write.asm -o release/bin/write.bin
nasm -f bin -Isrc/lib/ src/apps/brainf.asm -o release/bin/brainf.bin
nasm -f bin -Isrc/lib/ src/apps/barchart.asm -o release/bin/barchart.bin
nasm -f bin -Isrc/lib/ src/apps/snake.asm -o release/bin/snake.bin
nasm -f bin -Isrc/lib/ src/apps/calc.asm -o release/bin/calc.bin

echo -e "${GREEN}Compiling file system components to ELF objects${NC}"
nasm -f elf32 -Isrc/lib/ src/lib/io.asm -o temp/bin/obj/io.o
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/errors.asm -o temp/bin/obj/errors.o
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/fat.asm -o temp/bin/obj/fat.o
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/file.asm -o temp/bin/obj/file.o
nasm -f elf32 -Isrc/fs/ -Isrc/lib/ src/fs/recovery.asm -o temp/bin/obj/recovery.o

echo -e "${GREEN}Linking file system components into fs.bin${NC}"
x86_64-elf-ld -T src/link.ld -o temp/bin/fs.bin temp/bin/obj/io.o temp/bin/obj/errors.o temp/bin/obj/fat.o temp/bin/obj/file.o temp/bin/obj/recovery.o

echo -e "${GREEN}Creating a disk image${NC}"
# Initialize disk image (e.g., 25 sectors of 512 bytes, adjust as needed)
# Let's use a slightly larger image for now, 2880 sectors for 1.44MB floppy
dd if=/dev/zero of=release/img/x16pros.img bs=512 count=2880

echo -e "${GREEN}Writing components to disk image${NC}"
dd if=bin/boot.bin of=release/img/x16pros.img conv=notrunc
dd if=temp/bin/fs.bin of=release/img/x16pros.img bs=512 seek=1 conv=notrunc
# Assuming fs.bin fits within 4 sectors for now (1 boot + 4 fs = 5). Kernel starts at sector 5.
# This might need adjustment based on the actual size of fs.bin
dd if=bin/kernel.bin of=release/img/x16pros.img bs=512 seek=9 conv=notrunc
# Adjust seek for applications based on new kernel position
dd if=bin/write.bin of=release/img/x16pros.img bs=512 seek=10 conv=notrunc
dd if=bin/brainf.bin of=release/img/x16pros.img bs=512 seek=13 conv=notrunc
dd if=bin/barchart.bin of=release/img/x16pros.img bs=512 seek=16 conv=notrunc
dd if=bin/snake.bin of=release/img/x16pros.img bs=512 seek=18 conv=notrunc
dd if=bin/calc.bin of=release/img/x16pros.img bs=512 seek=20 conv=notrunc

echo -e "${GREEN}Done.${NC}"

echo -e "${GREEN}${LOGO}${NC}"

echo -e "${GREEN}Launching QEMU...${NC}"
qemu-system-i386 -hda release/img/x16pros.img -m 128M -serial stdio

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
    objfile="temp/bin/obj/${name}.o"
    srcfile="src/core/${module}.asm"
    nasm -f elf32 "$srcfile" -o "$objfile"
    KERNEL_OBJS="$KERNEL_OBJS $objfile"
done

echo -e "${GREEN}Linking all core modules into a single kernel.bin${NC}"
x86_64-elf-ld -T src/link.ld -o release/bin/kernel.bin "$KERNEL_OBJS" temp/bin/obj/io.o

# Write kernel.bin to the disk image at sector 9 (after boot and fs)
echo -e "${GREEN}Writing kernel.bin to disk image at sector 9${NC}"
dd if=release/bin/kernel.bin of=release/img/x16pros.img bs=512 seek=9 conv=notrunc
