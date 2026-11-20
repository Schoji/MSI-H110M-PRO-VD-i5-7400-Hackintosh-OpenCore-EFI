# 6. What is in the EFI and why

The base is OpenCore 1.0.8 (RELEASE), configured along the [Dortania Kaby Lake desktop guide](https://dortania.github.io/OpenCore-Install-Guide/config.plist/kaby-lake.html). This page lists everything that is specific to this machine, plus every value that differs from what Dortania suggests.

## Folder layout

```
EFI/
├── BOOT/
│   ├── BOOTx64.efi            OpenCore bootstrap
│   └── .contentVisibility     "Disabled" - hides this file from the picker
└── OC/
    ├── OpenCore.efi
    ├── config.plist
    ├── ACPI/                  SSDT-PLUG-DRTNIA, SSDT-EC-USBX-DESKTOP
    ├── Drivers/               OpenRuntime, HfsPlus, ResetNvramEntry, OpenCanopy, AudioDxe
    ├── Kexts/                 see below
    ├── Resources/             OpenCanopy theme, fonts, labels, boot chime
    └── Tools/                 OpenShell
```

## ACPI

The two SSDTs are Dortania's prebuilt ones for Skylake and newer desktops:

| File | What it does |
|---|---|
| `SSDT-PLUG-DRTNIA.aml` | Makes sure `X86PlatformPlugin` loads, for native CPU power management (XCPM). On macOS 12.3 and newer it loads by default anyway, so this SSDT is belt and braces. |
| `SSDT-EC-USBX-DESKTOP.aml` | Adds a fake embedded controller and USB power properties, which macOS expects. |

There are no ACPI patches.

## Kexts

| Kext | Version | Why |
|---|---|---|
| Lilu | 1.7.2 | Patching framework that the others need. |
| VirtualSMC | 1.3.8 | SMC emulation, required. |
| SMCProcessor | 1.3.8 | CPU temperatures and frequencies. |
| SMCSuperIO | 1.3.8 | Fan speed sensors from the Super I/O chip. |
| WhateverGreen | **1.7.2 + DPLL fix** | iGPU support. This is not the official build: it is [this fork's release](https://github.com/Schoji/WhateverGreen/releases/tag/v1.7.2-dpllfix), which adds `-igfxdpllfix`. Without it, sleep does not work (see [Troubleshooting](07-troubleshooting.md#sleep-machine-check-on-wake)). |
| AppleALC | 1.9.8 | Audio: Realtek ALC887 codec and HDMI audio. |
| RealtekRTL8111 | **2.5.0 + Wake-on-LAN patch** | Driver for the onboard RTL8111H network card, patched so Wake-on-LAN survives a warm restart (see [extras](../extras/README.md#rtl8111-wol-wake-on-lan-after-a-warm-restart)). |
| RestrictEvents | 1.1.6 | Kept from the installation phase. With `iMac19,1` and no `revpatch`/`revblock` boot-args it has almost nothing to do. It can probably be removed, but that was not tested. |
| USBMap | - | Codeless kext with the USB port map for this board (see below). |

## DeviceProperties

### Intel HD 630: `PciRoot(0x0)/Pci(0x2,0x0)`

| Property | Value | Why |
|---|---|---|
| `AAPL,ig-platform-id` | `00001259` (0x59120000) | Dortania's recommended Kaby Lake desktop framebuffer with the iGPU driving the display. |
| `framebuffer-patch-enable` | `01000000` | Allows the patches below. |
| `framebuffer-stolenmem` | `00003001` (19 MB) | Standard patch for a small DVMT pre-allocation. It is harmless with the 128M set in the BIOS. |
| `framebuffer-fbmem` | `00009000` (9 MB) | Same as above. |
| `framebuffer-con0/1/2-enable` | `01000000` | Allows the connector patches. |
| `framebuffer-con0/1/2-type` | `00080000` (HDMI) | **Required for the DVI-D port.** With the default connector types, the framebuffer came up but never saw the monitor on the board's DVI-D port. |
| `force-online` | `01000000` | Keeps the connectors online. |

The HD 630 (`8086:5912`) is supported natively, so there is **no** `device-id` spoof. An i3-6100 (HD 530) also worked in this board with `device-id` = `12590000`, but its sleep was never made reliable before the CPU was replaced.

The monitor is on framebuffer 1, port 6.

### Audio: `PciRoot(0x0)/Pci(0x1f,0x3)`

`layout-id` = `5` (AppleALC "Mirone 3 ports: Pink, Green, Blue").

- HDMI audio works.
- The analog jacks (rear Line Out, Mic, Line In; front headphones and mic) are detected but were never listened to.
- If they stay silent, layouts 3, 1 and 11 are the next ones to try.

### USB controller: `PciRoot(0x0)/Pci(0x14,0x0)`

`acpi-wake-type` = `01`. This is a Dortania fix for 100-series chipsets: without it, waking with a USB keyboard needs a second key press.

## USB map

The H110 controller exposes 10 USB 2.0 ports (HS01-HS10), and 4 of them also have a USB 3.0 side (SS01-SS04). That is 14 port entries, below the macOS limit of 15. So `XhciPortLimit` is off, and `USBMap.kext` lists all of them. The map is tied to the `iMac19,1` model.

| ACPI name | Connector | Where |
|---|---|---|
| HS01 + SS01, HS02 + SS02, HS07 + SS04, HS08 + SS03 | USB 3 (type 3) | rear blue ports and the USB 3 header |
| HS03-HS06, HS09, HS10 | USB 2 (type 0) | rear black ports and the USB 2 headers |

On the reference board, front port **HS09 does not work**. It gives power, but no device enumerates on it, in Linux either. This is a hardware fault on that one board, not a mapping problem.

## Boot and picker

| Setting | Value | Why |
|---|---|---|
| `Misc → Boot → PickerMode` | `External` | Graphical picker (OpenCanopy). |
| `PickerVariant` | `Acidanthera\GoldenGate` | Theme. `Syrah` and `Chardonnay` are also included. |
| `PickerAttributes` | `17` | Volume icons and mouse pointer support. |
| `Timeout` | `5` | Five seconds, then the default entry boots. |
| `ShowPicker` | `true` | Shows the picker on every boot. This makes it easy to pick another OS, or to stop the countdown with any key. |
| `HideAuxiliary` | `true` | Hides recovery and tools. Press Space in the picker to show them. |
| `Misc → Security → AllowSetDefault` | `true` | Ctrl+Enter on an entry makes it the default. |
| `ScanPolicy` | `17761539` | APFS and EFI partitions on internal drives only. **Set it to `0` on an installer or rescue stick.** |
| `SecureBootModel` | `Disabled` | Apple Secure Boot is off. |
| `BlessOverride` | `\EFI\debian\grubx64.efi` | Adds a "Debian" entry for the second OS on the reference machine. If nothing is at that path, it does nothing. Change or remove it for your own dual boot. |
| `UEFI → Output → Resolution` | `1920x1080@32` | Picker resolution. Fixed to 1080p because the capture card used for remote control lost the picture otherwise. `Max` should be fine with a normal monitor (not tested). |

**Boot chime:** `UEFI → Audio → AudioSupport = true`, played by `AudioDxe.efi` on the analog codec (`AudioCodec = 0`).

- The chime over HDMI (`AudioCodec = 2`) stays silent. The firmware drives the DVI-D port without audio.
- The analog chime was never heard, because nothing was plugged into the jacks.

## NVRAM

| Key | Value | Why |
|---|---|---|
| `boot-args` | `keepsyms=1 swd_panic=1 -igfxdpllfix` | `-igfxdpllfix` enables the sleep fix. `keepsyms=1` keeps readable panic logs. `swd_panic=1` turns a sleep/wake hang into a kernel panic, which writes a report to `/Library/Logs/DiagnosticReports/`. |
| `csr-active-config` | `00000000` | System Integrity Protection is fully on. |
| `prev-lang:kbd` | `en-US:0` | Recovery and Setup Assistant start in English with a US keyboard. |

## Quirks that differ from a blank config

- **Booter:** `AvoidRuntimeDefrag`, `EnableSafeModeSlide`, `EnableWriteUnprotector`, `ProvideCustomSlide`, `SetupVirtualMap`. All are Dortania's Kaby Lake defaults.
- **Kernel:** `DisableIoMapper`, `DisableLinkeditJettison`, `PanicNoKextDump`, `PowerTimeoutKernelPanic`, `AppleXcpmCfgLock`.
  - `AppleXcpmCfgLock` is not needed with this BIOS, because CFG Lock is disabled there. Leaving it on does no harm.
  - `DisableIoMapper` is set although VT-d is already disabled in the BIOS.
- **UEFI:** `EnableVectorAcceleration`, `ReleaseUsbOwnership`, `RequestBootVarRouting`.
