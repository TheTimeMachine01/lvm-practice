#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/6] Creating 3 Virtual Disk Images ==="
truncate -s 1G /root/disk1.img
truncate -s 1G /root/disk2.img
truncate -s 1G /root/disk3.img
ls -lh /root/disk*.img

echo "=== [2/6] Attaching Files to Loop Block Devices ==="
LOOP0=$(losetup -fP --show /root/disk1.img)
LOOP1=$(losetup -fP --show /root/disk2.img)
LOOP2=$(losetup -fP --show /root/disk3.img)

echo "Disks attached:"
echo "  Disk 1 -> $LOOP0"
echo "  Disk 2 -> $LOOP1"
echo "  Disk 3 -> $LOOP2"

echo "=== [3/6] Initializing PVs and VG with first 2 disks ==="
pvcreate "$LOOP0" "$LOOP1"
vgcreate my_vg "$LOOP0" "$LOOP1"
vgs my_vg

echo "=== [4/6] Creating, Formatting, and Mounting Logical Volume ==="
lvcreate -L 1.5G -n data_lv my_vg
mkfs.ext4 /dev/my_vg/data_lv
mkdir -p /mnt/lvm_storage
mount /dev/my_vg/data_lv /mnt/lvm_storage
echo "Testing LVM on loop devices" > /mnt/lvm_storage/hello.txt

echo "=== [5/6] Adding Third Disk ($LOOP2) to Volume Group ==="
pvcreate "$LOOP2"
vgextend my_vg "$LOOP2"
vgs my_vg

echo "=== [6/6] Expanding LV and ext4 Filesystem to Full Capacity ==="
lvextend -r -l +100%FREE /dev/my_vg/data_lv

echo "=========================================================="
echo "Setup Complete! Current State:"
echo "=========================================================="
pvs
vgs
lvs
df -h /mnt/lvm_storage
