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


string_proc_list_create_asm:
    ; malloc(sizeof(string_proc_list)) --> 16
    mov rdi, 16
    call malloc
    test rax, rax
    je .return_null

    ; Guardamos rax en rbx porque vamos a modificar rax luego
    mov rbx, rax
    ; list->first = NULL
    mov qword [rbx], 0
    ; list->last = NULL
    mov qword [rbx + 8], 0
    mov rax, rbx
    ret

.return_null:
    xor rax, rax
    ret





string_proc_node_create_asm:
    ; malloc(sizeof(string_proc_node)) --> 32
    mov rdi, 32
    call malloc
    test rax, rax
    je .return_null

    ; Guardamos puntero del nodo en rbx
    mov rbx, rax

    ; node->next = NULL
    mov qword [rbx], 0
    ; node->previous = NULL
    mov qword [rbx + 8], 0
    ; node->type = diluido en 1 byte (3er argumento -> dl)
    mov byte [rbx + 16], dl
    ; node->hash = rdx (4to argumento en rcx, pero ya movido a rdx por convención)
    mov qword [rbx + 24], rsi

    mov rax, rbx
    ret

.return_null:
    xor rax, rax
    ret





string_proc_list_add_node_asm:
    ; Argumentos:
    ; rdi = list
    ; sil = type
    ; rdx = hash

    ; Guardamos list en rbx
    mov rbx, rdi

    movzx edi, sil   ; type en edi
    mov rsi, rdx     ; hash
    call string_proc_node_create_asm
    test rax, rax
    je .return       ; si es NULL, return

    ; guardamos node en rcx
    mov rcx, rax

    ; if (list->first == NULL && list->last == NULL)
    mov rax, [rbx]
    mov rdx, [rbx + 8]
    test rax, rax
    jne .else_case
    test rdx, rdx
    jne .else_case

    ; list->first = node
    mov [rbx], rcx
    ; list->last = node
    mov [rbx + 8], rcx
    jmp .return

.else_case:
    ; curr_last = list->last
    mov rax, [rbx + 8]

    ; curr_last->next = node
    mov [rax], rcx

    ; node->previous = curr_last
    mov [rcx + 8], rax

    ; list->last = node
    mov [rbx + 8], rcx

.return:
    ret




string_proc_list_concat:
    ; malloc(1)
    mov rdi, 1
    call malloc
    test rax, rax
    je .return_null

    ; rax contiene puntero, lo guardamos en rbx
    mov rbx, rax
    mov byte [rbx], 0     ; result[0] = '\0'

    ; current = list->first
    mov r8, [rdi]

.loop:
    test r8, r8
    je .after_loop

    ; if (current->type == type)
    mov al, [r8 + 16]
    cmp al, sil
    jne .skip_concat

    ; str_concat(result, current->hash)
    mov rdi, rbx
    mov rsi, [r8 + 24]
    call str_concat

    ; free(result)
    mov rdi, rbx
    call free

    ; result = temp (en rax)
    mov rbx, rax

.skip_concat:
    ; current = current->next
    mov r8, [r8]
    jmp .loop

.after_loop:
    ; final_result = str_concat(result, hash)
    mov rdi, rbx
    mov rsi, rdx
    call str_concat

    ; free(result)
    mov rdi, rbx
    call free

    ; return final_result
    ret

.return_null:
    xor rax, rax
    ret