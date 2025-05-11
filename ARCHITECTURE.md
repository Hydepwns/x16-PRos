# x16-PRos Architecture

## System Overview

The x16-PRos operating system is designed with a modular architecture that emphasizes reliability, maintainability, and testability. The system is organized into several key components:

1. **Core System**
   - Memory management
   - Process management
   - Interrupt handling
   - System services

2. **File System**
   - FAT implementation
   - Directory management
   - File operations
   - Error recovery

3. **Testing Framework**
   - Test structure macros
   - Common test data
   - Test categories
   - Test runner

## Component Architecture

### Core System

#### File System Layout

```ruby
+------------------+
|    Boot Sector   | 256 bytes
+------------------+
|       FAT        | 4 sectors
+------------------+
|  Root Directory  | 4 sectors (32-byte entries)
+------------------+
|    Data Area     | Remaining sectors
+------------------+
```

#### File System Commands

```bash
fs init      # Initialize file system
fs create    # Create new file
fs read      # Read file contents
fs write     # Write to file
fs delete    # Delete file
fs list      # List directory
fs info      # Show file system info
```

#### Memory Map

```bash
0x7C00 +------------------+
       |    Boot Sector   |
0x7DFF +------------------+
0x8000 |    FAT Buffer    |
0x87FF +------------------+
0x8800 | Directory Buffer |
0x8FFF +------------------+
0x9000 |   File Buffer    |
0x9FFF +------------------+
0xA000 |      Stack       |
0xAFFF +------------------+
0xB000 | Error Buffer     |
0xB7FF +------------------+
0xB800 | Recovery Buffer  |
0xBFFF +------------------+
```

#### Source Code Organization

##### Directory Structure

```bash
src/
├── core/           # Core system files
│   ├── boot.asm    # Boot sector and initialization
│   ├── kernel.asm  # Core OS functionality
│   ├── memory/     # Memory management
│   │   └── memory.asm
│   ├── interrupts/ # Interrupt handling
│   │   └── interrupts.asm
│   ├── process/    # Process management
│   │   └── process.asm
│   ├── shell/      # Shell interface
│   │   └── shell.asm
│   ├── services/   # System services
│   │   └── services.asm
│   └── cpu/        # CPU information
│       └── cpu.asm
├── fs/            # File system implementation
│   ├── fat.asm    # FAT operations
│   ├── dir/       # Directory operations
│   │   ├── core.asm    # Core directory functions
│   │   ├── list.asm    # Directory listing functions
│   │   └── helpers.asm # Directory helper functions
│   ├── file.asm   # File operations
│   ├── errors.asm # Error handling
│   └── recovery.asm # Recovery mechanisms
├── lib/           # Common libraries
│   ├── constants.inc   # Centralized constants
│   ├── io.inc         # I/O operations
│   ├── utils.inc      # Utility functions
│   ├── ui.inc         # UI operations
│   └── memory.inc     # Memory operations
└── apps/          # User applications
    ├── calc.asm   # Calculator
    ├── snake.asm  # Snake game
    ├── brainf.asm # Brainfuck interpreter
    ├── barchart.asm # Bar chart visualization
    ├── clock.asm  # Clock/Time application
    └── write.asm  # Text editor
```

#### Core Dependencies

##### Memory Management

- Memory allocation/deallocation
  - Bitmap-based tracking
  - 8KB block size
  - System memory protection
  - Error handling
- Memory protection
  - System memory protection
  - Process memory isolation
  - Access control
- Memory mapping
  - Physical to virtual mapping
  - Page table management
  - Memory region tracking

##### Interrupt Handling

- Interrupt vector table
  - Exception handlers
  - IRQ handlers
  - Software interrupt handlers
- PIC configuration
  - IRQ masking
  - EOI handling
  - Priority management
- Error handling
  - Exception reporting
  - Error recovery
  - Debug information

##### Process Management

- Process control blocks
  - State management
  - Resource tracking
  - Priority handling
- Scheduling
  - Round-robin scheduling
  - Priority-based scheduling
  - Context switching
- Resource management
  - Memory allocation
  - I/O handling
  - Process synchronization

##### File System Operations

- FAT operations
  - Cluster allocation
  - Chain management
  - Space tracking
- Directory operations
  - Entry management
  - Attribute handling
  - Order maintenance
- File operations
  - I/O handling
  - Chain management
  - Size management

### File System

#### File System Layout

```ruby
+------------------+
|    Boot Sector   | 256 bytes
+------------------+
|       FAT        | 4 sectors
+------------------+
|  Root Directory  | 4 sectors (32-byte entries)
+------------------+
|    Data Area     | Remaining sectors
+------------------+
```

#### File System Commands

```bash
fs init      # Initialize file system
fs create    # Create new file
fs read      # Read file contents
fs write     # Write to file
fs delete    # Delete file
fs list      # List directory
fs info      # Show file system info
```

#### Memory Map

```bash
0x7C00 +------------------+
       |    Boot Sector   |
0x7DFF +------------------+
0x8000 |    FAT Buffer    |
0x87FF +------------------+
0x8800 | Directory Buffer |
0x8FFF +------------------+
0x9000 |   File Buffer    |
0x9FFF +------------------+
0xA000 |      Stack       |
0xAFFF +------------------+
0xB000 | Error Buffer     |
0xB7FF +------------------+
0xB800 | Recovery Buffer  |
0xBFFF +------------------+
```

### Testing Framework

The testing framework is designed to provide a standardized approach to testing all system components. It consists of:

#### Test Framework (`tests/test_framework.inc`)

```nasm
TEST_START      ; Begin test execution
TEST_END        ; End test execution
TEST_ERROR      ; Handle test errors
TEST_MESSAGE    ; Define test messages
```

#### Test Categories

1. **Core System Tests**
   - Boot sector validation
   - Kernel functionality
   - Memory management
   - Interrupt handling
   - Process management
   - System services
   - Error handling

2. **File System Tests**
   - FAT operations
   - Directory operations
   - File operations
   - Error recovery

3. **Application Tests**
   - Functionality verification
   - Error handling
   - User interface
   - Performance metrics

#### Test Runner (`tests/run_tests.sh`)

```bash
./run_tests.sh [test_category] [test_name]
```

## System Interfaces

### Core System Interfaces

#### File System Layout

```ruby
+------------------+
|    Boot Sector   | 256 bytes
+------------------+
|       FAT        | 4 sectors
+------------------+
|  Root Directory  | 4 sectors (32-byte entries)
+------------------+
|    Data Area     | Remaining sectors
+------------------+
```

#### File System Commands

```bash
fs init      # Initialize file system
fs create    # Create new file
fs read      # Read file contents
fs write     # Write to file
fs delete    # Delete file
fs list      # List directory
fs info      # Show file system info
```

#### Memory Map

```bash
0x7C00 +------------------+
       |    Boot Sector   |
0x7DFF +------------------+
0x8000 |    FAT Buffer    |
0x87FF +------------------+
0x8800 | Directory Buffer |
0x8FFF +------------------+
0x9000 |   File Buffer    |
0x9FFF +------------------+
0xA000 |      Stack       |
0xAFFF +------------------+
0xB000 | Error Buffer     |
0xB7FF +------------------+
0xB800 | Recovery Buffer  |
0xBFFF +------------------+
```

### File System Interfaces

#### File System Layout

```ruby
+------------------+
|    Boot Sector   | 256 bytes
+------------------+
|       FAT        | 4 sectors
+------------------+
|  Root Directory  | 4 sectors (32-byte entries)
+------------------+
|    Data Area     | Remaining sectors
+------------------+
```

#### File System Commands

```bash
fs init      # Initialize file system
fs create    # Create new file
fs read      # Read file contents
fs write     # Write to file
fs delete    # Delete file
fs list      # List directory
fs info      # Show file system info
```

#### Memory Map

```bash
0x7C00 +------------------+
       |    Boot Sector   |
0x7DFF +------------------+
0x8000 |    FAT Buffer    |
0x87FF +------------------+
0x8800 | Directory Buffer |
0x8FFF +------------------+
0x9000 |   File Buffer    |
0x9FFF +------------------+
0xA000 |      Stack       |
0xAFFF +------------------+
0xB000 | Error Buffer     |
0xB7FF +------------------+
0xB800 | Recovery Buffer  |
0xBFFF +------------------+
```

### Testing Framework Interfaces

1. **Test Framework Macros**

   ```nasm
   TEST_START      ; Begin test execution
   TEST_END        ; End test execution
   TEST_ERROR      ; Handle test errors
   TEST_MESSAGE    ; Define test messages
   ```

2. **Common Test Data**

   ```nasm
   test_data       ; Standard test data
   test_filename   ; Standard test filenames
   TEST_ATTR_*     ; File attribute constants
   TEST_BUFFER_SEG* ; Buffer segment constants
   ```

3. **Test Runner Interface**

   ```bash
   ./run_tests.sh [test_category] [test_name]
   ```

## Error Handling

### Directory Entry Structure

#### Field Layout

```ruby
+------------------+
|    Filename     | 8 bytes
+------------------+
|    Extension    | 3 bytes
+------------------+
|   Attributes    | 1 byte
+------------------+
|    File Size    | 3 bytes
+------------------+
| Starting Cluster| 2 bytes
+------------------+
|      Date       | 2 bytes
+------------------+
|      Time       | 2 bytes
+------------------+
|    Reserved     | 11 bytes
+------------------+
```

#### Field Details

1. **Filename (8 bytes)**
   - Uppercase letters only
   - Space padding
   - No special characters

2. **Extension (3 bytes)**
   - Uppercase letters only
   - Space padding
   - No special characters

3. **Attributes (1 byte)**
   - Bit 0: Read-only
   - Bit 1: Hidden
   - Bit 2: System
   - Bit 3: Volume label
   - Bit 4: Directory
   - Bit 5: Archive
   - Bits 6-7: Reserved

4. **File Size (3 bytes)**
   - Maximum size: 16,777,215 bytes
   - Little-endian format
   - Zero-padded

5. **Starting Cluster (2 bytes)**
   - 12-bit cluster numbers
   - Little-endian format
   - Zero for empty files

6. **Date (2 bytes)**
   - Bits 15-9: Year (0-127, +1980)
   - Bits 8-5: Month (1-12)
   - Bits 4-0: Day (1-31)

7. **Time (2 bytes)**
   - Bits 15-11: Hour (0-23)
   - Bits 10-5: Minute (0-59)
   - Bits 4-0: Second/2 (0-29)

8. **Reserved (11 bytes)**
   - Reserved for future use
   - Must be zero

## Recovery Mechanisms

## Build System

### Overview

The x16-PRos build system is designed to be cross-platform and flexible, supporting different sector sizes and disk configurations. The build process is managed by platform-specific scripts located in the `scripts/build` directory.

### Build Process

1. **Environment Setup**
   - Verifies required tools (NASM, cross-compiler)
   - Checks source file existence
   - Validates directory permissions
   - Cleans build artifacts if requested

2. **Assembly Phase**
   - Compiles boot sector to binary format
   - Compiles core modules to ELF64 format
   - Uses NASM with appropriate flags for each target

3. **Linking Phase**
   - Links core modules using x86_64-elf-ld
   - Creates final binary with proper memory layout
   - Handles symbol resolution and relocation

4. **Disk Image Creation**
   - Creates empty disk image with specified size
   - Writes boot sector to first sector
   - Writes core modules to sequential sectors
   - Writes file system to remaining sectors

### Core Module Layout

```ruby
Sector 1: Boot Sector
Sector 2: CPU Module
Sector 3: Loader Module
Sector 4: Services Module
Sector 5: Shell Module
Sector 6: Memory Module
Sector 7: Interrupt Module
Sector 8: Process Module
Sector 9: Kernel Module
```

### Build Configuration

The build system supports various configuration options:

1. **Disk Formats**
   - floppy360 (360KB, 720 sectors)
   - floppy720 (720KB, 1440 sectors)
   - floppy144 (1.44MB, 2880 sectors)
   - floppy288 (2.88MB, 5760 sectors)
   - hdd (10MB, 20480 sectors)

2. **Sector Sizes**
   - 256 bytes
   - 512 bytes (default)
   - 1024 bytes
   - 2048 bytes
   - 4096 bytes

3. **Build Options**
   - Clean build (removes all artifacts)
   - Verbose output
   - Test integration
   - Custom disk size

### Cross-Compilation Support

The build system supports cross-compilation for different platforms:

1. **Linux**
   - Uses native GCC toolchain
   - Supports both 32-bit and 64-bit systems

2. **macOS**
   - Uses x86_64-elf toolchain
   - Supports both Intel and Apple Silicon
   - Requires Homebrew for tool installation

3. **Windows**
   - Uses native NASM installation
   - May require Visual Studio Build Tools
   - Path environment variable must be properly set

### Error Handling

The build system includes comprehensive error handling:

1. **Tool Verification**
   - Checks for required tools
   - Validates tool versions
   - Provides installation instructions

2. **File Validation**
   - Verifies source file existence
   - Checks file permissions
   - Validates file formats

3. **Build Validation**
   - Verifies sector sizes
   - Validates disk formats
   - Checks build artifacts

4. **Test Integration**
   - Runs test suite after build
   - Reports test failures
   - Provides test coverage information

## Testing Architecture

The testing architecture is designed to ensure comprehensive test coverage and maintainable test code:

1. **Test Structure**
   - Standardized test format
   - Consistent error handling
   - Clear test organization
   - Reusable test components

2. **Test Categories**
   - Component-specific tests
   - Integration tests
   - System tests
   - Performance tests

3. **Test Execution**
   - Automated test running
   - Result collection
   - Error reporting
   - Cleanup management

4. **Test Framework**
   - Macro-based structure
   - Common test data
   - Standardized messages
   - Error handling patterns

## Future Architecture Plans

1. **Core System**
   - Virtual memory support
   - Process isolation
   - System call interface
   - Device management

2. **File System**
   - Journaling support
   - File compression
   - Encryption support
   - Cache optimization

3. **Testing Framework**
   - Performance measurement
   - Coverage tracking
   - Automated reporting
   - Stress testing
   - Test result visualization
   - Test case management
   - Continuous integration

### Build System

- Linter robustly enforces aggregator policy, detects build commands, and safely cleans up global directives (portable, safe for all filenames).

## Modular Assembly Guidelines (Terse)

- Only assemble implementation files (not aggregator files) as object files.
- Use `extern` for any cross-module symbols (functions/data).
- Never `%include` implementation files in tests or other modules; only include headers/macros.
- Aggregator files are for linking and should not be built as objects.
