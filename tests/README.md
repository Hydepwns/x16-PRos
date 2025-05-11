# x16-PRos Test Suite

This directory contains the test suite for the x16-PRos operating system, organized to match the source code structure.

## Directory Structure

### `/core`

Tests for core system components:

- `/boot` - Boot sector and initialization tests
- `/kernel` - Kernel functionality and system services tests

### `/fs`

File system component tests:

- `/fat` - FAT operations and integrity tests
- `/dir` - Directory operations and consistency tests
- `/file` - File operations and I/O tests
- `/init` - File system initialization and sector size validation tests

### `/apps`

Application-specific tests:

- `/calc` - Calculator functionality tests
- `/snake` - Snake game tests
- `/brainf` - Brainfuck interpreter tests
- `/barchart` - Bar chart visualization tests
- `/clock` - Clock application tests
- `/write` - Text editor tests

## Test Categories

### Core System Tests

- Boot sector validation
- Kernel functionality
- System services
- Error handling

### File System Tests

- FAT operations
- Directory operations
- File operations
- Error recovery

### Application Tests

- Functionality verification
- Error handling
- User interface
- Performance metrics

## Running Tests

Each test directory contains its own test runner and test cases. Tests should be run from the root of the project:

```bash
# Run all tests
./run_tests.sh

# Run specific test category
./run_tests.sh core
./run_tests.sh fs
./run_tests.sh apps

# Run specific component tests
./run_tests.sh fs/init
./run_tests.sh fs/fat
```

## Test Guidelines

1. Each test should be self-contained and independent
2. Tests should clean up after themselves
3. Error cases should be properly tested
4. Performance tests should be in separate suites
5. All tests should be documented

## Test Code Conventions

- All test assembly files should use `src/lib/constants.inc` for shared constants.
- Place all `%include` statements at the top of each file, before any use of constants or ORG directives.
