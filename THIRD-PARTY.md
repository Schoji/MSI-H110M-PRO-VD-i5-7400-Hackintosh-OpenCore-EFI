# Third-party components

The `EFI` folder contains binaries made by other people. They are included unmodified unless noted, under their own licenses.

| Component | Source | License |
|---|---|---|
| OpenCore 1.0.8: `BOOTx64.efi`, `OpenCore.efi`, `OpenRuntime.efi`, `ResetNvramEntry.efi`, `OpenCanopy.efi`, `AudioDxe.efi`, `OpenShell.efi` | [acidanthera/OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) | BSD 3-Clause |
| `SSDT-PLUG-DRTNIA.aml`, `SSDT-EC-USBX-DESKTOP.aml` | [Dortania prebuilt SSDTs](https://github.com/dortania/Getting-Started-With-ACPI) | see source |
| Lilu, VirtualSMC (+ SMCProcessor, SMCSuperIO), AppleALC, RestrictEvents | [acidanthera](https://github.com/acidanthera) | BSD 3-Clause |
| WhateverGreen 1.7.2 **with the DPLL fix** (modified) | [Schoji/WhateverGreen](https://github.com/Schoji/WhateverGreen) (fork of [acidanthera/WhateverGreen](https://github.com/acidanthera/WhateverGreen)) | BSD 3-Clause |
| RealtekRTL8111 2.5.0 **with the Wake-on-LAN patch** (modified, debug symbols stripped) | [Mieze/RTL8111_driver_for_OS_X](https://github.com/Mieze/RTL8111_driver_for_OS_X), patch in [`extras/rtl8111-wol`](extras/rtl8111-wol/rtl8111-wol.patch) | GPLv2 |
| `HfsPlus.efi`, `Resources/` (theme images, fonts, labels, boot chime) | [acidanthera/OcBinaryData](https://github.com/acidanthera/OcBinaryData) | no license file in the source repo; distributed there for use with OpenCore |

`USBMap.kext`, the `config.plist`, the guide and the scripts in `extras/` were written for this build and are covered by [LICENSE](LICENSE).
