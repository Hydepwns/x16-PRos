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

The build process starts with the boot sector (`/core/boot.asm`), which is written to the first sector of the disk image.
File system components (from `/fs` and relevant parts of `/lib` like `io.asm`, `errors.asm`) are compiled into ELF object files and then linked together by an ELF linker (using `src/link.ld`) to create a single `fs.bin`. This `fs.bin` is written to the disk image immediately following the boot sector.
The kernel (`/core/kernel.asm`) is compiled into `kernel.bin` and written to a subsequent sector. The kernel then provides the environment for running applications from the `/apps` directory, which are also compiled to raw binaries and placed on the disk image.

## Development Guidelines

1. Core system files should be kept minimal and focused on essential functionality
2. Applications should be self-contained and use the kernel's system calls
3. File system code (modules like `fat.asm`, `file.asm`, `recovery.asm`, `io.asm`, `errors.asm`) should be developed as separate assembly files. These are compiled to individual ELF object files (`.o`) and then linked together. Ensure that symbols intended for cross-module use are declared `GLOBAL` in their defining file and `EXTERN` in files that use them. The linker will resolve these dependencies.
4. All code should follow the established assembly coding standards

# x16-PRos Source Tree Overview

This directory contains the main source code for x16-PRos, organized for modularity and clarity.

## Directory Structure

```bash
src/
  core/   # Core OS: kernel, memory, process, interrupts, shell, services
  fs/     # File system: FAT, directory, file ops, recovery
  lib/    # Shared libraries, macros, error codes, constants
  apps/   # User and system applications
```

- See each subdirectory's `README.md` for details on modules, interfaces, and coding standards.

## Where to Go Next

- [src/core/README.md](core/README.md) — Core OS modules
- [src/fs/README.md](fs/README.md) — File system modules
- [src/lib/README.md](lib/README.md) — Libraries and macros
- [src/apps/README.md](apps/README.md) — Applications
- [../ARCHITECTURE.md](../ARCHITECTURE.md) — System architecture and build process
- [../scripts/README.md](../scripts/README.md) — Build & integration details
