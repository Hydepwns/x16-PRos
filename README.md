<div align="center">

  <h1>x16-PRos operating system</h1>

  <img src="https://github.com/PRoX2011/x16-PRos/raw/main/preview.gif" width="65%">
  
  **x16-PRos** is a minimalistic 16-bit operating system written in NASM for x86 architecture. It features a text interface, program loading, and basic system functions (CPU info, time, date, etc).

  <a href="https://x16-pros.netlify.app/">
    <img src="https://img.shields.io/badge/x16%20PRos-web%20site-blue.svg?style=for-the-badge" height="40">
  </a>

</div>

---

## Features

- Modular kernel (NASM, ELF object + linker)
- Simple shell and command interface
- Built-in apps: notepad, calculator, snake, barchart, brainf IDE, clock
- x16FS-Lite file system (floppy/hdd image)
- Runs on QEMU, Bochs, v86, or real hardware (BIOS/CSM)

---

## Supported Commands

- `help` — list commands
- `info` — system info
- `cls` — clear screen
- `shut` — shut down
- `reboot` — restart
- `date` — show date
- `time` — show time (UTC)
- `CPU` — CPU info
- `load` — load program from disk
- `write`, `brainf`, `barchart`, `snake`, `calc`, `clock` — launch built-in apps
- `fs` — file system operations

---

## Included Apps

- Notepad (write)
- Brainf IDE
- Barchart
- Snake
- Calc
- Clock

<img src="https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/3.png" width="60%">

---

## Quick Start

See [scripts/README.md](scripts/README.md) for full build and test instructions for all platforms.

```sh
# Clone
 git clone https://github.com/PRoX2011/x16-PRos.git
 cd x16-PRos

# Build (macOS/Linux/Windows)
 ./scripts/build/build.sh
 # or scripts/build/build-windows.bat

# Run in QEMU
 qemu-system-i386 -hda release/img/x16pros.img -m 128M -serial stdio
```

---

## Adding Your Own Program

You can add your own program to the disk image and run it with the `load` command:

```sh
dd if=YourProgram.bin of=release/img/x16pros.img bs=512 seek=KERNEL_END_SECTOR conv=notrunc
```

> **Note:** Sector 10 is the start of the kernel (see KERNEL_START_SECTOR in src/lib/constants.inc). Place your program after the kernel. If your kernel is N sectors, use sector 10+N for your program. Always check the kernel size before choosing the sector for new programs.

---

## Running & Emulators

- QEMU: `qemu-system-i386 -hda release/img/x16pros.img -m 128M -serial stdio`
- Bochs, v86, or real PC (BIOS/CSM)

---

## Contributing & Credits

- Lead: **PRoX (Faddey Kabanov)**
- Contributors: Loxsete (barchart), Saeta (calc logic)
- PRs, bug reports, and new apps welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) or open an issue.

---

## More Documentation

- [scripts/README.md](scripts/README.md) — Build & test system details
- [ARCHITECTURE.md](ARCHITECTURE.md) — System architecture
- [src/README.md](src/README.md) — Source code structure
- [tests/README.md](tests/README.md) — Test framework

---

## Build & Test System Overview

- Test output: `temp/`, release: `release/`. Test code never in production.
- Modular: Each binary links only needed modules. No test code in release.
- Config-driven: Tests built/run via `modules.conf`, `tests.conf`.
- Standalone boot sector tests: `nasm -f bin`, all code/data in one `.asm`. No linking/objcopy. Rare integration tests use a loader.

See [scripts/README.md](scripts/README.md) and [tests/README.md](tests/README.md) for full details.

---

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

Distributed under the MIT License.

To build the system on Linux or macOS, run:
```sh
scripts/build/build.sh
```
