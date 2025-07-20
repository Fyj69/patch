#!/bin/bash

set -e

aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/selinux_hooks_bprm_creds.cocci && spatch --sp-file selinux_hooks_bprm_creds.cocci security/selinux/hooks.c
aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/execveat.cocci  && spatch --sp-file execveat.cocci fs/exec.c
aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/faccessat.cocci && spatch --sp-file faccessat.cocci fs/open.c
aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/vfs_read.cocci && spatch --sp-file vfs_read.cocci fs/read_write.c
aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/vfs_statx.cocci && spatch --sp-file vfs_statx.cocci fs/stat.c
aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/path_umount.cocci && spatch --sp-file path_umount.cocci fs/namespace.c
aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/input_handle_event.cocci && spatch --sp-file input_handle_event.cocci drivers/input/input.c
aria2c https://github.com/dabao1955/kernel_build_action/raw/main/kernelsu/patches/devpts_get_priv.cocci && spatch --sp-file devpts_get_priv.cocci fs/devpts/inode.c
