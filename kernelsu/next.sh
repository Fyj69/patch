#!/bin/bash

set -e

aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_157.patch && patch -p1 -F 3 < kernel-4.9_157.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_158.patch && patch -p1 -F 3 < kernel-4.9_158.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_159.patch && patch -p1 -F 3 < kernel-4.9_159.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_1510.patch && patch -p1 -F 3 < kernel-4.9_1510.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_ksud.c.patch && patch -p1 -F 3 < fix_ksud.c.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_rules.c.patch && patch -p1 -F 3 < fix_rules.c.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_selinux.c.patch && patch -p1 -F 3 < fix_selinux.c.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_sucompat.c.patch && patch -p1 -F 3 < fix_sucompat.c.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_apk_sign.c.patch && patch -p1 -F 3 < fix_apk_sign.c.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_core_hook.c.patch && patch -p1 -F 3 < fix_core_hook.c.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_kernel_compat.c.patch && patch -p1 -F 3 < fix_kernel_compat.c.patch
