# x16-PRos Core System

Core OS components: low-level system management and services.

## Directory Structure

```text
core/
  boot.asm      # Boot/init
  kernel.asm    # Kernel, shell, core
  interrupts/   # Interrupts
  memory/       # Memory mgmt
  process/      # Process mgmt
  services/     # System services
  shell/        # Shell/commands
```
- See subdir READMEs for details.

## Where to Go Next

- [interrupts/README.md][int-readme]
- [memory/README.md][mem-readme]
- [process/README.md][proc-readme]
- [services/README.md][svc-readme]
- [shell/README.md][shell-readme]
- [ARCHITECTURE.md][arch]
- [../../lib/README.md][lib-readme]
- [../README.md][src-readme]

## Key Responsibilities

- Boot/init
- Kernel/shell
- Memory mgmt
- Process mgmt
- Interrupts
- System services

## Interfaces & APIs

- Exposes syscall interfaces for apps and FS.
- Entry points/calling conventions: code comments, [lib/README.md][lib-readme].

## Error Handling

- Uses error codes in [error_codes.inc][error-codes] and [constants.inc][constants].
- Error propagation: [ARCHITECTURE.md#error-handling][arch-error-handling].

## Build & Integration

- Built/linked as part of main OS ([Build System][arch-build]).
- No special steps.

## References

- [ARCHITECTURE.md][arch]
- [src/README.md][src-readme]
- [../../lib/README.md][lib-readme]

<!-- Reference-style links -->
[arch]: ../../ARCHITECTURE.md
[arch-build]: ../../ARCHITECTURE.md#build-system
[arch-error-handling]: ../../ARCHITECTURE.md#error-handling
[src-readme]: ../README.md
[lib-readme]: ../../lib/README.md
[int-readme]: interrupts/README.md
[mem-readme]: memory/README.md
[proc-readme]: process/README.md
[svc-readme]: services/README.md
[shell-readme]: shell/README.md
[error-codes]: ../../lib/error_codes.inc
[constants]: ../../lib/constants.inc
