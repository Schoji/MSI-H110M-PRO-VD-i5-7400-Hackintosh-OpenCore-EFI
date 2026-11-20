# 4. Installation

> **How the reference machine was actually installed.** It had a Radeon RX 460 that never showed a picture in macOS (see [Troubleshooting](07-troubleshooting.md#radeon-rx-460-no-picture-in-any-macos)). So macOS 15 Sequoia was installed from a Linux QEMU/KVM virtual machine that was given the whole physical SSD. After that, the SSD was booted on the real hardware with this EFI.
>
> The USB path below is the standard [Dortania](https://dortania.github.io/OpenCore-Install-Guide/) way, using the same EFI and the same recovery image. This EFI did boot from a USB stick on this board, and that stick also held this recovery. However, the full install from the stick to the desktop has **not** been run end to end on this exact machine. If something differs, please open an issue.

## 1. Boot the stick

1. Plug the stick into a **rear USB port**.
2. Turn on the PC and press **F11** repeatedly until the boot menu appears.
3. Choose the entry for your stick that starts with **`UEFI:`**, for example `UEFI: SanDisk ..., Partition 1`. A stick formatted on macOS has a hidden EFI partition first, so the right one may be `Partition 2`: pick the partition that holds the `EFI` folder.

The OpenCore picker appears after a few seconds. **Press Space** to show auxiliary entries: this config hides recovery entries (`HideAuxiliary`), and the recovery on the stick counts as one. Then pick the recovery entry, usually named **macOS Base System** or **Install macOS Sequoia** (the exact label can differ), and press **Enter**.

The Apple logo and a progress bar follow. Recovery takes a minute or two to start.

## 2. Erase the target disk

1. In the recovery window, open **Disk Utility**.
2. **View → Show All Devices**.
3. Select the **whole SSD** in the sidebar (the device, not a volume under it), then click **Erase**:
   - Name: `Macintosh HD`
   - Format: **APFS**
   - Scheme: **GUID Partition Map**
4. Quit Disk Utility.

This erases the whole disk. If you want to dual boot, use a second disk for the other OS. The reference machine kept Debian on a separate HDD.

## 3. Install macOS

1. Choose **Reinstall macOS Sequoia** → Continue.
2. Accept the license and select **Macintosh HD**.
3. The installer downloads about 15 GB from Apple.

The machine restarts several times during installation. Each time, OpenCore shows the picker:

- after the first restart, pick **macOS Installer**;
- once it disappears, pick **Macintosh HD**.

Expect about an hour for this part, depending on your internet connection.

## 4. Setup Assistant

Go through the setup screens normally. **Skip signing in with your Apple Account** if you have not yet put your own serial numbers into `config.plist` (see [3. SMBIOS](03-smbios.md)). You can sign in later in System Settings.

You are now running macOS from the SSD, but OpenCore still comes from the USB stick. The next step moves OpenCore onto the SSD.

Next: [5. Post-install](05-post-install.md).
