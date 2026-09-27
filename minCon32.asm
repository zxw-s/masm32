; MASM32 Console 最小骨干模板（黑窗口），subsystem:console
; 编译命令: ml miniCon32.asm /link /subsystem:Console /entry:main kernel32.lib user32.lib

.386
.model flat,stdcall
option casemap:none

GetStdHandle proto :DWORD
WriteConsoleA proto :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ExitProcess proto :DWORD

STD_OUTPUT_HANDLE equ -11

.data
szText db 'Hello MASM32 Console',0Dh,0Ah
lenText equ $ - szText

.data?
dwWritten dd ?

.code
start:
    push STD_OUTPUT_HANDLE
    call GetStdHandle

    push offset dwWritten
    push 0
    push lenText
    push offset szText
    push eax
    call WriteConsoleA

    push 0
    call ExitProcess
end start