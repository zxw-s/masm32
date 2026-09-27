# MASM 32位Windows汇编语言入门（Intel语法）

汇编语言是**机器码的助记符**，和CPU架构强绑定，最常见：x86（32位）、x86‑64（64位）、ARM。

> 汇编没有统一标准，Windows用MASM，Linux用NASM/GAS。

MASM 是微软宏汇编器，**Intel语法：目的操作数在前，源在后**。

```asm
mov 目的, 源
```

> 环境：VS自带ml.exe / ml64.exe；也可以用 MASM32 工具包。
> 
> ml.exe → 32位 x86
> 
> ml64.exe → 64位 x64（64位MASM不支持 .model 、invoke宏很多变化）
> 
> 入门优先学 **32位MASM（ml.exe）**，资料多、简单。
> 
> 汇编学习的重心是**寄存器、寻址、调用约定、系统 API**

## 一、核心寄存器（32位x86）

**32位通用寄存器**

| 寄存器 | 作用          |
| --- | ----------- |
| EAX | 累加器，返回值     |
| EBX | 基址          |
| ECX | 计数          |
| EDX | 数据          |
| ESI | 源索引         |
| EDI | 目的索引        |
| ESP | **栈指针（栈顶）** |
| EBP | 栈基址         |

可以访问16位、8位子部分：

 `EAX(32) → AX(16) → AL(低8),AH(高8)` 

## 二、段结构 .model .data .code

### 经典32位MASM框架

```asm
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
```

> **数据定义伪指令：**

-  `db`  1字节 byte

-  `dw`  2字节 word

-  `dd`  4字节 dword

-  `dq`  8字节 qword

### 基础指令

**mov 传送**

```asm
mov eax, 10 ; eax = 10 立即数
mov ebx, eax ; eax复制到ebx
mov eax, num ; 把num变量的值给eax
mov num, eax ; eax写入num变量
```

❌ 不能内存→内存： mov num2, num  非法，必须中转寄存器

**算术 add sub inc dec**

```asm
add eax,5 ; eax = eax+5
sub eax,2
inc eax ; eax++
dec eax ; eax--
```

**cmp 比较 + 条件跳转**

 `cmp a,b`  实际做 ` a‑b` ，只修改标志位，不改寄存器

```asm
cmp eax, 10
je equal_label ; equal 相等跳转
jg greater_label ; 大于
jl less_label ; 小于
jmp all_jump ; 无条件跳转
```

**栈 push pop**

栈：后进先出， `ESP 栈顶`

```asm
push eax ; 压栈
pop ebx ; 出栈到ebx
```

**调用过程 call ret**

```asm
call my_func ; 调用过程，返回地址压栈
ret ; 弹出返回地址回去
```

### 完整示例：简单加减，无窗口控制台

```asm
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
```

### 调用Windows API（MASM最常用）

想要控制台输出文字，需要调用Windows kernel32.dll的API。

 `stdcall` ：Windows API调用约定，参数从右往左压栈，函数内部平衡栈。

> 需要引入库： `kernel32.lib` 

**完整HelloWorld控制台（32位MASM）**

```asm
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
```

> `invoke`  是MASM宏，自动帮你把参数压栈，简化call。
> 
> `offset msg` ：取msg变量的内存地址。

**编译命令（cmd，ml.exe在VS工具目录）**

```cmd
ml /c /coff hello.asm
link /subsystem:console hello.obj kernel32.lib
```

- `/c` ：只汇编不链接

-  `/coff` ：输出COFF目标文件

- `/subsystem:console`  控制台程序；如果写窗口用  `windows` 

运行得到  `hello.exe` 。

### 寻址方式

```asm
mov eax, num ; 取变量值
mov eax, offset num ; 取变量地址
mov eax, [ebx] ; [] 访问内存，ebx里面存的地址
```

### 简单if-else示例

```asm
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
```

### 简单循环示例

```asm
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
```

也可以用  `loop`  指令： `loop label`  → ecx--，ecx≠0跳转。

## 三、MASM32 Windows 最小骨干模板

> 环境：MASM32 SDK，ml.exe(masm 6.14) + link.exe(微软32位链接器)，生成 **Win32 GUI 可执行PE**，无多余库依赖，最小骨架，弹出消息框。
> 特点：WinMain入口，不需要控制台，纯Windows API，可直接编译运行，带注释。

### GUI版本最小模板mini.asm

```asm
; MASM32 32-bit Windows 最小GUI骨干模板
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
```

### 编译批处理 build.bat

```bat
@echo off
ml /c /coff mini.asm
if errorlevel 1 goto err
link /subsystem:windows mini.obj user32.lib kernel32.lib
echo build ok: mini.exe
goto end
:err
echo compile error!
:end
pause
```

---

### 控制台版本最小模板miniCon.asm（备选）

如果想要 **Console 32位程序**（黑窗口），subsystem:console

```asm
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
```

编译命令：

```cmd
ml /c /coff miniCon.asm
link /subsystem:console miniCon.obj kernel32.lib
```

---

### 关键知识点（概述）

1. `.386`：32位保护模式；`.model flat,stdcall` Windows 32程序标准模型；`stdcall` 被调用方清理栈。
2. `option casemap:none`：API函数名大小写敏感，避免`messageboxa`找不到符号。
3. `end start`：必须指定入口标签，linker以此找PE入口。
4. `user32.lib`：UI函数 MessageBox；`kernel32.lib`：进程、IO基础API。
5. `MessageBoxA` = ANSI版本；`MessageBoxW`=Unicode宽字符。

### 习题

1. 修改GUI模板，把弹窗内容改成你自己的文字，重新编译运行。
2. 修改参数，让弹窗出现警告图标 `MB_ICONWARNING`（值=30h）。
3. 尝试删除 `ExitProcess` 调用，观察程序运行会发生什么。

## 四、32位MASM重要知识点

1. ` .model flat,stdcall`  32位Windows必备；64位MASM没有这个。

2.  `invoke`  只是宏，不是CPU指令，只在MASM可用。

3.  `[]`  代表访问内存； `offset` 获取地址。

4. stdcall：API参数**从右向左压栈**，函数内部ret n清理栈。

5. 伪指令（db dd .code .data）是汇编器处理，**不是CPU机器指令**。

## 五、32位 vs 64位 MASM(ml64.exe)

- 64位不再支持  `.model` ，不支持`invoke` 宏

- 寄存器变成 rax rbx rcx rdx rsi rdi r8‑r15

- 调用约定：前4参数：rcx,rdx,r8,r9，后面放栈上

- API直接call，手动处理参数，写起来繁琐；新手先学32位。

## 六、常见坑

1. 不要混淆值和地址： `mov eax,msg`  拿地址； `mov eax,[msg]` 拿内存里的数据。

2. Windows API字符串： `WriteConsoleA`  ANSI； `WriteConsoleW`  Unicode宽字符。

3. link的时候 subsystem 选错，程序一闪而过。

4. 汇编伪指令不是CPU指令。

## 七、学习路线

1. 熟悉寄存器、寻址、mov/add/sub/cmp/jmp、loop

2. 写分支、循环小例子

3. invoke调用Windows控制台API，输入输出

4. 栈帧、手写过程（不使用invoke）

5. 简单窗口程序

6. 阅读C语言反汇编（VS调试窗口看反汇编）

接下来可以： 手写栈调用，不使用invoke宏

# MASM 64位Windows最小骨干模板

> 环境：MASM64 (ml64.exe)，Windows SDK，x64，无CRT，直接调用Win32 API，最小可编译运行，无多余依赖。
> 功能：弹出简单MessageBox，程序退出。
> 要点：64位Windows调用约定：**fastcall**，前4个参数 RCX, RDX, R8, R9，其余栈上；栈必须16字节对齐；函数调用后栈要平衡。

## mini.asm 完整源码

```asm
; MASM64 x64 Windows 最小骨干模板
; 编译命令: ml64 mini.asm /link /subsystem:windows /entry:main kernel32.lib user32.lib

extrn GetStdHandle:PROC
extrn WriteConsoleA:PROC
extrn MessageBoxA:PROC
extrn ExitProcess:PROC

.data
szTitle     db  "MASM64 Demo",0
szMsg       db  "Hello MASM64 Windows!",0

.code

main PROC
    ; 64位栈对齐：进入入口，栈需要保持16字节对齐
    ; call 会压入8字节返回地址，所以sub rsp, 20h 保证对齐 + 预留4个参数影子空间(shadow space)
    sub     rsp, 28h        ; shadow space 32(20h) + 额外8保证16字节对齐

    ; MessageBoxA(hWnd, lpText, lpCaption, uType)
    ; RCX = hWnd = NULL(0)
    ; RDX = lpText
    ; R8  = lpCaption
    ; R9  = uType = MB_OK = 0
    xor     rcx, rcx
    lea     rdx, szMsg
    lea     r8, szTitle
    xor     r9, r9
    call    MessageBoxA

    ; ExitProcess(uExitCode)
    xor     rcx, rcx
    call    ExitProcess

main ENDP

END
```

## 编译批处理 build.bat

```bat
@echo off
:: 需要ml64.exe，一般在VS Build Tools目录
ml64 mini.asm /link /subsystem:windows /entry:main kernel32.lib user32.lib
pause
```

### 编译参数说明

1. `ml64 mini.asm`：MASM64汇编器
2. `/link`：调用链接器link.exe
3. `/subsystem:windows`：GUI程序；如果写控制台程序改为`/subsystem:console`
4. `/entry:main`：自定义入口点，不使用CRT的mainCRTStartup
5. `kernel32.lib user32.lib`：API导入库

## 关键知识点（64‑bit MASM）

1. **Shadow Space（影子空间）** 调用Win32 API之前，**必须在栈上预留32字节(0x20)影子空间**，由调用者分配，被调用函数使用。 `sub rsp,28h`：0x20影子空间 + 0x8，保证`call`压入返回地址之后RSP仍然16字节对齐。
   
   > 64位Windows硬性规则：**每次函数调用指令执行时刻，RSP必须是16字节对齐**。

2. 寄存器传参顺序(fastcall)
   
   | 参数序号 | 寄存器      |
   | ---- | -------- |
   | 第1参数 | RCX      |
   | 第2参数 | RDX      |
   | 第3参数 | R8       |
   | 第4参数 | R9       |
   | 5及以后 | 栈，从右往左压入 |

3. 字符串：`.data`段以`0`结尾C‑风格ASCII字符串，`MessageBoxA`为ANSI版本；Unicode用`MessageBoxW` + `dw`宽字符。

## 控制台版本变体（可选）

如果你想要控制台最小模板，替换`.code`部分：

```asm
; MASM64 x64 Console 最小骨干模板（黑窗口），subsystem:console

extrn GetStdHandle:PROC
extrn WriteConsoleA:PROC
extrn MessageBoxA:PROC
extrn ExitProcess:PROC

.data
szTitle     db  "MASM64 Demo",0
szMsg       db  "Hello MASM64 Windows!",0

.code
main PROC
    sub rsp,28h

    ; GetStdHandle(STD_OUTPUT_HANDLE = -11)
    mov rcx, -11
    call GetStdHandle

    ; WriteConsoleA( hConsoleOutput, lpBuffer, nNumberOfCharsToWrite, lpNumberOfCharsWritten, lpReserved )
    mov rcx, rax
    lea rdx, szMsg
    mov r8, sizeof szMsg -1
    xor r9, r9
    push 0
    call WriteConsoleA

    xor rcx,0
    call ExitProcess
main ENDP

END
```

编译链接改为：`ml64 mini.asm /link /subsystem:Console /entry:main kernel32.lib user32.lib`

## 常见踩坑清单（习题）

1. ❌忘记`sub rsp,28h` → 程序随机崩溃，栈未对齐
2. ❌混淆32位MASM(`invoke`)，**MASM64没有invoke宏**，必须手动填寄存器
3. ❌忘记影子空间，API内部读写栈破坏数据
4. ❌使用`/entry:main`但还链接CRT库，冲突
5. ❌ASCII/W API混用：A后缀用`db`，W后缀用`dw L"xxx",0`

> 练习任务：

1. 编译运行模板，弹出消息框。
2. 修改代码使用`MessageBoxW`宽字符版本，显示中文。
3. 在模板基础上增加调用`Beep()`API。

如果你需要，我可以给你：

- 完整Unicode版本模板
- 最小裸机无lib导入版本（手动LoadLibrary/GetProcAddress）
- VS配置MASM64项目的步骤。

# MASM x86-32 vs x86-64 语法差异速查表

> 说明：MASM = Microsoft Macro Assembler，32位俗称MASM32；64位ml64.exe，**ml.exe只编译32位，ml64.exe只编译64位**
> 
> 调用约定重点：32位常用 `cdecl/stdcall`；64位Windows固定 `Microsoft x64 Calling Convention`

| 对比项              | MASM x86-32（ml.exe）                                                                       | MASM x86-64（ml64.exe）                                                                                            |
| ---------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| 汇编器程序            | `ml /c /coff main.asm`                                                                    | `ml64 /c main.asm`                                                                                               |
| 内存模型             | 平坦内存模型，支持段：`.code` `.data` `.data?` `.stack`                                              | 同样支持`.code` `.data` `.data?`；**不再支持 .stack 段定义栈大小**                                                              |
| 通用寄存器            | 16位：AX,BX,CX,DX,SI,DI,BP,SP<br>32位：EAX,EBX,ECX,EDX,ESI,EDI,EBP,ESP                        | 在32位基础上新增64位寄存器：<br>RAX,RBX,RCX,RDX,RSI,RDI,RBP,RSP<br>新增8个通用寄存器：R8~R15（只有64位可用）                                 |
| 寄存器访问规则          | 修改EAX，AX，AH/AL互不影响（AH/BH/CH/DH可用）                                                         | 写32位寄存器（如EAX）会自动清零对应64位寄存器高32位<br>⚠️ **AH、BH、CH、DH 在64位下不能和R8-R15混用**                                            |
| 函数调用约定           | cdecl：调用方平衡栈<br>stdcall：被调用方平衡栈<br>关键字：`PROC C` / `PROC STDCALL`                          | Windows x64：**无stdcall/cdecl关键字，全部统一约定**<br>前4个参数：RCX,RDX,R8,R9；剩余参数放栈上<br>栈必须16字节对齐！<br>被调用方负责清理栈局部变量，调用方清理传入参数 |
| PROC / ENDP 过程定义 | 支持`MyFunc PROC stdcall`，可带参数<br>`MyFunc PROC`<br>`push ebp`<br>`mov ebp,esp`<br>栈帧手动搭建很常见 | `MyFunc PROC`，**PROC后面不能写stdcall/cdecl等调用约定**<br>不再强制EBP栈帧，推荐RBP做可选栈帧；大量使用影子空间(home space)                       |
| 变量定义             | 局部变量：`[ebp-4]`<br>全局：`.data` `var DWORD 10`<br>`.data? buf db 1024 dup(?)`                | 全局变量定义语法基本不变<br>局部变量：`[rbp-4]`<br>栈上分配，必须保证RSP16字节对齐                                                             |
| 中断调用             | `int 21h` DOS中断（16位）；Win32用`call`调用API                                                    | ❌ **不支持 int 21h**；Win64 API全部使用call调用<br>不能使用软中断调用系统服务                                                           |
| API调用示例          | `call GetConsoleTitleA`，参数从右往左压栈                                                          | `sub rsp, 32` 预留32字节影子空间，前4参数放入RCX,RDX,R8,R9，再call API                                                           |
| 指针大小             | 指针 = 32位（DWORD）                                                                           | 指针 = 64位（QWORD）                                                                                                  |
| 寻址               | `mov eax, [ebx+esi*2+10]` 完整缩放寻址                                                          | `mov rax, [rbx+rsi*2+10]` 缩放寻址保留；但部分限制                                                                           |
| 宏 & 关键字          | `INVOKE` 支持！可以直接调用函数自动压参数                                                                 | ❌ **ml64 移除 INVOKE 宏**，必须手动传参、手动维护栈对齐                                                                            |
| 段寄存器             | CS DS ES SS FS GS                                                                         | GS寄存器用于TEB；FS在64位Windows不再用于TEB                                                                                  |
| 入口标记             | `END start` 指明入口标签start                                                                   | `END` 后面**不能写入口标签**，入口在链接时指定`/entry:start`                                                                       |

## 最小示例对比

### ✅ MASM x86-32 最小模板 (min32.asm)

```asm
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
```

编译：`ml /c /coff min32.asm`  
链接：`link /subsystem:console min32.obj kernel32.lib`

### ✅ MASM x86-64 最小模板 (min64.asm)

```asm
; ml64 64位MASM，无.model，无.stack，无INVOKE
ExitProcess PROTO :DWORD

.code
main PROC
    sub rsp, 20h        ; 预留32字节影子空间，保证16字节对齐
    mov rcx, 0          ; 第1参数放入RCX
    call ExitProcess
    add rsp, 20h        ; 恢复栈
    ret
main ENDP
END
```

编译：`ml64 /c min64.asm`  
链接：`link /subsystem:console /entry:main min64.obj kernel32.lib`

## 高频易错点总结

1. **ml64 没有 INVOKE**：32位方便的自动参数宏，64位MASM删掉了，必须手动处理寄存器与栈
2. **栈16字节对齐是硬性要求**，调用Windows API之前必须满足，否则程序随机崩溃
3. 64位调用API，**哪怕函数只有1个参数，也要预留32字节影子空间**
4. 64位不能写 `PROC STDCALL`，调用约定固定微软x64
5. END 指令，32位写`END label`；64位只能写`END`，入口交给linker指定

## 练习题

1. ml.exe 和 ml64.exe，哪个支持 `.model flat, stdcall`？
2. Windows x64 MASM，函数前4个参数分别放在哪几个寄存器？
3. x64调用API，影子空间（home space）固定多少字节？为什么要栈16字节对齐？

# MASM 16位DOS汇编语言

> MASM 和 NASM 语法不一样！MASM 是微软的汇编器，段定义、变量、入口、注释语法都不同。
> 环境：DOSBox + MASM5.0 / MASM6.11，16位实模式 DOS 程序。

## MASM 16位完整段最小可运行骨干框架

> 16位DOS EXE程序，**完整SEGMENT段格式（考试大题优先写这个）** 包含：数据段、栈段、代码段、ASSUME、DS初始化、程序退出、END入口标记

```asm
;MASM 16位最小可运行骨干框架
;16位DOS EXE程序，完整SEGMENT段格式（考试大题优先写这个）， 包含：数据段、栈段、代码段、ASSUME、DS初始化、程序退出、END入口标记

DATA SEGMENT
    ; 数据段：定义变量、字符串
DATA ENDS

STACK SEGMENT STACK
    ; 栈段，开辟栈空间，256个字    
    dw 100H DUP(?)
STACK ENDS

CODE SEGMENT
    ; ASSUME：告诉汇编器，段寄存器对应哪一个逻辑段
    ; ASSUME仅仅是汇编器的提示，**不会修改CPU寄存器**！
    ASSUME CS:CODE, DS:DATA, SS:STACK

; 程序入口标签，名字自定义，一般叫start
START:
    ; 初始化DS数据段寄存器
    mov ax,DATA
    mov ds,ax

    ; 在这里写功能代码

    ; DOS 4Ch功能调用，DOS中断退出程序
    mov ah,4CH
    int 21H
CODE ENDS
END START    ; end后面指定入口标签start，告诉MASM程序入口
```

### 必记易错点（考试高频）

1. `ASSUME`只是给汇编器看，**不会修改CPU寄存器**，DS必须手动赋值。
2. 09H字符串输出，字符串末尾必须带 `'$'`。
3. 文件最后一行必须写 `END START`，指定程序入口标签`START`。
4. `STACK SEGMENT STACK` 第二个`STACK`伪指令告诉汇编这是栈段。

## MASM 16位简化段最小骨架（.model small）

> 代码短，考试如果没有强制要求完整SEGMENT可以用

```asm
.model small
.stack 100h
.data
    ;数据放这里
.code
start:
    mov ax,@data
    mov ds,ax

    ;功能代码

    mov ah,4Ch
    int 21h
end start
```

## MASM 16位最小可编译运行完整标准框架（两种写法：简化段、完整段）

带输出示例，DOS .EXE 程序，MASM/TASM 可用

> 环境：MS‑DOS / DOSBox，16位实模式，完整 `.EXE` 框架，**最小可编译运行骨架**，带详细注释，可直接扩充功能。
> 编译链路：`masm main.asm;` → `link main.obj;` → `main.exe`

### 方式1：简化段定义写法（.model small，常用，简单）

```asm
; ==============================================
; MASM 16位 EXE 程序骨干结构
; MASM 简化段格式 .model .stack .data .code
; 存储模型：内存模型 small：代码段1个，数据段1个，64KB
; ==============================================
.MODEL SMALL        ; 内存小模型：CS=代码段，DS=数据段，代码段1个，数据段1个，64KB
.STACK 100H         ; 设置栈大小 256字节

; ---------------- 数据段：定义变量、字符串 ----------------
.DATA
    msg db  'Hello MASM!',0DH,0AH,'$'  ; 字符串，DOS int 21h 09h号功能：输出字符串，以$作为结束标记

; ---------------- 代码段 ----------------
.CODE
START:          ; 程序入口标签，名字自定义，一般叫start
    ; 初始化DS数据段寄存器（small模型必须手动赋值ds）
    MOV AX, @DATA
    MOV DS, AX          ; DS 指向我们的数据段

    ; ========== 在这里写你的业务汇编代码 ==========
    ; DOS 21h 09号功能：输出字符串，ds:dx指向字符串，$结尾
    LEA DX, msg
    MOV AH, 09H
    INT 21H
    ; ============================================

    ; DOS 4Ch功能调用，DOS程序标准退出，返回操作系统
    MOV AH, 4CH
    INT 21H

END START           ; end后面指定程序入口点标记START，告诉MASM程序入口
```

> ⚠️重点区别 NASM vs MASM

1. MASM：`end start` 指定入口；**没有 global _start**（NASM语法）
2. DOS 09h打印字符串：MASM习惯用`$`结尾，不是靠长度计数；NASM示例是按字符循环打印。
3. 必须手动给DS赋值：`mov ax,@data` → `mov ds,ax`，简化段模型下不能省略。
4. 变量定义：`db dw dd` 一样；取地址用 `lea dx,msg`，NASM是`mov dx, offset msg`。

---

### 方式2：传统完整段定义写法（传统完整SEGMENT格式）

（**老式MASM教学常用这种显式 `SEGMENT` 完整框架，不使用`.MODEL`伪指令，考试常考**）

> 使用**传统完整SEGMENT段定义格式**（考试最常考，完整展示全部结构）
> 功能：在屏幕输出一行字符串 `Hello MASM Assembly!`，然后程序正常退出。
> 文件：`hello.asm`，MASM编译生成 `.exe` 可执行文件

```asm
; MASM 完整段定义示例，理解完整程序结构
DATA SEGMENT
    ; 数据段：存放初始化好的数据、字符串
    msg  db  'Hello MASM Assembly!',0Dh,0Ah,'$'
    ; 0Dh=回车，0Ah=换行，$ 是DOS 09H输出功能的结束标记
DATA ENDS

STACK SEGMENT STACK
    ; 栈段，开辟栈空间，256个字，STACK属性交给链接器处理SS:SP
    dw  100H  DUP(?)
STACK ENDS

CODE SEGMENT
    ; ASSUME：告诉汇编器，段寄存器对应哪一个逻辑段。仅汇编器映射，不会修改CPU寄存器！！
    ASSUME CS:CODE, DS:DATA, SS:STACK

START:
    ; ========= 1.初始化数据段寄存器DS，必须手动赋值 =========
    mov  ax, DATA
    mov  ds, ax

    ; ========= 2.DOS 21H中断 09H功能：输出$结尾字符串 =========
    ; 入口要求：DS:DX = 字符串首地址，AH=09H
    ; 用户代码区域
    lea  dx, msg      ; 取msg的偏移地址送入dx
    mov  ah, 09H
    int  21H

    ; =========3.程序退出返回DOS系统 4CH功能 =========
    mov  ah, 4CH
    int  21H

CODE ENDS
END START   ; 文件最后一行！END + 入口标签START，指定程序执行起点
```

### 关键知识点梳理

1. 关键字：
   - `SEGMENT`：段开始
   - `ENDS`：段结束
   - `ASSUME`：只是给汇编器的映射声明，**不会修改寄存器的值**，必须自己mov给ds。
2. **`.MODEL SMALL`**：小模型，最适合初学16位DOS程序；
3. `ASSUME`：告诉汇编器段寄存器对应哪个段，**不修改硬件寄存器**；真正赋值需要 `MOV AX,DATA / MOV DS,AX`；
4. `INT 21H` DOS系统调用：
   - `AH=09H`：打印 `$` 结尾字符串
   - `AH=4CH`：程序退出返回DOS（必须要有，否则程序跑飞）
5. `END 入口标号`：指定程序从哪里开始执行，**不能漏**。

---

## 拆解MASM完整程序五大组成部分

- **DATA SEGMENT ~ DATA ENDS 数据段** 存放常量、字符串、已初始化变量。程序运行时DS寄存器指向这个段。

- **STACK SEGMENT ~ STACK ENDS 栈段** 提供程序栈空间，保存返回地址、临时数据；`STACK`关键字告诉链接器这是栈段，自动设置SS:SP。

- **CODE SEGMENT ~ CODE ENDS 代码段** 存放CPU机器指令，CS寄存器指向代码段。

- **ASSUME CS:CODE,DS:DATA,SS:STACK**
  
  > ⚠️高频考点：**ASSUME 不改变硬件寄存器！只给汇编器做映射说明**。
  > 真正给DS赋值，必须写：

```asm
mov ax,DATA
mov ds,ax
```

5. **入口标记 `START` 和 `END START`**
- `START`：代码段内的标签，程序第一条要执行指令的位置。

- `END START`：文件最后一行，告诉链接器：程序从`START`标签处开始运行。
  
  > NASM用`global _start`；MASM用`END 入口标签`，这是两者最大区别。

## MASM（16位DOS汇编）编译链接运行完整流程

MASM是**x86实模式汇编**，面向DOS系统；最终生成**原生机器码exe/com**，CPU直接执行，**没有虚拟机、没有中间字节码**。

> 完整流程：**编辑 → 汇编 → 链接 → 运行**
> 
> 环境说明：16位程序不能直接在现代Windows运行，依赖 DOSBox 模拟器。

### ① 编辑

编写 `.asm` 汇编源文件，纯文本，CPU不能识别。

### ② 汇编（masm/ml 汇编器）

```cmd
masm test.asm;
```

把汇编助记符（mov、int、push）翻译成**二进制机器码** 输出：`test.obj` 目标文件

- 做语法检查：指令写错、寄存器非法、段定义错误在这里报错。
- `.obj`：二进制机器码，**还不能直接运行**，段地址、符号地址还没有确定。

> 注意：obj里面有段信息、符号表，还没有完成地址重定位。

### ③ 链接 link.exe

```cmd
link test.obj;
```

链接器处理段合并、地址重定位，解析符号，生成可执行文件
输出：`test.exe`（16位DOS可执行程序）

### ④ 运行

在DOSBox(DOS环境)加载exe，**CPU直接执行机器指令**，没有虚拟机、没有解释器。
程序调用DOS中断 `int 21h` 完成输入输出、退出。

> 程序入口：`end start` 指定入口标号`start`，CPU从start标号处开始执行。

输出：

```plaintext
Hello MASM Assembly!
```

### 文件对照表

| 文件            | 说明                  | 能否直接CPU运行   |
| ------------- | ------------------- | ----------- |
| `.asm`        | 汇编源代码文本             | ❌           |
| `.obj`        | 汇编生成目标文件，机器码，地址未重定位 | ❌           |
| `.exe`(dos16) | 16位DOS可执行，原生机器码     | ✅（需要DOSBox） |

## MASM（16位DOS汇编）项目通用目录结构

> MASM没有官方强制目录规范，考试、课程作业通用模板；使用`masm.exe`汇编、`link.exe`链接，依赖DOSBox运行。 `.obj`、`.exe`属于编译产物，不要和源码混放，不提交版本控制。

### 1.极简练习版本（课堂小作业，单asm文件）

```plaintext
masm_demo/
├── hello.asm     ;汇编主源码
└── readme.txt
```

操作：直接在DOSBox下执行

```cmd
masm hello.asm;
link hello.obj;
```

### 2.标准项目目录（课程大作业，多模块、包含文件）

```plaintext
masm_project/
├── src/                ;汇编源代码 .asm
│   ├── main.asm        ;主程序，end start写在此文件
│   └── sub.asm        ;子模块汇编文件
├── include/            ;头文件 .inc，宏定义、常量、数据段复用
│   └── macro.inc
├── obj/                ;汇编输出 *.obj 目标文件（masm生成）
├── bin/                ;链接输出 *.exe 可执行文件（link生成）
├── make.bat            ;Windows批处理脚本，一键汇编+链接
└── README.md
```

#### 各个目录说明

1. **src/** 存放所有`.asm`汇编源码。
- `main.asm`：主程序，必须包含 `end start` 指定程序入口。

- `sub.asm`：子功能模块，多个asm可以分别汇编得到obj，再一起link链接。
2. **include/** 存放 `.inc` 包含文件，等价C语言`.h`头文件。
   内容：宏定义、常量、字符串、复用的段声明。
   在asm中使用：

```asm
include macro.inc
```

3. **obj/**`masm.exe`汇编后生成`.obj`目标文件，编译中间产物，自动生成。

4. **bin/**`link.exe`链接之后，输出最终`.exe`16位DOS可执行程序。

5. **make.bat** 批处理脚本（一键构建）
   
   > 在Windows主机执行批处理，把obj、exe输出到对应目录，再拷贝到DOSBox工作目录。

```bat
@echo off
masm src\main.asm obj\main.obj;
masm src\sub.asm obj\sub.obj;
link obj\main.obj + obj\sub.obj, bin\main.exe;
echo 编译链接完成，输出 bin\main.exe
```

> link可以多个obj一起链接：`link a.obj+b.obj, output.exe;`

### 多模块项目关键点

1. 多个asm文件，**分别汇编得到各自obj**，再把多个obj输入link链接成一个exe。
2. 模块之间互相调用，需要使用`extrn`外部符号、`public`导出符号。

```asm
;main.asm中声明外部过程
extrn print_str:far

;sub.asm中将过程导出
public print_str
print_str proc far
    ;子程序代码
retf
print_str endp
```

3. `.inc`文件放公共常量、宏，不要写完整代码段。

### 重要坑点

1. ❌ 不要把obj、exe和asm源码放在同一个文件夹，文件很乱。
2. ❌ `end start` **只能写在主程序main.asm末尾**，子asm文件不要写end start。
3. ✅ obj、bin为编译产物，版本控制忽略。
4. ✅ 16位exe不能直接windows运行，必须放到DOSBox运行。

## 关键概念

1. **assume cs:code,ds:data** 只是告诉汇编器段寄存器对应哪个段，**不会修改寄存器实际值**；
   真正给ds赋值需要手动写`mov ax,data; mov ds,ax`。
2. `end start` 两件事：①标记程序结束；②指定程序入口标号start。**没有start程序不知道从哪里开始跑**。
3. int 21h：DOS系统功能调用，操作系统提供的服务。 `4ch`号功能：程序退出返回DOS。

## 报错阶段

1. **汇编阶段报错（masm）**：指令错误、寄存器错误、语法错误，例如之前遇到的`A2004 symbol type conflict`。
2. **链接阶段报错（link）**：符号未定义、缺少end start、段问题。
3. **运行时错误**：汇编链接全部成功，DOS下运行异常，比如内存乱改、段寄存器没赋值，程序卡死。

> ⚠️现代Windows不能直接运行16位exe，必须DOSBox。

## 易错坑

1. MASM 简化段模型，**千万不要忘记**：

```asm
mov ax,@data
mov ds,ax
```

忘记这两句，**DS不对，打印乱码**。

2. `ASSUME CS:CODE,DS:DATA`只是通知汇编器，**不会改变CPU寄存器**。
3. end后面必须写入口标签`end start`，否则链接器不知道程序从哪里开始。

---

## 核心易错清单（做题必记）

1. 完整段定义下，`ASSUME`不会修改DS，**必须手动mov ax,DATA → mov ds,ax**。
2. DOS `ah=09h`输出字符串，字符串**必须以`$`结尾**，否则乱码。
3. 文件末尾必须写`END 入口标签`，不能只写`END`。
4. 栈段带上`STACK`属性，链接器自动设置SS、SP，不用手动设置。
5. `lea dx,msg`等价于`mov dx,offset msg`，获取变量偏移地址。

---

## 配套小练习

1. 修改字符串内容，重新编译运行观察输出；
2. 在打印字符串之后，增加 `INT 21H` 的单字符输出功能（`AH=02H`）输出一个字符；
3. 尝试注释掉 `MOV AH,4CH / INT 21H`，看程序异常现象。

## 完整段 vs 简化段对照表

| 项目   | 完整SEGMENT段                 | 简化段 .model small           |
| ---- | -------------------------- | -------------------------- |
| 数据段  | `DATA SEGMENT … DATA ENDS` | `.data`                    |
| 代码段  | `CODE SEGMENT … CODE ENDS` | `.code`                    |
| DS赋值 | `mov ax,DATA` `mov ds,ax`  | `mov ax,@data` `mov ds,ax` |
| 入口结束 | `END START`                | `end start`                |

> 笔试、试卷大题，优先写**完整SEGMENT版本**。 

## MASM关键语法要点

1. **入口**
- NASM：`global _start`，标签`_start`

- MASM：`end start`，代码段标签名字一般写`start`，大小写不敏感。
2. **取偏移地址**

```asm
lea dx, msg    ; MASM推荐
mov dx, offset msg
```

3. **DOS功能调用不变**：
- `ah=09h`：输出`$`结尾字符串

- `ah=4Ch`：程序退出 `int 21h`
4. 注释：分号`;`开头

## NASM转MASM快速对照

| 功能    | NASM               | MASM                       |
| ----- | ------------------ | -------------------------- |
| 声明入口  | `global _start`    | `end start`                |
| 数据段   | `section .data`    | `.data` / `DATA SEGMENT`   |
| 代码段   | `section .text`    | `.code` / `CODE SEGMENT`   |
| 设置ds  | 不需要手动设置            | `mov ax,@data` `mov ds,ax` |
| 字符串结束 | 0Dh,0Ah回车换行，循环计数打印 | `$`作为字符串结束符（09h功能）         |

## 和NASM关键对比小结

| 项目       | NASM(DOS‑COM)   | MASM(EXE完整段)   |
| -------- | --------------- | -------------- |
| 数据段      | `section .data` | `DATA SEGMENT` |
| 代码段      | `section .text` | `CODE SEGMENT` |
| 入口声明     | `global _start` | `END START`    |
| DS寄存器    | com程序不用手动设置     | 必须手动赋值DS       |
| 09h字符串结束 | 不用，循环按长度输出      | 必须`$`结束        |

> 去电脑版继续完成，多端协作更高效 →

## MASM：键盘输入 + 屏幕回显示例（完整段格式）

功能：读取键盘输入一串字符，按下回车结束，把输入的内容再输出到屏幕，最后退出DOS。进一步熟悉DOS中断调用。
文件名：`input_echo.asm`

> 使用 DOS 21H 中断：0AH号功能，缓冲区输入字符串。

```asm
DATA SEGMENT
    ; 0AH功能输入缓冲区格式：
    ; 第1字节：缓冲区最大可输入字符数
    ; 第2字节：实际读到的字符数（由系统回填）
    ; 后面字节：存放输入字符
    buf db  50, ?, 50 dup(?)   ; 最多输入49个字符

    prompt db 0Dh,0Ah,'Please input your string: $'
    outmsg db 0Dh,0Ah,'You typed: $'
DATA ENDS

STACK SEGMENT STACK
    dw 100h dup(?)
STACK ENDS

CODE SEGMENT
ASSUME CS:CODE,DS:DATA,SS:STACK

START:
    ; 初始化DS
    mov ax,DATA
    mov ds,ax

    ; 1.输出提示字符串
    lea dx,prompt
    mov ah,09h
    int 21h

    ; 2.DOS 0AH号功能：键盘字符串输入
    ; DS:DX指向输入缓冲区
    lea dx,buf
    mov ah,0Ah
    int 21h

    ; 3.输出回显提示
    lea dx,outmsg
    mov ah,09h
    int 21h

    ; 修改输入字符串末尾，加上$，方便用09h输出
    xor bx,bx
    mov bl,buf+1        ; bl = 实际输入字符个数
    mov buf[bx+2],'$'   ; 在字符末尾写入$结束符

    ; 4.打印用户输入的字符串
    lea dx,buf+2        ; 真正字符从buf+2开始
    mov ah,09h
    int 21h

    ; 程序退出
    mov ah,4Ch
    int 21h
CODE ENDS
END START
```

### DOSBox编译运行

```bash
masm input_echo.asm;
link input_echo.obj;
input_echo.exe
```

运行效果示例

```plaintext
Please input your string: hello masm
You typed: hello masm
```

## 0AH输入缓冲区结构（考试高频）

```asm
buf db 50, ?, 50 dup(?)
```

- `buf[0]`：最大允许输入字符数（含回车），这里写50，最多输入49个有效字符
- `buf[1]`：**系统自动填入**，用户实际敲入的字符数量（不含回车）
- `buf[2] ~ buf[49]`：存放键入的字符，回车符会存入缓冲区，但不计入计数。

> 重点坑：
> 0AH输入得到的字符串**不带$结束符**，不能直接拿给09h打印，必须手动在末尾补`$`。

---

## MASM DOS常用21H中断速记

| AH值 | 功能        | 入口参数          |
| --- | --------- | ------------- |
| 01H | 单字符输入，回显  | 无；AL=读到字符     |
| 02H | 输出单个字符    | DL=要输出的ASCII码 |
| 09H | 输出$结尾字符串  | DS:DX=字符串首地址  |
| 0AH | 键盘字符串输入   | DS:DX=输入缓冲区   |
| 4CH | 程序退出返回DOS | AL=返回码        |

### 补充：01H单字符输入极简小片段

```asm
mov ah,01h
int 21h   ; 等待按键，按键回显到屏幕，AL保存字符
```

# MASM和其他语言对比

| 语言         | 编译器/工具      | 中间产物        | 执行载体         | 内存管理             | 显式编译命令        | 程序入口                                     |
| ---------- | ----------- | ----------- | ------------ | ---------------- | ------------- | ---------------------------------------- |
| C          | gcc         | `.o`，原生exe  | CPU直接执行      | 手动malloc/free    | ✅gcc          | `int main()`                             |
| C++        | g++         | `.o`，原生exe  | CPU直接执行      | new/delete手动     | ✅g++          | `int main()`                             |
| C#         | csc/dotnet  | IL中间语言exe   | .NET CLR JIT | GC自动回收           | ✅dotnet build | `static void Main()`                     |
| Java       | javac       | `.class`字节码 | JVM JIT      | GC自动回收           | ✅javac        | `public static void main(String[] args)` |
| Python     | python解释器   | pyc字节缓存     | PVM解释执行      | 引用计数+GC          | ❌运行时编译        | `if __name__ == "__main__"`              |
| **MASM汇编** | masm + link | `.obj`目标文件  | **CPU直接执行**  | **完全手动管理寄存器、内存** | ✅masm、link    | `end start`标号                            |

# MASM项目目录

```plaintext
masm_demo/
├── test.asm      ;汇编源码
├── obj/          ;存放 .obj
├── bin/          ;存放生成的exe
└── readme.txt
```

## 六大语言项目目录对照

| 语言     | 构建脚本             | 源码目录            | 头/包含文件           | 编译产物目录      |
| ------ | ---------------- | --------------- | ---------------- | ----------- |
| C      | Makefile         | src             | include(.h)      | obj、bin     |
| C++    | Makefile         | src             | include(.h/.hpp) | obj、bin     |
| C#     | csproj/sln       | Models/Services | 无                | obj、bin     |
| Java   | Maven pom.xml    | src/main/java   | 无                | target      |
| Python | requirements.txt | 自定义包mylib       | **init**.py      | **pycache** |
| MASM汇编 | bat批处理           | src             | include(.inc)    | obj、bin     |

---

# MASM 考试速记模板

> 两类：**完整SEGMENT段定义（大题常考）**、**简化段定义（选择填空）** 16位DOS EXE程序，MASM，重点标记考试易错点，直接背诵默写。

## 1、完整段定义模板（SEGMENT / ENDS，考试写大题优先用这个）

```asm
DATA SEGMENT
    ;========数据段：定义字符串、变量========
    ;示例字符串，09H输出必须以 $ 结尾
    str db 'test',0Dh,0Ah,'$'
DATA ENDS

STACK SEGMENT STACK
    ;栈段，开辟栈空间，STACK属性交给链接器处理SS:SP
    dw 100H DUP(?)
STACK ENDS

CODE SEGMENT
    ; ASSUME：仅汇编器映射，**不会修改CPU寄存器！！！**
    ASSUME CS:CODE, DS:DATA, SS:STACK

START:
    ;====必写！初始化DS，千万不能漏====
    mov ax,DATA
    mov ds,ax

    ;====业务逻辑写在这里====
    ;示例：09H输出字符串
    lea dx,str
    mov ah,09H
    int 21H

    ;====程序退出，固定模板====
    mov ah,4CH
    int 21H

CODE ENDS
END START   ; 文件最后一行！END后面跟入口标签START
```

### 完整段必背考点

1. `ASSUME CS:CODE,DS:DATA,SS:STACK` 只是声明，**不改变硬件寄存器**。
2. DS必须手动赋值：`mov ax,DATA` + `mov ds,ax`。
3. 栈段带上关键字 `STACK`，不用手动设置SS、SP。
4. 文件末尾：`END START`，指定程序入口，不能只写`END`。
5. `09H`输出字符串末尾必须有`$`。

---

## 2、简化段定义模板（.model small，选择填空、小题）

```asm
.model small    ;内存模型 small：1个代码段，1个数据段
.stack 100h     ;栈大小

.data
    ;数据段，变量、字符串
    str db 'hello',0Dh,0Ah,'$'

.code
start:
    ;必写：给DS赋值，@data代表简化段的数据段
    mov ax,@data
    mov ds,ax

    ;业务代码
    lea dx,str
    mov ah,09h
    int 21h

    ;退出
    mov ah,4Ch
    int 21h
end start
```

### 简化段必背考点

1. `.model small` 不能丢。
2. DS初始化：`mov ax,@data`，`mov ds,ax`。
3. 结尾 `end start`。

---

# DOS 21H 高频中断调用默写表（考试高频）

| AH  | 功能         | 入口参数            |
| --- | ---------- | --------------- |
| 01H | 单字符输入（回显）  | 返回：AL=输入字符      |
| 02H | 输出单个字符     | DL=待输出ASCII     |
| 09H | 输出`$`结尾字符串 | DS:DX = 字符串偏移地址 |
| 0AH | 字符串键盘输入    | DS:DX指向输入缓冲区    |
| 4CH | 程序退出返回DOS  | AL=返回码，一般写0     |

> 0AH输入缓冲区固定格式（大题常考）

```asm
buf db 50, ?, 50 dup(?)
; buf[0]：最大字符数；buf[1]：系统回填实际输入个数；buf+2开始存字符
; 0AH输入不会自动加$，用09H输出前要手动补 '$'
```

取偏移地址两种写法，等价：

```asm
lea dx, str
mov dx, offset str
```

---

# 考试高频坑（写代码前过一遍）

1. ❌忘记初始化DS，输出乱码。
2. ❌`ASSUME`写完就以为DS已经设置。
3. ❌09H字符串没有`$`结束符。
4. ❌文件末尾只写`END`，没有写`END START`。
5. ❌0AH输入缓冲区结构写错，忘记手动补`$`。
6. ❌混淆NASM `global _start` 和 MASM `END START`。

# 常见坑

1. 寄存器、内存不能直接内存到内存复制： `mov (rbx), (rcx)`  ❌非法，要借助寄存器中转

2. 栈向下增长，push会减小rsp，函数调用记得平衡栈

3. Linux系统调用号x86‑32和x86‑64完全不一样，不要混用

4. 汇编没有自动类型，全部是字节、字、双字、四字，自己管理长度

# 学习路线

1. 熟悉寄存器、寻址方式

2. 写简单循环、分支

3. 理解栈帧、函数调用ABI规范

4. 系统调用，读写文件

5. C语言和汇编混合，看C编译出来的汇编（ `gcc -S main.c` ）

# NASM ↔ MASM 快速区分（选择题）

| 项目       | NASM（COM）       | MASM（EXE完整段）   |
| -------- | --------------- | -------------- |
| 数据段      | `section .data` | `DATA SEGMENT` |
| 代码段      | `section .text` | `CODE SEGMENT` |
| 入口声明     | `global _start` | `END START`    |
| DS寄存器    | COM程序不用手动设置     | 必须手动设置DS       |
| 09H字符串结束 | 不用$，按长度循环输出     | 必须`$`结尾        |

---

# 极简填空版（考前快速默写草稿）

### 完整段填空版

```asm
DATA SEGMENT

DATA ENDS
STACK SEGMENT STACK
    dw ___ DUP(?)
STACK ENDS
CODE SEGMENT
ASSUME CS:___,DS:___,SS:___
START:
    mov ax,___
    mov ds,ax

    ;业务

    mov ah,4Ch
    int 21H
CODE ENDS
END ___
```

如果你需要，我可以出2道MASM完整段的编程小题（带参考答案）巩固这套模板。

# MASM 完整段编程练习题

> 全部使用**完整SEGMENT段定义格式**，考试大题风格，2道基础编程题，附带参考答案。

## 习题1

编写MASM16位DOS程序：

1. 数据段定义字符串：`'Assembly Test Program',0Dh,0Ah,'$'`
2. 使用DOS 09H功能调用输出该字符串
3. 程序正常返回DOS
   要求：写出完整可编译程序，包含数据段、栈段、代码段、ASSUME、DS初始化、END入口。

---

## 习题2

编写MASM16位DOS程序：

1. 定义输入缓冲区，最多接收30个字符；
2. 输出提示文字：`"Please input:"`；
3. 使用0AH功能读取键盘输入；
4. 在输入字符串末尾补`$`，把输入的内容打印出来；
5. 程序退出。

---

## 参考答案

### 习题1参考代码

```asm
DATA SEGMENT
    str db 'Assembly Test Program',0Dh,0Ah,'$'
DATA ENDS

STACK SEGMENT STACK
    dw 100H DUP(?)
STACK ENDS

CODE SEGMENT
ASSUME CS:CODE,DS:DATA,SS:STACK
START:
    mov ax,DATA
    mov ds,ax

    lea dx,str
    mov ah,09H
    int 21H

    mov ah,4CH
    int 21H
CODE ENDS
END START
```

### 习题2参考代码

```asm
DATA SEGMENT
    buf db 30, ?, 30 dup(?)
    prompt db 'Please input:$'
DATA ENDS

STACK SEGMENT STACK
    dw 100H DUP(?)
STACK ENDS

CODE SEGMENT
ASSUME CS:CODE,DS:DATA,SS:STACK
START:
    mov ax,DATA
    mov ds,ax

    ;输出提示
    lea dx,prompt
    mov ah,09H
    int 21H

    ;键盘输入 0AH
    lea dx,buf
    mov ah,0AH
    int 21H

    ;末尾补$
    xor bx,bx
    mov bl,buf+1
    mov buf[bx+2],'$'

    ;输出输入内容
    lea dx,buf+2
    mov ah,09H
    int 21H

    mov ah,4CH
    int 21H
CODE ENDS
END START
```

---

# MASM汇编专项练习题（16位DOS，完整段+简化段）

> 题型：判断、单选、找错题，全部是考试高频考点

## 一、判断题（对√，错×）

1. MASM中 `ASSUME CS:CODE,DS:DATA` 指令会自动把DS寄存器设置为DATA段地址。（ ）
2. MASM完整段定义，栈段定义带上`STACK`属性，链接器会自动设置SS、SP。（ ）
3. DOS中断`ah=09H`输出字符串，字符串必须以`$`作为结束标记。（ ）
4. DOS `0AH`键盘输入功能，输入结束后字符串自带`$`，可以直接交给09H输出。（ ）
5. MASM程序文件末尾 `END START`，START是代码段内的执行入口标签。（ ）
6. NASM使用`global _start`声明入口；MASM完整段EXE程序同样使用`global _start`。（ ）
7. `lea dx,msg` 和 `mov dx,offset msg` 都可以获取变量msg的偏移地址。（ ）
8. 简化段`.model small`模式下，`mov ax,@data`，`mov ds,ax`可以省略。（ ）

## 二、单选题

1. MASM完整段定义中，用来告诉汇编器段寄存器与逻辑段对应关系的伪指令是（）
   A. SEGMENT B. ASSUME C. ENDS D. END
2. DOS 21H中断，实现程序返回DOS退出，AH应该设置为（）
   A. 09H B. 0AH C. 4CH D. 01H
3. DOS 0AH字符串输入缓冲区定义 `buf db 40,?,40 dup(?)`，用户实际输入字符个数存放在（）
   A. buf B. buf+1 C. buf+2 D. buf‑1
4. MASM完整段EXE程序，对DS寄存器初始化正确的是（）
   A. mov ds,DATA
   B. mov ax,DATA ；mov ds,ax
   C. mov ds,@data
   D. assume ds:DATA
5. 下面哪一个是MASM程序正确的文件结束写法（）
   A. END
   B. END CODE
   C. END START
   D. END _start

## 三、找错题（找出代码全部错误，说明原因，完整段格式）

### 题目3‑1

```asm
DATA SEGMENT
    str db 'Hello',0Dh,0Ah
DATA ENDS

STACK SEGMENT
    dw 100h dup(?)
STACK ENDS

CODE SEGMENT
ASSUME CS:CODE,DS:DATA,SS:STACK

START:
    lea dx,str
    mov ah,09h
    int 21h

    mov ah,4Ch
    int 21h
CODE ENDS
END
```

### 题目3‑2

```asm
DATA SEGMENT
    buf db 20,?,20 dup(?)
DATA ENDS

STACK SEGMENT STACK
    dw 100h dup(?)
STACK ENDS

CODE SEGMENT
ASSUME CS:CODE,DS:DATA,SS:STACK
START:
    lea dx,buf
    mov ah,0Ah
    int 21h

    lea dx,buf+2
    mov ah,09h
    int 21h

    mov ah,4Ch
    int 21h
CODE ENDS
END START
```

## 四、简答小题

1. 简述伪指令`ASSUME`的作用，它会不会修改CPU内部段寄存器？
2. DOS 0AH功能输入缓冲区三个部分分别是什么？
3. MASM完整段与简化段中，DS分别如何初始化？

---

## 参考答案

### 一、判断题

1.× 2.√ 3.√ 4.× 5.√ 6.× 7.√ 8.×

### 二、单选题

1.B 2.C 3.B 4.B 5.C

### 三、找错题解析

#### 3‑1错误点

1. 字符串`str`没有`$`结束符，09H输出会乱码。
2. **没有初始化DS寄存器**：缺少`mov ax,DATA`、`mov ds,ax`。
3. 文件末尾`END`缺少入口标签，应写`END START`。

修正片段：

```asm
str db 'Hello',0Dh,0Ah,'$'

START:
    mov ax,DATA
    mov ds,ax
    lea dx,str
    mov ah,09h
    int 21h

    mov ah,4Ch
    int 21h
CODE ENDS
END START
```

#### 3‑2错误点

0AH输入得到的字符串没有`$`结束标记，直接用09H输出会乱码；需要取出实际字符个数，在末尾手动补`$`。

增加片段：

```asm
lea dx,buf
mov ah,0Ah
int 21h

xor bx,bx
mov bl,buf+1
mov buf[bx+2],'$'   ;补充$

lea dx,buf+2
mov ah,09h
int 21h
```

### 四、简答参考答案

1. `ASSUME`：告诉汇编器各个段寄存器对应哪一个逻辑段，用于汇编阶段语法检查；**不会修改CPU硬件寄存器**，DS等寄存器需要MOV指令手动赋值。
2. 0AH缓冲区：
   - 第1字节：缓冲区最大允许输入字符数；
   - 第2字节：系统回填用户实际输入字符数量；
   - 后续字节：存放用户输入的字符。
- 完整段：`mov ax,DATA`，`mov ds,ax`
- 简化段`.model small`：`mov ax,@data`，`mov ds,ax`

# MASM配套练习题

## 选择题

1.MASM汇编器masm把asm生成（）
A.exe B.obj C.class D.pyc

2.MASM中指定程序入口的是（）
A.main B.end start C.assume D.int 21h

3.MASM链接工具link的输入文件是（）
A.asm B.obj C.exe D.com

4.16位MASM生成exe，在现代Windows直接运行结果（）
A.正常运行 B.报错，需要DOSBox C.自动JIT D.直接编译

## 判断题

1. `.obj`目标文件可以直接在DOS运行（）
2. assume cs:code会自动修改cs寄存器的值（）
3. int 21h是DOS系统功能调用（）
4. MASM汇编完成后还需要链接步骤才可以生成exe。（）

## 简答

简述MASM汇编语言从asm源码到运行完整流程。

---

## 参考答案

选择：1.B 2.B 3.B 4.B
判断：1.× 2.× 3.√ 4.√

简答：
1.编写`.asm`汇编源文件；
2.masm汇编器将asm源码汇编生成`.obj`目标文件；
3.link链接器对obj做地址重定位，生成16位dos的`.exe`可执行文件；
4.在DOSBox(DOS环境)加载exe，CPU直接执行机器指令，调用int21h完成系统功能。

# MASM目录配套练习题

## 选择题

1.MASM汇编包含文件后缀（等价C的.h）（）
A.asm B.inc C.obj D.exe

2.MASM编译生成obj目标文件存放目录（）
A.src B.include C.obj D.bin

3.最终生成exe可执行文件输出目录（）
A.obj B.bin C.src D.include

4.多模块MASM项目，主程序的`end start`写在哪里（）
A.每个asm都写 B.仅主main.asm末尾 C.inc文件 D.obj文件

## 判断题

1. obj、bin目录属于编译产物，不提交版本控制（）
2. `.inc`文件用来存放宏、常量，作为汇编包含文件（）
3. 多个asm模块，直接include子asm，不需要分别汇编链接（）
4. link可以把多个obj文件链接成一个exe（）

## 简答

MASM项目中 `public` 和 `extrn` 的作用是什么？

---

## 参考答案

选择：1.B 2.C 3.B 4.B
判断：1.√ 2.√ 3.× 4.√

简答：

- `public`：把本文件内的标号/子程序导出，允许其他obj模块访问。
- `extrn`：声明外部符号，告诉汇编器这个标号定义在别的obj模块，供本文件调用。

---

# 自测检查清单（写完对照）

1. ✅ DATA、STACK、CODE三段完整
2. ✅ STACK段带`STACK`属性
3. ✅ 写了`ASSUME CS:CODE,DS:DATA,SS:STACK`
4. ✅ START内部：`mov ax,DATA`、`mov ds,ax`
5. ✅ 09H输出字符串末尾带`$`
6. ✅ 0AH缓冲区结构正确，输出前手动补`$`
7. ✅ 有退出 `mov ah,4Ch` `int 21h`
8. ✅ 文件末尾 `END START`

# MASM考前快速自查清单（做题写代码前过一遍）

1. 完整段：DATA、STACK(带STACK属性)、CODE三段齐全
2. 写ASSUME，但**不要忘记手动给DS赋值**
3. 09H输出字符串末尾必须有`$`
4. 0AH输入，输出前手动补`$`
5. 程序退出：`mov ah,4Ch` `int 21h`
6. 文件末尾：`END 入口标签`

# MASM README（x32/x64）

```plaintext
# 项目简介

基于 MASM（Microsoft Macro Assembler，微软宏汇编器），Windows平台，支持 **32位(x32) / 64位(x64)** 汇编程序开发。
内置3套链接方案：

1. MinGW GCC（封装ld，入门快速验证）
2. MinGW ld（原生链接器，无C运行时包装，底层学习）
3. Microsoft link.exe（VS BuildTools 原生链接器，MASM官方配套，推荐）

开发工具：VSCode + C/C++插件 + cppvsdbg调试器

> 调试特性：VSCode调试面板直接查看CPU寄存器（rax/rbx/rip / eax/ebx/eip）

# 环境依赖

## 必须安装

1. **MASM（ml.exe / ml64.exe）**
  - 来自 Visual Studio BuildTools，安装「使用C++的桌面开发」组件
  - `ml.exe`：32位汇编器；`ml64.exe`：64位汇编器
  - ⚠️ MASM工具必须在**VS开发者终端**环境运行，否则找不到ml/ml64/link
2. **MinGW-w64**（使用gcc / ld链接时才需要）
  - 编译32位程序需要完整32bit库支持
3. VSCode插件：C/C++（Microsoft官方插件，提供cppvsdbg调试）

# 关于 tasks.json 中 command 路径说明

> 本项目tasks.json上传GitHub/Gitee时，**全部直接写程序名，不硬编码绝对路径**
> 示例：`"command":"ml64"` / `"command":"link"` / `"command":"gcc"`

## 两种写法对比

1. 直接写命令名（✅推荐，仓库版本使用这个）

  - 原理：读取终端环境变量`PATH`自动搜索程序
  - 优点：可移植，其他人克隆项目不需要修改tasks.json
  - 前提：VSCode从**VS开发者终端**启动，自动注入VS工具链环境变量
2. 写死绝对路径（❌不建议提交到代码仓库，仅本地临时调试）

  ```json
  "command": "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\Bin\\x64\\ml64.exe"
```

```
- 缺点：VS安装目录每个人不一样，换电脑直接失效；提交仓库会给其他人带来麻烦
- Windows JSON路径规则：必须使用双反斜杠`\\`，单反斜杠`\`会导致JSON解析报错

## 报错处理：提示“xxx不是内部或外部命令”

二选一：

1. 【推荐】从VS开发者终端启动VSCode，自动加载ml、ml64、link环境变量；MinGW、NASM可手动添加到系统PATH，重启VSCode生效
2. 本地临时方案：command填写完整绝对路径，**提交仓库前务必改回命令名**

# 项目目录结构

```plaintext
.
├── .vscode
│ ├── tasks.json // 编译任务配置，x32/x64 + gcc/ld/mslink全套任务
│ └── launch.json // 调试配置，6套调试方案
├── src // 汇编源码目录（*.asm）
├── README.md
└── .gitignore
```

```
# 编译任务说明（Ctrl+Shift+B 调出任务列表）

> 编译产物命名规则：`文件名_位数_链接器.exe`，产物互不覆盖
> 例：`test_x64_gcc.exe`、`test_x32_mslink.exe`

## 🔹 64位(x64)任务

1. `masm-build-x64`：仅汇编，ml64生成x64 obj目标文件
2. `masm-link-x64-gcc`：汇编 + GCC链接
3. `masm-link-x64-ld`：汇编 + MinGW ld链接
4. `masm-link-x64-mslink`：汇编 + MS link.exe链接（MASM首选）
5. `build-run-x64-gcc`：汇编+链接+一键运行(GCC)
6. `build-run-x64-ld`：汇编+链接+一键运行(ld)
7. `build-run-x64-mslink`：汇编+链接+一键运行(link.exe)

## 🔹 32位(x32)任务

1. `masm-build-x32`：仅汇编，ml生成x32 obj目标文件
2. `masm-link-x32-gcc`：汇编 + GCC链接
3. `masm-link-x32-ld`：汇编 + MinGW ld链接
4. `masm-link-x32-mslink`：汇编 + MS link.exe链接（MASM首选）
5. `build-run-x32-gcc`：汇编+链接+一键运行(GCC)
6. `build-run-x32-ld`：汇编+链接+一键运行(ld)
7. `build-run-x32-mslink`：汇编+链接+一键运行(link.exe)

# 三套链接器对比

| 链接器 | 来源  | 优点  | 适用场景 |
| --- | --- | --- | --- |
| GCC | MinGW-w64 | 使用简单，自动处理入口，快速验证代码 | 快速Demo，临时测试 |
| ld  | MinGW-w64 | 底层原生链接器，无C标准库包装，贴近PE原理 | PE文件底层、操作系统原理实验 |
| link.exe | VS BuildTools | MASM官方配套，Windows原生PE链接器，兼容性最好 | MASM开发、逆向学习，**推荐默认使用** |

> ⚠️ 重要提示：MASM汇编器`ml.exe/ml64.exe`本身就依赖VS环境。无论用哪套链接器，**推荐全程从VS开发者终端启动VSCode**。

# 调试使用方法

1. 打开对应的`.asm`源码文件
2. Ctrl+Shift+B，执行编译任务生成exe
3. F5启动调试，下拉选择对应调试配置：
  - MASM x64 GCC
  - MASM x64 LD
  - MASM x64 MS Link
  - MASM x32 GCC
  - MASM x32 LD
  - MASM x32 MS Link
4. VSCode左侧调试面板，可以直接查看通用寄存器、指令指针、栈信息。

# 示例代码

## x64示例 src/test_x64.asm

```asm
; MASM x64 汇编
.code
main proc
    mov rax, 01234h
    ret
main endp
end
```

```
## x32示例 src/test_x32.asm

```asm
; MASM x32 汇编
.386
.model flat,stdcall
.code
main proc
    mov eax, 01234h
    ret
main endp
end main
```

```
# Git提交规范

```plaintext
feat: 新增xxx汇编demo
fix: 修复汇编链接报错
docs: 更新README说明
refactor: 重构汇编代码
```

```
# 常见问题排查

1. `ml/ml64不是内部命令`：必须在**VS开发者终端**启动VSCode
2. gcc `-m32`报错：MinGW缺少32位库，更换完整MinGW-w64版本
3. link.exe找不到：同上，VS开发者终端环境变量才会加载VS工具链
4. 程序直接闪退：使用F5调试，设置断点在入口函数观察寄存器
5. 寄存器窗口看不到：确认调试器选择`cppvsdbg`，不要使用gdb
6. x64 MASM语法报错：MASM x64不支持`.model flat`，语法和32位MASM差异很大

# License

MIT
```
