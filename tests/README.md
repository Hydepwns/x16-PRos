# x16-PRos Test Suite

This directory contains all automated tests, macros, runners, and test scripts for x16-PRos. All test scripts and runners are organized here by subsystem.

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

- `core/`, `fs/`, `apps/`, `src/` — Test sources for each subsystem
- `test_framework.inc`, `test_data.inc` — (Legacy) Shared macros and data for older tests
- `linker.ld` — (Legacy) Test linker script
- `scripts/` — **All test, build, and utility scripts**
- `run_tests.sh` — Main test builder (assembles all tests)
- `run_qemu_tests.sh` — Runs all test binaries in QEMU and collects results
- `modules.conf`, `tests.conf` — Config files listing all build targets

## Test Output & Artifacts

- **All test and development output is written to `temp/`**
  - Object files: `temp/bin/obj/`
  - Test binaries, images, and logs: `temp/bin/`
- **Production-ready artifacts are only in `release/`**

## Running Tests (Config-Driven)

Build all tests:

```sh
./scripts/tests/run_tests.sh
```

Run all tests in QEMU:

```sh
./scripts/tests/run_qemu_tests.sh
```

## Adding or Modifying Tests/Modules

- Edit `scripts/tests/modules.conf` or `scripts/tests/tests.conf`.
- Each line: `src=... out=... macros=... includes=...`
- No script changes needed for new tests/modules.

Example:

```sh
src=tests/fs/dir/test_dir_fill_clean.asm \
out=test_dir_fill.o \
macros=SECTOR_SIZE=512 \
includes=src
```

- `src` — Source file path
- `out` — Output file name
- `macros` — Optional macros to pass to nasm
- `includes` — Optional include paths

## Standalone Boot Sector Tests

Most tests in this suite are now written as **fully self-contained boot sector binaries**. These tests:
- Do **not** use `extern` or require linking with any external modules.
- Contain all code and data needed for the test in a single `.asm` file.
- Are assembled with `nasm -f bin` and padded to 512 bytes with a boot signature.
- Can be run directly in QEMU or on real hardware as a boot sector.

**Minimal Test Template Example:**

```nasm
[BITS 16]
org 0x7C00

start:
    ; Test logic here
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

## Loader/Harness-Based Test Automation (Rare)

- Some rare, complex integration tests may use a loader or harness if they require a more complex environment or are not true boot sectors.
- See [`scripts/utils/make_loader_disk.sh`](../scripts/utils/make_loader_disk.sh) and [`scripts/utils/loader.asm`](../scripts/utils/loader.asm) for details.

---

(Sections about legacy modular linking and test framework macros can be marked as legacy or moved to the end.)
