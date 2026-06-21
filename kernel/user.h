#ifndef KERNEL_USER_H
#define KERNEL_USER_H

#include <stdint.h>

struct user_spawn_args
{
    const char *name;
    uint64_t arg0;
    uint64_t arg1;
    uint64_t arg2;
    uint64_t arg3;
};

/**
 * 准备并运行当前内嵌的最小用户态 demo。
 *
 * 当前用户程序来自 kernel ELF 携带的 initramfs，还不是磁盘文件系统。
 */
int user_demo_run(void);

/**
 * 从 initramfs 中加载一个用户 ELF，并创建对应 task。
 *
 * 这是后续 exec/sys_spawn 的内核侧公共入口。当前实现仍使用静态 slot，task 退出后
 * 暂不回收地址空间、栈和 slot。
 */
int user_spawn(const char *path, const struct user_spawn_args *args);

#endif
