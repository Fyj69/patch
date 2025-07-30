#!/bin/bash
# Patches author: backslashxx @ Github
# Shell authon: JackA1ltman <cs2dtzq@163.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9, 4.4, 3.18, 3.10, 3.4
# 20250309

patch_files=(
    fs/exec.c
    fs/open.c
    fs/read_write.c
    fs/stat.c
    fs/namespace.c
    fs/devpts/inode.c
    drivers/input/input.c
    security/security.c
    security/selinux/hooks.c
)

PATCH_LEVEL="1.5"
KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')

echo "Current patch version:$PATCH_LEVEL"

for i in "${patch_files[@]}"; do

    if grep -q "ksu" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    fi

    case $i in

    # fs/ changes
    fs/exec.c)
        sed -i '/static int do_execveat_common/i\#ifdef CONFIG_KSU\nextern bool ksu_execveat_hook __read_mostly;\nextern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,\n			void *envp, int *flags);\nextern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,\n				 void *argv, void *envp, int *flags);\n#endif' fs/exec.c
        if grep -q "return __do_execve_file(fd, filename, argv, envp, flags, NULL);" fs/exec.c; then
            sed -i '/return __do_execve_file(fd, filename, argv, envp, flags, NULL);/i\	#ifdef CONFIG_KSU\n	if (unlikely(ksu_execveat_hook))\n		ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);\n	else\n		ksu_handle_execveat_sucompat(&fd, &filename, &argv, &envp, &flags);\n	#endif' fs/exec.c
        else
            sed -i '/if (IS_ERR(filename))/i\	#ifdef CONFIG_KSU\n	if (unlikely(ksu_execveat_hook))\n		ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);\n	else\n		ksu_handle_execveat_sucompat(&fd, &filename, &argv, &envp, &flags);\n	#endif' fs/exec.c
        fi
        ;;

    fs/open.c)
        if grep -q "long do_faccessat(int dfd, const char __user \*filename, int mode)" fs/open.c; then
            sed -i '/long do_faccessat(int dfd, const char __user \*filename, int mode)/i\#ifdef CONFIG_KSU\nextern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,\n			 int *flags);\n#endif' fs/open.c
        else
            sed -i '/SYSCALL_DEFINE3(faccessat, int, dfd, const char __user \*, filename, int, mode)/i\#ifdef CONFIG_KSU\nextern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,\n			 int *flags);\n#endif' fs/open.c
        fi
        sed -i '/if (mode & ~S_IRWXO)/i\	#ifdef CONFIG_KSU\n	ksu_handle_faccessat(&dfd, &filename, &mode, NULL);\n	#endif\n' fs/open.c
        ;;

    fs/read_write.c)
        sed -i '/ssize_t vfs_read(struct file/i\#ifdef CONFIG_KSU\nextern bool ksu_vfs_read_hook __read_mostly;\nextern int ksu_handle_vfs_read(struct file **file_ptr, char __user **buf_ptr,\n		size_t *count_ptr, loff_t **pos);\n#endif' fs/read_write.c
        sed -i '/ssize_t vfs_read(struct file/,/ssize_t ret;/{/ssize_t ret;/a\
    #ifdef CONFIG_KSU\
    if (unlikely(ksu_vfs_read_hook))\
        ksu_handle_vfs_read(&file, &buf, &count, &pos);\
    #endif
        }' fs/read_write.c
        ;;

    fs/stat.c)
        if grep -q "int vfs_statx(int dfd, const char __user \*filename, int flags," fs/stat.c; then
            sed -i '/int vfs_statx(int dfd, const char __user \*filename, int flags,/i\#ifdef CONFIG_KSU\nextern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);\n#endif' fs/stat.c
            sed -i '/unsigned int lookup_flags = LOOKUP_FOLLOW | LOOKUP_AUTOMOUNT;/a\\n	#ifdef CONFIG_KSU\n	ksu_handle_stat(&dfd, &filename, &flags);\n	#endif' fs/stat.c
        else
            sed -i '/int vfs_fstatat(int dfd, const char __user \*filename, struct kstat \*stat,/i\#ifdef CONFIG_KSU\nextern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);\n#endif\n' fs/stat.c
            sed -i '/if ((flag & ~(AT_SYMLINK_NOFOLLOW | AT_NO_AUTOMOUNT |/i\	#ifdef CONFIG_KSU\n	ksu_handle_stat(&dfd, &filename, &flag);\n	#endif\n' fs/stat.c
        fi
        ;;

    # drivers/input changes
    ## input.c
    drivers/input/input.c)
        sed -i '/static void input_handle_event/i\#ifdef CONFIG_KSU\nextern bool ksu_input_hook __read_mostly;\nextern int ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);\n#endif\n' drivers/input/input.c
        sed -i '/int disposition = input_get_disposition(dev, type, code, &value);/a\	#ifdef CONFIG_KSU\n	if (unlikely(ksu_input_hook))\n		ksu_handle_input_handle_event(&type, &code, &value);\n	#endif' drivers/input/input.c
        ;;

    # security/ changes
    ## security.c
    security/security.c)
        if [ "$FIRST_VERSION" -lt 4 ] && [ "$SECOND_VERSION" -lt 18 ]; then
            sed -i '/#ifdef CONFIG_BPF_SYSCALL/i \#ifdef CONFIG_KSU\nextern int ksu_handle_prctl(int option, unsigned long arg2, unsigned long arg3,\n\t\t   unsigned long arg4, unsigned long arg5);\nextern int ksu_handle_rename(struct dentry *old_dentry, struct dentry *new_dentry);\nextern int ksu_handle_setuid(struct cred *new, const struct cred *old);\n#endif' security/security.c
            sed -i '/if (unlikely(IS_PRIVATE(old_dentry->d_inode) ||/i \#ifdef CONFIG_KSU\n\tksu_handle_rename(old_dentry, new_dentry);\n#endif' security/security.c
            sed -i '/return security_ops->task_fix_setuid(new, old, flags);/i \#ifdef CONFIG_KSU\n\tksu_handle_setuid(new, old);\n#endif' security/security.c
            sed -i '/return security_ops->task_prctl(option, arg2, arg3, arg4, arg5);/i \#ifdef CONFIG_KSU\n\tksu_handle_prctl(option, arg2, arg3, arg4, arg5);\n#endif' security/security.c
        fi
        ;;

    ## selinux/hooks.c
    security/selinux/hooks.c)
        if [ "$FIRST_VERSION" -lt 4 ] && [ "$SECOND_VERSION" -lt 11 ]; then
            sed -i '/static int selinux_bprm_set_creds(struct linux_binprm \*bprm)/i \#ifdef CONFIG_KSU\nextern bool is_ksu_transition(const struct task_security_struct \*old_tsec,\n\t\t\tconst struct task_security_struct \*new_tsec);\n#endif' security/selinux/hooks.c
            sed -i '/new_tsec->exec_sid = 0;/a \#ifdef CONFIG_KSU\n\t\tif (is_ksu_transition(old_tsec, new_tsec))\n\t\t\treturn 0;\n#endif' security/selinux/hooks.c
        elif [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 10 ]; then
            sed -i '/static int check_nnp_nosuid(const struct linux_binprm \*bprm,/i \#ifdef CONFIG_KSU\nextern bool ksu_execveat_hook __read_mostly;\nextern bool is_ksu_transition(const struct task_security_struct \*old_tsec,\n\t\t\t\tconst struct task_security_struct \*new_tsec);\n#endif' security/selinux/hooks.c
            sed -i '/rc = security_bounded_transition(old_tsec->sid, new_tsec->sid);/i \#ifdef CONFIG_KSU\n\tif (is_ksu_transition(old_tsec, new_tsec))\n\t\treturn 0;\n#endif' security/selinux/hooks.c
        fi
        ;;

    # fs/ changes
    ## fs/namespace.c
    fs/namespace.c)
        if [[ $(grep -c "static int can_umount(const struct" fs/namespace.c) == 0 ]]; then
            if grep -q "may_mandlock(void)" fs/namespace.c; then
                umount='may_mandlock(void)/,/^}/ { /^}/ {n;a'
            else
                umount='int ksys_umount(char __user \*name, int flags)/i'
            fi
        sed -i "/${umount} \
#ifdef CONFIG_KSU\n\
static int can_umount(const struct path *path, int flags)\n\
{\n\
    struct mount *mnt = real_mount(path->mnt);\n\
\n\
    if (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\
        return -EINVAL;\n\
    if (!may_mount())\n\
        return -EPERM;\n\
    if (path->dentry != path->mnt->mnt_root)\n\
        return -EINVAL;\n\
    if (!check_mnt(mnt))\n\
        return -EINVAL;\n\
    if (mnt->mnt.mnt_flags & MNT_LOCKED) /* Check optimistically */\n\
        return -EINVAL;\n\
    if (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\
        return -EPERM;\n\
    return 0;\n\
}\n\
\n\
int path_umount(struct path *path, int flags)\n\
{\n\
    struct mount *mnt = real_mount(path->mnt);\n\
    int ret;\n\
\n\
    ret = can_umount(path, flags);\n\
    if (!ret)\n\
        ret = do_umount(mnt, flags);\n\
\n\
    /* we must not call path_put() as that would clear mnt_expiry_mark */\n\
    dput(path->dentry);\n\
    mntput_no_expire(mnt);\n\
    return ret;\n\
}\n\
#endif
}}" fs/namespace.c
        fi
        ;;

    # fs/devpts changes
    ## inode.c
    fs/devpts/inode.c)
        sed -i '/struct dentry \*devpts_pty_new/,/return dentry;/ {
    /return dentry;/ {n; a\
#ifdef CONFIG_KSU\nextern int ksu_handle_devpts(struct inode*);\n#endif
    }
}
        /if (dentry->d_sb->s_magic != DEVPTS_SUPER_MAGIC)/i\
	#ifdef CONFIG_KSU\n	ksu_handle_devpts(dentry->d_inode);\n	#endif' fs/devpts/inode.c
        ;;
    esac

    echo "Patch applied successfully to $i"

done
