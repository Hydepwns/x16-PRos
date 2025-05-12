%ifndef TEST_DATA_INCLUDED
%define TEST_DATA_INCLUDED

; Common test data
section .data
test_data: db "Test data"
test_data_len equ $ - test_data
test_data_size equ test_data_len

test_data2: db "Updated test data"
test_data2_size equ $ - test_data2

section .bss
test_buffer: resb 256

; Common test filenames
test_filename: db "TEST    TXT", 0
test_filename2: db "TEST2   TXT", 0
test_filename3: db "TEST3   TXT", 0
test_filename4: db "TEST4   TXT", 0
test_filename5: db "TEST5   TXT", 0

%endif ; TEST_DATA_INCLUDED 