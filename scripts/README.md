# Build & Utility Scripts

## Structure

- build/: Platform build scripts
- tests/: Test build/run scripts
- utils/: Helpers (loaders, disk tools)

## Build System

- Test output: `temp/`, release: `release/`
- Modular: Only needed modules linked
- Standalone boot sector tests: `nasm -f bin`, all code/data in one `.asm`
  - For `-f bin`: no `section .text`/`.data`. Use `%ifidn __OUTPUT_FORMAT__, "bin"` for `ORG`.
- Config-driven: `modules.conf`, `tests.conf`

## Quick Start

- Install: `nasm`, `x86_64-elf-binutils`, `qemu`
- Build: `./scripts/build/build.sh` (Unix), `scripts\build\build-windows.bat` (Win)
- Run: `qemu-system-i386 -hda release/img/x16pros.img -m 128M -serial stdio`

## Scripts

- build.sh: Unix build/package
- build-windows.bat: Windows build/package
- build-fs.sh: Release only, no tests

## Disk Layout

| Sector | Contents     |
|--------|-------------|
| 0      | Boot sector |
| 1      | FS          |
| 2-5    | FAT         |
| 6-9    | Root dir    |
| 10+    | Kernel      |
| ...    | Apps        |

## Test Scripts

- run_tests.sh: Assembles all test bins (`nasm -f bin`)
- run_qemu_tests.sh: Runs all test bins in QEMU
- modules.conf/tests.conf: Build targets

## Add/Run Tests

- Edit `modules.conf`/`tests.conf`
- Build: `./scripts/tests/run_tests.sh`
- Run: `./scripts/tests/run_qemu_tests.sh`

## Disk Image Check

- `utils/check-image.sh`: Verifies image, boot sig, FS, FAT, kernel, boot
