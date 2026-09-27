; 简单循环示例
; ecx做计数器

.386
.model flat,stdcall
.stack 4096
.data

.code
main proc
    mov ecx,5
loop_label:
    ; 循环体
    dec ecx
    jnz loop_label ; ecx≠0就跳回 loop_label继续循环

    ret
main endp
end main
