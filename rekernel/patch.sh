#!/bin/bash

set -eu

# Download source and patches
aria2c https://github.com/Fyj69/patch/raw/main/rekernel/src.zip
aria2c -d cocci https://raw.githubusercontent.com/Fyj69/patch/main/rekernel/patches/proc_ops.patch
aria2c -d cocci https://raw.githubusercontent.com/Fyj69/patch/main/rekernel/patches/binder.patch
aria2c -d cocci https://raw.githubusercontent.com/Fyj69/patch/main/rekernel/patches/signal.patch

# Extract source
unzip src.zip
mv -v rekernel drivers/

# Apply Coccinelle patches to C files
rekernel_file=drivers/rekernel/rekernel.c
if grep -q 'struct proc_ops' include/linux/proc_fs.h; then
    patch -p1 -F 3 < cocci/proc_ops.patch
fi

patch_files=(
    drivers/android/binder.c
    kernel/signal.c
)

for i in "${patch_files[@]}"; do
    if [ -f "$i" ]; then
        case "$i" in
            drivers/android/binder.c)
                if ! grep -q 'binder_proc_transaction() - sends a transaction to a process and wakes it up' "$i"; then
                    echo "Error: Could not find 'binder_proc_transaction()' in '$i'"
                    continue
                fi
                patch -p1 -F 3 < cocci/binder.patch
                ;;
            kernel/signal.c)
                patch -p1 -F 3 < cocci/signal.patch
                ;;
        esac
    fi
done

# Handle config files with sed
patch_configs=(
    arch/arm64/configs/defconfig
    drivers/Kconfig
    drivers/Makefile
)

for i in "${patch_configs[@]}"; do
    if grep -iq "rekernel" "$i"; then
        echo "Warning: '$i' contains Re:Kernel"
        continue
    fi

    case "$i" in
        arch/arm64/configs/defconfig)
            sed -i '$a\
CONFIG_REKERNEL=y\
CONFIG_REKERNEL_NETWORK=n' "$i"
            ;;
        drivers/Kconfig)
            # Check if the line already exists
            if ! grep -q 'source "drivers/rekernel/Kconfig"' "$i"; then
                # Find the last endmenu line
                last_endmenu=$(grep -n "endmenu" "$i" | tail -n1 | cut -d: -f1)
                if [ -n "$last_endmenu" ]; then
                    # Insert before the last endmenu
                    sed -i "${last_endmenu}i\source \"drivers/rekernel/Kconfig\"" "$i"
                else
                    # If no endmenu found, append to the end
                    echo 'source "drivers/rekernel/Kconfig"' >> "$i"
                fi
            fi
            ;;
        drivers/Makefile)
            sed -i '$a\
obj-$(CONFIG_REKERNEL) += rekernel/' "$i"
            ;;
    esac
done
