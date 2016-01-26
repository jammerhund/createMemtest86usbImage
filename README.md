# createMemtest86+usbImage

A small Bash script for creating a bootable Memtest86+ image. The background is, that the original ISO images from http://www.memtest.org/ are only bootalble from a CD, but not from a USB stick.

You need the following tools installed to run the script: dd, parted, syslinux, mkdosfs, wget, gzip

At the moment there are no error checks! It's only a quick & dirty hack.

## License
createMemtest86+usbImage is licensed under the GNU GPL Version 3.0. [View the license file](LICENSE)

Copyright 2016 Matthias Scholz
