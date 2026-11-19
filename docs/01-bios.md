# 1. BIOS settings

The board uses MSI Click BIOS 5, version **`E7996IMS.2H0`** (2018-06-16). Other versions may name or place things a little differently.

- **Del** opens the BIOS.
- **F11** opens the one-time boot menu.
- In the BIOS, the arrow keys switch tabs, **Enter** opens a setting, **Esc** goes back, and **F10** saves and exits.

> **Swapping the CPU, clearing CMOS or replacing the battery resets these settings to defaults.** After a CPU swap, `CFG Lock`, the wake options and the power-loss behavior had to be set again. Come back to this page after any of those.

Settings marked **required** are needed by macOS. The rest are what the reference machine uses, with the reason given.

<!-- BIOS-SCREENS -->

## Summary

| Where | Setting | Value | |
|---|---|---|---|
| Advanced → Integrated Graphics Configuration | Initiate Graphic Adapter | **IGD** | required without a graphics card |
| | Integrated Graphics Share Memory (DVMT) | **128M** | recommended (64M also worked with the framebuffer patches) |
| Advanced → USB Configuration | XHCI Hand-off | **Enabled** | required |
| | Legacy USB Support | Enabled | |
| Advanced → Windows OS Configuration | Windows 8.1/10 WHQL Support | **Enabled** | UEFI boot only, no CSM |
| | MSI Fast Boot / Fast Boot | **Disabled** | required, otherwise USB is not ready for OpenCore |
| Advanced → Windows OS Configuration → Secure Boot | Secure Boot Support | **Disabled** | required |
| Advanced → Power Management Setup | EuP 2013 | **Disabled** | needed for Wake-on-LAN and USB wake from sleep |
| | Restore after AC Power Loss | Power On | personal choice: the PC starts when power returns |
| Advanced → Wake Up Event Setup | Wake Up Event By | BIOS | |
| | Resume By PCI-E Device | **Enabled** | Wake-on-LAN |
| | Resume By USB Device | Enabled | wake from USB keyboard/mouse |
| | Resume By RTC Alarm, PS/2 | Disabled | |
| Overclocking → CPU Features | Intel Virtualization Tech | Enabled | |
| | Intel VT-D Tech | **Disabled** | required (or keep `DisableIoMapper`) |
| | CFG Lock | **Disabled** | recommended, gives native power management without patching |
| | Intel C-State | Auto | |
| | C1E Support | Disabled | |
| | Package C State Limit | Auto | |
| | SW Guard Extensions (SGX) | Disabled | |
| Boot | Boot Option #1 | UEFI Hard Disk | |
| Boot → UEFI Hard Disk Drive BBS Priorities | Boot Option #1 | `UEFI OS (P0: <macOS SSD>)` | that entry is OpenCore on the SSD |

**About C-States:** disabling Intel C-State made the old wake crashes rarer, but did not fix them. With the DPLL fix in place, `Auto` is fine and saves power at idle.

**About the boot order:** MSI ignores boot order changes made from the operating system (`efibootmgr -o`, `bless`) and boots disks in the order of the BBS priority list. So set the order here, in the BIOS.
