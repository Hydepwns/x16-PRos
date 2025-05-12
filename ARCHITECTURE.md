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
Sector 1: File System (fs.bin)
Sectors 2–5: FAT
Sectors 6–9: Root Directory
Sector 10+: Kernel (kernel.bin, see KERNEL_START_SECTOR in src/lib/constants.inc), then apps
```

For full build options and configuration, see [scripts/README.md](scripts/README.md).

---

## Error Handling

x16-PRos uses a unified error handling system across all modules. Error codes are defined in [`src/lib/error_codes.inc`](src/lib/error_codes.inc) and [`src/lib/constants.inc`](src/lib/constants.inc). Functions set the Carry Flag (CF) on error and return an error code in AX. For the canonical list and details, see the linked files.

---

## Testing Architecture

The test suite provides comprehensive coverage using standardized macros, reusable data, and automated runners. All test scripts and runners are in `scripts/tests/`, and all test output is written to `temp/`. For test structure, categories, and framework, see [tests/README.md](tests/README.md).

**Standalone Test Binaries:**

- Some test files (e.g., `tests/fs/dir/test_dir_consistency.asm`) can be built as fully standalone, self-contained binaries for direct execution in emulators or on hardware.
- To achieve this, all external includes, macros, and dependencies must be removed or inlined, and all routines must be defined within the file.
- This approach is useful for low-level or boot sector testing, and for environments where linking or test frameworks are not available.

---

## Modular Build & Test Separation

- **Strict separation of test and production builds:** All test scripts and outputs are written to `temp/`, while production (release) artifacts are written to `release/`. Test code is never included in production builds.
- **Modular linking logic:** Each binary (kernel, file system, apps, tests) is linked only with the modules it requires. No unnecessary or test modules are included in production artifacts, preventing symbol conflicts and ensuring clean builds.
- **Standalone vs. integration tests:** Some tests are fully standalone (linked only with minimal support objects), while others are integration tests (linked with core modules). This distinction is reflected in the test build scripts and config files, and ensures clear test coverage.

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
