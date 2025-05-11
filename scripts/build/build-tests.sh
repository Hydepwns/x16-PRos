#!/bin/bash

# Colors for output
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NC='\033[0m'

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

# Check required commands
echo -e "${GREEN}Checking required tools...${NC}"
check_command nasm
check_command gcc

# Create necessary directories
echo -e "${GREEN}Creating directories...${NC}"
mkdir -p bin
check_error "Failed to create bin directory"

# Compile test files
echo -e "${GREEN}Compiling test files...${NC}"

# Compile directory test
echo -e "${GREEN}Compiling directory test...${NC}"
nasm -f elf32 -I src/lib/ -I src/fs/ tests/fs/dir/test_dir.asm -o bin/test_dir.o
check_error "Failed to compile test_dir.asm"

# Compile library files
echo -e "${GREEN}Compiling library files...${NC}"
nasm -f elf32 -I src/lib/ src/lib/io.asm -o bin/io.o
check_error "Failed to compile io.asm"

# Compile filesystem files
echo -e "${GREEN}Compiling filesystem files...${NC}"
nasm -f elf32 -I src/lib/ -I src/fs/ src/fs/errors.asm -o bin/errors.o

# Compile directory implementation files
echo -e "${GREEN}Compiling directory implementation files...${NC}"
nasm -f elf32 -I src/lib/ -I src/fs/ src/fs/dir/core.asm -o bin/dir_core.o
check_error "Failed to compile core.asm"
nasm -f elf32 -I src/lib/ -I src/fs/ src/fs/dir/list.asm -o bin/dir_list.o
check_error "Failed to compile list.asm"
nasm -f elf32 -I src/lib/ -I src/fs/ src/fs/dir/helpers.asm -o bin/dir_helpers.o
check_error "Failed to compile helpers.asm"

# Link test files
echo -e "${GREEN}Linking test files...${NC}"
x86_64-elf-gcc -m32 -nostdlib -Wl,-e,_start bin/test_dir.o bin/io.o bin/errors.o bin/dir_core.o bin/dir_list.o bin/dir_helpers.o -o bin/test_dir
check_error "Failed to link test files"

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}Test binary created at bin/test_dir${NC}" 