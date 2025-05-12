# x16-PRos Test Suite

This directory contains all automated tests, macros, runners, and test scripts for x16-PRos. All test scripts and runners are organized here by subsystem.

## Directory Structure

- `core/`, `fs/`, `apps/`, `src/` — Test sources for each subsystem
- `test_framework.inc`, `test_data.inc` — Shared macros and data for tests
- `linker.ld` — Test linker script
- `scripts/` — **All test, build, and utility scripts**
- `run_tests.sh` — Main test runner (assembles, links, and runs all tests)

## Test Output & Artifacts

- **All test and development output is written to `temp/`**
  - Object files: `temp/bin/obj/`
  - Test binaries, images, and logs: `temp/bin/`
- **Production-ready artifacts are only in `release/`**

## Running Tests

To build and run all tests:

```sh
# Build all tests
./scripts/tests/build-tests.sh

# Run all tests
./scripts/tests/run-tests.sh
```

To build specific test binaries (for example, directory tests):

```sh
# Build specific test
./scripts/tests/build-tests.sh fs/dir

# Run specific test
./scripts/tests/run-tests.sh temp/bin/test_dir.elf

# Run specific test in emulator
x16emu -f temp/bin/test_dir.bin
```

## Adding New Tests

- Place new test sources in the appropriate subsystem directory (e.g., `tests/fs/dir/`).
- Add or update build scripts in `scripts/tests/` as needed.
- Ensure all temporary outputs go to `temp/`.

## More Information

- See [../ARCHITECTURE.md](../ARCHITECTURE.md) for the full system and artifact flow.
- See subsystem READMEs for details on test structure and conventions.
