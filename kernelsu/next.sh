#!/bin/bash

set -e

aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_157.patch && patch -p1 -F 3 < kernel-4.9_157.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_158.patch && patch -p1 -F 3 < kernel-4.9_158.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_159.patch && patch -p1 -F 3 < kernel-4.9_159.patch
aria2c https://github.com/Fyj69/patch/raw/main/kernelsu/kernel-4.9_1510.patch && patch -p1 -F 3 < kernel-4.9_1510.patch
