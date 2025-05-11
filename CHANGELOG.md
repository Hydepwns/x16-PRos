# Changelog

## [Unreleased: 0.2.0 {proposed by Hydepwns}]

### Added

- Core Structures
  - Boot sector with signature and configuration
  - FAT with 12-bit cluster management
  - Root directory with 32-byte entries
  - Error handling system with centralized error codes
  - Recovery mechanisms for disk operations
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
- Initial Project Structure
  - Core system components
  - File system implementation
  - Basic applications
  - Common utilities library
- Test Suite Organization
  - Modular test structure in tests/fs/
  - Directory-specific tests in tests/fs/dir/
  - FAT tests in tests/fs/fat/
  - File operation tests in tests/fs/file/
  - File system initialization tests in tests/fs/init/
  - Removed monolithic test.asm
  - Updated include conventions
  - Enhanced test maintainability
- Test Framework
  - Added standardized test structure macros
  - Implemented common test patterns
  - Added shared test data and constants
  - Enhanced error handling consistency
  - Improved test message formatting
  - Added test result reporting
  - Standardized buffer segments
  - Added common attribute definitions
- Build System Improvements
  - Reorganized build scripts into scripts/build directory
  - Added cross-compilation support for macOS
  - Added predefined disk formats (floppy360, floppy720, floppy144, floppy288, hdd)
  - Added verbose build mode
  - Added test integration
  - Added build artifact cleaning
  - Added sector size validation
  - Added disk format validation
  - Enhanced error reporting
  - Added detailed build documentation
  - Added x86_64-elf toolchain support for macOS
  - Added platform-specific build configurations
  - Added build configuration validation
  - Added comprehensive error handling for build process
  - Added build artifact management
  - Added cross-platform compatibility checks

### Changed

- Project Organization
  - Created dedicated directories for core, fs, apps, and lib
  - Moved common utilities to top-level lib directory
  - Consolidated boot sector implementation
  - Organized test suite to match source structure
  - Moved test files to dedicated tests directory
  - Updated build script for new structure
- Enhanced error handling
  - Centralized error codes
  - Standardized error reporting
  - Added error recovery procedures
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
- Improved build system
  - Added sector size validation
  - Enhanced disk image creation
  - Added component verification
  - Added cross-platform support
  - Added build configuration options
  - Improved build documentation
  - Updated build scripts for modern macOS compatibility
  - Switched to x86_64-elf toolchain for macOS builds
  - Enhanced build script error handling
  - Improved build artifact management
  - Updated build process documentation
- Test Suite Refactoring
  - Standardized test structure across all test files
  - Implemented common test patterns and macros
  - Enhanced test message consistency
  - Improved error handling standardization
  - Added shared test data and constants
  - Updated test runner for framework support
  - Enhanced test maintainability
  - Improved test documentation
- Refactored src/fs/dir.asm to be a pure aggregator, removing duplicate implementations and resolving label redefinition errors.
- Cleaned up src/lib/constants.inc to ensure proper formatting and remove any stray characters causing assembler errors.
- Linter script improvements:
  - Excludes itself from aggregator checks to prevent false positives.
  - Only matches actual build commands for aggregator detection.
  - Uses portable, robust method for removing global directives from helper functions (awk+while-read loop).
  - Handles all filenames safely (null-delimited find+while-read).

### Fixed

- Removed stray {}.tmp file from project root and improved linter script to prevent its creation.
- Resolved NASM macro/constant conflict by changing SECTOR_SIZE from equ to %define in src/lib/constants.inc, ensuring compatibility with macro logic in all modules and fixing test build errors.
- Fixed build system compatibility issues on modern macOS by switching to x86_64-elf toolchain
- Resolved symbol redefinition errors in test suite
- Fixed build script error handling and validation
- Corrected build artifact management and cleanup
- Fixed cross-platform compatibility issues in build scripts
- Fixed directory entry field offsets and validation
- Corrected file size handling in directory entries
- Fixed date and time field handling
- Improved directory listing format and readability
- Fixed test framework integration issues
- Corrected test message formatting
- Fixed test buffer segment conflicts
- Resolved test attribute definition issues

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
  - Improve test documentation
  - Add test result reporting
  - Implement test coverage tracking
  - Add automated test execution
  - Enhance test framework capabilities

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
  - Add build system documentation
  - Create troubleshooting guide
  - Add platform-specific guides
  - Add API documentation
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
