# 5. Post-install

## Move OpenCore to the SSD

Up to now OpenCore has been starting from the USB stick. Copy it to the EFI partition of the macOS SSD, so the stick is no longer needed.

1. Find the SSD's EFI partition. It is the `EFI` partition on the disk that holds `Macintosh HD`. With more than one disk, it is not always `disk0`:
   ```bash
   diskutil list
   ```
2. Mount it (replace `disk0s1` with what you found):
   ```bash
   sudo diskutil mount disk0s1
   ```
3. Copy the `EFI` folder **from this repo** (with your serials filled in) to the root of the partition. The internal copy keeps the strict `ScanPolicy` 17761539; the `0` belongs only on the USB stick.
   ```bash
   sudo cp -R EFI /Volumes/EFI/
   ```
   If the repo is not on this Mac, copy the EFI from the USB stick instead and set the strict policy back:
   ```bash
   sudo cp -R /Volumes/OPENCORE/EFI /Volumes/EFI/
   sudo plutil -replace Misc.Security.ScanPolicy -integer 17761539 /Volumes/EFI/EFI/OC/config.plist
   ```
4. Unmount the partition:
   ```bash
   sudo diskutil unmount /Volumes/EFI
   ```

Then reboot into the BIOS and put the SSD first. In **Boot → UEFI Hard Disk Drive BBS Priorities**, set Boot Option #1 to `UEFI OS (P0: <your SSD>)`, and in the main boot order make **UEFI Hard Disk** #1 (see [1. BIOS](01-bios.md#summary)). Unplug the USB stick and boot: the picker now comes from the SSD.

Keep the USB stick as a rescue stick. If an EFI change ever breaks booting, press F11 and start from the stick.

> **Why there is no "EFI" entry in the picker.** `EFI/BOOT/.contentVisibility` contains `Disabled`. Without it, the picker shows OpenCore's own `BOOTx64.efi` as an extra "EFI" entry, and choosing it (or letting the timeout pick it) hangs the machine. For the same reason, do not create an NVRAM boot entry that points at `\EFI\BOOT\BOOTx64.efi`: MSI boots the disk from the BBS priority list anyway.

## Power settings

These are the `pmset` values the reference machine runs with. They give working sleep (S3), Wake-on-LAN, and no hibernation (unreliable on hackintoshes and not used here):

```bash
sudo pmset -a hibernatemode 0 standby 0 autopoweroff 0 powernap 0 proximitywake 0 tcpkeepalive 0
sudo pmset -a womp 1           # Wake for network access (Wake-on-LAN)
sudo pmset -a displaysleep 10
sudo rm -f /var/vm/sleepimage
```

For the idle sleep itself there are two options:

- **Simple:** set "Prevent automatic sleeping" and the sleep timer in System Settings → Energy, as on any Mac.
- **What runs here:** `sudo pmset -a sleep 0` plus [sleepkeeper](../extras/README.md#sleepkeeper-idle-sleep-that-keeps-wake-on-lan-working). It sleeps after 30 minutes without input or SSH sessions, and always arms Wake-on-LAN.

Sleep needs the **DPLL fix**. It is already enabled in this EFI by `-igfxdpllfix` in `boot-args`. Without it, every wake hangs the machine with a machine check (see [Troubleshooting](07-troubleshooting.md#sleep-machine-check-on-wake)).

**Mounted external drives block sleep.** macOS holds an `ExternalMedia` assertion while a USB stick is mounted. Eject the rescue stick or keep it unplugged.

After a CPU swap, the `pmset` values were found reset (`hibernatemode 3`, `standby 1`). Check `pmset -g` after any big hardware change.

## Wake-on-LAN

Wake-on-LAN works from sleep (about 4 seconds to wake) and from shutdown, also after a warm restart of macOS. Three things make it work:

- **BIOS:** `Resume By PCI-E Device = Enabled`, `EuP 2013 = Disabled` (see [1. BIOS](01-bios.md)).
- **Driver:** the patched RealtekRTL8111 in this EFI (see [extras](../extras/README.md#rtl8111-wol-wake-on-lan-after-a-warm-restart)).
- **macOS:** `pmset womp 1`.

From sleep, a magic packet gives a **DarkWake**: the system wakes without turning the display on, and goes back to sleep soon after. To wake it fully and keep it awake from another machine over SSH, run:

```bash
caffeinate -u -t 2
```

## Updates

- **Point releases of Sequoia (15.x):** install them by hand from System Settings → General → Software Update. Before each one, update OpenCore and the kexts if the release needs it, and keep the rescue stick up to date.
- **New major versions:** do not install them. `iMac19,1` is not supported after Sequoia, and nothing newer was tested on this hardware. On the reference machine Software Update still listed macOS 26 Tahoe once; ignore it.

To stop automatic installs but keep security and XProtect updates:

```bash
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
```

## iCloud and Apple Account

Sign in only once your own serials are in `config.plist` and the internal EFI is in place (see [3. SMBIOS](03-smbios.md)). iCloud sign-in works on the reference machine. iMessage and FaceTime were not tested.

## Optional: network fallback for 10/100 switches

If the link does not come up on a 10/100 switch, install [netkeeper](../extras/README.md#netkeeper-link-fallback-for-10100-switches). On a gigabit switch the link is fine without it.
