# 2. USB installer

The installer is a USB stick with two folders on it:

- the `EFI` folder from this repo, which contains OpenCore;
- the Sequoia recovery image, downloaded straight from Apple.

The recovery boots from the stick and downloads the full macOS from Apple during installation, so the machine needs a wired network connection. The driver for that is already in the EFI.

You can make the stick on macOS, Linux or Windows.

## What you need

- A USB stick of 4 GB or more. Everything on it will be erased.
- Python 3.
- [OpenCorePkg 1.0.8](https://github.com/acidanthera/OpenCorePkg/releases), the RELEASE zip. You only need `Utilities/macrecovery` and `Utilities/macserial` from it.
- This repo, with your serial numbers filled in. See [3. SMBIOS](03-smbios.md).

## 1. Download the Sequoia recovery

```bash
cd OpenCore-1.0.8-RELEASE/Utilities/macrecovery    # wherever you unpacked the zip
python3 macrecovery.py -b Mac-937A206F2EE63C01 -m 00000000000000000 download
```

On Windows, use `py` instead of `python3`.

This creates a folder `com.apple.recovery.boot` containing `BaseSystem.dmg` (about 850 MB) and `BaseSystem.chunklist`. The board ID above is the one used for this build, and it gave the macOS 15 Sequoia recovery.

## 2. Format the stick as FAT32

The stick needs a GUID partition table and one FAT32 partition. The examples below name it `OPENCORE`.

- **macOS:** Disk Utility → View → Show All Devices → select the stick (the device, not the volume) → Erase → Format **MS-DOS (FAT)**, Scheme **GUID Partition Map**. From the command line, check the disk number first, because the wrong number erases the wrong disk:
  ```bash
  diskutil list
  diskutil eraseDisk FAT32 OPENCORE GPT /dev/diskN
  ```
- **Linux:** use `gdisk` or `parted`: create a GPT table and one partition, then `mkfs.vfat -F 32 -n OPENCORE /dev/sdX1`.
- **Windows:** in Disk Management, delete the old partitions, convert the disk to GPT, and create one FAT32 volume. Windows refuses FAT32 above 32 GB. For a bigger stick, use [Rufus](https://rufus.ie) with "Non bootable" and FAT32.

## 3. Copy the files

The root of the stick should look like this:

```
OPENCORE/
├── EFI/
│   ├── BOOT/
│   └── OC/
└── com.apple.recovery.boot/
    ├── BaseSystem.dmg
    └── BaseSystem.chunklist
```

## 4. Let OpenCore see the stick

The `config.plist` in this repo is the one used every day from the internal SSD. Its `ScanPolicy` (`17761539`) shows only APFS volumes and EFI system partitions on internal SATA/SAS/SCSI/NVMe/PCI drives. USB devices and the recovery image are hidden, so the picker would not show the recovery on the stick.

**On the stick only**, set `ScanPolicy` to `0`, which shows everything:

```bash
plutil -replace Misc.Security.ScanPolicy -integer 0 /Volumes/OPENCORE/EFI/OC/config.plist
```

In ProperTree, the key is `Misc → Security → ScanPolicy`, and the value should be `0` (number). This is exactly the difference between the rescue stick and the internal EFI on the reference machine.

The recovery still does not show up in the picker by default, because `HideAuxiliary` is on. Press **Space** in the picker to show it (see [4. Installation](04-install.md#1-boot-the-stick)).

## 5. Check before you boot

- Your own `SystemSerialNumber`, `MLB`, `SystemUUID` and `ROM` are in `config.plist`. See [3. SMBIOS](03-smbios.md).
- The BIOS is set up as in [1. BIOS](01-bios.md).
- The network cable is plugged into the onboard port.
- The monitor is on the **DVI-D** port. VGA does not work in macOS on this platform. See [the README](../README.md#display).

Next: [4. Installation](04-install.md).
