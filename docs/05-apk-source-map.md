# Decompiled APK Source Map

Reference for navigating the decompiled Smart Control Plus APK.
Base path: `apk/decompiled/`

## App Info
- Package: `com.sonova.chb.control`
- Framework: Flutter (Dart compiled, Java/Kotlin native bridge)
- BLE plugin: `flutter_reactive_ble` (com.signify.hue.flutterreactiveble)
- Bluetooth stack: Airoha SDK (native Java)
- Serialization: GSON (Google JSON) for Airoha messages
- Protobuf: For Flutter-to-native bridge only (not device protocol)

## Airoha SDK (core protocol)

### API Layer
| File | Purpose |
|------|---------|
| `sources/com/airoha/sdk/api/message/AirohaBaseMsg.java` | Base message: messageId + msgContent + isPush |
| `sources/com/airoha/sdk/api/utils/AirohaMessageID.java` | All 130+ message ID enum values |
| `sources/com/airoha/sdk/api/utils/AirohaStatusCode.java` | Response status codes |
| `sources/com/airoha/sdk/api/utils/AirohaAncMode.java` | ANC mode enum |
| `sources/com/airoha/sdk/api/utils/AirohaEQBandType.java` | EQ band type enum |
| `sources/com/airoha/sdk/api/utils/ConnectionProtocol.java` | Protocol types (SPP/BLE/etc.) |
| `sources/com/airoha/sdk/api/utils/ConnectionUUID.java` | UUID holder for SPP/BLE connections |
| `sources/com/airoha/sdk/api/utils/DeviceType.java` | Device type enum |
| `sources/com/airoha/sdk/api/utils/DeviceRole.java` | Device role enum |
| `sources/com/airoha/sdk/api/utils/AudioChannel.java` | Audio channel enum |

### Message Payloads
| File | Message ID | Purpose |
|------|-----------|---------|
| `sources/com/airoha/sdk/api/message/AirohaAncSettings.java` | ANC_STATUS | ANC mode, filter, gain |
| `sources/com/airoha/sdk/api/message/AirohaBatteryInfo.java` | BATTERY_STATUS | Battery levels/charging |
| `sources/com/airoha/sdk/api/message/AirohaEQPayload.java` | PEQ_INFO | EQ bands with IIR params |
| `sources/com/airoha/sdk/api/message/AirohaEQSettings.java` | PEQ_INFO | EQ category + payload wrapper |
| `sources/com/airoha/sdk/api/message/AirohaGestureSettings.java` | GESTURE_STATUS | Gesture→action mappings |
| `sources/com/airoha/sdk/api/message/AirohaSidetoneInfo.java` | SIDETONE_STATUS | Sidetone on/off + level |
| `sources/com/airoha/sdk/api/message/AirohaWindInfo.java` | WIND_INFO | Wind noise data |
| `sources/com/airoha/sdk/api/message/AirohaCmdSettings.java` | SEND_CUSTOM_CMD | Raw RACE command + RaceType |
| `sources/com/airoha/sdk/api/message/AirohaCodecConfig.java` | - | Codec configuration |
| `sources/com/airoha/sdk/api/message/AirohaDeviceInfoMsg.java` | DEVICE_INFO | Device info response |
| `sources/com/airoha/sdk/api/message/AirohaFeatureCapabilities.java` | AIROHA_FEATURE_CAPABILITIES | Chip features |
| `sources/com/airoha/sdk/api/message/AirohaAncUserTriggerSettings.java` | ANC_USER_TRIGGER_STATUS | ANC calibration |
| `sources/com/airoha/sdk/api/message/AirohaEnvironmentDetectionInfo.java` | ENVIRONMENT_DETECTION_INFO | Env. detection |
| `sources/com/airoha/sdk/api/message/AirohaFullAdaptiveAncInfo.java` | FULL_ADAPTIVE_ANC_STATUS | Adaptive ANC |
| `sources/com/airoha/sdk/api/message/AirohaAdaptiveEqInfo.java` | ADAPTIVE_EQ_STATUS | Adaptive EQ |
| `sources/com/airoha/sdk/api/message/AirohaShareModeInfo.java` | SHARE_MODE_STATE | Share mode |
| `sources/com/airoha/sdk/api/message/AirohaLinkDeviceStatus.java` | LINK_DEVICE_STATUS | Connected devices |
| `sources/com/airoha/sdk/api/message/AirohaLinkHistoryInfo.java` | LINK_HISTORY | Pairing history |

### Control Interfaces
| File | Purpose |
|------|---------|
| `sources/com/airoha/sdk/api/control/AirohaDeviceControl.java` | Main device control (60+ methods) |
| `sources/com/airoha/sdk/api/control/PEQControl.java` | EQ control (get/set/replace/reset) |
| `sources/com/airoha/sdk/api/control/HAControl.java` | Hearing aid control |
| `sources/com/airoha/sdk/api/control/AirohaBaseControl.java` | Base control interface |
| `sources/com/airoha/sdk/api/control/AirohaDeviceListener.java` | Callback: onRead + onChanged |

### Device Model
| File | Purpose |
|------|---------|
| `sources/com/airoha/sdk/api/device/AirohaDevice.java` | Device state model |
| `sources/com/airoha/sdk/api/device/ApiStrategy.java` | API strategy |
| `sources/com/airoha/sdk/api/ota/FotaInfo.java` | Firmware OTA info |
| `sources/com/airoha/sdk/api/ota/FotaSettings.java` | Firmware OTA settings |
| `sources/com/airoha/sdk/api/ota/AirohaFOTAControl.java` | Firmware update control |

## Transport Layer (obfuscated packages)

| File | Purpose |
|------|---------|
| `sources/p533w2/C7053b.java` | **RACE packet builder** — frame assembly |
| `sources/p533w2/EnumC7052a.java` | Packet send state enum |
| `sources/p409l3/C5640c.java` | **SPP socket** — read/write raw bytes |
| `sources/p354g3/AbstractC5030c.java` | **Bluetooth UUIDs** — all service/char UUIDs |
| `sources/p365h3/C5148d.java` | Connection manager — H4 protocol |
| `sources/p377i3/C5281d.java` | SPP connection parameters |
| `sources/p073G3/AbstractC0734b.java` | **Byte utilities** — hex, LE encoding |
| `sources/p095I3/C0922S.java` | Connector — SPP/BLE connection orchestrator |
| `sources/p095I3/C0916L.java` | **Main message handler** (~3600 lines) |

## Flutter Bridge (not device protocol)

| File | Purpose |
|------|---------|
| `sources/com/signify/hue/flutterreactiveble/PluginController.java` | Flutter method channel handler |
| `sources/com/signify/hue/flutterreactiveble/ble/ReactiveBleClient.java` | BLE operations wrapper |
| `sources/com/signify/hue/flutterreactiveble/ble/DeviceConnector.java` | BLE connection management |
| `resources/bledata.proto` | Flutter↔native protobuf (BLE abstraction) |

## Device Configuration

| File | Purpose |
|------|---------|
| `resources/assets/flutter_assets/assets/configs/hdb630-0.json` | **HDB 630 production config** |
| `resources/assets/flutter_assets/assets/dev_configs/hdb630-0.json` | HDB 630 development config |
| `resources/assets/flutter_assets/AssetManifest.json` | All Flutter assets list |

## Not Relevant
- `resources/google/` — Google API protos (Firebase, etc.)
- `resources/firebase/` — Firebase performance monitoring
- `sources/com/microsoft/` — MSAL auth library
- `resources/client_analytics.proto` — App analytics
- `resources/messaging_event.proto` — Firebase messaging
