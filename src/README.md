# x16-PRos Source Code

## Structure

```text
src/
  core/   # Kernel, memory, process, interrupts, shell, services
  fs/     # FAT, directory, file ops, recovery
  lib/    # Shared libs, macros, error codes, constants
  apps/   # User/system apps
```

### core/

- `boot.asm`: Boot sector, init
- `kernel.asm`: Kernel, shell, services

### apps/

- `calc.asm`: Calculator
- `snake.asm`: Snake game
- `brainf.asm`: Brainfuck
- `barchart.asm`: Bar chart
- `clock.asm`: Clock
- `write.asm`: Text editor

### fs/

- File system ops, dir, file, recovery

### lib/

- `constants.inc`: Global constants/macros
- Place `%include` at top, before constants/ORG

## Build

- Boot sector: `/core/boot.asm` → sector 0
- FS: `/fs/` + `/lib/` → ELF objects, linked to `fs.bin` (sector 1+)
- Kernel: `/core/kernel.asm` → `kernel.bin` (sector 10+)
- Apps: `/apps/` → raw binaries

- For NASM `-f bin`: do NOT use `section .text`/`.data`. Use `%ifidn __OUTPUT_FORMAT__, "bin"` for `ORG`.

## Dev Guidelines

- Core: minimal, essential
- Apps: self-contained, use syscalls
- FS: separate modules, ELF objects, use `GLOBAL`/`EXTERN`
- Only needed modules linked per binary
- No test code in production

## Next

- [core/README.md][core-readme]: Core modules
- [fs/README.md][fs-readme]: FS modules
- [lib/README.md][lib-readme]: Libs/macros
- [apps/README.md][apps-readme]: Apps
- [../ARCHITECTURE.md][arch]: System/build
- [../scripts/README.md][scripts-readme]: Build scripts

## References

- [core/README.md][core-readme]
- [fs/README.md][fs-readme]
- [lib/README.md][lib-readme]
- [apps/README.md][apps-readme]
- [../ARCHITECTURE.md][arch]
- [../scripts/README.md][scripts-readme]

[core-readme]: core/README.md
[fs-readme]: fs/README.md
[lib-readme]: lib/README.md
[apps-readme]: apps/README.md
[arch]: ../ARCHITECTURE.md
[scripts-readme]: ../scripts/README.md

## Disk Layout

- 0: Boot
- 1: FS
- 2–5: FAT
- 6–9: Root dir
- 10+: Kernel, apps
