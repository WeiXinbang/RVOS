#include "syscall_numbers.h"

.section .text.start, "ax"
.globl _start
.align 2
_start:
    /*
     * a1 = 首次打印前的 sleep 毫秒数。这个程序只输出一次就退出，用来证明
     * initramfs 里可以放多个不同的用户 ELF。
     */
    beqz a1, 1f
    mv a0, a1
    li a7, SYS_SLEEP_MS
    ecall

1:
    li a0, 1
    la a1, message
    la a2, message_end
    sub a2, a2, a1
    li a7, SYS_WRITE
    ecall

    li a0, 0
    li a7, SYS_EXIT
    ecall

2:
    j 2b

.section .rodata, "a"
message:
    .ascii "user ELF once: loaded from /bin/once\r\n"
message_end:
