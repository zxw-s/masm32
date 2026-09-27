; 调用Windows API（MASM最常用）
; 想要控制台输出文字，需要调用Windows kernel32.dll的API。
; stdcall：Windows API调用约定，参数从右往左压栈，函数内部平衡栈。
; 需要引入库：kernel32.lib

.386
.model flat,stdcall
.stack 4096

; 导入API声明
GetStdHandle proto dwStdHandle:dword
WriteConsoleA proto hConsoleOutput:dword, lpBuffer:ptr byte, nNumberOfCharsToWrite:dword, lpNumberOfCharsWritten:ptr dword, lpReserved:dword
ExitProcess proto dwExitCode:dword

includelib kernel32.lib

.data
msg db "Hello MASM!",0Ah ; 0Ah换行
msg_len equ $ - msg
written dd ?

.code
main proc
    ; 获取标准输出句柄 -11 = STD_OUTPUT_HANDLE
    invoke GetStdHandle, -11
    ; 输出字符串
    invoke WriteConsoleA, eax, offset msg, msg_len, offset written, 0
    ; 退出程序
    invoke ExitProcess,0
main endp
end main