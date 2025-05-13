#!/usr/bin/env bash
# Patches author: weishu <twsxtd@gmail.com>
# Shell authon: xiaoleGun <1592501605@qq.com>
#               bdqllW <bdqllT@gmail.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9
# 20240601

set -e

patch_files=(
    fs/devpts/inode.c
    security/selinux/hooks.c
)

for i in "${patch_files[@]}"; do

    if grep -iq "ksu\|ksu_sid" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    fi

    case $i in

    # fs/devpts/inode.c
    fs/devpts/inode.c)
        sed -i '/struct dentry \*devpts_pty_new/,/return dentry;/ {
    /return dentry;/ {n; a\
#if defined(CONFIG_KSU) && !defined(CONFIG_KSU_HOOK_KPROBES)\nextern int ksu_handle_devpts(struct inode*);\n#endif
    }
}
        /if (dentry->d_sb->s_magic != DEVPTS_SUPER_MAGIC)/i\
	#if defined(CONFIG_KSU) && !defined(CONFIG_KSU_HOOK_KPROBES)\n	ksu_handle_devpts(dentry->d_inode);\n	#endif' fs/devpts/inode.c
        ;;

    # security/selinux/hooks.c
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
