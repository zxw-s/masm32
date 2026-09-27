; 简单if-else示例

.386
.model flat,stdcall
.stack 4096
ExitProcess proto dwExitCode:dword
includelib kernel32.lib

.code
main proc
    mov eax, 8
    cmp eax, 10
    jge bigger ; eax >=10跳bigger

    ; 小于10分支
    mov ebx,1
    jmp done

bigger:
    mov ebx,2

done:
    invoke ExitProcess,0
main endp
end main