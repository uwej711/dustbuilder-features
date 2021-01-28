#!/bin/bash
# Author: Dennis Giese [dgiese at dontvacuum.me]
# Copyright 2020 by Dennis Giese
# 
# Intended to work on s5e,p5,a08,a11
#
echo "---------------------------------------------------------------------------"
echo " Roborock manual Firmware installer"
echo " Copyright 2020 by Dennis Giese [dgiese at dontvacuum.me]"
echo " Intended to work on s5e, p5, a08, a11"
echo " Use at your own risk"
echo "---------------------------------------------------------------------------"

grep -q "boot_fs=a" /proc/cmdline
if [ $? -eq 1 ]
then
   echo "(!!!) You are booted currently in the backup copy of your operation system. This installer does not supports this case!"
   exit 1
fi

grep -q "nande" /proc/cmdline
if [ $? -eq 1 ]
then
   echo "(!!!) It seems you are trying to run the installer on the wrong device."
   exit 1
fi

echo "preparing installation"
  cp /bin/busybox /tmp/busybox
  chmod +x /tmp/busybox
  ln -s /tmp/busybox /tmp/reboot
  ln -s /tmp/busybox /tmp/bash

echo "check image file size"
  maximumsize=26000000
  minimumsize=20000000
  actualsize=$(wc -c < /mnt/data/rootfs.img)
  if [ $actualsize -ge $maximumsize ]; then
    echo "(!!!) rootfs.img looks to big. The size might exceed the available space on the flash. Aborting the installation"
    exit 1
  fi
  if [ $actualsize -le $minimumsize ]; then
    echo "(!!!) rootfs.img looks to small. Maybe something went wrong with the image generation. Aborting the installation"
    exit 1
  fi

if [[ -f /mnt/data/boot.img ]]; then
  if [[ -f /mnt/data/rootfs.img ]]; then
	echo "Checking integrity"
	md5sum -c firmware.md5sum
	if [ $? -ne 0 ]; then
		echo "(!!!) integrity check failed. Firmware files are damaged. Please re-download the firmware. Aborting the installation"
		exit 1
	fi 
	echo "Start installation ..."
	echo "Installing Kernel on kernel_a"
	dd if=/mnt/data/boot.img of=/dev/nandc bs=8192
	echo "Installing Kernel on kernel_b"
	dd if=/mnt/data/boot.img of=/dev/nandd bs=8192
	rm /mnt/data/boot.img
	echo "Installing OS in system_b"
	dd if=/mnt/data/rootfs.img of=/dev/nandf bs=8192
	echo "Trying to mount system_b"
	mkdir /tmp/system_b
	mount /dev/nandf /tmp/system_b
	if [ ! -f /tmp/system_b/build.txt ]; then
	    echo "(!!!) Did not found marker in updated firmware. Update likely failed, wont update system_a."
	    exit 1
	fi
	rm /mnt/data/rootfs.img
	rm /mnt/data/firmware.md5sum
	echo "Installing OS in system_a"
	/sbin/reboot -h >/dev/null 2>&1
	/tmp/reboot -h >/dev/null 2>&1
	dd if=/dev/nandf of=/dev/nande bs=8192
	/tmp/reboot

	echo "----------------------------------------------------------------------------------"
	echo "Done, rebooting"
	echo "Dont forget to delete the installer files after rebooting"
	echo "----------------------------------------------------------------------------------"
  else
	echo "(!!!) rootfs.img not found in /mnt/data"
  fi
else
	echo "(!!!) boot.img not found in /mnt/data"
fi