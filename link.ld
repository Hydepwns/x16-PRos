OUTPUT_FORMAT("binary")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
    . = 0x7C00;
    
    /* Boot sector code */
    .boot : {
        *(.boot)
    }
    
    /* IO library */
    . = 0x8000;
    .io : {
        io.o(.text)
        io.o(.data)
        io.o(.bss)
    }
    
    /* File system components */
    . = 0x9000;
    .text : {
        *(.text)
    }
    .data : {
        *(.data)
    }
    .bss : {
        *(.bss)
    }
} 