# x16-PRos Library

Common utility functions and macros for the OS. All functions are size-optimized and preserve registers.

## Files

### `constants.inc`

- All global constants and macros. Add new constants here only.
- `%include` at the top of every asm file.
- For NASM `-f bin`, use `%ifidn __OUTPUT_FORMAT__, "bin"` for `ORG`. No `section` directives.

### `error_codes.inc`

- System-wide error codes for consistent reporting.

### `io.inc`

- String printing (various colors), input, screen control.
- All functions preserve ax, cx, dx, si, di.

Example:

```nasm
mov si, message
call print_string_green
```

### `utils.inc`

- String compare (case-insensitive), number/string conversion, cursor control.
- All functions preserve ax, cx, dx, si, di.

Example:

```nasm
mov si, str1
mov di, str2
call compare_strings
```

### `ui.inc`

- Screen layout, window/menu drawing, input validation.
- All functions preserve ax, cx, dx, si, di.

### `memory.inc`

- Buffer alloc, copy, clear, validate.
- All functions preserve ax, cx, dx, si, di.

### `app.inc`

- Common app macros and functions. For app/OS interaction. Preserves ax, cx, dx, si, di.

## Register Preservation

All library functions preserve: ax, cx, dx, si, di.

## Size Optimizations

- Consolidated print functions
- Efficient string ops
- Optimized number conversions
- Minimal register use
- Smart branching

## Adding Functions

1. Add to the right `.inc` file
2. Document: purpose, params, return, registers
3. Follow style
4. Test
5. Preserve registers
6. Optimize for size

## Error Handling

- ZF for string compare
- AX for numeric returns
- DI for string buffer pos
- CX for string lengths

# Library Overview

*See each `.inc` file for details.*

## Purpose

- Shared macros, constants, and utilities for all modules.

## Key Responsibilities

- Centralized constants/macros
- Common string/utility functions
- I/O and UI helpers
- Memory routines
- App support

## Directory Structure

```text
lib/
  constants.inc   # Constants/macros
  error_codes.inc # Error codes
  io.inc          # I/O
  utils.inc       # Utilities
  ui.inc          # UI helpers
  memory.inc      # Memory
  app.inc         # App support
  ...
```

## Interfaces & APIs

- Macros and routines for all system/app code.
- See each `.inc` for usage.

## Error Handling

- Error codes: [error_codes.inc][error-codes], [constants.inc][constants].
- Conventions: [ARCHITECTURE.md#error-handling][arch-error-handling].

## Build & Integration

- Include relevant `.inc` at top of each source.
- No special build steps.
- For flat binary: no `section` directives, use conditional `ORG`.

## References

- [ARCHITECTURE.md][arch]
- [src/README.md][src-readme]
- [core/README.md][core-readme]
- [fs/README.md][fs-readme]
- [error_codes.inc][error-codes]
- [constants.inc][constants]

<!-- Reference-style links -->
[arch]: ../../ARCHITECTURE.md
[arch-error-handling]: ../../ARCHITECTURE.md#error-handling
[src-readme]: ../README.md
[core-readme]: ../core/README.md
[fs-readme]: ../fs/README.md
[error-codes]: error_codes.inc
[constants]: constants.inc
