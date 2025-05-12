# x16-PRos Architecture

## System Overview

x16-PRos is a modular operating system with three main components:

- **Core System:** Memory, process, interrupt, and system service management ([src/core/README.md](src/core/README.md))
- **File System:** FAT implementation, directory and file operations, error recovery ([src/fs/README.md](src/fs/README.md))
- **Testing Framework:** Automated tests, macros, runners, and scripts ([tests/README.md](tests/README.md))

See the linked subdocs for detailed responsibilities and interfaces.

---

## Directory Responsibilities & Artifact Flow

| Directory              | Purpose                                         | Output/Artifacts          |
|------------------------|------------------------------------------------|----------------------------|
| `src/`                 | Source code (core, fs, apps, libs)             | -                          |
| `tests/`               | Test sources, macros, runners, scripts          | Test scripts, test data   |
| `temp/`                | **All dev/test build & run output**             | ISO,BIN/OBJ,.IMG,...      |
| `release/`             | **Production release artifacts only**           | ISO,BIN/OBJ,.IMG,...      |
| `scripts/build/`       | Build scripts                                    | -                        |
| `scripts/tests/`       | Test scripts                                      | -                        |
| `scripts/utils/`       | Utility scripts                                  | -                        |

- *`.gitkeep` files are used in `temp/` and `release/` subdirectories to ensure empty directories are tracked by git.*
- *All test/dev build and run output goes to `temp/` (never to `release/`).*
- *`release/` is reserved for production-ready artifacts only.*

---

## Component Architecture

- **Core System:** Manages low-level OS services. See [src/core/README.md](src/core/README.md).
- **File System:** Provides persistent storage and file/directory management. See [src/fs/README.md](src/fs/README.md).
- **Testing Framework:** Ensures correctness and reliability. See [tests/README.md](tests/README.md).

---

## Build System

x16-PRos uses a modular, cross-platform build system. All core modules are assembled as ELF object files and linked using platform-specific scripts in `scripts/build/`. Build and test artifacts are output to `temp/` (see scripts for details).

**Example Build Flow:**

```sh
nasm -f elf32 -o temp/bin/obj/kernel.o src/core/kernel.asm
nasm -f elf32 -o temp/bin/obj/shell.o src/core/shell/shell.asm
ld -T link.ld -o temp/bin/kernel.bin temp/bin/obj/kernel.o temp/bin/obj/shell.o [other .o files...]
```

**Disk Layout:**

```sh
Sector 0: Boot Sector (boot.bin)
Sector 1+: File System (fs.bin)
Sector N: Kernel (kernel.bin)
Sector N+M: Applications (*.bin)
```

For full build options and configuration, see [scripts/README.md](scripts/README.md).

---

## Error Handling

x16-PRos uses a unified error handling system across all modules. Error codes are defined in [`src/lib/error_codes.inc`](src/lib/error_codes.inc) and [`src/lib/constants.inc`](src/lib/constants.inc). Functions set the Carry Flag (CF) on error and return an error code in AX. For the canonical list and details, see the linked files.

---

## Testing Architecture

The test suite provides comprehensive coverage using standardized macros, reusable data, and automated runners. All test scripts and runners are in `scripts/tests/`, and all test output is written to `temp/`. For test structure, categories, and framework, see [tests/README.md](tests/README.md).

---

## References & Further Reading

- [src/core/README.md](src/core/README.md) — Core system modules
- [src/fs/README.md](src/fs/README.md) — File system modules
- [src/lib/README.md](src/lib/README.md) — Libraries and macros
- [src/apps/README.md](src/apps/README.md) — Applications
- [tests/README.md](tests/README.md) — Test suite
- [scripts/README.md](scripts/README.md) — Build system
- [src/lib/error_codes.inc](src/lib/error_codes.inc) — Error codes
- [src/lib/constants.inc](src/lib/constants.inc) — Constants
- [TODO.md](TODO.md) — Future plans
