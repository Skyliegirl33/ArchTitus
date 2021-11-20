#!/bin/bash

bash 0-preinstall.sh
arch-chroot /mnt /root/QuackOS/1-setup.sh
source /mnt/root/QuackOS/install.conf
arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/QuackOS/2-user.sh
arch-chroot /mnt /root/QuackOS/3-post-setup.sh