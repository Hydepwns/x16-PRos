[BITS 16]

; Include constants
%include "src/lib/constants.inc"

; External error handling functions
extern set_error
extern get_error
extern print_error

; Include directory modules
%include "src/fs/dir/core.asm"
%include "src/fs/dir/list.asm"
%include "src/fs/dir/helpers.asm"

; Export directory functions
