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
    push rbp
    mov rbp, rsp
    sub rsp, 32
   
    mov [rbp - 32], rsi      

    mov byte [rbp - 20], dil

    mov edi, 32          
    call malloc           

    test rax, rax
    je .return_null    


    mov [rbp - 8], rax

    movzx edx, byte[rbp - 20]
    mov rax, [rbp - 8]
    mov byte[rax + 16], dl

    mov rdx, [rbp - 32]
    mov [rax + 24], rdx

    mov qword[rax], 0

    mov qword[rax+8], 0

    mov rax, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

.return_null:
    xor rax, rax
    mov rsp, rbp
    pop rbp
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
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Guardamos argumentos
    mov [rbp - 32], rdi        ; list
    mov [rbp - 40], sil        ; type
    mov [rbp - 48], rdx        ; hash

    ; Inicializar result = malloc(1)
    mov rdi, 1
    call malloc
    mov [rbp - 8], rax         ; result
    mov byte [rax], 0          ; result[0] = '\0'

    ; current = list->first
    mov rax, [rbp - 32]
    mov rax, [rax]             ; list->first
    mov [rbp - 16], rax        ; current

.loop_start:
    mov rax, [rbp - 16]
    test rax, rax
    je .fin_loop

    ; if (current->type == type)
    movzx eax, byte [rax + 16] ; current->type
    cmp al, byte [rbp - 40]
    jne .concat_skip

    ; temp = str_concat(result, current->hash)
    mov rdi, [rbp - 8]         ; result
    mov rsi, [rbp - 16]
    mov rsi, [rsi + 24]        ; current->hash
    call str_concat
    mov [rbp - 24], rax        ; temp

    ; free(result)
    mov rdi, [rbp - 8]
    call free

    ; result = temp
    mov rax, [rbp - 24]
    mov [rbp - 8], rax

.concat_skip:
    ; current = current->next
    mov rax, [rbp - 16]
    mov rax, [rax]             ; current->next
    mov [rbp - 16], rax
    jmp .loop_start

.fin_loop:
    ; final_result = str_concat(result, hash)
    mov rdi, [rbp - 8]         ; result
    mov rsi, [rbp - 48]        ; hash
    call str_concat
    mov [rbp - 24], rax        ; final_result

    ; free(result)
    mov rdi, [rbp - 8]
    call free

    ; result = final_result
    mov rax, [rbp - 24]
    mov [rbp - 8], rax

    ; return result
    mov rax, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret


