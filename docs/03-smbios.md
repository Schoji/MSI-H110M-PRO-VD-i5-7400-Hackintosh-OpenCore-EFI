# 3. Your own serial numbers (SMBIOS)

The `config.plist` in this repo has **placeholder** identifiers. OpenCore will boot with them, but iCloud, iMessage and FaceTime need values of your own.

**Do this before you install macOS.** Do not sign in to an Apple Account until these values are final, and never change them afterwards.

| Key in `PlatformInfo → Generic` | Placeholder in this repo | What to put there |
|---|---|---|
| `SystemProductName` | `iMac19,1` | keep it |
| `SystemSerialNumber` | `W00000000001` | serial from `macserial` |
| `MLB` | `M0000000000000001` | board serial from `macserial` |
| `SystemUUID` | `00000000-0000-0000-0000-000000000000` | a random UUID |
| `ROM` | `112233445566` | MAC address of the onboard Realtek network card |

## Why iMac19,1

This build drives the display from the Intel HD 630, and macOS 15 Sequoia has to support the model. The Kaby Lake iMacs (`iMac18,x`) are not supported by Sequoia. `iMac19,1` is the oldest iMac that Sequoia supports and that also uses the Intel iGPU, so it is the usual choice for a Kaby Lake desktop with no graphics card.

Sequoia is also the last macOS version for `iMac19,1`. See [Post-install](05-post-install.md#updates).

## Generate serial, MLB and UUID

`macserial` is in the OpenCore package ([OpenCorePkg releases](https://github.com/acidanthera/OpenCorePkg/releases), version 1.0.8 matches this EFI). Its location is `Utilities/macserial/`.

macOS:

```bash
cd OpenCore-1.0.8-RELEASE/Utilities/macserial
xattr -c macserial && chmod +x macserial
./macserial -m iMac19,1 -n 1
```

Linux:

```bash
./macserial.linux -m iMac19,1 -n 1
```

Windows: run `macserial.exe -m iMac19,1 -n 1`.

The output looks like `iMac19,1 | C02XXXXXXXXX | C02YYYYYYYYYYYYYY`:

- the first value is `SystemSerialNumber`;
- the second value is `MLB`.

For `SystemUUID`, use any random UUID: `uuidgen` on macOS or Linux, or `[guid]::NewGuid()` in PowerShell.

[GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) can do all of this in one menu, if you prefer.

## Check that the serial is not a real Mac

Enter the serial at [checkcoverage.apple.com](https://checkcoverage.apple.com).

- **"Please enter a valid serial number"** is what you want.
- **Purchase or coverage details** mean the serial belongs to a real iMac. Generate a new one. This happened here on the first try.

## ROM = your network card's MAC address

`ROM` is the 6-byte MAC address of the onboard RTL8111H, written as hex data without colons. For example, `00:11:22:33:44:55` becomes `001122334455`. Ways to find it:

- Linux: `ip link`;
- Windows: `getmac`;
- macOS on this machine: `ifconfig en0 ether`. You can boot once with the placeholder, read the MAC, then fix `ROM` before signing in to iCloud.

`en0` must be the built-in port, which it is with this EFI: `ioreg -l | grep IOBuiltin` shows `Yes`.

## Put the values into config.plist

You can edit `EFI/OC/config.plist` with [ProperTree](https://github.com/corpnewt/ProperTree), or with `plutil` on macOS:

```bash
C=EFI/OC/config.plist
plutil -replace PlatformInfo.Generic.SystemSerialNumber -string "C02XXXXXXXXX" $C
plutil -replace PlatformInfo.Generic.MLB -string "C02YYYYYYYYYYYYYY" $C
plutil -replace PlatformInfo.Generic.SystemUUID -string "$(uuidgen)" $C
plutil -replace PlatformInfo.Generic.ROM -data "$(echo 001122334455 | xxd -r -p | base64)" $C
plutil -lint $C
```

Keep a copy of these four values somewhere safe. If you ever rebuild the EFI with different values, macOS and iCloud see it as a different Mac.
