# x16-PRos Source Code Organization

This directory contains the source code for the x16-PRos operating system, organized into the following structure:

## Directory Structure

### `/core`

Core system files that handle the basic functionality of the operating system:

- `boot.asm` - Boot sector and system initialization
- `kernel.asm` - Core OS functionality, shell, and system services

### `/apps`

User applications and utilities:

- `calc.asm` - Calculator application
- `snake.asm` - Snake game
- `brainf.asm` - Brainfuck interpreter
- `barchart.asm` - Bar chart visualization
- `clock.asm` - Clock/Time application
- `write.asm` - Text editor

### `/fs`

File system related code:

- File system operations
- Directory handling
- File operations
- Error handling and recovery

### `/lib`

Common utility functions, macros, and global constants:

- `constants.inc` - Centralized location for all global constants and macros used throughout the OS. All new constants should be added here, and duplication in other files should be avoided.
- All assembly files should include necessary `.inc` files from `src/lib/` at the top, before any use of constants or ORG directives.

## Build Process

The build process starts with the boot sector (`/core/boot.asm`), which loads the kernel (`/core/kernel.asm`). The kernel then provides the environment for running applications from the `/apps` directory.

## Development Guidelines

1. Core system files should be kept minimal and focused on essential functionality
2. Applications should be self-contained and use the kernel's system calls
3. File system code should implement proper error handling and recovery
4. All code should follow the established assembly coding standards
