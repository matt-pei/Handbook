#!/bin/bash

parted /dev/xvdb
mklabel
gpt
mkpart
primary
ext4
1
100G

