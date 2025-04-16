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

; ---------------------------------------------

string_proc_list_create_asm: 
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


; ---------------------------------------------
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

; ---------------------------------------------
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
; ---------------------------------------------

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