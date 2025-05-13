# x16-PRos Test Suite

All automated tests, macros, runners, and scripts for x16-PRos live here. Tests are organized by subsystem.

## Directory Structure

```text
tests/
  core/       # Core system tests
  fs/         # File system tests
  apps/       # App tests
  src/        # Library/module tests
  scripts/    # Test/build scripts
  test_framework.inc   # (Legacy) Old test macros
  test_data.inc        # (Legacy) Old test data
  linker.ld           # (Legacy) Test linker script
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
  - Test binaries: `temp/img/fs/dir/`
  - Logs/results: `temp/log/`

## Running Tests

Build all:

```sh
./scripts/tests/run_tests.sh
```

Test binaries are output to `temp/img/fs/dir/`, and logs/results to `temp/log/`.
Review test results in `temp/log/` after running.

Run all in QEMU:

```sh
./scripts/tests/run_qemu_tests.sh
```

## Where to Go Next

- [ARCHITECTURE.md][arch]
- [../src/README.md][src-readme]
- [../scripts/README.md][scripts-readme]

## References

- [ARCHITECTURE.md][arch]
- [../src/README.md][src-readme]
- [../scripts/README.md][scripts-readme]

[arch]: ../ARCHITECTURE.md
[src-readme]: ../src/README.md
[scripts-readme]: ../scripts/README.md