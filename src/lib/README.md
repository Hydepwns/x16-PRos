# x16-PRos Library

This directory contains common utility functions and macros used throughout the operating system. All functions are optimized for size and performance while maintaining register preservation.

## Files

### `constants.inc`

Centralized file for all global constants and macros used throughout x16-PRos. All new constants should be added here, and duplication in other files should be avoided.

**Include Order Convention:**
All assembly files should place `%include` statements (especially for `constants.inc`) at the very top, before any use of constants or ORG directives.

For NASM flat binary output (`-f bin`), do NOT use `section .text` or `section .data`. Use `%ifidn __OUTPUT_FORMAT__, "bin"` to conditionally set `ORG`.

### `error_codes.inc`

Definitions for system-wide error codes. Used for consistent error reporting across modules.

### `io.inc`

Basic input/output operations with register preservation:

- String printing with different colors (white, green, cyan, red)
- Newline printing
- String input with backspace support
- Screen manipulation
- All functions preserve registers (ax, cx, dx, si, di)

Example usage:

```nasm
mov si, message    ; Load string address
call print_string_green  ; Print in green
```

### `utils.inc`

General utility functions with register preservation:

- Case-insensitive string comparison
- Number to string conversion (up to 6 digits)
- String to number conversion
- Cursor position control
- All functions preserve registers (ax, cx, dx, si, di)

Example usage:

```nasm
mov si, str1      ; First string
mov di, str2      ; Second string
call compare_strings  ; Compare strings (case-insensitive)
```

### `ui.inc`

User interface operations:

- Screen layout management
- Window drawing
- Menu handling
- Input validation
- All functions preserve registers (ax, cx, dx, si, di)

### `memory.inc`

Memory management operations:

- Buffer allocation
- Memory copying
- Memory clearing
- Memory validation
- All functions preserve registers (ax, cx, dx, si, di)

### `app.inc`

Provides common functions, macros, and constants tailored for application development within x16-PRos. Facilitates interaction with OS services and standard library features. Registers ax, cx, dx, si, di are preserved by its functions.

## Register Preservation

All library functions preserve the following registers:

- ax: General purpose
- cx: Counter
- dx: Data
- si: Source index
- di: Destination index

## Size Optimizations

The library has been optimized for size:

- Consolidated print functions
- Efficient string operations
- Optimized number conversions
- Minimal register usage
- Smart branch instructions

## Adding New Functions

When adding new utility functions:

1. Place them in the appropriate include file
2. Add proper documentation including:
   - Function purpose
   - Input parameters
   - Return values
   - Register preservation
3. Follow existing coding style
4. Test thoroughly
5. Ensure register preservation
6. Optimize for size

## Error Handling

Functions use the following conventions:

- ZF (Zero Flag) for string comparison results
- AX register for numeric returns
- DI register for string buffer positions
- CX register for string lengths

# Library Overview

*For detailed macros, constants, and function documentation, see the canonical include files in this directory.*

## Purpose

The `lib/` directory provides shared macros, constants, and utility functions for all x16-PRos modules, supporting code reuse and consistency.

## Key Responsibilities

- Centralized global constants and macros
- Common utility and string functions
- Input/output and user interface helpers
- Memory management routines
- Application development support

## Directory Structure

```bash
lib/
  constants.inc   # Global constants and macros
  error_codes.inc # System-wide error codes
  io.inc          # Input/output functions
  utils.inc       # General utilities
  ui.inc          # User interface helpers
  memory.inc      # Memory management
  app.inc         # Application support macros
  ...             # Additional shared includes
```

For detailed documentation, see comments in each `.inc` file.

## Interfaces & APIs

- Provides macros and callable routines for use by all system and application code.
- Canonical interface and usage documentation is in the respective `.inc` files.

## Error Handling

- Defines standard error codes in `error_codes.inc` and `constants.inc`.
- Error handling conventions are described in [ARCHITECTURE.md#error-handling](../../ARCHITECTURE.md#error-handling).

## Build & Integration

- All modules include relevant `.inc` files from `lib/` at the top of each source file.
- No special build steps; included as part of standard assembly and linking.

For flat binary output, do NOT use section directives. Use conditional `ORG` as above.

## References & Further Reading

- [ARCHITECTURE.md](../../ARCHITECTURE.md)
- [src/README.md](../README.md)
- [src/core/README.md](../core/README.md)
- [src/fs/README.md](../fs/README.md)
