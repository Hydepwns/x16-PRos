%ifndef TEST_DATA_INCLUDED
%define TEST_DATA_INCLUDED

; Common test data
section .data
test_data: db "Test data"
test_data_len equ $ - test_data

; Common test filenames
test_filename: db "TEST    TXT", 0
test_filename2: db "TEST2   TXT", 0
test_filename3: db "TEST3   TXT", 0
test_filename4: db "TEST4   TXT", 0
test_filename5: db "TEST5   TXT", 0

%endif ; TEST_DATA_INCLUDED 