#!/bin/bash
# A small Bash script for creating a bootable Memtest86+ image.
# The background is, that the original ISO images from http://www.memtest.org/
# are only bootalble from a CD, but not from a USB stick.
#
# You need the following tools installed to run the script: dd, parted, syslinux, mkdosfs, wget, gzip
#
# At the moment there are no error checks! It's only a quick & dirty hack.
#
# For more informations about that see http://forum.canardpc.com/threads/28875-Linux-HOWTO-Boot-Memtest-on-USB-Drive
#
# Licence:
#    Copyright (C) 2016 Matthias Scholz
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


IMAGE_FILE="memtest86+.iso"
IMAGE_SIZE="300K"
MBR_BIN="/usr/lib/syslinux/mbr.bin"
MEMTEST_DOWNLOAD="http://www.memtest.org/download/5.01/memtest86+-5.01.bin.gz"

echo "creating empty image ${IMAGE_FILE}"
dd if=/dev/zero of=${IMAGE_FILE} bs=${IMAGE_SIZE} count=1 2>/dev/null
echo "creating partition table on ${IMAGE_FILE}"
parted -s ${IMAGE_FILE} mklabel msdos
parted -s ${IMAGE_FILE} mkpart primary fat16 0 100% >/dev/null
parted -s ${IMAGE_FILE} set 1 boot on

echo -n "do losetup ${IMAGE_FILE} to "
p=$(parted -m -s ${IMAGE_FILE} unit B print | grep '^1:' | sed 's/B//g ; s/:/ /g')
read part start end size rest <<< ${p}
loopdev=$(losetup --offset ${start} --sizelimit ${size} --show -f ${IMAGE_FILE})
echo ${loopdev}

temp_mount=$(mktemp -d)

echo "making filesystem on ${loopdev}"
mkdosfs ${loopdev} >/dev/null
echo "running syslinux on ${loopdev}"
syslinux ${loopdev}
echo "mounting ${loopdev} to ${temp_mount}"
mount ${loopdev} ${temp_mount}
echo "creating syslinux.cfg"
cat > ${temp_mount}/syslinux.cfg <<EOF
default memtest
label memtest
kernel memtest
EOF

echo "downloading memtest86+ from ${MEMTEST_DOWNLOAD}"
wget -O /tmp/memtest.gz "${MEMTEST_DOWNLOAD}" 2>/dev/null
echo "copy memtest to ${temp_mount}"
gzip -d /tmp/memtest.gz
cp -a /tmp/memtest ${temp_mount}
rm -f /tmp/memtest

echo "umounting ${loopdev}"
sleep 3
umount ${loopdev}
rmdir ${temp_mount}

echo "integrating MBR into ${IMAGE_FILE}"
mbrSize=$(stat -c "%s" ${MBR_BIN})
mv ${IMAGE_FILE} ${IMAGE_FILE}_
(cat ${MBR_BIN} && dd if=${IMAGE_FILE}_ bs=1 skip=${mbrSize} 2>/dev/null) > ${IMAGE_FILE}
rm ${IMAGE_FILE}_

echo "closing ${loopdev}"
losetup -d ${loopdev}

echo "DONE with ${IMAGE_FILE} :-)"
echo "Now you can run \"dd if=${IMAGE_FILE} of=/dev/<your_USB_stick>\" to copy the bootable Memtest86+ image to your USB stick."
exit
