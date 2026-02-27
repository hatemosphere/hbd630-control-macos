# HDB 630 Device Configuration

Extracted from `apk/decompiled/resources/assets/flutter_assets/assets/configs/hdb630-0.json`.
Product key: `products/0013/0`.

## Connection Type

```json
"connection_type_ios": { "type": "Classic" },
"connection_type_android": { "type": "Classic" }
```

Both platforms use Bluetooth Classic (SPP/RFCOMM), not BLE.

## Supported Features & Variants

Each feature has a `variant` number (protocol version) and optional `config`.

### ConnectionManagement (variant 1)
- `multipointSwitchSupported`: false (true from FW 3.24.0+)

### Battery (variant 1)
No config — standard battery reporting.

### FactoryReset (variant 1)
No config.

### FirmwareUpdate (variant 1)
- `reconnectTimeoutSec`: 10

### ProductInfo (variant 1)
No config.

### AudioModes (variant 1)
- `usageWithSoundProfileSupported`: false
- `productSupportedResolutions`: ["highResolution"]
- `support`: ["aptX96kHz"]

### AutoAnswerCalls (variant 1)
No config.

### AutoPowerOff (variant 1)
No config.

### Codec (variant 1)
```
Standard: SBC, AAC
Advanced: aptX, aptXAdaptive, LC3, aptXHD
Low Latency: null
```

### ComfortCalls (variant 1)
No config.

### Crossfeed (variant 1)
No config.

### Equalizer (variant 2)

#### Graphic EQ
- 5 bands: 50Hz, 250Hz, 800Hz, 3000Hz, 8000Hz
- Presets with gain values (dB):

| Preset | 50Hz | 250Hz | 800Hz | 3kHz | 8kHz |
|--------|------|-------|-------|------|------|
| Rock | 0.0 | 2.0 | 2.5 | 1.5 | -2.0 |
| Pop | 0.0 | -2.5 | 0.0 | 2.5 | 0.0 |
| Dance | 3.5 | 2.0 | -1.5 | 1.5 | 3.0 |
| Hip Hop | 3.0 | 1.5 | -1.5 | 0.0 | -1.5 |
| Classical | -2.0 | -1.5 | 0.0 | 3.5 | 4.0 |
| Movie | 0.0 | 0.0 | 2.0 | 2.0 | -2.0 |
| Jazz | -3.2 | 0.0 | 2.2 | 2.2 | 0.0 |

#### Parametric EQ
- `frequency_min`: 20 Hz
- `frequency_max`: 20000 Hz
- `gain_min`: -6.0 dB
- `gain_max`: 6.0 dB
- `q_min`: 0.25
- `q_max`: 8.0
- `min_master_gain`: -12.0 dB
- `bands_count`: 5
- `high_low_shelf_q_max`: 0.71
- `master_gain_calculated_on_client`: true

Features: `supports_parametric_equalizer`, `supports_graphic_equalizer`, `supports_bass_boost`.

### OnHeadDetection (variant 1)
- `raw_sensor_data_supported`: false

### NoiseControl (variant 2)
- `supported_anti_wind_values`: ["off", "max", "auto"]
- `supported_modes`: ["adaptive", "custom", "off"]

### PodcastMode (variant 1)
No config.

### SmartPause (variant 1)
No config.

### Sidetone (variant 1)
- `steps`: 5

### SignalPath (variant 1)
No config.

### SoundZones (variant 1)
No config.

### Telemetry (variant 1)
No config.

### ToneAndVoicePrompts (variant 1)
No config.

### TouchControls (variant 1)

Product type: `headband`
`keepsMmiLockedAfterReboot`: true
`supportsDisableTouchHold`: false
`supportsButtonActivityNotification`: false

Onboarding gestures: tap, doubleTap, slideUp, slideRight, spread

#### Generic Controls (always active)
| Gesture ID | Action ID | Meaning |
|-----------|-----------|---------|
| 18 | 5 | PASS_THROUGH |
| 17 | 4 | (custom) |
| 13 | 256 | (custom) |
| 14 | 257 | (custom) |

#### During Music
| Gesture ID | Action ID | Meaning |
|-----------|-----------|---------|
| 1 | 1 | VOLUME_UP |
| 15 | 2 | VOLUME_DOWN |
| 16 | 3 | ANC |
| 19 | 261 | (custom) |
| 20 | 262 | (custom) |
| 2 | 6 | NEXT_TRACK |

#### During Telephony
| Gesture ID | Action ID | Meaning |
|-----------|-----------|---------|
| 1 | 258 | (custom) |
| 15 | 128 | (custom) |
| 16 | 259 | (custom) |
| 2 | 260 | (custom) |
| 7 | 129 | (custom) |

### Crashdumps (variant 1)
No config.

## Optional App Features
- FindHeadphones
- Onboarding

## Firmware Version Overrides

### FW 3.24.0+
- ConnectionManagement: `multipointSwitchSupported` → true

## Dev Config Extras

From `dev_configs/hdb630-0.json` (FW 0.0.1+):

### RenameDevice (variant 1)
- `forcedRebootRequired`: true
- `maxNameLength`: 16
- `product_type`: "headband"
