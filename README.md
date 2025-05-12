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
 ./scripts/build/build-macos.sh
 # or ./scripts/build/build-linux.sh
 # or scripts\build\build-windows.bat

# Run in QEMU
 qemu-system-i386 -hda release/img/x16pros.img -m 128M -serial stdio
```

---

## Adding Your Own Program

You can add your own program to the disk image and run it with the `load` command:

```sh
dd if=YourProgram.bin of=release/img/x16pros.img bs=512 seek=DiskSector conv=notrunc
```

See [scripts/README.md](scripts/README.md) for details.

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

Distributed under the MIT License.
