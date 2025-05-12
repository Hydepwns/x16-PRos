# x16-PRos Core System Overview

This directory contains the essential components of the x16-PRos operating system, responsible for low-level system management and core OS services.

## Directory Structure

```bash
core/
  boot.asm      # Boot sector and system initialization
  kernel.asm    # Main kernel, shell, and core services
  interrupts/   # Interrupt handling code
  memory/       # Memory management routines
  process/      # Process management and scheduling
  services/     # System services and CPU utilities
  shell/        # Shell and command interpreter
```

- See each subdirectory's `README.md` for module details and coding standards.

## Where to Go Next

- [core/interrupts/README.md](interrupts/README.md) — Interrupt handling
- [core/memory/README.md](memory/README.md) — Memory management
- [core/process/README.md](process/README.md) — Process management
- [core/services/README.md](services/README.md) — System services
- [core/shell/README.md](shell/README.md) — Shell and command interpreter
- [../../ARCHITECTURE.md](../../ARCHITECTURE.md) — System architecture and build process
- [../lib/README.md](../../lib/README.md) — Libraries and macros
- [../README.md](../README.md) — Source tree overview

## Key Responsibilities

- Bootstrapping and system initialization
- Kernel and shell implementation
- Memory management
- Process management and scheduling
- Interrupt handling
- System services and CPU utilities

## Interfaces & APIs

- Exposes system call interfaces for applications and file system modules.
- Entry points and calling conventions are documented in code comments and referenced in [src/lib/README.md](../../lib/README.md).

## Error Handling

- Uses the unified error code system defined in `src/lib/error_codes.inc` and `src/lib/constants.inc`.
- Error propagation follows the conventions described in [ARCHITECTURE.md#error-handling](../../ARCHITECTURE.md#error-handling).

## Build & Integration

- Assembled and linked as part of the main OS build process (see [Build System](../../ARCHITECTURE.md#build-system)).
- No special build steps beyond standard modular assembly and linking.

## References & Further Reading

- [ARCHITECTURE.md](../../ARCHITECTURE.md)
- [src/README.md](../README.md)
- [src/lib/README.md](../../lib/README.md)
