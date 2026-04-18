section .payload progbits alloc exec write
global factor
; uint factor(uint n)
; return n!
factor:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    esi
    push    edi

    mov     eax, 1
    mov     ecx, 2
    mov     ebx, dword [ebp + 8]
.loop:
    cmp     ecx, ebx
    ja      .next

    mul     ecx

    inc     ecx
    jmp     .loop

.next:
    pop     edi
    pop     esi
    pop     ebx

    pop     ebp
    ret

global fibb
; uint fibb(uint n)
; return n-th fibonacci number
fibb:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    esi
    push    edi

    mov     ebx, dword [ebp + 8]
    mov     eax, 0
    mov     edx, 1
    mov     ecx, 0
.loop:
    cmp     ecx, ebx
    jae     .next

    mov     esi, edx
    add     edx, eax
    mov     eax, esi

    inc     ecx
    jmp     .loop

.next:
    pop     edi
    pop     esi
    pop     ebx

    pop     ebp
    ret


section .status progbits alloc write
    mode db 0

section .data
    proc_self_exe db "/proc/self/exe", 0
    mode0_ok db "Packed successfully!", 0
    mode0_err db "Error occurred while packing", 0
    mode1_ok db "Dynamically unpacked and executed successfully!", 0
    mode1_err db "Error occurred while unpacking or executing", 0

global main
section .text
extern io_print_udec, io_print_string, io_newline
main:
    mov     ebp, esp

    mov     al, byte [mode]
    test    al, al
    jz      .mode0

.mode1:
    call    target_exec
    test    eax, eax
    jz      .print_ok1
    mov     eax, mode1_err
    call    io_print_string
    call    io_newline
    jmp     .quit
.print_ok1:
    mov     eax, mode1_ok
    call    io_print_string
    call    io_newline
    jmp     .quit
.mode0:
    call    first_exec
    test    eax, eax
    jz      .print_ok0
    mov     eax, mode0_err
    call    io_print_string
    call    io_newline
    jmp     .quit
.print_ok0:
    mov     eax, mode0_ok
    call    io_print_string
    call    io_newline

.quit:
    xor     eax, eax
    ret 

global targetExec
target_exec:
    ret

global firstExec
first_exec:
    ret

global pack
; void xor(char* buf, size_t size, const char* key, size_t key_size)
; XOR cipher
pack:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    esi
    push    edi

    mov     esi, dword [ebp + 8] ; buf
    mov     ecx, dword [ebp + 12] ; size
    mov     edi, dword [ebp + 16] ; key
    mov     edx, dword [ebp + 20] ; key_size
    mov     ebx, 0 ; buf offset
    mov     eax, 0 ; key offset
.loop:
    cmp     ebx, ecx
    jae     .next

    cmp     eax, edx ; assuming that key_size might be smaller than size
    jb      .skip
    mov     eax, 0
.skip:

    push    ecx
    mov     cl, byte [edi + eax]
    xor     byte [esi + ebx], cl
    pop     ecx

    inc     ebx
    inc     eax
    jmp     .loop

.next:
    pop     edi
    pop     esi
    pop     ebx

    pop     ebp
    ret