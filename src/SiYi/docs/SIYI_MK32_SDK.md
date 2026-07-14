# SIYI MK32 Datalink SDK

> Source: *MK32 SDK*, §4.8 "SIYI Datalink SDK" (pp. 101–111 of 154).
> Transcribed from `mk32_sdk.pdf`. Example frames CRC-verified (CRC-16/XMODEM, see [§4](#4-crc16)).
>
> The MK32 SDK is identical to [MK15](SIYI_MK15_SDK.md) except for the physical-channel
> mapping table ([§2, 0x49](#0x49--request-a-specific-channel-mapping)). In QGC the MK32 link
> is served by [`SiYiTransmitter`](../SiYiTransmitter.h) over TCP `192.168.144.12:5864`.

## 1. Frame format

| Field    | Offset | Size       | Description |
|----------|--------|------------|-------------|
| STX      | 0      | 2          | Start flag `0x5566` (on the wire `55 66`) |
| CTRL     | 2      | 1          | Bit0 `need_ack`, Bit1 `ack_pack`, Bits2–7 reserved |
| Data_len | 3      | 2          | Length of `DATA` (low byte first) |
| SEQ      | 5      | 2          | Frame sequence 0–65535 (low byte first) |
| CMD_ID   | 7      | 1          | Command ID |
| DATA     | 8      | `Data_len` | Payload |
| CRC16    | 8+len  | 2          | CRC-16 over the whole packet (low byte first) |

## 2. Commands

### 0x40 — Request Hardware ID
- **ACK**: `uint8_t hardware_id[12]` — 10-digit string.
- Send: `55 66 01 00 00 00 00 40 81 9c`
- Resp: `55 66 02 0C 00 09 00 40 36 38 30 31 31 33 30 31 31 31 00 00 7b 8b` → `"6801130111"`

### 0x16 — Request System Settings (10 Hz)
- **ACK** (4 × uint8): `match`, `Baud_type`, `Joy_type`, `Rc_bat`
  - `match`: 0 start, 1/2 binding, 3 finished
  - `Baud_type` (**telemetry baud**): 0=4800, 1=9600, 2=38400, 3=57600, 4=76800, 5=115200, 6=230400
  - `Joy_type`: 0 Mode1, 1 Mode2, 2 Mode3, 3 Custom
  - `Rc_bat`: ground-unit battery level ×10 V

### 0x17 — Send System Settings to Ground Unit
- **Send** (uint8): `match`, `Baud_type`, `Joy_type`, `reserved`
- **ACK**: `int8 sta` — 1 ok, negative = error

### 0x42 — Request Channel Data
- **Send**: `uint8 freq` — 0 OFF, 1=2Hz, 2=4Hz, 3=5Hz, 4=10Hz, 5=20Hz, 6=50Hz, 7=100Hz
- **ACK**: `int16 CH1..CH16` (default 1050–1950)
- ⚠️ Enabling RC output affects telemetry (shared port).

### 0x43 — Request Datalink Status
- **ACK**: `uint16 freq`, `uint8 pack_loss_rate`, `uint16 real_pack`, `uint16 real_pack_rate`,
  `uint32 data_up`, `uint32 data_down` (bytes/s). *No link-2 fields.*
- Resp: `55 66 02 0F 00 01 00 43 02 00 00 02 00 02 00 00 00 00 00 00 00 00 00 2E 5C` (15 data bytes)

### 0x44 — Request Image Transmission Link Status
- **ACK** (9 × int32 = 36 bytes): `signal` (%), `inactive_time`, `upstream` (B/s),
  `downstream` (B/s), `txbandwidth` (÷1000 Mbps), `rxbandwidth` (÷1000 Mbps),
  `rssi` (dBm), `freq` (MHz), `channel`
- Resp (36 data bytes): `55 66 02 24 00 02 00 44 …(36 bytes)… 2C D9`
- **Note**: this `int32 × 9` layout matches [`SiYiTransmitter::HeartbeatAckContext`](../SiYiTransmitter.h).

### 0x47 — Request Firmware Version
- **ACK**: `uint32 rc_version`, `rf_version`, `ground_version`, `sky_version`.
  4 bytes each; low byte = product ID, high 3 bytes = `major.minor.patch`.

### 0x48 — Request All Channel Mappings
- **ACK**: 16 × (`uint8 type`, `uint8 entity_id`). `type` 0 = joystick/dial, 1 = button/switch.

### 0x49 — Request A Specific Channel Mapping
- **Send**: `uint8 rc_ch` (1–16). **ACK**: `rc_ch`, `type`, `entity_id`.

#### Channel Mapping Type Definition (MK32)
| Physical channel | type | entity_id | Definition |
|---|---|---|---|
| Joystick | 0 | 0/1/2/3 | J1/J2/J3/J4 |
| Joystick / Dial | 0 | 4/5/6/7 | LD1/RD1/LD2/RD2 |
| 3-stage switch | 5 | 0/1/2/3/4/5 | SA/SB/SC/SD/SE/SF |
| Button | 1 | 0/1 | S1/S2 |
| Virtual channel | 2 | 0 | — |
| No physical channel mapped | 3 | 0 | NULL |

*(MK32 has more switches than MK15: LD2/RD2, SD/SE/SF, S1/S2.)*

### 0x4A — Send Channel Mapping to Ground Unit
- **Send**: `uint8 rc_ch`, `uint8 type`, `uint8 entity_id`. **ACK**: `rc_ch`, `int8 sta`.
- Send: `55 66 01 03 00 00 00 4A 02 00 00 4F EB`

### 0x4B — Request All Channel Reverse
- **ACK**: `int8 CHn_reverse` (1 normal, −1 reversed).

### 0x4C / 0x4D — Request / Send Channel Reverse
- **Send/ACK**: `uint8 rc_ch`, `int8 reverse` (1 normal, −1 reversed).
- 0x4D resp: `55 66 02 02 00 1D 00 4D 02 01 8B 65`

> MK32 has **no** `0x4E` (multi-device) or `0x4F` (system status) commands — those are UniRC 7 only.

## 3. Communication interface
The datalink SDK supports four interfaces, switchable in the SIYI TX app:
1. **UART serial** — `/dev/ttyHS0`, 115200 baud
2. **USB COM** (USB-to-serial; baud follows datalink baud)
3. **Bluetooth**
4. **MK32 RC Type-C Port** (virtual serial over USB)

> There is **no UDP interface**. In QGC, MK32 link status is read via
> [`SiYiTransmitter`](../SiYiTransmitter.h) over **TCP `192.168.144.12:5864`**.

## 4. CRC16
CRC-16/XMODEM: polynomial `0x1021` (`X^16+X^12+X^5+1`), init `0`, MSB-first 256-entry table,
little-endian in the frame. Implemented by [`SiYiCrcApi`](../SiYiCrcApi.h).
