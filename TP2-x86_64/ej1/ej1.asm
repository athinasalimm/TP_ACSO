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

    mov [rbp - 8], rdi            
    mov byte [rbp - 16], sil        
    mov [rbp - 24], rdx           

    
    mov rax, [rbp - 8]
    test rax, rax
    je .return_null

    mov rax, [rbp - 24]
    test rax, rax
    je .return_null

    ;saco longitud de hash
    mov rdi, [rbp - 24]
    call strlen
    add rax, 1                     
    mov rdi, rax
    call malloc
    test rax, rax
    je .return_null
    mov [rbp - 32], rax            

    ;strcpy(result, hash)
    mov rsi, [rbp - 24]
    mov rdi, [rbp - 32]
    call strcpy

    ;current = list->first
    mov rax, [rbp - 8]
    mov rax, [rax]
    mov [rbp - 40], rax            

.loop:
    mov rax, [rbp - 40]
    test rax, rax
    je .done

    movzx eax, byte [rax + 16]
    cmp al, byte [rbp - 16]
    jne .skip_concat

    mov rax, [rbp - 40]
    mov rsi, [rax + 24]        
    mov rdi, [rbp - 32]        
    call str_concat
    test rax, rax
    je .concat_fail
    mov [rbp - 48], rax           

    mov rdi, [rbp - 32]
    call free
    mov rax, [rbp - 48]
    mov [rbp - 32], rax

.skip_concat:

    mov rax, [rbp - 40]
    mov rax, [rax]                
    mov [rbp - 40], rax
    jmp .loop

.done:
    movzx ecx, byte [rbp - 16]     
    mov rdx, [rbp - 32]            
    mov rax, [rbp - 8]             
    mov esi, ecx
    mov rdi, rax
    call string_proc_list_add_node_asm

    mov rax, [rbp - 32]
    leave
    ret

.concat_fail:
    mov rdi, [rbp - 32]
    call free
    xor rax, rax
    leave
    ret

.return_null:
    xor rax, rax
    leave
    ret