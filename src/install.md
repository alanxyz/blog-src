# Arch Linux Installation Guide

![penguin](img/linux.png)

## Introduction
This guide is intended to be an open-source and free guide for installing of Arch Linux.
You are free to modify it in any way, this guide is written using Markdown. 

## Contents
**1 What is Arch Linux?**  

**2 Pre-installation**  

**3 Installation**  
- *3.1* Make sure you use UEFI  
- *3.2* Configure a network connection  
- *3.3* Doing partitions  
- *3.4* Installing base system, making essential files  
- *3.5* Final touches, boot loader  

**3 End**  

## 1 What is Arch Linux?
Arch Linux is a [GNU/Linux](https://pastebin.com/raw/7mq2kKqC) distribution that lets you the user create their own experience. It is a relatively lightweight distribution that allows the user to choose what they want to use, so you can install a system with only the essentials.

## 2 Pre-installation
To download the Arch Linux Installation Medium, head over to https://www.archlinux.org/download/ and download from the closest mirror to you.
When you are done downloading the ISO, use a writing utility, on Windows you should use Rufus, on a Unix System (basically every other OS), dd. Now boot into the installation medium, by going into your BIOS and booting into the device with the ISO written onto it. 

## 3 Installation
It's installation time! Get ready. It's gonna be hard.

### 3.1 Make sure you use UEFI
To check if you are on UEFI, run this command 
`ls /sys/firmware/efi/efivars`
If you do not get any error, you are in UEFI mode, if you do get one, reboot into the USB as UEFI or else you will not be able to use the bootloader part of this guide.

### 3.2 Configure a network connection
- Ensure your network interface is listed and enabled, in this example with [ip-link](https://jlk.fjfi.cvut.cz/arch/manpages/man/ip-link.8)
  `ip link`
- For wireless, make sure the wireless card is not blocked with [rfkill](https://wiki.archlinux.org/index.php/Network_configuration/Wireless#Rfkill_caveat)
- Connect to the network:
  - Ethernet - Plug in the cable
  - Wi-Fi - Authenticate to the wireless network using [iwctl](https://wiki.archlinux.org/index.php/Iwctl)
- The connection can be verified using [ping](https://en.wikipedia.org/wiki/ping_(networking_utility))
  `ping google.com`

### 3.3 Checking drive labels and setting up partitions

#### Quick time synchronisation 

Before we get into partitioning, run a quick command to make sure the system clock is accurate. 
`timedatectl set-ntp true`

When disks are recognized by the live system, they are assigned to a block device, such as `/dev/sda`, `/dev/nvme0n1`, etc. You can identify these devices by running [lsblk](https://wiki.archlinux.org/index.php/Lsblk) or in our case, fdisk. 
`fdisk -l`
You may ignore results which end in `rom`, `loop`, `airoot`. 

The partition layout we will be using is the following. 
```  
| Mount Point | Partition           | Partition Type       | Suggested Size          |  
|-------------|---------------------|----------------------|-------------------------|  
| /mnt/efi    | /dev/efi_partition  | EFI System Partition | 512MiB                  |  
| [SWAP]      | /dev/swap_partition | Linux Swap           | More than 512MiB        |  
| /mnt        | /dev/root_partition | Linux Filesystem     | Remainder of the device |  
```  
#### How to modify partition tables
Use a tool such as fdisk or gparted. In this example, we will be using fdisk.
Get the identifier of your block device, in my example `/dev/sda` and do `fdisk /dev/sda` (replace /dev/sda with your block device).
This guide is going to assume that you have nothing on this drive.
`g` This makes the drive use GPT.  
`n` This prompts to make a new partition.    
`ENTER` We do not want a First Sector.  
`512M` We want this partition to be 512MiB as this will be our EFI Partition.   
`t` This will prompt the partition for changing it's type. We will want to make it an EFI Partition.  
`1` In the listing, EFI Partition is 1.  
We have made an EFI Partition!  
Let's repeat the process to make a SWAP Partition.  
`n` This prompts to make a new partition.  
`ENTER` We do not want a First Sector.  
Now you have your own choice, SWAP is like virtual RAM, I reccomend using more than 512MiB and usually 4GiB. In this example I will use 4GiB.  
`4G` This wil make the partition 4GiB.  
`t`  
`2` This will select the second partition, AKA our SWAP.  
`19` This will make the partition a SWAP Partition.  
Yay! We made an EFI and SWAP partition, now is the easy one.  
`n` This will make a new partition.  
`ENTER` We do not want a first sector.  
`ENTER` This will make the partition use the rest of the space on the disk.  
We have made a Linux Filesystem partition, this is what it needs to be. 
`w` Save our changes and quit.
Phew! We're done with that. 

#### Format the partitions

Alright, so take your block device and put it into fdisk. Like this, `fdisk -l /dev/sda` Change `/dev/sda` according to your block device, not every system is equal! You should see 3 partitions. In my example, `/dev/sda1` is EFI, `/dev/sda2` is SWAP, `/dev/sda3` is Root. 

- Let's format our EFI partition. `mkfs.fat -F 32 -n boot /dev/sda1` This will make an EFI Partition with a FAT32 Filesystem along with a label "boot", this will simplify things later.  
- Let's format our SWAP partition. `mkswap -L swap /dev/sda2` This will make a SWAP Partition with a SWAP Filesystem and a label of "swap". 
- Let's format our Root partition. `mkfs.ext4 -L root /dev/sda3` This will make a Root Partition with an EXT4 Filesystem and a label of "root". 

That's formatting done! 

#### Mounting the partitions / filesystems
Let's mount and take our labels to use, shall we?
`mount /dev/disk/by-label/root /mnt` This will mount our root partition to `/mnt`.
`mkdir /mnt/efi && mount /dev/disk/by-label/boot /mnt/efi` This will make a folder named `efi` on our Root partition and mounts the EFI partition there.
`swapon /dev/disk/by-label/swap` This enables our SWAP partition, gotta make it do something.

### 3.4 Installing base system, making essential files 
Alright, let's install the base system packages.  
`pacstrap /mnt base linux linux-firmware man nano vim` You may also want to include packages like `nvidia`, `nvidia-dkms` and `linux-headers` for NVIDIA GPU drivers, etc. If you are using Ethernet and DHCP (if you don't know what this is, then I assume you are using it), then also include `dhcpcd`.  

Now lets make an fstab file, this basically defines where each partition is mounted, settings about it  
`genfstab -U /mnt >> /mnt/etc/fstab` 
