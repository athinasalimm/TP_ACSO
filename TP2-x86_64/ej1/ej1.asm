%define NULL 0
%define TRUE 1
%define FALSE 0

section .text
    global string_proc_list_create_asm
    global string_proc_node_create_asm
    global string_proc_list_add_node_asm
    global string_proc_list_concat_asm

    extern malloc
    extern free
    extern strlen
    extern strcpy
    extern str_concat


string_proc_list_create_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     edi, 16
        call    malloc
        mov     QWORD [rbp-8], rax
        mov     rax, QWORD [rbp-8]
        mov     QWORD [rax], 0
        mov     rax, QWORD [rbp-8]
        mov     QWORD [rax+8], 0
        mov     rax, QWORD [rbp-8]
        mov     rsp, rbp
        pop     rbp
        ret   

string_proc_node_create_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 32
        mov     eax, edi
        mov     QWORD [rbp-32], rsi
        mov     BYTE  [rbp-20], al
        mov     edi, 32
        call    malloc
        mov     QWORD [rbp-8], rax
        mov     rax, QWORD [rbp-8]
        movzx   edx, BYTE [rbp-20]
        mov     BYTE  [rax+16], dl
        mov     rax, QWORD [rbp-8]
        mov     rdx, QWORD [rbp-32]
        mov     QWORD [rax+24], rdx
        mov     rax, QWORD [rbp-8]
        mov     QWORD [rax], 0
        mov     rax, QWORD [rbp-8]
        mov     QWORD [rax+8], 0
        mov     rax, QWORD [rbp-8]
        mov     rsp, rbp
        pop     rbp
        ret


string_proc_list_add_node_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 48
        mov     QWORD [rbp-24], rdi
        mov     eax, esi
        mov     QWORD [rbp-40], rdx
        mov     BYTE  [rbp-28], al
        movzx   eax, BYTE [rbp-28]
        mov     rdx, QWORD [rbp-40]
        mov     rsi, rdx
        mov     edi, eax
        call    string_proc_node_create_asm
        mov     QWORD [rbp-8], rax
        mov     rax, QWORD [rbp-24]
        mov     rax, QWORD [rax]
        test    rax, rax
        jne     nodo_existente
        mov     rax, QWORD [rbp-24]
        mov     rdx, QWORD [rbp-8]
        mov     QWORD [rax], rdx
        mov     rax, QWORD [rbp-24]
        mov     rdx, QWORD [rbp-8]
        mov     QWORD [rax+8], rdx
        jmp     fin_agregar
nodo_existente:
        mov     rax, QWORD [rbp-24]
        mov     rax, QWORD [rax+8]
        mov     rdx, QWORD [rbp-8]
        mov     QWORD [rax], rdx
        mov     rax, QWORD [rbp-24]
        mov     rdx, QWORD [rax+8]
        mov     rax, QWORD [rbp-8]
        mov     QWORD [rax+8], rdx
        mov     rax, QWORD [rbp-24]
        mov     rdx, QWORD [rbp-8]
        mov     QWORD [rax+8], rdx
fin_agregar:
        nop
        mov     rsp, rbp
        pop     rbp
        ret


string_proc_list_concat_asm:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 64
        mov     QWORD [rbp-40], rdi
        mov     eax, esi
        mov     QWORD [rbp-56], rdx
        mov     BYTE  [rbp-44], al
        mov     rax, QWORD [rbp-56]
        mov     rdi, rax
        call    strlen
        add     rax, 1
        mov     rdi, rax
        call    malloc
        mov     QWORD [rbp-8], rax
        mov     rdx, QWORD [rbp-56]
        mov     rax, QWORD [rbp-8]
        mov     rsi, rdx
        mov     rdi, rax
        call    strcpy
        mov     rax, QWORD [rbp-40]
        mov     rax, QWORD [rax]
        mov     QWORD [rbp-16], rax
        jmp     loop_fin
loop_cuerpo:
        mov     rax, QWORD [rbp-16]
        movzx   eax, BYTE [rax+16]
        cmp     BYTE [rbp-44], al
        jne     saltar_concat
        mov     rax, QWORD [rbp-16]
        mov     rdx, QWORD [rax+24]
        mov     rax, QWORD [rbp-8]
        mov     rsi, rdx
        mov     rdi, rax
        call    str_concat
        mov     QWORD [rbp-24], rax
        mov     rax, QWORD [rbp-8]
        mov     rdi, rax
        call    free
        mov     rax, QWORD [rbp-24]
        mov     QWORD [rbp-8], rax
saltar_concat:
        mov     rax, QWORD [rbp-16]
        mov     rax, QWORD [rax]
        mov     QWORD [rbp-16], rax
loop_fin:
        cmp     QWORD [rbp-16], 0
        jne     loop_cuerpo
        movzx   ecx, BYTE [rbp-44]
        mov     rdx, QWORD [rbp-8]
        mov     rax, QWORD [rbp-40]
        mov     esi, ecx
        mov     rdi, rax
        call    string_proc_list_add_node_asm
        mov     rax, QWORD [rbp-8]
        mov     rsp, rbp
        pop     rbp
        ret