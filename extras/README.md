# Extras

Things that live outside the EFI folder: two small launch daemons and the source patch for the network driver.

## sleepkeeper: idle sleep that keeps Wake-on-LAN working

macOS's own idle sleep caused two problems on this build:

- the first automatic sleep after boot did not arm Wake-on-LAN in the RealtekRTL8111 driver, while `pmset sleepnow` always did;
- it ignored SSH sessions and put the machine to sleep during remote work.

`sleepkeeper` replaces it. Once a minute it checks for keyboard and mouse activity, SSH connections and sleep-preventing assertions such as `caffeinate`. If the machine has been idle for `IDLE_MIN` minutes, it runs `pmset sleepnow`.

You only need this if you want Wake-on-LAN, or if you use the machine over SSH. Without it, the normal Energy settings in System Settings work.

```bash
sudo cp sleepkeeper/sleepkeeper.sh /usr/local/bin/ && sudo chmod 755 /usr/local/bin/sleepkeeper.sh
sudo mkdir -p /usr/local/etc && sudo cp sleepkeeper/sleepkeeper.conf /usr/local/etc/
sudo cp sleepkeeper/local.sleepkeeper.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/local.sleepkeeper.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/local.sleepkeeper.plist
sudo pmset -a sleep 0        # sleepkeeper does the sleeping now
```

## netkeeper: link fallback for 10/100 switches

With a gigabit switch you do not need this. On a 10/100 switch the RealtekRTL8111 driver in autoselect mode never brought the link up on this board, while a link forced to 100baseTX full-duplex worked. `netkeeper` checks `en0` every 10 seconds:

- in autoselect mode with the link up, it does nothing;
- after about 20 seconds without a link, it forces 100baseTX and renews DHCP;
- if the forced link is down, it goes back to autoselect.

```bash
sudo cp netkeeper/netkeeper.sh /usr/local/bin/ && sudo chmod 755 /usr/local/bin/netkeeper.sh
sudo cp netkeeper/local.netkeeper.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/local.netkeeper.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/local.netkeeper.plist
```

## rtl8111-wol: Wake-on-LAN after a warm restart

`EFI/OC/Kexts/RealtekRTL8111.kext` is [Mieze's RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) **2.5.0** built with `rtl8111-wol.patch`.

**Why:** the stock driver treats Wake-on-LAN as available only if the card's Config3/Config5 Wake-on-LAN bits are set when the driver starts. The driver itself clears those bits when macOS restarts or shuts down. After a warm restart from macOS, Wake-on-LAN was therefore permanently disabled (Linux `ethtool` showed `Wake-on: d`). After a cold boot it worked.

**What the patch changes:**

- Wake-on-LAN capability is taken from PCI PME support only.
- `setWakeOnMagicPacket(true)` always arms magic-packet wake.

**Result:** Wake-on-LAN works from sleep and from shutdown, also after a warm restart of macOS.

**To build it yourself:**

1. Get the driver source, version 2.5.0.
2. Add [MacKernelSDK](https://github.com/acidanthera/MacKernelSDK) next to the project, as the driver's README describes.
3. Apply the patch:
   ```bash
   git apply rtl8111-wol.patch
   ```
4. Build in Xcode or with:
   ```bash
   xcodebuild -configuration Release ARCHS=x86_64 MACOSX_DEPLOYMENT_TARGET=12.0
   ```

The driver is published under GPLv2. This patch is the only change to its source.

The binary in this repo has its debug symbols stripped (`strip -S`). This only removes build paths; the code is unchanged.
