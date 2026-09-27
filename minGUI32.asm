; MASM32 32-bit Windows 最小GUI骨干模板
; Win32 GUI 可执行PE
; 编译命令:
; ml /c /coff mini.asm
; link /subsystem:windows mini.obj user32.lib kernel32.lib
; /c:只编译不链接  /coff:输出COFF目标文件
; subsystem:windows = GUI程序，不是控制台

.386                    ; 启用32位指令集
.model flat,stdcall     ; 平坦内存模型，stdcall调用约定
option casemap:none     ; 符号区分大小写，Windows API习惯
include windows.inc
includelib user32.lib
includelib kernel32.lib

; ========== Windows API 函数原型声明 ==========
; 也可以直接include <windows.inc>，这里手写声明做到模板最小化，不依赖外部inc文件
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
MessageBoxA proto :DWORD,:DWORD,:DWORD,:DWORD
ExitProcess proto :DWORD

; ========== 数据段：只读/初始化数据 ==========
.data
szTitle     db  "MASM32 Minimal Template",0
szMsg       db  "Hello MASM32 Win32!",0

; ========== 代码段 ==========
.code

start:
    ; Win32 GUI程序真正入口，CRT会调用WinMain
    push 0
    push 0
    push 0
    push 0
    call WinMain

    ; WinMain返回后退出进程
    push eax
    call ExitProcess

; ------------------------------
; WinMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow)
; ------------------------------
WinMain proc hInst:HINSTANCE,hPrev:HINSTANCE,lpCmd:LPSTR,nShow:DWORD
    ; MessageBoxA( hWnd, lpText, lpCaption, uType )
    push 0                  ; MB_OK
    push offset szTitle     ; 标题字符串
    push offset szMsg       ; 消息内容
    push 0                  ; 父窗口句柄NULL
    call MessageBoxA

    mov eax,0               ; 返回0
    ret
WinMain endp

end start   ; 指定程序入口点 start