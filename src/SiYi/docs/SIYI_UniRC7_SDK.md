# SIYI UniRC 7 Datalink SDK

> Source: *UniRC 7 SDK*, Chapter 6 "SDK Communication Protocol" (pp. 128–145 of 157).
> Transcribed from `unirc_sdk.pdf`. All example frames below were CRC-verified
> (CRC-16/XMODEM, see [§4](#4-crc16)).
>
> Implemented in QGC by [`SiYiUniRC`](../SiYiUniRC.h). See
> [SIYI model protocol differences](#appendix-differences-vs-mk15--mk32) at the end.

## 1. Frame format

| Field    | Offset | Size       | Description |
|----------|--------|------------|-------------|
| STX      | 0      | 2          | Start flag, fixed `0x5566` (little-endian on the wire: `55 66`) |
| CTRL     | 2      | 1          | Bit0 `need_ack`, Bit1 `ack_pack`, Bits2–7 reserved |
| Data_len | 3      | 2          | Length of `DATA` (little-endian) |
| SEQ      | 5      | 2          | Frame sequence 0–65535 (little-endian) |
| CMD_ID   | 7      | 1          | Command ID |
| DATA     | 8      | `Data_len` | Payload |
| CRC16    | 8+len  | 2          | CRC-16 over the whole packet up to CRC (little-endian) |

## 2. Commands

### 0x40 — Get Remote Controller Hardware ID
- **ACK**: `uint8_t hardware_id[12]` — 10-digit ASCII string (+ padding).
- Send: `55 66 01 00 00 00 00 40 81 9c`
- Resp: `55 66 02 0C 00 09 00 40 36 38 30 31 31 33 30 31 31 31 00 00 7b 8b` → `"6801130111"`

### 0x16 — Get System Settings (pushed at 10 Hz when subscribed)
- **ACK** (5 × uint8): `match`, `Com1_baud_type`, `Joy_type`, `Rc_bat`, `Com2_baud_type`
  - `match`: 0 start pairing, 1/2 pairing, 3 complete
  - `Com1/Com2_baud_type`: **1**=9600, **3**=57600, **5**=115200 (Air Unit UART1 / UART2)
  - `Joy_type`: 0 Mode1, 1 Mode2, 2 Mode3, 3 Custom
  - `Rc_bat`: RC battery voltage ×10

### 0x17 — Set System Settings
- **Send** (5 × uint8): `match` (1 enable binding / 0 disable), `Com1_baud_type`, `Joy_type` (0 Japanese, 1 American, 2 Chinese, 3 Custom), `reserved`, `Com2_baud_type`
- **ACK**: `int8_t sta` — 1 ok, negative = config error

### 0x42 — RC Channel Data
- **Send**: `uint8_t freq` — output frequency: 0 OFF, 1=2Hz, 2=4Hz, 3=5Hz, 4=10Hz, 5=20Hz, 6=50Hz, 7=100Hz. **Send 3× consecutively.**
- **ACK**: `int16_t CH1..CH16` (little-endian, default range 1050–1950)
- ⚠️ Enabling RC output can interfere with telemetry sharing the same port.

### 0x43 — Retrieve Remote Link Information
- **ACK**: `uint16 freq`, `pack_loss_rate`, `uint32 real_pack`, `real_pack_rate`,
  `data_up`, `data_down`, `data_up_2`, `data_down_2` (bytes/s; link 2 fields are UniRC-only)

### 0x44 — Retrieve Video Link Information
- **ACK** (compact, 8 bytes): `uint16 video_up` (÷10 Kbps), `uint16 video_down` (÷10 Mbps),
  `uint8 channel` (1–16), `int16 signal_strength` (−15..30), `uint8 signal_quality`
  (Strong ≥10, Medium 5–10, Weak <5)

### 0x47 — Retrieve Firmware Version
- **ACK**: `uint32 rc_version`, `rf_version`, `ground_version`, `sky_version`.
  Each is 4 bytes; low byte = product ID (ignore), high 3 bytes = `major.minor.patch`.
- Send: `55 66 01 00 00 00 00 47 66 ec`

### 0x48 — Retrieve All Channel Mappings
- **ACK**: 16 × (`uint8 type`, `uint8 entity_id`). `type` 0 = joystick/dial, 1 = button.

### 0x49 — Retrieve One Channel Mapping
- **Send**: `uint8 rc_ch` (1–16). **ACK**: `rc_ch`, `type`, `entity_id`.

#### Channel Mapping Type Definition (UniRC 7)
| Category | type | entity_id | Physical switch |
|---|---|---|---|
| Joystick | 0 | 0/1/2/3 | J1/J2, J3/J4, J5/J6, LD1/RD1 |
| Joystick | 0 | 8/9 | SA/SB, S1/S2 |
| Dial | 0 | 4/5 | S3/S4, L1/L2 |
| 3-position switch | 5 | 0/1 | R1 |
| Button | 1 | 0–14 | …, R2, R3, M1–M6 |
| Virtual channel | 2 | 0/1 | NULL / RSSI |
| No physical channel | 3 | 0 | NULL |

### 0x4A — Set Channel Mapping
- **Send**: `uint8 rc_ch`, `uint8 type`, `uint8 entity_id`. **ACK**: `rc_ch`, `int8 sta`.

### 0x4B — Retrieve All Channel Reverses
- **ACK**: 16 × `int8 reverse` (1 normal, −1 = `0xFF` reversed).

### 0x4C / 0x4D — Retrieve / Set Channel Reverse
- **Send/ACK**: `uint8 rc_ch`, `int8 reverse`.

### 0x4E — Get Multi-device Interconnection Status *(UniRC 7 only)*
- **ACK** (4 × uint8): `rc_multi_ctl_mode`, `main_vice_link_status`, `rc_relay_status`, `dual_ctl_status`
  - `rc_multi_ctl_mode`: 0 dual-ctrl master, 1 dual-ctrl slave, 2 relay master, 3 relay slave, 4 relay, 5 single control
  - `main_vice_link_status`: 0 not connected, 1 connected, 2 out of control
  - `rc_relay_status`: 0 master authority, 1 slave authority, 2 out of control
  - `dual_ctl_status`: 0 disabled (master all), 1 enabled (slave channels)
- Send: `55 66 01 00 00 00 00 4e 4f 7d`
- Resp: `55 66 02 04 00 02 00 4E 03 01 00 00 40 AB` → mode 3, link 1, relay 0, dual 0

### 0x4F — Get System Status *(UniRC 7 only; actively pushed on warning)*
- **Send**: `uint8 freq` — 0 disable, 1 enable active sending.
- **ACK**: enable/disable reply is a single `int8 sta`; active status reports carry
  2 × uint8 `G_led_status`, `s_led_status`.
  - `G_led_status` (ground unit) 0–18: 0 none, 3 MCU fw mismatch, 4 link init failed,
    5 joystick needs calibration, 8 power voltage abnormal, 9 BT not recognized,
    10–12 temperature alarm L1–L3, 13 video fw mismatch, … (14–18 packet-rate, reserved)
  - `s_led_status` (air unit) 0–4: 0 none, 1 voltage alarm (<12V), 2–4 temperature alarm L1–L3
- Enable:  `55 66 01 01 00 00 00 4f 01 8a 86` → reply `55 66 02 01 00 2B 00 4F 01 59 77`
- Status:  `55 66 02 02 00 E7 00 4F 03 00 03 51` → G_led 3, s_led 0

## 3. Communication interfaces
1. **Serial** — `/dev/ttyHS3`, 115200 baud
2. **Bluetooth**
3. **Type-C USB** virtual serial port
4. **UDP** — server `192.168.144.20`, port `19856` (do not bind 19856 on the client side)

Android model name (`ro.product.model`) distinguishes controllers: Standard = `Standard_94`, Pro = `Pro_94`.

## 4. CRC16
- CRC-16/XMODEM: polynomial `G(X)=X^16+X^12+X^5+1` (`0x1021`), init `0`, no reflection,
  256-entry MSB-first lookup table, stored little-endian in the frame.
- Implemented in QGC by [`SiYiCrcApi`](../SiYiCrcApi.h).

## Appendix: differences vs MK15 / MK32
- `0x4E`, `0x4F` are **UniRC 7 only** — absent on MK15/MK32.
- `0x44` layout differs: UniRC 7 is the compact 8-byte form above; MK15/MK32 use `int32 × 9`.
- `0x16/0x17` baud enum differs: UniRC uses `1/3/5` with separate UART1/UART2; MK uses `0–6`.
- `0x43` adds `data_up_2`/`data_down_2` (link 2) not present on MK.
- Transport: UniRC 7 has UDP `192.168.144.20:19856`; MK15/MK32 have no UDP (serial `/dev/ttyHS0`).
- In QGC, MK15/MK32 link status is served by [`SiYiTransmitter`](../SiYiTransmitter.h) over TCP `192.168.144.12:5864`.
