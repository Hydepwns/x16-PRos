; File Operations Header (src/fs/file.inc)
%ifndef FILE_INC_INCLUDED
%define FILE_INC_INCLUDED

[BITS 16]

extern file_init
extern file_create
extern file_delete
extern file_read
extern file_write
extern file_exists
extern file_size
extern file_get_size
extern recover_file_size

%endif ; FILE_INC_INCLUDED 