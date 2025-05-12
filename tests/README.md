# x16-PRos Test Suite

All automated tests, macros, runners, and scripts for x16-PRos live here. Tests are organized by subsystem.

## Directory Structure

```text
tests/
  core/     # Core system tests
  fs/       # File system tests
  apps/     # App tests
  src/      # Library/module tests
  scripts/  # Test/build scripts
  test_framework.inc   # (Legacy) Old test macros
  test_data.inc        # (Legacy) Old test data
  linker.ld            # (Legacy) Test linker script
  ...
```

- `core/`, `fs/`, `apps/`, `src/`: Test sources by subsystem
- `test_framework.inc`, `test_data.inc`, `linker.ld`: Legacy
- `scripts/`: All test/build/utility scripts
- `run_tests.sh`: Main test builder
- `run_qemu_tests.sh`: Runs all test binaries in QEMU
- `modules.conf`, `tests.conf`: Build configs

## Test Output

- All test/dev output: `temp/`
  - Objects: `temp/bin/obj/`
  - Binaries, images, logs: `temp/bin/`
- Production artifacts: `release/`

## Running Tests

Build all:

```sh
./scripts/tests/run_tests.sh
```

Run all in QEMU:

```sh
./scripts/tests/run_qemu_tests.sh
```

## Adding/Modifying Tests

- Edit `scripts/tests/modules.conf` or `scripts/tests/tests.conf`.
- Each line: `src=... out=... macros=... includes=...`
- No script changes needed for new tests.

Example:

```sh
src=tests/fs/dir/test_dir_fill_clean.asm \
out=test_dir_fill.o \
macros=SECTOR_SIZE=512 \
includes=src
```

## Standalone Boot Sector Tests

- Most tests are self-contained boot sector binaries.
- No `extern` or linking. All code/data in one `.asm` file.
- Assembled with `nasm -f bin`, padded to 512 bytes, boot signature at end.
- Run directly in QEMU or on hardware.

**Minimal Template:**

```nasm
[BITS 16]
org 0x7C00

start:
    ; Test logic
    call print_success
    jmp $

fail:
    call print_error
    jmp $

print_success:
    mov si, success_msg
    call print_string
    ret

print_error:
    mov si, error_msg
    call print_string
    ret

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp print_string
.done:
    ret

success_msg db "All tests passed!", 13, 10, 0
error_msg   db "Test failed!", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
```

See `tests/fs/dir/test_dir_consistency.asm` for a real example.

## Loader/Harness-Based Tests

- Rare, for complex integration.
- See [`scripts/utils/make_loader_disk.sh`](../scripts/utils/make_loader_disk.sh) and [`scripts/utils/loader.asm`](../scripts/utils/loader.asm).
