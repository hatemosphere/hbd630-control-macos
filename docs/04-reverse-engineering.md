# Reverse Engineering the HDB 630 Protocol

How we went from "Sennheiser doesn't have a desktop app" to a fully working macOS control app.

## Starting Point

The Sennheiser HDB 630 headphones have a ton of configurable settings — ANC modes, EQ, crossfeed, sidetone, etc. But the only way to access them is through the "Smart Control Plus" mobile app. No desktop client, no API docs, no protocol spec.

The headphones use an Airoha AB1568 Bluetooth chipset. We wanted native macOS control.

## APK Decompilation

First move: decompile the Android app.

```
jadx -d apk/decompiled/ SmartControlPlus.apk
```

Smart Control Plus (`com.sonova.chb.control`) turned out to be a Flutter app with a native Kotlin/Java layer wrapping the Airoha SDK.

The goldmine was in the assets: `assets/configs/hdb630-0.json` — a complete device capability config. It listed every feature the headphones support, the connection type (Classic, not BLE), touch control gestures, EQ band ranges, everything.

The Airoha SDK sources showed how RACE (Remote Airoha Command Engine) protocol packets are built:
- `C7053b.java` — RACE packet builder
- `C5640c.java` — SPP transport
- `AbstractC5030c.java` — Bluetooth UUIDs

## Wrong Turn: RACE Protocol

Based on the Airoha chipset and the SDK code, we assumed HDB 630 uses the RACE protocol. Built CLI tools that connected via SPP to the vendor UUID (`00000000-0000-0000-0099-AABBCCDDEEFF`) and sent RACE packets.

The connection worked — we could open an RFCOMM channel on ch14 (the DECA-FADE / RACE channel). But the headphones didn't respond meaningfully to RACE commands. They'd sometimes ACK but never returned real data.

Weeks of poking at RACE before we found the real answer.

## Finding GAIA v3

Two key discoveries:

**1. Sennheiser desktop client.** Found a Qt-based desktop client for Sennheiser headphones. Inside it: `gaiaV3/m4.json` — a complete database of every GAIA v3 command. Vendor IDs, command IDs, payload formats, response formats. This was the entire protocol spec sitting in a JSON file.

**2. Qualcomm GAIAControl.** An open-source reference app from Qualcomm for the GAIA protocol. The Java source (`BREDRProvider.java`) confirmed the GAIA service UUID: `00001107-D102-11E1-9B23-00025B00A5A5`.

So the HDB 630 speaks GAIA v3 (Qualcomm protocol) despite having an Airoha chipset. The RACE channel exists on the device but isn't used for user-facing control.

## Bluetooth Packet Capture

To confirm the protocol and figure out exact value mappings, we captured live traffic.

**Setup:**
1. Install Xcode Additional Tools (includes PacketLogger)
2. Pair iPhone with HDB 630
3. Start PacketLogger on Mac
4. Use Smart Control Plus on iPhone to change settings
5. Capture the HCI packets

The `.pklg` files contain raw HCI packets. GAIA v3 packets are embedded inside ACL/RFCOMM frames.

### Parsing pklg Files

pklg format is straightforward:
```
[4 bytes] length (little-endian)
[8 bytes] timestamp
[1 byte]  type (0x02=TX phone→headphones, 0x03=RX headphones→phone)
[N bytes] HCI packet data
```

To find GAIA packets, search for the magic bytes `FF 03` in RFCOMM payload data. For Sennheiser commands specifically, look for `04 95` (vendor ID) following the paramSize field.

We wrote a Python script that extracts and decodes all GAIA packets from a capture. This was essential for confirming things like:
- Podcast mode uses `[0x00, 0x02]` for on and `[0x00, 0x01]` for off (the extra 0x00 prefix)
- Crossfeed value 2 means "off" (not what you'd expect)
- EQ gains are signed int8 representing dB x 10

## CLI Probing

Once we knew the protocol, we built standalone Swift scripts for direct testing:

```swift
// Simplified — actual code does SDP lookup, error handling, etc.
let packet = GAIAPacket(vendor: 0x0495, cmd: 0x0603) // Get Battery
rfcommChannel.writeSync(packet.data)
// Response: FF 03 00 01 04 95 07 03 28 → battery at 40%
```

### Systematic Command Discovery

We iterated through command ID ranges to find all working commands:
- Try GET (even cmd IDs), check for response vs error vs timeout
- Try SET with various payloads, verify with GET
- Check if notifications fire after SET

This is how we discovered:
- Crossfeed lives at 0x2E00/0x2E01 (not documented in m4.json)
- Sidetone range is 0-4 (5+ returns error)
- GET EQ (0x1002) is broken — always returns error 0x1182
- Which notification features exist (0-13, with gaps)

### Notification Feature Probing

Registering for nonexistent features doesn't error — it just silently times out after 5 seconds. We tried features 0-15 and found:
- Working: 0, 2, 3, 4, 8, 9, 10, 11, 12, 13
- Rejected/timeout: 1, 5, 6, 7, 14, 15

## Ghidra / Native Library Analysis

The APK contains native `.so` libraries:
- `librace.so`, `libairoha_sdk.so` — Airoha native SDK
- `libapp.so` — Dart AOT compiled (Flutter app logic)
- `libflutter.so` — Flutter engine

You can load these into Ghidra for deeper analysis. For the Flutter `libapp.so`, there's a tool called [blutter](https://github.com/aspect-security-research/blutter) that can partially decompile Dart AOT code.

For HDB 630 we didn't need to go this deep — the desktop client's m4.json plus packet captures gave us everything.

## Key Lessons

**Don't assume protocol from chipset.** HDB 630 has an Airoha AB1568 chip but uses Qualcomm GAIA v3. The RACE channel exists but isn't the control protocol.

**Desktop clients are goldmines.** Sennheiser's Qt desktop client had a complete command database in a JSON file. Always look for desktop/CLI tools — they're less obfuscated than mobile apps.

**Packet capture confirms everything.** The m4.json had the command structure, but packet capture confirmed exact value mappings, byte ordering, and the quirky payload formats (podcast mode's extra 0x00 byte, crossfeed's inverted values).

**SDP lookup is mandatory.** RFCOMM channel numbers change between pairings. Hard-coding a channel number will break.

**Register for notifications.** Without explicit registration, the headphones won't push state changes. Each feature needs its own registration command.

**Clean disconnect matters.** Closing the Bluetooth device connection (instead of just the RFCOMM channel) kills the audio link. And unclean exits can leave the headphones in a weird state requiring re-pairing.
