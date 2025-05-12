# Changelog

## [Unreleased: 0.2.0 {proposed by Hydepwns}]

### Added

- Core Structures
  - Boot sector with signature and configuration
  - FAT with 12-bit cluster management
  - Root directory with 32-byte entries
  - Added error handling system featuring:
    - Centralized error codes
    - Standardized error reporting
  - Added recovery mechanisms for disk operations, including error recovery procedures.
- Memory Layout
  - Defined map (0x7C00-0xBFFF)
  - Boot sector region
  - FAT and directory buffers
  - File buffer and stack
  - Error handling buffer
  - Recovery operation buffer
- Core Operations
  - BIOS disk I/O functions with retry mechanism
  - FAT operations (init, alloc, dealloc, chain validation)
  - Directory operations (CRUD, list, entry validation)
  - File operations (create, delete, read, write)
  - Error handling and recovery operations
- Basic Commands
  - File system initialization
  - File creation and deletion
  - File read and write
  - Directory listing and info
  - Error reporting and recovery
- Test Suite Organization
  - Modular test structure in `tests/fs/`
  - Directory-specific tests in `tests/fs/dir/`
  - FAT tests in `tests/fs/fat/`
  - File operation tests in `tests/fs/file/`
  - File system initialization tests in `tests/fs/init/`
  - Removed monolithic `test.asm`
  - Updated include conventions
- Test Framework
  - Added a new test framework including:
    - Standardized test structure macros
    - Common test patterns
    - Shared test data and constants
    - Test result reporting capabilities
    - Standardized buffer segments
    - Common attribute definitions
    - Mechanisms for consistent error handling and message formatting in tests.
- Build System Improvements
  - Reorganized build scripts into `scripts/build` directory.
  - Added cross-compilation support for macOS, utilizing the x86_64-elf toolchain.
  - Introduced predefined disk formats (floppy360, floppy720, floppy144, floppy288, hdd).
  - Added verbose build mode.
  - Integrated test execution into the build process.
  - Implemented build artifact cleaning and management.
  - Added validation for sector size, disk format, and build configuration.
  - Enhanced error reporting and comprehensive error handling for the build process.
  - Added detailed build documentation.
  - Added platform-specific build configurations.
  - Added cross-platform compatibility checks.
- NASM Modular Assembly Compatibility Guidelines
  - Documented best practices for making NASM code compatible with both flat binary and ELF object file outputs.
  - Included instructions for conditional `ORG` directive, unique macro labels, avoiding duplicate global labels, and proper function exporting for linking.
  - Provided troubleshooting checklist and example code for modular assembly development.

### Changed

- Project Organization
  - Moved test files to dedicated `tests` directory.
  - Updated build scripts for the new project structure and to integrate new build system features.
  - Updated build process documentation to reflect new structure and features.
  - Refactored `scripts/build/build-linux.sh`:
    - File system components (`io.asm`, `errors.asm`, `fat.asm`, `file.asm`, `recovery.asm`) now compile to ELF32 objects.
    - ELF objects are linked into a single `fs.bin`.
    - `fs.bin` is written to the disk image, with kernel and application sector offsets adjusted.
    - Toolchain check for `x86_64-elf-ld` added.
    - Creates `bin/obj` directory for intermediate object files.
    - Standardized disk image size to 1.44MB.
  - Refactored `scripts/build/build-windows.bat`:
    - Adopted ELF32 object and linking model for file system components, similar to Linux/macOS.
    - Added check for `ld.exe` (ELF linker).
    - File system objects are linked into `fs.bin` and written to the disk image.
    - Kernel and application sector offsets adjusted.
    - Standardized disk image size to 1.44MB.
    - Aligned application binary inclusion (`snake.asm`, `calc.asm`) with `build-linux.sh`.
    - Creates `bin\obj` directory for intermediate object files.
- Directory Entry Structure
  - Updated to 32-byte entries for better field alignment
  - Improved date and time field handling (2 bytes each)
  - Enhanced file size handling (3 bytes)
  - Added proper field validation
  - Improved directory listing format
- Directory Operations
  - Enhanced directory entry validation
  - Improved file size and cluster validation
  - Added proper field initialization
  - Enhanced directory listing display
  - Added human-readable date/time formatting
- Test Suite Refactoring
  - Migrated existing tests to the new framework, standardizing structure and patterns.
  - Updated test runner for framework support.
  - Enhanced overall test maintainability.
  - Improved test documentation.
- Refactored `src/fs/dir.asm` to be a pure aggregator, removing duplicate implementations and resolving label redefinition errors.
- Cleaned up `src/lib/constants.inc` to ensure proper formatting and remove any stray characters causing assembler errors.
- Linter script improvements:
  - Excludes itself from aggregator checks to prevent false positives.
  - Only matches actual build commands for aggregator detection.
  - Uses portable, robust method for removing global directives from helper functions (awk+while-read loop).
  - Handles all filenames safely (null-delimited find+while-read).
- Documentation Refactor
  - Major cleanup and deduplication of `ARCHITECTURE.md`
  - Removed duplicate headings and merged unique content under single headings
  - Applied DRY principles throughout documentation
  - Improved section referencing and canonicalization
  - Ensured markdown linter compliance (no duplicate headings, consistent spacing)
- **Documentation & Build System**
  - Streamlined the root `README.md` to be concise and focused on features, usage, and high-level build info. All detailed build, test, and troubleshooting instructions are now in `scripts/README.md`.
  - Major expansion of `scripts/README.md` to serve as the canonical reference for all build and test scripts, including quick start, platform-specific instructions, disk image layout, troubleshooting, and extension guidelines.
  - Unified and clarified modular build scripts for macOS, Linux, and Windows: all core modules are now built as ELF objects and linked into a single kernel binary; only the boot sector and apps are built as flat binaries.
  - Updated documentation to consistently refer to the new modular build process and script locations.

### Fixed

- Removed stray `{}.tmp` file from project root and improved linter script to prevent its creation.
- Resolved NASM macro/constant conflict by changing `SECTOR_SIZE` from `equ` to `%define` in `src/lib/constants.inc`, ensuring compatibility with macro logic in all modules and fixing test build errors.
- Fixed build system compatibility issues on modern macOS by switching to x86_64-elf toolchain.
- Resolved symbol redefinition errors in test suite.
- Fixed build script error handling and validation.
- Corrected build artifact management and cleanup.
- Fixed cross-platform compatibility issues in build scripts.
- Fixed directory entry field offsets and validation.
- Corrected file size handling in directory entries.
- Fixed date and time field handling.
- Improved directory listing format and readability.
- Fixed test framework integration issues.
- Corrected test message formatting.
- Fixed test buffer segment conflicts.
- Resolved test attribute definition issues.

### Future Plans {loose proposals by Hydepwns, would love to be discuss}

#### P1: Core

- File System Check
  - FAT chain validation and repair
  - Directory entry consistency check
  - Cluster allocation verification
  - File size vs chain validation
- Recovery System
  - FAT backup and restoration
  - Directory entry recovery
  - Cluster chain reconstruction
  - Bad sector handling
- Test Suite Enhancement
  - Add performance benchmarks
  - Implement stress testing
  - Add edge case coverage
  - Implement test coverage tracking
  - Add automated test execution
  - Enhance test framework capabilities (e.g., for advanced scenarios)

#### P2: Essential

- Subdirectory Support
  - Hierarchical directory structure
  - Path resolution and navigation
  - Directory size management
  - Special directory handling
- File Attributes
  - Basic attribute flags
  - Timestamp management
  - Extended attributes
  - Access control

#### P3: Performance

- Caching System
  - FAT cache implementation
  - Directory entry caching
  - Read-ahead buffering
  - Write-back optimization
- Performance Optimization
  - Cluster pre-allocation
  - Defragmentation tools
  - I/O pattern optimization
  - Buffer size tuning

#### P4: Advanced

- FAT12/16 Compatibility
  - Legacy format support
  - Format conversion tools
  - Automatic format detection
  - Cluster size adaptation
- External Tools
  - Disk image mounting
  - Backup/restore utilities
  - Debug interface
  - Cross-platform tools

#### P5: User Experience

- File Manager
  - Directory browsing
  - File operations interface
  - Status display
  - Progress indicators
- Command System
  - Command history
  - Tab completion
  - Wildcard expansion
  - Batch operations

#### P6: Optional

- Compression
  - LZ compression algorithm
  - Compression level control
  - Compressed file markers
  - Compression statistics
- Encryption
  - XOR encryption
  - Password protection
  - Encrypted file markers
  - Key management

#### P7: Build System

- Build Configuration
  - Add configuration file support
  - Implement build profiles
  - Add dependency tracking
  - Add build variant support
- Performance
  - Add parallel build support
  - Implement incremental builds
  - Add build caching
  - Optimize build times
- Testing
  - Add automated test suite
  - Implement build verification
  - Add performance benchmarks
  - Add regression testing
- Documentation
  - Create troubleshooting guide
  - Add platform-specific guides
  - Add API documentation for build system components.
- Cross-Platform Support
  - Enhance macOS compatibility
  - Improve Windows support
  - Add containerized builds
  - Add CI/CD integration
- Development Environment
  - Add Docker/Virtual Machine support
  - Create development environment setup guide
  - Add platform-specific troubleshooting guides
  - Add development tools integration

## [0.1.0] - 2025-05-10 {first release by PRoX2011 & contributors}

### Added

- Initial project structure
  - Core system components
  - File system implementation
  - Basic applications
  - Common utilities library

### Changed

- Project Organization
  - Created dedicated directories for core, fs, apps, and lib
  - Moved common utilities to top-level lib directory
  - Consolidated boot sector implementation
  - Organized test suite to match source structure
- Documentation
  - Added comprehensive README files
  - Updated architecture documentation
  - Added library usage guidelines
  - Improved code documentation

### Fixed

- Boot Sector
  - Consolidated duplicate boot implementations
  - Added proper file system initialization
  - Improved error handling
  - Enhanced system checks
- Library Organization
  - Moved common utilities out of fs directory
  - Improved utility function documentation
  - Standardized include paths
  - Enhanced code reusability
