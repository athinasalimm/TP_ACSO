; /** defines bool y puntero **/
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
    mov rbx, rdi     
    movzx rcx, sil   
    mov r8, rdx    

    mov rdi, 1
    call malloc
    mov byte [rax], 0     
    mov r9, rax            

    mov r10, [rbx]        

.loop:
    test r10, r10
    je .concat_extra_hash  

    movzx r11, byte [r10 + 16] 
    cmp r11b, cl
    jne .skip_concat           

    mov rdi, r9             
    mov rsi, [r10 + 24]     
    call str_concat


    mov rdi, r9
    call free


    mov r9, rax

.skip_concat:
    mov r10, [r10 + 0]
    jmp .loop

.concat_extra_hash:
    mov rdi, r9        
    mov rsi, r8       
    call str_concat

    mov rdi, r9
    call free

    ret