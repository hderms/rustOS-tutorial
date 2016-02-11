global start
extern long_mode_start

section .text
bits 32
start:
    mov esp, stack_top
    ; print `OK` to screen
    call check_multiboot
    call set_up_page_tables
    call enable_paging

; load GTD
   lgdt [gdt64.pointer]
   ; update gdt selectors
   mov ax, gdt64.data
    mov ss, ax  ; stack selector
    mov ds, ax  ; data selector
    mov es, ax  ; extra selector

    mov dword [0xb8000], 0x2f4b2f4f

    jmp gdt64.code:long_mode_start

    hlt
; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al
    hlt
check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error
set_up_page_tables:
  ;map first P4 entry to P3 table
  mov eax, p3_table
  or eax, 0b11
  mov [p4_table], eax

  ; map first P3 entry to P2 table
  mov eax, p2_table
  or eax, 0b11; present + writable
  mov [p3_table], eax
  mov ecx, 0

.map_p2_table:
  mov eax, 0x200000
  mul ecx
  or eax, 0b10000011
  mov [p2_table + ecx * 8], eax

  inc ecx
  cmp ecx, 512
  jne .map_p2_table

  ret
enable_paging:
;  load P4 to cr3 register (cpu uses this to access the P4 table)
  mov eax, p4_table
  mov cr3, eax

  ; enable PAE-flag in cr4 (Physical Address Extension)
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; set the long mode bit in the EFER MSR (model specific register)
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax
  ret

section .bss
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack_bottom:
    resb 64
stack_top:

section .rodata
gdt64:
    dq 0 
.code: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
.data: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) 
.pointer:
    dw $ - gdt64 - 1
    dq gdt64
