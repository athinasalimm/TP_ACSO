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
    sub     rsp, 8           ; espacio para guardar hash

    movzx   ecx, dil         ; type → cl
    mov     [rbp-8], rsi     ; guardamos hash en stack

    mov     edi, 32
    call    malloc

    test    rax, rax
    je      .return_null

    mov     qword [rax + 0], 0      ; next
    mov     qword [rax + 8], 0      ; previous
    mov     byte  [rax + 16], cl    ; type

    mov     rdx, [rbp-8]            ; recuperamos hash
    mov     qword [rax + 24], rdx   ; hash

    leave
    ret

.return_null:
    xor     rax, rax
    leave
    ret

; ---------------------------------------------

string_proc_list_add_node_asm:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48

    mov     [rbp-24], rdi         ; list
    mov     [rbp-40], rdx         ; hash
    mov     [rbp-28], sil         ; type

    movzx   edi, byte [rbp-28]
    mov     rsi, [rbp-40]
    call    string_proc_node_create_asm
    mov     [rbp-8], rax          ; node

    mov     rax, [rbp-24]
    mov     rax, [rax]
    test    rax, rax
    jne     .nodo_existente

    ; lista vacía
    mov     rax, [rbp-24]
    mov     rdx, [rbp-8]
    mov     [rax], rdx
    mov     rax, [rbp-24]
    mov     rdx, [rbp-8]
    mov     [rax+8], rdx
    jmp     .fin_agregar

.nodo_existente:
    mov     rax, [rbp-24]
    mov     rax, [rax+8]
    mov     rdx, [rbp-8]
    mov     [rax], rdx

    mov     rax, [rbp-24]
    mov     rdx, [rax+8]
    mov     rax, [rbp-8]
    mov     [rax+8], rdx

    mov     rax, [rbp-24]
    mov     rdx, [rbp-8]
    mov     [rax+8], rdx

.fin_agregar:
    mov     rsp, rbp
    pop     rbp
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