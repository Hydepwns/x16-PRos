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

echo -e "${GREEN}Compiling the bootloader${NC}"
nasm -f bin src/core/boot.asm -o bin/boot.bin

echo -e "${GREEN}Compiling the kernel and programs${NC}"
nasm -f bin -Isrc/lib/ src/core/kernel.asm -o bin/kernel.bin
nasm -f bin -Isrc/lib/ src/apps/write.asm -o bin/write.bin
nasm -f bin -Isrc/lib/ src/apps/brainf.asm -o bin/brainf.bin
nasm -f bin -Isrc/lib/ src/apps/barchart.asm -o bin/barchart.bin
nasm -f bin -Isrc/lib/ src/apps/snake.asm -o bin/snake.bin
nasm -f bin -Isrc/lib/ src/apps/calc.asm -o bin/calc.bin

echo -e "${GREEN}Compiling file system components${NC}"
# nasm -f bin -I src/fs src/fs/fat.asm -o bin/fat.bin  # Aggregator module, not built directly
nasm -f bin -I src/fs src/fs/file.asm -o bin/file.bin
nasm -f bin -I src/fs src/fs/recovery.asm -o bin/recovery.bin

echo -e "${GREEN}Creating a disk image${NC}"
dd if=/dev/zero of=disk_img/x16pros.img bs=512 count=25

dd if=bin/boot.bin of=disk_img/x16pros.img conv=notrunc
dd if=bin/kernel.bin of=disk_img/x16pros.img bs=512 seek=1 conv=notrunc
dd if=bin/write.bin of=disk_img/x16pros.img bs=512 seek=8 conv=notrunc 
dd if=bin/brainf.bin of=disk_img/x16pros.img bs=512 seek=11 conv=notrunc 
dd if=bin/barchart.bin of=disk_img/x16pros.img bs=512 seek=14 conv=notrunc
dd if=bin/snake.bin of=disk_img/x16pros.img bs=512 seek=15 conv=notrunc
dd if=bin/calc.bin of=disk_img/x16pros.img bs=512 seek=17 conv=notrunc
dd if=bin/file.bin of=disk_img/x16pros.img bs=512 seek=20 conv=notrunc
dd if=bin/recovery.bin of=disk_img/x16pros.img bs=512 seek=21 conv=notrunc
echo -e "${GREEN}Done.${NC}"

echo -e "${GREEN}${LOGO}${NC}"

echo -e "${GREEN}Launching QEMU...${NC}"
qemu-system-i386 -hda disk_img/x16pros.img -m 128M -serial stdio
