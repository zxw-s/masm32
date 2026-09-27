; MASM x86-32 最小模板 (min32.asm)
; 编译：ml /c /coff min32.asm
; 链接：link /subsystem:console min32.obj kernel32.lib

.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

.code
main PROC
    push 0
    call ExitProcess
main ENDP
END main