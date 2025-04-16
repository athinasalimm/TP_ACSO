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
    mov rbx, rdi         ; rbx ← lista
    movzx rcx, sil       ; rcx ← type a filtrar
    mov r8, rdx          ; r8 ← extra_hash (char*)

    ; Reservamos espacio para un string vacío inicial
    mov rdi, 1
    call malloc
    mov byte [rax], 0     ; string vacío → '\0'
    mov r9, rax           ; r9 ← resultado parcial

    mov r10, [rbx]        ; r10 ← primer nodo

.loop:
    test r10, r10
    je .concat_extra_hash

    movzx r11, byte [r10 + 16]   ; r11 ← nodo->type
    cmp r11b, cl
    jne .skip_concat             ; si no es del tipo deseado, salteamos

    ; Validar que el hash no sea NULL
    mov rax, [r10 + 24]          ; rax ← nodo->hash
    test rax, rax
    je .skip_concat              ; si es NULL, no concatenar

    ; Concatenar el string actual con el hash del nodo
    mov rsi, rax                 ; segundo string (hash)
    mov rdi, r9                  ; primer string acumulado
    mov r12, r9                  ; salvamos r9 para liberar después
    call str_concat              ; rax ← nuevo string concatenado
    mov r9, rax
    mov rdi, r12
    call free

.skip_concat:
    mov r10, [r10 + 0]           ; siguiente nodo
    jmp .loop

.concat_extra_hash:
    ; Concatenar el resultado acumulado con el hash extra
    mov rdi, r9                  ; primer string acumulado
    mov rsi, r8                  ; string adicional
    mov r12, r9
    call str_concat
    mov r9, rax
    mov rdi, r12
    call free

    mov rax, r9                  ; devolver string final
    ret