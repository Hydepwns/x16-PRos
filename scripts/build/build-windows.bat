@echo off

where nasm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo NASM is not found in PATH
    echo Please install NASM and add it to your PATH
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

if exist disk_img rmdir /s /q disk_img
if exist bin rmdir /s /q bin
mkdir bin
mkdir disk_img

echo Compiling the bootloader...
nasm -f bin src/boot.asm -o bin/boot.bin

echo Compiling the kernel and programs...
nasm -f bin src/kernel.asm -o bin/kernel.bin
nasm -f bin src/clock.asm -o bin/clock.bin
nasm -f bin src/write.asm -o bin/write.bin
nasm -f bin src/brainf.asm -o bin/brainf.bin
nasm -f bin src/barchart.asm -o bin/barchart.bin

echo Creating a disk image...
fsutil file createnew disk_img/x16pros.img 12800

copy /b bin\boot.bin disk_img\x16pros.img

powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('bin\kernel.bin'); $stream = [System.IO.File]::OpenWrite('disk_img\x16pros.img'); $stream.Position = 512; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('bin\clock.bin'); $stream = [System.IO.File]::OpenWrite('disk_img\x16pros.img'); $stream.Position = 512 * 7; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('bin\write.bin'); $stream = [System.IO.File]::OpenWrite('disk_img\x16pros.img'); $stream.Position = 512 * 8; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('bin\brainf.bin'); $stream = [System.IO.File]::OpenWrite('disk_img\x16pros.img'); $stream.Position = 512 * 11; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"
powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('bin\barchart.bin'); $stream = [System.IO.File]::OpenWrite('disk_img\x16pros.img'); $stream.Position = 512 * 14; $stream.Write($bytes, 0, $bytes.Length); $stream.Close()"

echo Starting the emulator...
qemu-system-i386 -hda disk_img/x16pros.img

echo Done.