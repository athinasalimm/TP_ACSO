

; /* defines bool y puntero */
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat
extern strcpy
extern strlen


string_proc_list_create_asm:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16

    mov     edi, 16
    call    malloc
    mov     [rbp-8], rax
    mov     rax, [rbp-8]
    mov     qword [rax], NULL
    mov     rax, [rbp-8]
    mov     qword [rax+8], NULL
    mov     rax, [rbp-8]

    mov     rsp, rbp
    pop     rbp
    ret


string_proc_list_create_asm: MALO
    mov rdi, 16         
    call malloc          

    test rax, rax       
    je .return_null      

    mov qword [rax], 0       

    mov qword [rax + 8], 0   

    ret

.return_null:
    xor rax, rax        
    ret


string_proc_node_create_asm:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    mov     [rbp-32], rsi     ; hash
    mov     [rbp-20], dil     ; type

    mov     edi, 32
    call    malloc
    mov     [rbp-8], rax
    mov     rax, [rbp-8]

    mov     qword [rax], NULL          ; next
    mov     qword [rax+8], NULL        ; previous

    movzx   edx, byte [rbp-20]
    mov     byte [rax+16], dl          ; type

    mov     rdx, [rbp-32]
    mov     qword [rax+24], rdx        ; hash

    mov     rax, [rbp-8]

    mov     rsp, rbp
    pop     rbp
    ret

string_proc_node_create_asm: MALO
    movzx rcx, dil       
    mov rdx, rsi         

    mov rdi, 32
    call malloc

    test rax, rax
    je .return_null

    mov qword [rax + 0], 0      
    mov qword [rax + 8], 0      
    mov byte  [rax + 16], cl   
    mov qword [rax + 24], rdx   

    ret

.return_null:
    xor rax, rax        
    ret 

string_proc_list_add_node_asm:
    mov rbx, rdi        
    movzx rcx, sil      
    mov r8, rdx         

    movzx rdi, cl
    mov rsi, r8
    call string_proc_node_create_asm

    test rax, rax
    je .fin          

    mov r9, rax         

    mov rax, [rbx]
    mov rdx, [rbx + 8]

    test rax, rax
    jne .lista_no_vacia
    test rdx, rdx
    jne .lista_no_vacia

    mov [rbx], r9       
    mov [rbx + 8], r9   
    jmp .fin

.lista_no_vacia:
    mov rax, [rbx + 8]

    mov [rax + 0], r9

    mov [r9 + 8], rax

    mov [rbx + 8], r9

.fin:
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




help
string_proc_list_concat_asm:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 64

    mov     [rbp-40], rdi         ; list
    mov     [rbp-56], rdx         ; hash
    mov     [rbp-44], sil         ; type

    ; malloc(strlen(hash) + 1)
    mov     rdi, [rbp-56]
    call    strlen
    add     rax, 1
    mov     rdi, rax
    call    malloc
    mov     [rbp-8], rax

    ; strcpy(result, hash)
    mov     rdi, [rbp-8]
    mov     rsi, [rbp-56]
    call    strcpy

    ; current = list->first
    mov     rax, [rbp-40]
    mov     rax, [rax]
    mov     [rbp-16], rax

.loop_fin:
    cmp     qword [rbp-16], 0
    je      .fin_loop

.loop_cuerpo:
    mov     rax, [rbp-16]
    movzx   eax, byte [rax+16]
    cmp     byte [rbp-44], al
    jne     .saltar_concat

    ; temp = str_concat(result, current->hash)
    mov     rax, [rbp-16]
    mov     rsi, [rax+24]
    mov     rdi, [rbp-8]
    call    str_concat
    mov     [rbp-24], rax

    ; free(result)
    mov     rdi, [rbp-8]
    call    free

    ; result = temp
    mov     rax, [rbp-24]
    mov     [rbp-8], rax

.saltar_concat:
    mov     rax, [rbp-16]
    mov     rax, [rax]
    mov     [rbp-16], rax
    jmp     .loop_fin

.fin_loop:
    movzx   esi, byte [rbp-44]
    mov     rdx, [rbp-8]
    mov     rdi, [rbp-40]
    call    string_proc_list_add_node_asm

    mov     rax, [rbp-8]
    mov     rsp, rbp
    pop     rbp
    ret