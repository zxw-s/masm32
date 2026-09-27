; 完整示例1：简单加减，无窗口控制台

.386
.model flat,stdcall
.stack 4096

.data
val1 dd 20
val2 dd 30
res dd ? ; ?代表未初始化

.code
main proc
    mov eax, val1
    add eax, val2 ; eax = 20+30=50
    mov res, eax

    ret
main endp
end main