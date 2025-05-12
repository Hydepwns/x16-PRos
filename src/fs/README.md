# x16-PRos File System Documentation

## Directory Entry Fields

| Field             | Size (bytes) | Offset | Description                |
|-------------------|--------------|--------|----------------------------|
| Filename          | 8            | 0      | Name of the file (padded with spaces) |
| Extension         | 3            | 8      | File extension (padded with spaces)   |
| Attributes        | 1            | 11     | File attributes (see below)           |
| Reserved1         | 2            | 12     | Reserved for future use               |
| File Size         | 3            | 14     | Size of the file in bytes (24-bit LE) |
| Starting Cluster  | 2            | 17     | First cluster of the file (LE)        |
| Reserved2         | 2            | 19     | Reserved for future use               |
| Date              | 2            | 21     | Creation/modification date (see below)|
| Time              | 2            | 23     | Creation/modification time (see below)|
| Reserved3         | 7            | 25     | Reserved for future use               |

---

### Field Encodings and Conventions

#### Filename & Extension

- Both are padded with spaces (ASCII 0x20) if shorter than their maximum length.
- Only uppercase letters, digits, and a limited set of symbols are allowed.
- The filename and extension together form the classic 8.3 format.

#### Attributes (1 byte)

Bitmask of file properties:

| Bit(s) | Value | Name             | Meaning                |
|--------|-------|------------------|------------------------|
| 0      | 0x01  | Read-only        | File is read-only      |
| 1      | 0x02  | Hidden           | File is hidden         |
| 2      | 0x04  | System           | System file            |
| 3      | 0x08  | Volume label     | Entry is a volume label|
| 4      | 0x10  | Directory        | Entry is a directory   |
| 5      | 0x20  | Archive          | File is archived       |
| 6-7    | 0xC0  | Invalid/unused   | Should be zero         |

#### File Size (3 bytes)

- 24-bit little-endian integer (low, mid, high byte).
- Maximum file size: 0xFFFFFF (16,777,215 bytes).

#### Starting Cluster (2 bytes)

- 16-bit little-endian value.
- Indicates the first cluster of the file's data.

#### Date (2 bytes)

- Encoded as follows:
  - Bits 15–9: Month (1–12)
  - Bits 8–4:  Day (1–31)
  - Bits 3–0:  Year offset from 1980 (0–15, so 1980–1995)
- Example: 0x4A21 = 0b0100101000100001
  - Month: 0b01001 = 9 (September)
  - Day:   0b00010 = 2
  - Year:  0b0001 = 1 (1981)

#### Time (2 bytes)

- Encoded as follows:
  - Bits 15–11: Hours (0–23)
  - Bits 10–5:  Minutes (0–59)
  - Bits 4–0:   Seconds/2 (0–29, representing 0–58 seconds in 2-second increments)
- Example: 0xA5C0 = 0b1010010111000000
  - Hours:   0b10100 = 20 (8 PM)
  - Minutes: 0b101110 = 46
  - Seconds: 0b00000 = 0 (0 seconds)

#### Reserved Fields

- Reserved1 (2 bytes), Reserved2 (2 bytes), Reserved3 (7 bytes):  
  Reserved for future use. Should be set to zero.

---

### Special Values

- **Free Entry:** First byte (filename) is 0x00.
- **Deleted Entry:** First byte (filename) is 0xE5.

<!-- Add further details on field encoding, conventions, and attribute flags here. -->

# File System Overview

This directory contains the file system implementation for x16-PRos, providing persistent storage, directory management, and file operations.

## Directory Structure

```bash
fs/
  fat/    # FAT table management
  dir/    # Directory management
  file/   # File operations
  ...     # Additional file system modules
```

- See each subdirectory's `README.md` for module details and coding standards.
- Deep technical details (directory entry fields, encodings, etc.) are documented in the [Canonical File System Spec](../ARCHITECTURE.md#file-system).

## Where to Go Next

- [fs/fat/README.md](fat/README.md) — FAT table management
- [fs/dir/README.md](dir/README.md) — Directory management
- [fs/file/README.md](file/README.md) — File operations
- [../ARCHITECTURE.md](../ARCHITECTURE.md) — Canonical file system spec and architecture
- [../lib/README.md](../lib/README.md) — Libraries and macros
- [../core/README.md](../core/README.md) — Core OS modules
- [../README.md](../README.md) — Source tree overview

## Purpose

The `fs/` directory contains the file system implementation for x16-PRos, providing persistent storage, directory management, and file operations.

## Key Responsibilities

- FAT-based file system implementation
- Directory and file management
- Error detection and recovery
- Integration with core system services

## Interfaces & APIs

- Exposes file system commands and APIs for use by the kernel and applications.
- Canonical interface definitions are documented in code comments and in [src/lib/README.md](../lib/README.md).

## Error Handling

- Uses the unified error code system defined in `src/lib/error_codes.inc` and `src/lib/constants.inc`.
- Error propagation follows the conventions described in [ARCHITECTURE.md#error-handling](../../ARCHITECTURE.md#error-handling).

## Build & Integration

- Assembled and linked as part of the main OS build process (see [Build System](../../ARCHITECTURE.md#build-system)).
- No special build steps beyond standard modular assembly and linking.

## References & Further Reading

- [Canonical File System Spec](../ARCHITECTURE.md#file-system)
- [src/README.md](../README.md)
- [src/lib/README.md](../lib/README.md)
- [src/core/README.md](../core/README.md)
