# Build & Utility Scripts Overview

## Purpose

The `scripts/` directory contains build, test, and utility scripts for x16-PRos, supporting cross-platform development and automation.

**All test build and utility scripts are now in the `tests/` directory.**

---

## 🚀 Quick Start (Build via Scripts)

1. **Install prerequisites:**
   - **macOS:** `brew install nasm x86_64-elf-binutils qemu`
   - **Linux:** Use your package manager to install `nasm`, `x86_64-elf-binutils`, and `qemu-system-i386`
   - **Windows:** See [Running x16-PRos on Windows](../README.md#⚙-running-x16-pros-on-windows)

2. **Build the system:**

   ```txt
   # On macOS
   ./scripts/build/build-macos.sh

   # On Linux
   ./scripts/build/build-linux.sh

   # On Windows
   scripts\build\build-windows.bat
   ```

3. **Run in QEMU:**

   ```sh
   qemu-system-i386 -hda release/img/x16pros.img -m 128M -serial stdio
   ```

---

## 📜 Build Scripts

- **build-macos.sh** – Build and package the OS on macOS.
- **build-linux.sh** – Build and package the OS on Linux.
- **build-windows.bat** – Build and package the OS on Windows.
- **build-fs.sh** – Builds only release (non-test) components and does not assemble or write test binaries.
- **Other scripts** – Utilities for modularity checks, etc. (Test build and utility scripts are now in `tests/`.)

All main build scripts:

- Assemble all core modules as ELF objects and link them into a single kernel.
- Build the boot sector and applications as flat binaries.
- Create a bootable disk image at `release/img/x16pros.img`.

### Script Details

- **build-macos.sh / build-linux.sh**: Bash scripts for Unix-like systems. They check for required tools, clean and create output directories, assemble and link all modules, and write all components to the disk image.
- **build-windows.bat**: Batch script for Windows. Uses NASM and `ld` (from MinGW or similar), and PowerShell for writing binaries to the disk image at the correct offsets.
- **build-fs.sh**: Builds only release (non-test) components and does not assemble or write test binaries.

---

## 💾 Disk Image Layout (Summary)

| Sector | Contents         |
|--------|-----------------|
| 0      | Boot sector     |
| 1-8    | File system     |
| 9+     | Kernel          |
| ...    | Applications    |

---

## 🧪 Running Tests

To build and run the test suite:

```sh
./scripts/tests/run_tests.sh
```

This will assemble and run all test suites in QEMU, reporting results to the console. **All test binaries and images are output to `temp/` and are not included in release images.**

To build test binaries only (without running):

```sh
./scripts/tests/build-tests.sh
```

---

## 🛠 Extending the Build System

- **To add a new core module**: place your `.asm` file in `src/core/`, update the list of modules in the build scripts, and ensure it is assembled as an ELF object and linked into `kernel.bin`.
- **To add a new app**: place your `.asm` file in `src/apps/`, and add a `nasm -f bin ...` line to the build script to produce a flat binary.
- **For new scripts/utilities**: add them to `scripts/` or `scripts/build/` and document their usage here.

---

## ❓ Troubleshooting & FAQ

- **Q: I get 'command not found' for nasm, ld, or qemu-system-i386.**
  - A: Make sure you have installed all prerequisites and that they are in your PATH.

- **Q: The build script fails with a permissions error.**
  - A: Try running the script with `chmod +x` to make it executable, or use `sudo` if necessary (not usually required).

- **Q: The disk image does not boot in QEMU.**
  - A: Double-check that all build steps completed successfully and that the correct files were written to the disk image.

- **Q: How do I add my own program to the disk image?**
  - A: See the 'Adding programs' section in the main README for instructions using `dd`.

For more help, see the [ARCHITECTURE.md](../ARCHITECTURE.md) and [../README.md](../README.md), or open an issue on GitHub.

---

## Directory Structure

```bash
scripts/
  build/      # Platform-specific build scripts
  tests/      # Test build and utility scripts
  utils/      # Utility scripts
  ...         # Additional utility scripts
```

For details, see comments in each script and the main [ARCHITECTURE.md](../ARCHITECTURE.md#build-system).

## Key Responsibilities

- Automate the build process for all system components
- Manage disk image creation and artifact placement
- Provide test integration and runner scripts
- Support cross-compilation and platform-specific workflows

## Interfaces & APIs

- Scripts are invoked from the command line and may be called by higher-level build tools.
- Main entry points and usage are documented in script comments and [ARCHITECTURE.md](../ARCHITECTURE.md#build-system).

## Error Handling

- Scripts include error checking for tool presence, file validity, and build success.
- Error reporting conventions are described in [ARCHITECTURE.md#error-handling](../ARCHITECTURE.md#error-handling).

## Build & Integration

- Scripts are integral to the build and test process (see [Build System](../ARCHITECTURE.md#build-system)).
- No special integration steps beyond standard usage.

## 🛠 Shared Build Utilities & Modularization

All build and test scripts now source a shared utility script: `scripts/utils/build_common.sh`.

- **Common functions** for error checking, file/dir validation, and argument validation are defined in this file.
- **Color variables** and default values are also shared.
- **BUILD_MODE**: All scripts use a `BUILD_MODE` variable (`release` or `test`) to control logic and output locations. This can be set via the environment or by calling `set_build_mode` in the script.
- **OUTDIR**: Scripts use the `OUTDIR` variable, set based on `BUILD_MODE`, to determine where to place build artifacts (e.g., `release/bin` for release, `temp/bin` for test).

### Example: Setting Build Mode

```sh
# In a build script (release by default):
set_build_mode release

# In a test script:
set_build_mode test

# Or override globally:
BUILD_MODE=test ./scripts/build/build-macos.sh
```

### Example: Using OUTDIR

```sh
if [ "$BUILD_MODE" = "test" ]; then
    OUTDIR="temp/bin"
else
    OUTDIR="release/bin"
fi
nasm -f bin src/core/boot.asm -o "$OUTDIR/boot.bin"
```

## References & Further Reading

- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [src/README.md](../src/README.md)
- [tests/README.md](../tests/README.md)
