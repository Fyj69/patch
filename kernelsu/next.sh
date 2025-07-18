#!/bin/bash

set -e

aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_157.patch && patch -p1 -F 3 < kernel-4.9_157.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_158.patch && patch -p1 -F 3 < kernel-4.9_158.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_159.patch && patch -p1 -F 3 < kernel-4.9_159.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_1510.patch && patch -p1 -F 3 < kernel-4.9_1510.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_ksud.c.patch -d ./KernelSU-Next -o ksud.patch && patch -d KernelSU-Next -p1 --forward --fuzz=3 < ./KernelSU-Next/ksud.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_rules.c.patch -d ./KernelSU-Next -o rules.patch && patch -d KernelSU-Next -p1 --forward --fuzz=3 < ./KernelSU-Next/rules.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_selinux.c.patch -d ./KernelSU-Next -o selinux.patch && patch -d KernelSU-Next -p1 --forward --fuzz=3 < ./KernelSU-Next/selinux.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_sucompat.c.patch -d ./KernelSU-Next -o sucompat.patch && patch -d KernelSU-Next -p1 --forward --fuzz=3 < ./KernelSU-Next/sucompat.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_apk_sign.c.patch -d ./KernelSU-Next -o sign.patch && patch -d KernelSU-Next -p1 --forward --fuzz=3 < ./KernelSU-Next/sign.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_core_hook.c.patch -d ./KernelSU-Next -o hook.patch && patch -d KernelSU-Next -p1 --forward --fuzz=3 < ./KernelSU-Next/hook.patch
aria2c https://raw.githubusercontent.com/Fyj69/patch/main/next/fix_kernel_compat.c.patch -d ./KernelSU-Next -o compat.patch && patch -d KernelSU-Next -p1 --forward --fuzz=3 < ./KernelSU-Next/compat.patch
