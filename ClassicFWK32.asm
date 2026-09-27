; 经典32位MASM框架
; 段结构 .model .data .code

.386 ; 启用386指令集
.model flat,stdcall ; flat平坦内存模型，stdcall调用约定
.stack 4096 ; 栈大小4KB

.data
; 数据段：定义变量
msg db 'Hello MASM',0 ; db = byte字节，0字符串结束符
num dd 100 ; dd = dword 32位整数

.code
main proc ; 过程=函数
    ; 写代码在这里

    ret
main endp
end main ; 程序入口main