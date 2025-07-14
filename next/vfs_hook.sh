#!/usr/bin/env bash
# Patches author: weishu <twsxtd@gmail.com>
# Shell authon: xiaoleGun <1592501605@qq.com>
#               bdqllW <bdqllT@gmail.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9
# 20240601

set -e

patch_files=(
    arch/arm/kernel/sys_arm.c
    fs/namespace.c
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

    drivers/tty/pty.c)
        sed -i '0,/static struct tty_struct \*pts_unix98_lookup(struct tty_driver \*driver,/s//#ifdef CONFIG_KSU\nextern int ksu_handle_devpts(struct inode*);\n#endif\n&/' drivers/tty/pty.c
        sed -i ':a;N;$!ba;s/\(\tmutex_lock(&devpts_mutex);\)/#ifdef CONFIG_KSU\n\tksu_handle_devpts((struct inode *)file->f_path.dentry->d_inode);\n#endif\n\1/2' drivers/tty/pty.c
        ;;

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
