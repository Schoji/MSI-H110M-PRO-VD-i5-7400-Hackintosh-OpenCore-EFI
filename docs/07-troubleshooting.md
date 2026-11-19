# 7. Troubleshooting and lessons learned

Problems that came up while building this machine, roughly in the order they appeared.

## Radeon RX 460: no picture in any macOS

**Symptom:** the machine boots, but there is no picture on any output. The recovery and the installer reach the GUI with no display. The kernel log shows `AMD9500Controller::start(GFX0) failed` about 0.75 s after boot.

**Cause:** the card itself. It was an XFX RX 460 2 GB with an OEM, passively cooled VBIOS (`113-BAFFIN_PRO_160621_D5_2G_MIC_NOFAN_W8`). The failure was identical in Monterey, Sequoia and Tahoe, and the card had problems under Linux too.

**Tried without success:**

- other cables, outputs, and running without the HDMI splitter;
- CSM on and off;
- WhateverGreen on and off;
- `-radvesa`, `-wegnoegpu`, `agdpmod=pikera`;
- four SMBIOS models;
- a `device-id` spoof;
- injecting the retail VBIOS as `ATY,bin_image`.

**Solution:** the card was removed, and the build uses the iGPU. Note that Polaris cards (RX 4xx/5xx) do not work in macOS 26 Tahoe at all, so check your GPU against the target macOS first.

## iGPU: framebuffer up, but the monitor stays black

**Symptom:** with the iGPU on Sequoia, the system boots and the framebuffers load, but the monitor on the DVI-D port shows nothing.

**Solution:** set all connectors to type HDMI with `framebuffer-con0/1/2-type` = `00080000` (see [config](06-config-explained.md#intel-hd-630-pciroot0x0pci0x20x0)). DVI is electrically close to HDMI, and the default connector types did not match the board's port.

VGA does not work at all. macOS has had no analog output since Skylake.

## Sleep: machine check on wake

**Symptom:** the machine sleeps fine, but every wake with the monitor on hangs it hard. It needs a hard power-off. There is no panic log, or there is a `Sleep Wake failure` / machine check (`IA32_MC4_STATUS 0xba00000011000402`, a PCU error).

- It happened on both the HD 530 (i3-6100) and the HD 630 (i5-7400).
- Changing C-States in the BIOS made it rarer, but did not fix it.

**Cause:** a bug in Apple's framebuffer driver on Skylake and Kaby Lake. After S3 the display PLL (DPLL) that clocks the HDMI/DVI port is reset, and on wake the driver has to program it from scratch:

1. It **enables the PLL before writing its configuration** (the configuration registers are zero after S3).
2. It waits only about 2 ms for the PLL to lock, but the PLL needs about 2.5 ms.
3. The PLL never locks, the display pipe is enabled anyway on an unclocked port, and the CPU raises a machine check.

On a cold boot the bug does not appear, because the driver inherits the PLL that the firmware already set up. Linux does it in the right order and waits up to 5 ms.

**Solution:** WhateverGreen with the DPLL fix, enabled with `-igfxdpllfix`. It is already in this EFI. Source and details: [Schoji/WhateverGreen](https://github.com/Schoji/WhateverGreen/tree/dpll-wake-fix).

## Wake-on-LAN works after a cold boot, but not after a restart

**Cause:** the RealtekRTL8111 driver decides at start whether Wake-on-LAN is available, based on bits in the card that the driver itself clears on restart and shutdown.

**Solution:** the patched driver in this EFI. See [extras](../extras/README.md#rtl8111-wol-wake-on-lan-after-a-warm-restart).

## First automatic sleep does not arm Wake-on-LAN, or the Mac sleeps during SSH work

**Solution:** [sleepkeeper](../extras/README.md#sleepkeeper-idle-sleep-that-keeps-wake-on-lan-working) instead of the built-in idle sleep.

## Machine never sleeps

Check what is holding it awake:

```bash
pmset -g assertions
```

What came up here:

- **A mounted USB stick** (`ExternalMedia`). Eject it, or keep it unplugged. An `/etc/fstab` entry with `noauto` did not always stop macOS from mounting it.
- **A stuck key from a USB KVM.** macOS sees constant input and the idle time stays at 0 s. Check it with `ioreg -c IOHIDSystem | grep HIDIdleTime`.
- `bluetoothd` takes short assertions all the time even with no Bluetooth hardware. They do not block sleep.

## An "EFI" entry in the picker hangs the machine

That entry is OpenCore itself: `\EFI\BOOT\BOOTx64.efi`. Choosing it starts OpenCore inside OpenCore, which hangs.

The fix is already in this EFI: `EFI/BOOT/.contentVisibility` containing `Disabled`. Also, do not add NVRAM boot entries pointing at it.

## No network link

- On a **10/100 switch** the RTL8111H driver in autoselect mode never brought the link up. Forcing 100baseTX full-duplex worked. Use [netkeeper](../extras/README.md#netkeeper-link-fallback-for-10100-switches), or a gigabit switch.
- On a **gigabit switch** autoselect gives 1000baseT with no extra steps.

## BIOS settings and pmset suddenly back to defaults

**Swapping the CPU resets the BIOS**, and the same is true for clearing CMOS or replacing the battery. After the swap from the i3-6100 to the i5-7400, these values came back as defaults:

- `CFG Lock = Enabled`;
- `Restore after AC Power Loss = Power Off`;
- `Resume By PCI-E/USB = Disabled`.

macOS `pmset` was reset at the same time (`hibernatemode 3`, `standby 1`). Go through [1. BIOS](01-bios.md) and the [power settings](05-post-install.md#power-settings) again after any such change. The boot order with OpenCore survived.

## Apple Account sign-in spins forever

**Symptom:** after macOS asked to sign in to the Apple Account again, the sign-in sheet spun endlessly, and System Settings did not respond at all. In this case `System Settings` was hung at 100% CPU.

**Solution:** close it and restart the sign-in service, then sign in again:

```bash
killall "System Settings" AppleIDSettings
killall -9 akd       # launchd starts it again
```

If it keeps happening, check that serial, MLB, ROM and the network card did not change:

```bash
system_profiler SPHardwareDataType
nvram 4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:MLB
ioreg -l | grep IOBuiltin
```

## Useful commands

```bash
# what is preventing sleep
pmset -g assertions
# last sleep/wake reasons
pmset -g log | grep -E "Sleep|Wake|DarkWake" | tail -20
# boot-args and loaded kexts
nvram boot-args
kmutil showloaded --list-only 2>/dev/null | grep -v com.apple
# mount the EFI partition of the internal SSD
sudo diskutil mount disk0s1
```
