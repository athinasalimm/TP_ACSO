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
    test    rax, rax
    je      .return_null

    mov     [rbp-8], rax
    mov     rbx, [rbp-8]

    mov     qword [rbx], NULL
    mov     qword [rbx+8], NULL

    mov     rax, rbx
    jmp     .end

.return_null:
    mov     rax, NULL

.end:
    mov     rsp, rbp
    pop     rbp
    ret


string_proc_node_create_asm:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32

    mov     [rbp-32], rsi     ; hash
    mov     [rbp-20], dil     ; type

    mov     edi, 32
    call    malloc
    test    rax, rax
    je      .ret_null

    mov     [rbp-8], rax
    mov     rbx, [rbp-8]

    mov     qword [rbx], NULL
    mov     qword [rbx+8], NULL
    movzx   eax, byte [rbp-20]
    mov     byte [rbx+16], al
    mov     rax, [rbp-32]
    mov     qword [rbx+24], rax

    mov     rax, rbx
    jmp     .done

.ret_null:
    mov     rax, NULL

.done:
    mov     rsp, rbp
    pop     rbp
    ret


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

    mov     rbx, [rbp-24]
    mov     rax, [rbx]
    test    rax, rax
    jne     .append

    ; lista vacía
    mov     [rbx], rax            ; list->first = node
    mov     rbx, [rbp-24]
    mov     rdx, [rbp-8]
    mov     [rbx+8], rdx          ; list->last = node
    jmp     .end_add

.append:
    mov     rbx, [rbp-24]
    mov     rdx, [rbx+8]          ; curr_last
    mov     rax, [rbp-8]          ; node
    mov     [rdx], rax            ; curr_last->next = node
    mov     [rax+8], rdx          ; node->prev = curr_last
    mov     [rbx+8], rax          ; list->last = node

.end_add:
    mov     rsp, rbp
    pop     rbp
    ret


string_proc_list_concat_asm:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 64

    mov     [rbp-40], rdi         ; list
    mov     [rbp-56], rdx         ; hash
    mov     [rbp-44], sil         ; type

    ; strlen(hash) + 1
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

.loop_start:
    cmp     qword [rbp-16], NULL
    je      .loop_end

    mov     rax, [rbp-16]
    movzx   eax, byte [rax+16]
    cmp     al, byte [rbp-44]
    jne     .skip_concat

    ; result = str_concat(result, current->hash)
    mov     rdi, [rbp-8]
    mov     rax, [rbp-16]
    mov     rsi, [rax+24]
    call    str_concat
    mov     [rbp-24], rax

    mov     rdi, [rbp-8]
    call    free

    mov     rax, [rbp-24]
    mov     [rbp-8], rax

.skip_concat:
    ; current = current->next
    mov     rax, [rbp-16]
    mov     rax, [rax]
    mov     [rbp-16], rax
    jmp     .loop_start

.loop_end:
    ; agregar el nuevo nodo con el resultado final
    movzx   esi, byte [rbp-44]
    mov     rdx, [rbp-8]
    mov     rdi, [rbp-40]
    call    string_proc_list_add_node_asm

    mov     rax, [rbp-8]
    mov     rsp, rbp
    pop     rbp
    ret