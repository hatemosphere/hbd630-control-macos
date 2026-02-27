# GAIA v3 Protocol — As Discovered on HDB 630

## Wire Format

Every GAIA v3 packet looks like this:

```
[FF] [03] [paramSize hi] [paramSize lo] [vendorId hi] [vendorId lo] [cmdId hi] [cmdId lo] [payload...]
```

- `FF 03` — magic bytes, always the same
- `paramSize` — big-endian uint16, counts only the payload bytes (NOT vendor + cmd)
- Total packet length = 8 + paramSize
- All multi-byte header fields are big-endian

Example — get battery level:
```
FF 03 00 00 04 95 06 03
         ^^^^^ ^^^^^ ^^^^^
         |     |     cmd 0x0603 (Get Battery)
         |     vendor 0x0495 (Sennheiser)
         paramSize = 0 (no payload)
```

Response:
```
FF 03 00 01 04 95 07 03 28
                  ^^^^^ ^^
                  |     payload: 0x28 = 40%
                  cmd 0x0703 (response = 0x0603 | 0x0100)
```

## Command/Response ID Scheme

Given a request command ID `X`:
- Response: `X | 0x0100`
- Error: `X | 0x0180`
- Notification (push): GET cmd `X | 0x0080`

So for ANC Mode Set (0x1A00):
- Response to set: 0x1B00
- Error on set: 0x1B80
- Notification (push): 0x1A81 (based on GET 0x1A01)

## Vendor IDs

| Vendor | ID | Used For |
|--------|------|----------|
| Qualcomm | 0x001D | Serial number, API version |
| Sennheiser | 0x0495 | Everything else — ANC, EQ, battery, codec, settings |

## SDP Discovery

RFCOMM channel numbers are dynamic. You must do SDP lookup every time you connect.

The HDB 630 exposes the GAIA service with two UUIDs in its ServiceClassIDList:
- Standard GAIA: `00001107-D102-11E1-9B23-00025B00A5A5`
- Vendor-specific: `A2129FF3-081B-4C45-8AFE-469D9C4842EC`

Either UUID works for the SDP query. On macOS, use `IOBluetoothDevice.performSDPQuery()` and then search the service records for the GAIA UUID to extract the RFCOMM channel number.

Other RFCOMM services on the device:
- Channel 14: DECA-FADE / Airoha RACE (exists but not used for control)
- Channel 10: HFP (Hands-Free Profile)

## Notification Registration

Headphones won't push state changes unless you explicitly register for notifications. This is per-feature, per-vendor.

Registration command: cmd `0x0007` on the relevant vendor, payload = `[featureID]`.

### Sennheiser Features (vendor 0x0495)

| Feature ID | Name | What It Covers |
|-----------|------|----------------|
| 0 | Core | ? |
| 2 | Device | Device info |
| 3 | Battery | Battery level, charging status |
| 4 | Generic Audio | Codec, sidetone, podcast, smart pause, auto-answer, comfort call |
| 8 | User EQ | EQ bands, bass boost |
| 9 | Versions | Firmware version |
| 10 | Device Management | Connection status, paired devices |
| 11 | MMI | ? |
| 12 | Transparent Hearing | Transparency level |
| 13 | ANC | ANC mode, ANC status |

### Qualcomm Features (vendor 0x001D)

Only feature 0 (Core) works. Everything else times out.

### Features That Don't Exist on HDB 630

Features 1, 5, 6, 7, 14, 15 — all rejected by the device. Each one takes ~5 seconds to time out, so don't bother trying them during connection setup.

### Registration Sequence

At connect time, register for all known features:
```
Sennheiser: 0, 2, 3, 4, 8, 9, 10, 11, 12, 13
Qualcomm:   0
```

Without this, changing settings on the phone (or via touch controls) won't be reflected in the app.

## Connection Notes

**Clean disconnect**: Close the RFCOMM channel only. Do NOT call `device.closeConnection()` — that tears down the entire Bluetooth link including audio.

**Unclean disconnect** (SIGKILL, crash): Headphones may get confused. Sometimes needs re-pairing. The RFCOMM channel number will likely change after re-pairing.

**Multipoint**: HDB 630 supports up to 2 simultaneous connections and 3 paired devices. You can have audio from BTD 700 dongle + SPP control from Mac at the same time, but that uses both slots.
