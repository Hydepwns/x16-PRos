# x16-PRos Architecture

## Directory Structure (Top Level)

```text
.
├── src/      # Source code (kernel, fs, apps, libs)
├── tests/    # Test sources, scripts, configs
├── scripts/  # Build and utility scripts
├── release/  # Production artifacts
├── temp/     # Test/build output (not versioned)
├── assets/   # Screenshots, gifs, etc
```

## System Overview

x16-PRos is a modular operating system with three main components:

- **Core System:** Memory, process, interrupt, and system service management ([core][core-readme])
- **File System:** FAT implementation, directory and file operations, error recovery ([fs][fs-readme])
- **Testing Framework:** Automated tests, macros, runners, and scripts ([tests][tests-readme])

See the linked subdocs for detailed responsibilities and interfaces.

---

## Directory Responsibilities & Artifact Flow

| Directory              | Purpose                                         | Output/Artifacts          |
|------------------------|------------------------------------------------|----------------------------|
| `src/`                 | Source code (core, fs, apps, libs)             | -                          |
| `tests/`               | Test sources, macros, runners, scripts          | Test scripts, test data   |
| `temp/`                | **All dev/test build & run output**             | ISO,BIN/OBJ,IMG,...      |
| `release/`             | **Production release artifacts only**           | ISO,BIN/OBJ,IMG,...      |
| `scripts/build/`       | Build scripts                                    | -                        |
| `scripts/tests/`       | Test scripts                                     | -                        |
| `scripts/utils/`       | Utility scripts                                  | -                        |

- *`.gitkeep` files are used in `temp/` and `release/` subdirectories to ensure empty directories are tracked by git.*
- *All test/dev build and run output goes to `temp/` (never to `release/`).*
- *`release/` is reserved for production-ready artifacts only.*

---

## Component Architecture

- **Core System:** Manages low-level OS services. See [core][core-readme].
- **File System:** Provides persistent storage and file/directory management. See [fs][fs-readme].
- **Testing Framework:** Ensures correctness and reliability. See [tests][tests-readme].
- **Libraries:** Shared utilities and macros. See [lib][lib-readme].
- **Applications:** User/system apps. See [apps][apps-readme].

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
Sector 1: File System (fs.bin)
Sectors 2–5: FAT
Sectors 6–9: Root Directory
Sector 10+: Kernel (kernel.bin, see KERNEL_START_SECTOR in src/lib/constants.inc), then apps
```

For full build options and configuration, see [build system][scripts-readme].

## Error Handling

Error codes in [error_codes.inc][error-codes] and [constants.inc][constants]. Functions set CF on error, return code in AX.

## Testing Architecture

Tests use macros and runners in [test scripts][scripts-tests]. Output goes to `temp/`. See [tests][tests-readme].

**Standalone Tests:**

- Some tests (e.g. `tests/fs/dir/test_dir_consistency.asm`) run as standalone binaries
- No external deps - all code/data in one file
- Good for boot sector tests and bare metal

## Build & Test System

- Tests go to `temp/`, releases to `release/`
- Each binary links only what it needs
- Tests are either standalone or integration

---

## References & Further Reading

- [core][core-readme] — Core system modules
- [fs][fs-readme] — File system modules
- [lib][lib-readme] — Libraries and macros
- [apps][apps-readme] — Applications
- [tests][tests-readme] — Test suite
- [build system][scripts-readme] — Build system
- [error_codes.inc][error-codes] — Error codes
- [constants.inc][constants] — Constants
- [TODO.md][todo] — Future plans

<!-- Reference-style links -->
[core-readme]: src/core/README.md
[fs-readme]: src/fs/README.md
[lib-readme]: src/lib/README.md
[apps-readme]: src/apps/README.md
[tests-readme]: tests/README.md
[scripts-readme]: scripts/README.md
[scripts-tests]: scripts/tests/
[error-codes]: src/lib/error_codes.inc
[constants]: src/lib/constants.inc
[todo]: TODO.md
