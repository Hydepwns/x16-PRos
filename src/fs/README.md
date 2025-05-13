# x16-PRos File System

## Directory Entry Fields

| Field      | Size | Offset | Description                |
|------------|------|--------|----------------------------|
| Filename   | 8    | 0      | Name (space padded)        |
| Extension  | 3    | 8      | Extension (space padded)   |
| Attributes | 1    | 11     | Bitmask (see below)        |
| Reserved1  | 2    | 12     | Reserved                   |
| File Size  | 3    | 14     | 24-bit LE size             |
| Start Clus | 2    | 17     | First cluster (LE)         |
| Reserved2  | 2    | 19     | Reserved                   |
| Date       | 2    | 21     | Date (see below)           |
| Time       | 2    | 23     | Time (see below)           |
| Reserved3  | 7    | 25     | Reserved                   |

- **Filename/Extension:** Space padded, uppercase, 8.3 format.
- **Attributes:** 0x01=RO, 0x02=Hidden, 0x04=System, 0x08=Label, 0x10=Dir, 0x20=Archive.
- **File Size:** 24-bit LE.
- **Start Cluster:** 16-bit LE.
- **Date:** Bits 15–9: Month, 8–4: Day, 3–0: Year offset from 1980.
- **Time:** Bits 15–11: Hours, 10–5: Minutes, 4–0: Seconds/2.
- **Reserved:** Set to zero.
- **Free:** Filename[0]=0x00. **Deleted:** Filename[0]=0xE5.

# File System Overview

FAT-based file system: persistent storage, directory, file ops.

## Directory Structure

```text
fs/
  fat/    # FAT
  dir/    # Directory
  file/   # File ops
  ...
```
- See subdir READMEs for details.
- Full spec: [Canonical Spec][arch-fs].

## Where to Go Next

- [fat/README.md][fat-readme]
- [dir/README.md][dir-readme]
- [file/README.md][file-readme]
- [ARCHITECTURE.md][arch]
- [../lib/README.md][lib-readme]
- [../core/README.md][core-readme]
- [../README.md][src-readme]

## Purpose

- FAT-based file system
- Directory/file management
- Error detection/recovery
- Core system integration

## Interfaces & APIs

- Exposes FS commands/APIs for kernel/apps.
- Canonical interface: code comments, [lib/README.md][lib-readme].

## Error Handling

- Uses error codes in [error_codes.inc][error-codes] and [constants.inc][constants].
- Error propagation: [ARCHITECTURE.md#error-handling][arch-error-handling].

## Build & Integration

- Built/linked as part of main OS ([Build System][arch-build]).
- No special steps.

## References

- [fat/README.md][fat-readme]
- [dir/README.md][dir-readme]
- [file/README.md][file-readme]
- [ARCHITECTURE.md][arch]
- [../lib/README.md][lib-readme]
- [../core/README.md][core-readme]
- [../README.md][src-readme]

<!-- Reference-style links -->
[arch]: ../ARCHITECTURE.md
[arch-fs]: ../ARCHITECTURE.md#file-system
[arch-build]: ../ARCHITECTURE.md#build-system
[arch-error-handling]: ../ARCHITECTURE.md#error-handling
[src-readme]: ../README.md
[lib-readme]: ../lib/README.md
[core-readme]: ../core/README.md
[fat-readme]: fat/README.md
[dir-readme]: dir/README.md
[file-readme]: file/README.md
[error-codes]: ../lib/error_codes.inc
[constants]: ../lib/constants.inc
