@echo off

set OUTDIR=release

where nasm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo NASM is not found in PATH
    echo Please install NASM and add it to your PATH
    pause
    exit /b 1
)

where ld >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ld.exe (ELF linker, e.g., from MinGW/x86_64-elf-gcc) is not found in PATH
    echo Please install an appropriate ELF linker and add it to your PATH
    pause
    exit /b 1
)

where qemu-system-i386 >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo QEMU is not found in PATH
    echo Please install QEMU and add it to your PATH
    pause
    exit /b 1
)

if exist %OUTDIR%\img rmdir /s /q %OUTDIR%\img
if exist %OUTDIR%\bin rmdir /s /q %OUTDIR%\bin
mkdir %OUTDIR%\bin
mkdir %OUTDIR%\img
if not exist %OUTDIR%\bin\obj mkdir %OUTDIR%\bin\obj
if not exist %OUTDIR%\log mkdir %OUTDIR%\log

echo Compiling the bootloader...
nasm -f bin src\core\boot.asm -o %OUTDIR%\bin\boot.bin

echo Compiling the kernel and programs...
REM === Modular kernel build: assemble all core modules as ELF objects and link into kernel.bin ===
set CORE_MODULES=services/cpu services/loader services/services shell/shell memory/memory interrupts/interrupts process/process kernel
set KERNEL_OBJS=
for %%M in (%CORE_MODULES%) do (
    set NAME=%%~nxM
    nasm -f elf32 src\core\%%M.asm -o %OUTDIR%\bin\obj\%%NAME%%.o
    set KERNEL_OBJS=!KERNEL_OBJS! %OUTDIR%\bin\obj\%%NAME%%.o
)
REM Link all core modules into a single kernel.bin
ld -melf_i386 -T src\link.ld -o %OUTDIR%\bin\kernel.bin %KERNEL_OBJS% %OUTDIR%\bin\obj\io.o
REM Write kernel.bin to the disk image at sector 9 (after boot and fs)
powershell -Command "$stream = [System.IO.File]::OpenWrite('release\\img\\x16pros.img'); $bytes = [System.IO.File]::ReadAllBytes('release\\bin\\kernel.bin'); $stream.Position = 512 * 9; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
REM Remove old per-module .bin creation and write steps for core modules
REM === End modular kernel build section ===

nasm -f bin -Isrc\lib\ src\core\kernel.asm -o %OUTDIR%\bin\kernel.bin
nasm -f bin -Isrc\lib\ src\apps\write.asm -o %OUTDIR%\bin\write.bin
nasm -f bin -Isrc\lib\ src\apps\brainf.asm -o %OUTDIR%\bin\brainf.bin
nasm -f bin -Isrc\lib\ src\apps\barchart.asm -o %OUTDIR%\bin\barchart.bin
nasm -f bin -Isrc\lib\ src\apps\snake.asm -o %OUTDIR%\bin\snake.bin
nasm -f bin -Isrc\lib\ src\apps\calc.asm -o %OUTDIR%\bin\calc.bin
REM nasm -f bin src\clock.asm -o bin\clock.bin (clock.asm seems to be missing from src/apps, was in original .bat but not in linux .sh or src structure)

echo Compiling file system components to ELF objects...
nasm -f elf32 -Isrc\lib\ src\lib\io.asm -o %OUTDIR%\bin\obj\io.o
nasm -f elf32 -Isrc\fs\ -Isrc\lib\ src\fs\errors.asm -o %OUTDIR%\bin\obj\errors.o
nasm -f elf32 -Isrc\fs\ -Isrc\lib\ src\fs\fat.asm -o %OUTDIR%\bin\obj\fat.o
nasm -f elf32 -Isrc\fs\ -Isrc\lib\ src\fs\file.asm -o %OUTDIR%\bin\obj\file.o
nasm -f elf32 -Isrc\fs\ -Isrc\lib\ src\fs\recovery.asm -o %OUTDIR%\bin\obj\recovery.o

echo Linking file system components into fs.bin...
ld -melf_i386 -T src\link.ld -o %OUTDIR%\bin\fs.bin %OUTDIR%\bin\obj\io.o %OUTDIR%\bin\obj\errors.o %OUTDIR%\bin\obj\fat.o %OUTDIR%\bin\obj\file.o %OUTDIR%\bin\obj\recovery.o

echo Creating a disk image (1.44MB)...
fsutil file createnew %OUTDIR%\img\x16pros.img 1474560

echo Writing components to disk image...
copy /b %OUTDIR%\bin\boot.bin %OUTDIR%\img\x16pros.img > nul

powershell -Command "$stream = [System.IO.File]::OpenWrite('release\\img\\x16pros.img'); $bytes = [System.IO.File]::ReadAllBytes('release\\bin\\fs.bin'); $stream.Position = 512 * 1; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$stream = [System.IO.File]::OpenWrite('release\\img\\x16pros.img'); $bytes = [System.IO.File]::ReadAllBytes('release\\bin\\write.bin'); $stream.Position = 512 * 10; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$stream = [System.IO.File]::OpenWrite('release\\img\\x16pros.img'); $bytes = [System.IO.File]::ReadAllBytes('release\\bin\\brainf.bin'); $stream.Position = 512 * 13; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$stream = [System.IO.File]::OpenWrite('release\\img\\x16pros.img'); $bytes = [System.IO.File]::ReadAllBytes('release\\bin\\barchart.bin'); $stream.Position = 512 * 16; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$stream = [System.IO.File]::OpenWrite('release\\img\\x16pros.img'); $bytes = [System.IO.File]::ReadAllBytes('release\\bin\\snake.bin'); $stream.Position = 512 * 18; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$stream = [System.IO.File]::OpenWrite('release\\img\\x16pros.img'); $bytes = [System.IO.File]::ReadAllBytes('release\\bin\\calc.bin'); $stream.Position = 512 * 20; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
REM powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('bin\clock.bin'); $stream = [System.IO.File]::OpenWrite('img\x16pros.img'); $stream.Position = 512 * 7; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"

echo Starting the emulator...
qemu-system-i386 -hda %OUTDIR%\img\x16pros.img

echo Done.