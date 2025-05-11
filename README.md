<div align="center">

  <h1>x16-PRos operating system</h1>

  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#)
  [![Version](https://img.shields.io/badge/version-0.2.6-blue.svg)](#)
  [![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](#)

  <img src="https://github.com/PRoX2011/x16-PRos/raw/main/preview.gif" width="65%">
  
  **x16-PRos**
 is a minimalistic 16-bit operating system written in NASM for x86 architecture. It supports a text interface, loading programs from disk, and basic
 system functions such as displaying CPU information, time, and date.

 <img src="https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/1.png" width="75%">

 ---

<a href="https://x16-pros.netlify.app/">
  <img src="https://img.shields.io/badge/x16%20PRos-web%20site-blue.svg?style=for-the-badge&logoWidth=40&labelWidth=100&fontSize=20" height="50">
</a>
  
</div>

---

## 📋 Supported commands in x16 PRos terminal

- **help** display list of commands
- **info** brief system information
- **cls** clear screen
- **shut** shut down the system
- **reboot** restart the system
- **date** display date
- **time** show time (UTC)
- **CPU** CPU information
- **load** load program from disk sector (0000x800h)
- **write** start text editor program
- **brainf** start brainfuck interpreter
- **barchart** start bar chart visualization
- **snake** start Snake game
- **calc** start calculator program
- **clock** start clock/time application
- **fs** file system operations (x16FS-Lite -- 1.44MB floppy disk image)

---

## 📦 x16 PRos Software Package

Basic x16 PRos software package includes:

<div align="center">
  <table>
    <tr>
      <td align="center">
        <strong>Notepad</strong><br>
        <em>for writing and saving texts to disk sectors</em><br>
        <img src="https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/3.png" width="85%">
      </td>
      <td align="center">
        <strong>Brainf IDE</strong><br>
        <em>for working with Brainf*ck language</em><br>
        <img src="https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/4.png" width="85%">
      </td>
    </tr>
    <tr>
      <td align="center">
        <strong>Barchart</strong><br>
        <em>program for creating simple diagrams</em><br>
        <img src="https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/5.png" width="85%">
      </td>
      <td align="center">
        <strong>Snake</strong><br>
        <em>classic Snake game</em><br>
        <img src="https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/6.png" width="95%">
      </td>
    </tr>
    <tr>
      <td colspan="2" align="center">
        <strong>Calc</strong><br>
        <em>help with simple mathematical calculations</em><br>
        <img src="https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/7.png" width="57.5%">
      </td>
    </tr>
  </table>
</div>

---
  
## 🛠 Adding programs

x16 PRos includes a small set of built-in programs. You can add your own program to the system image and then run it using the load command, specifying the disk sector number where you wrote the program as an argument.

Here's how you can add a program:

```bash
dd if=YourProgram.bin of=disk_img/x16pros.img bs=512 seek=DiskSector conv=notrunc
```

You can read more about the software development process for x16-PRos on the project website:
[x16-PRos web site](https://x16-pros.netlify.app/)

---

## 🛠 Compilation

First, clone the repository:

```bash
git clone https://github.com/PRoX2011/x16-PRos.git
cd x16-PRos
```

### Prerequisites

#### Linux

```bash
sudo apt install nasm qemu-system-x86_64
```

#### macOS

```bash
brew install nasm x86_64-elf-gcc qemu
```

#### Windows

```powershell
winget install nasm
winget install qemu
```

### Building

The build scripts are located in the `scripts/build` directory. Choose the appropriate script for your platform:

#### Linux

```bash
chmod +x scripts/build/build-linux.sh
./scripts/build/build-linux.sh
```

#### macOS

```bash
chmod +x scripts/build/build-macos.sh
./scripts/build/build-macos.sh
```

#### Windows

```batch
scripts\build\build-windows.bat
```

### Build Options

The build scripts support several options:

- `-s, --size SIZE`: Specify disk size in sectors (default: 2880 for 1.44MB)
- `-z, --sector SIZE`: Specify sector size in bytes (default: 512)
- `-c, --clean`: Clean build artifacts before building
- `-h, --help`: Show help message

Example:

```bash
# Build with 1024-byte sectors
./scripts/build/build-macos.sh -z 1024

# Build with custom disk size and clean build
./scripts/build/build-macos.sh -s 4096 -c
```

### macOS Dependencies

- You must install GNU binutils via Homebrew for the build system to work:

  ```sh
  brew install binutils
  ```

- Homebrew installs GNU tools with a `g` prefix (e.g., `gobjcopy`).
- Ensure your build scripts use `gobjcopy` instead of `objcopy` on macOS.

---

## 🚀 Launchng

To launch x16 PRos, use emulators such as **QEMU**,**Bochs** or online emulator like [v86](https://copy.sh/v86/).
Example command for **QEMU**:

```bash
qemu-system-x86_64 -fda x16-PRos-disk-image.img
```

You can also try running x16-PRos on a **real PC** (preferably with BIOS, not UEFI)

If you still want to run x16-PRos on a UEFI PC, you will need to enable "CSM support" in your BIOS. It may be called slightly differently.

---

## ⚙ Running x16-PRos on windows

### Installation Steps

1. Open PowerShell as Administrator and run:

```powershell
winget install nasm
winget install qemu
```

2. Add NASM and QEMU to System Path by running:

```powershell
setx PATH "%PATH%;C:\Program Files\NASM;C:\Program Files\qemu"
```

3. Reboot your PC for the PATH changes to take effect.

4. Run the build script:

```batch
build-windows.bat
```

**Note**: Make sure to restart your terminal or IDE after modifying the PATH variable.

### Troubleshooting

- If commands are not recognized, verify the installation paths
- Ensure PowerShell was run as Administrator during installation
- Check if PATH was updated correctly by running `echo %PATH%`

---

## 👨‍💻 x16-PRos Developers

- **PRoX (Faddey Kabanov)** lead developer. Creator of the kernel, command interpreter, writer, brainf, snake programs.
- **Loxsete** developer of the barchart program.
- **Saeta** developer of the calculation logic in the program "Calculator".

---

## 🤝 Contribute to the Project

If you want to contribute to the development of x16 PRos, you can:

- Report bugs via GitHub Issues.
- Suggest improvements or new features on GitHub.
- Help with documentation by emailing us at <prox.dev.code@gmail.com>.
- Develop new programs for the system.

The project is distributed under the **MIT** license. You are free to use, modify and distribute the code.

---

<a href="https://www.donationalerts.com/r/proxdev">
  <img src="https://img.shields.io/badge/Support%20me-blue.svg?style=for-the-badge&logoWidth=40&labelWidth=100&fontSize=20" height="35">
</a>

## 💾 x16FS-Lite File System

x16FS-Lite supports configurable sector sizes (256-4096 bytes) with the following requirements:

- Must be a power of 2
- Must be aligned to 256 bytes
- Default size is 512 bytes

### File System Layout

```ruby
+------------------+
|    Boot Sector   | 256 bytes
+------------------+
|       FAT        | 4 sectors
+------------------+
|  Root Directory  | 4 sectors
+------------------+
|    Data Area     | Remaining sectors
+------------------+
```

### Memory Map

```bash
0x7C00 +------------------+
       |    Boot Sector   |
0x7DFF +------------------+
0x8000 |    FAT Buffer    |
0x87FF +------------------+
0x8800 | Directory Buffer |
0x8FFF +------------------+
0x9000 |   File Buffer    |
0x9FFF +------------------+
0xA000 |      Stack       |
0xAFFF +------------------+
0xB000 | Error Buffer     |
0xB7FF +------------------+
0xB800 | Recovery Buffer  |
0xBFFF +------------------+
```

### Basic Commands

```bash
fs init      # Initialize file system
fs create    # Create new file
fs read      # Read file contents
fs write     # Write to file
fs delete    # Delete file
fs list      # List directory
fs info      # Show file system info
```

## Build System

The x16-PRos build system is designed to be cross-platform and flexible. It supports:

- Multiple disk formats (floppy360, floppy720, floppy144, floppy288, hdd)
- Configurable sector sizes (256-4096 bytes)
- Cross-compilation for Linux, macOS, and Windows
- Comprehensive error handling and validation
- Test integration
- Build artifact management

For detailed information about the build system, see:

- [Build System Documentation](docs/build-system.md)
- [Build System Architecture](ARCHITECTURE.md#build-system-architecture)
