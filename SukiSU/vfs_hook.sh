#!/usr/bin/env bash
# Patches author: weishu <twsxtd@gmail.com>
# Shell authon: xiaoleGun <1592501605@qq.com>
#               bdqllW <bdqllT@gmail.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9
# 20240601

set -e

patch_files=(
    arch/arm/kernel/sys_arm.c
    fs/exec.c
    fs/open.c
    fs/read_write.c
    fs/stat.c
    drivers/input/input.c
    drivers/tty/pty.c
    fs/devpts/inode.c
    security/selinux/hooks.c
)

for i in "${patch_files[@]}"; do

    if grep -iq "ksu\|ksu_sid" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    fi

    case $i in

    arch/arm/kernel/sys_arm.c)
        if [ "$FIRST_VERSION" -lt 4 ] && [ "$SECOND_VERSION" -lt 18 ]; then
            sed -i '/asmlinkage int sys_execve(const char __user \*filenamei,/i \#ifdef CONFIG_KSU\nextern bool ksu_execveat_hook __read_mostly;\nextern int ksu_handle_execve_sucompat(int *fd, const char __user **filename_user,\n\t\t\t\t        void *__never_use_argv, void *__never_use_envp,\n\t\t\t\t        int *__never_use_flags);\nextern int ksu_handle_execve_ksud(const char __user *filename_user,\n\t\t\tconst char __user *const __user *__argv);\n#endif' arch/arm/kernel/sys_arm.c
            sed -i '/error = PTR_ERR(filename);/a \#ifdef CONFIG_KSU\n\tif (unlikely(ksu_execveat_hook))\n\t\tksu_handle_execve_ksud(filename, argv);\n\telse\n\t\tksu_handle_execve_sucompat((int *)AT_FDCWD, &filename, NULL, NULL, NULL);\n#endif' arch/arm/kernel/sys_arm.c
        fi
        ;;

    fs/exec.c)
        sed -i '/int do_execve(struct filename \*filename,/i\#ifdef CONFIG_KSU\nextern bool ksu_execveat_hook __read_mostly;\nextern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,\n\t\t\tvoid *envp, int *flags);\nextern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,\n\t\t\t\tvoid *argv, void *envp, int *flags);\n#endif' fs/exec.c
        sed -i '/do_execve *(/,/^}/ {
/struct user_arg_ptr envp = { .ptr.native = __envp };/a\
#ifdef CONFIG_KSU\
\tif (unlikely(ksu_execveat_hook))\
\t\tksu_handle_execveat((int *)AT_FDCWD, &filename, &argv, &envp, 0);\
\telse\
\t\tksu_handle_execveat_sucompat((int *)AT_FDCWD, &filename, NULL, NULL, NULL);\
#endif
}' fs/exec.c

        sed -i ':a;N;$!ba;s/\(return do_execveat_common(AT_FDCWD, filename, argv, envp, 0);\)/\n#ifdef CONFIG_KSU\n\tif (!ksu_execveat_hook)\n\t\tksu_handle_execveat_sucompat((int *)AT_FDCWD, \&filename, NULL, NULL, NULL); \/* 32-bit su *\/\n#endif\n\1/2' fs/exec.c
        ;;

    fs/open.c)
        if grep -q "return do_faccessat(dfd, filename, mode);" fs/open.c; then
            sed -i '/return do_faccessat(dfd, filename, mode);/i\#ifdef CONFIG_KSU\nextern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,\n\tint *flags);\n#endif' fs/open.c
        else
            sed -i ':a;N;$!ba;s/\(unsigned int lookup_flags = LOOKUP_FOLLOW;\)/\1\n#ifdef CONFIG_KSU\n\tksu_handle_faccessat(\&dfd, \&filename, \&mode, NULL);\n#endif/2' fs/open.c

        fi
        sed -i '0,/SYSCALL_DEFINE3(faccessat, int, dfd, const char __user \*, filename, int, mode)/s//#ifdef CONFIG_KSU\nextern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,\n\t\t\t                    int *flags);\n#endif\n&/' fs/open.c
        ;;

    fs/read_write.c)
        if grep -q "return ksys_read(fd, buf, count);" fs/read_write.c; then
            sed -i '/return ksys_read(fd, buf, count);/i\#ifdef CONFIG_KSU\n\tif (unlikely(ksu_vfs_read_hook))\n\t\tksu_handle_sys_read(fd, &buf, &count);\n#endif' fs/read_write.c
        else
            sed -i '0,/loff_t pos = file_pos_read(f.file);/s//loff_t pos = file_pos_read(f.file);\n#ifdef CONFIG_KSU\n\tif (unlikely(ksu_vfs_read_hook))\n\t\tksu_handle_sys_read(fd, \&buf, \&count);\n#endif/' fs/read_write.c
        fi
        sed -i '/SYSCALL_DEFINE3(read, unsigned int, fd, char __user \*, buf, size_t, count)/i\#ifdef CONFIG_KSU\nextern bool ksu_vfs_read_hook __read_mostly;\nextern int ksu_handle_sys_read(unsigned int fd, char __user **buf_ptr,\n\t\t\tsize_t *count_ptr);\n#endif' fs/read_write.c
        ;;

    fs/stat.c)
        sed -i '/#if !defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_SYS_NEWFSTATAT)/i\#ifdef CONFIG_KSU\nextern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);\n#endif' fs/stat.c
        sed -i '0,/\terror = vfs_fstatat(dfd, filename, &stat, flag);/s//#ifdef CONFIG_KSU\n\tksu_handle_stat(\&dfd, \&filename, \&flag);\n#endif\n&/' fs/stat.c
        sed -i ':a;N;$!ba;s/\(\terror = vfs_fstatat(dfd, filename, &stat, flag);\)/#ifdef CONFIG_KSU\n\tksu_handle_stat(\&dfd, \&filename, \&flag);\n#endif\n\1/2' fs/stat.c
        ;;

    drivers/input/input.c)
        sed -i '0,/void input_event(struct input_dev \*dev,/s//#ifdef CONFIG_KSU\nextern bool ksu_input_hook __read_mostly;\nextern int ksu_handle_input_handle_event(unsigned int \*type, unsigned int \*code, int \*value);\n#endif\n&/' drivers/input/input.c
        sed -i '0,/\tif (is_event_supported(type, dev->evbit, EV_MAX)) {/s//#ifdef CONFIG_KSU\n\tif (unlikely(ksu_input_hook))\n\t\tksu_handle_input_handle_event(\&type, \&code, \&value);\n#endif\n&/' drivers/input/input.c
        ;;

    drivers/tty/pty.c)
        sed -i '0,/static struct tty_struct \*pts_unix98_lookup(struct tty_driver \*driver,/s//#ifdef CONFIG_KSU\nextern int ksu_handle_devpts(struct inode*);\n#endif\n&/' drivers/tty/pty.c
        sed -i ':a;N;$!ba;s/\(\tmutex_lock(&devpts_mutex);\)/#ifdef CONFIG_KSU\n\tksu_handle_devpts((struct inode *)file->f_path.dentry->d_inode);\n#endif\n\1/2' drivers/tty/pty.c
        ;;

    fs/devpts/inode.c)
        sed -i '/struct dentry \*devpts_pty_new/,/return dentry;/ {
    /return dentry;/ {n; a\
#ifdef CONFIG_KSU\nextern int ksu_handle_devpts(struct inode*);\n#endif
    }
}
        /if (dentry->d_sb->s_magic != DEVPTS_SUPER_MAGIC)/i\
	#ifdef CONFIG_KSU\n	ksu_handle_devpts(dentry->d_inode);\n	#endif' fs/devpts/inode.c
        ;;

    security/selinux/hooks.c)
        if grep -q "^VERSION = [1-4]" Makefile; then
        sed -i '/int nnp = (bprm->unsafe & LSM_UNSAFE_NO_NEW_PRIVS);/i\    static u32 ksu_sid;\n    char *secdata;' security/selinux/hooks.c
        sed -i '/if (!nnp && !nosuid)/i\    int error;\n    u32 seclen;\n' security/selinux/hooks.c
        sed -i '/return 0; \/\* No change in credentials \*\//a\\n    if (!ksu_sid)\n        security_secctx_to_secid("u:r:su:s0", strlen("u:r:su:s0"), &ksu_sid);\n\n    error = security_secid_to_secctx(old_tsec->sid, &secdata, &seclen);\n    if (!error) {\n        rc = strcmp("u:r:init:s0", secdata);\n        security_release_secctx(secdata, seclen);\n        if (rc == 0 && new_tsec->sid == ksu_sid)\n            return 0;\n    }' security/selinux/hooks.c
        fi
        ;;
    esac

    echo "Patch applied successfully to $i"

done
