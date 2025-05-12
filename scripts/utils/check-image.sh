#!/bin/bash

# Usage: check-image.sh [image_path]
# Checks disk image for boot sector signature, FS sector, and lists FAT contents if possible

IMAGE="${1:-release/img/x16fs.img}"

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NC='\033[0m'

# 1. Check if file exists and is readable
if [ ! -f "$IMAGE" ]; then
    echo -e "${RED}Error: File '$IMAGE' not found.${NC}"
    exit 1
fi
if [ ! -r "$IMAGE" ]; then
    echo -e "${RED}Error: File '$IMAGE' is not readable.${NC}"
    exit 1
fi

echo -e "${GREEN}Disk image: $IMAGE${NC}"

# 2. Check boot sector signature (0x55AA at offset 510)
sig=$(xxd -s 510 -l 2 "$IMAGE" | awk '{print $2$3}')
if [ "$sig" == "55aa" ] || [ "$sig" == "55AA" ]; then
    echo -e "${GREEN}Boot sector signature 0x55AA found at offset 510.${NC}"
else
    echo -e "${RED}Boot sector signature 0x55AA NOT found at offset 510!${NC}"
fi

# 3. Show first 32 bytes of boot sector and FS sector
echo -e "${YELLOW}First 32 bytes of boot sector:${NC}"
dd if="$IMAGE" bs=1 count=32 2>/dev/null | hexdump -C

echo -e "${YELLOW}First 32 bytes of FS sector (sector 1):${NC}"
dd if="$IMAGE" bs=512 skip=1 count=32 2>/dev/null | hexdump -C

# 4. List FAT filesystem contents if mtools is installed
if command -v mdir &>/dev/null; then
    echo -e "${GREEN}Listing FAT filesystem contents (using mdir):${NC}"
    mdir -i "$IMAGE" ::
else
    echo -e "${YELLOW}mtools not installed; skipping FAT directory listing.${NC}"
fi

# 5. Search for known strings
for s in FS FAT KERNEL BOOT; do
    if strings "$IMAGE" | grep -q "$s"; then
        echo -e "${GREEN}Found string: $s${NC}"
    else
        echo -e "${YELLOW}String not found: $s${NC}"
    fi
done

echo -e "${GREEN}Image check complete.${NC}" 