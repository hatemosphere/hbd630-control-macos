# BTD 700 Bluetooth USB-C Dongle

## What It Is
- Sennheiser BTD 700 is a Bluetooth 5.4 USB-C dongle
- Plugs into Mac/PC/phone USB-C port
- Appears as a **USB audio device** (class-compliant USB DAC) to the OS
- Wirelessly streams audio to HDB 630 at up to 24-bit/96kHz
- Supports: aptX Adaptive, aptX HD, aptX, aptX Voice, SBC, AAC
- NOT a standard USB Bluetooth HCI adapter — proprietary audio transport only

## How It Relates to the App

### Two Separate Connections
1. **Audio path**: Mac USB → BTD 700 → (BT wireless) → HDB 630
   - Just works, no app needed, OS sees it as USB audio output
2. **Control path**: Mac Bluetooth → (BT Classic SPP) → HDB 630
   - Our app connects directly to headphones over Bluetooth
   - Independent of the dongle

### Dongle as Airoha Device
From decompiled code (`p095I3/C0920P.java` line 127-128):
```java
if (deviceName.toUpperCase().contains("DONGLE")) {
    deviceType = DeviceType.DONGLE;
}
```

The BTD 700 is also an **Airoha chipset device**. The Smart Control app can connect
to it via Bluetooth using the same RACE protocol as the headphones. Known dongle
operations:
- Firmware update (FOTA) — battery threshold set to -1 for dongle since no battery
- Device info query

### No USB Control Path
The Airoha SDK defines `PROTOCOL_USB` (value 1048576) and `PROTOCOL_CABLE` (65536)
in `ConnectionProtocol.java`, but these are **not used** for BTD 700 in the Smart
Control Plus app. The dongle exposes only USB audio, not USB serial/control.

### Can We Configure Headphones Through the Dongle?
**No.** The dongle is a transparent audio bridge. Control commands go directly to the
headphones via their own Bluetooth SPP connection. The dongle and headphones are two
separate Bluetooth devices.

## Multipoint & Connection Budget
HDB 630 supports up to **2 simultaneous connections** and **3 paired devices** (confirmed: cmd 0x1409 returns 0x02, paired list size returns 0x03).

Using BTD 700 for audio + this app for control from the **same Mac** takes **both slots**:
1. **BTD 700** — Bluetooth audio (aptX Adaptive, high quality)
2. **Mac Bluetooth** — RFCOMM/SPP control (this app)

That leaves **no room** for another device (e.g. phone for calls). To free a slot,
disconnect the dongle or close this app.

Without the dongle, regular Mac Bluetooth handles both audio and control over a single
connection, leaving 1 slot free for another device — but you're limited to AAC/SBC codecs.

## macOS App Implications

### Must-Have
- Connect directly to HDB 630 over Bluetooth SPP for all control features
- BTD 700 audio "just works" via USB — no special code needed

### Nice-to-Have (optional)
- Detect if BTD 700 is plugged in (USB device enumeration — check for Sennheiser USB audio device)
- Show signal path info: "Audio: USB → BTD 700 → aptX Adaptive → HDB 630"
- Show active codec from headphones' A2DP_STATUS (message ID 1007)
- SignalPath feature (variant 1) — the app has this for displaying codec/audio path

### Not Needed
- Direct communication with BTD 700 — dongle firmware updates via macOS Bluetooth
  would be possible but low priority
