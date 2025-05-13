# Changelog

## [Unreleased: 0.2.0]

### Added

- Boot sector, FAT12, root dir (32-byte entries)
- Centralized error codes, reporting, and recovery
- Memory map (0x7C00-0xBFFF), buffers, stack
- BIOS disk I/O with retry
- FAT: init, alloc, dealloc, chain validation
- Dir: CRUD, list, entry validation
- File: create, delete, read, write
- Error handling and recovery ops
- Basic FS commands: init, create, delete, read, write, list, info
- Modular test structure: `tests/fs/`, `tests/fs/dir/`, `tests/fs/fat/`, `tests/fs/file/`, `tests/fs/init/`
- Standalone boot sector tests (nasm -f bin, all code/data in one file)
- New test framework: macros, patterns, shared data, result reporting
- Build system: modular scripts, cross-platform, disk formats, verbose mode, artifact cleaning, validation, error reporting, docs
- NASM modular assembly guidelines: conditional ORG, unique macro labels, no duplicate globals, proper exports

### Changed

- Moved tests to `tests/`, updated build scripts, docs
- Refactored build scripts: ELF32 objects, single fs.bin, sector offsets, toolchain checks, output dirs, 1.44MB image
- Dir entries: 32 bytes, better alignment, date/time, file size, validation
- Dir ops: validation, size/cluster checks, field init, listing format
- Tests: migrated to new framework, improved runner, maintainability, docs
- Refactored `src/fs/dir.asm` to aggregator, fixed label errors
- Cleaned up `src/lib/constants.inc`
- Linter: improved aggregator checks, global detection, file handling
- Docs: major cleanup, deduplication, DRY, canonical refs, markdown compliance
- Unified build/test output structure: bin/obj, bin/, img/, log/
- All build scripts: correct output, dir creation, artifact placement
- Linter: aggregator checks, error function uniqueness, extern warnings
- `tests/fs/dir/test_dir_consistency.asm`: now fully standalone
- All major READMEs: terse, up-to-date dir structure, legacy marked

### Fixed

- Removed stray temp files, improved linter
- Fixed NASM macro/constant conflicts
- macOS build compatibility (x86_64-elf)
- Symbol redefinition in tests
- Build script error handling, artifact management
- Cross-platform build fixes
- Dir entry offsets, validation, file size, date/time
- Test framework integration, message formatting, buffer segments, attribute defs
- Test build script now assembles all test binaries as flat binaries (`-f bin`) and outputs them to `temp/img/fs/dir/` for correct test harness discovery.
- Test harness (`run_tests.sh`) now finds and runs all test binaries in QEMU without missing file errors.
- Test logs and results are now consistently written to `temp/log/` for easier review and automation.

### Future

- See bottom of file for roadmap: FS check, recovery, subdirs, caching, perf, FAT12/16, tools, UX, compression, encryption, build system, CI, docs, etc.

## [0.1.0] - 2025-05-10

### Added

- Initial project structure: core, fs, apps, lib

### Changed

- Moved utilities, consolidated boot, organized tests
- Docs: comprehensive READMEs, architecture, usage

### Fixed

- Boot sector: consolidation, FS init, error handling
- Library: moved utils, doc, paths, reusability
