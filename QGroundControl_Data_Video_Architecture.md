# QGroundControl 데이터 통신 및 영상 스트리밍 구조

## 목차
1. [전체 시스템 아키텍처](#전체-시스템-아키텍처)
2. [데이터 통신 구조](#데이터-통신-구조)
3. [영상 스트리밍 구조](#영상-스트리밍-구조)
4. [통신 프로토콜 계층](#통신-프로토콜-계층)
5. [비디오 처리 파이프라인](#비디오-처리-파이프라인)
6. [실시간 데이터 흐름](#실시간-데이터-흐름)
7. [성능 최적화](#성능-최적화)

---

## 전체 시스템 아키텍처

```mermaid
graph TB
    subgraph "QGroundControl Application"
        QGC[QGroundControl App]
        LinkManager[LinkManager]
        VideoManager[VideoManager]
        
        subgraph "Communication Links"
            SerialLink[Serial Link]
            TCPLink[TCP Link]
            UDPLink[UDP Link]
            WebRTCLink[WebRTC Link]
            BluetoothLink[Bluetooth Link]
        end
        
        subgraph "Data Processing"
            MAVLinkProtocol[MAVLink Protocol]
            VehicleManager[Vehicle Manager]
            MissionManager[Mission Manager]
            ParameterManager[Parameter Manager]
        end
        
        subgraph "Video Processing"
            VideoReceiver[Video Receiver]
            VideoDecoder[Video Decoder]
            VideoRenderer[Video Renderer]
            VideoRecorder[Video Recorder]
        end
    end
    
    subgraph "External Systems"
        Vehicle[Vehicle/Drone]
        Camera[Camera System]
        GCS[Ground Control Station]
        CloudServer[Cloud Server]
    end
    
    subgraph "Network Infrastructure"
        STUNServer[STUN Server]
        TURNServer[TURN Server]
        SignalingServer[Signaling Server]
        VideoServer[Video Server]
    end
    
    QGC --> LinkManager
    QGC --> VideoManager
    
    LinkManager --> SerialLink
    LinkManager --> TCPLink
    LinkManager --> UDPLink
    LinkManager --> WebRTCLink
    LinkManager --> BluetoothLink
    
    SerialLink --> MAVLinkProtocol
    TCPLink --> MAVLinkProtocol
    UDPLink --> MAVLinkProtocol
    WebRTCLink --> MAVLinkProtocol
    BluetoothLink --> MAVLinkProtocol
    
    MAVLinkProtocol --> VehicleManager
    MAVLinkProtocol --> MissionManager
    MAVLinkProtocol --> ParameterManager
    
    VideoManager --> VideoReceiver
    VideoReceiver --> VideoDecoder
    VideoDecoder --> VideoRenderer
    VideoDecoder --> VideoRecorder
    
    Vehicle --> SerialLink
    Vehicle --> TCPLink
    Vehicle --> UDPLink
    Vehicle --> WebRTCLink
    Vehicle --> BluetoothLink
    
    Camera --> VideoReceiver
    
    STUNServer --> WebRTCLink
    TURNServer --> WebRTCLink
    SignalingServer --> WebRTCLink
    VideoServer --> VideoReceiver
```

---

## 데이터 통신 구조

```mermaid
graph LR
    subgraph "QGroundControl Data Layer"
        QGCApp[QGroundControl App]
        LinkInterface[Link Interface]
        MAVLinkProtocol[MAVLink Protocol]
        
        subgraph "Communication Protocols"
            Serial[Serial Protocol]
            TCP[TCP Protocol]
            UDP[UDP Protocol]
            WebRTC[WebRTC Protocol]
            Bluetooth[Bluetooth Protocol]
        end
        
        subgraph "Data Processing"
            MessageParser[Message Parser]
            MessageBuilder[Message Builder]
            DataValidator[Data Validator]
            StatisticsCollector[Statistics Collector]
        end
    end
    
    subgraph "Vehicle Communication"
        Vehicle[Vehicle System]
        Autopilot[Autopilot]
        Sensors[Sensors]
        Actuators[Actuators]
    end
    
    subgraph "Data Types"
        Telemetry[Telemetry Data]
        Commands[Command Data]
        Parameters[Parameter Data]
        Mission[Mission Data]
        Status[Status Data]
    end
    
    QGCApp --> LinkInterface
    LinkInterface --> MAVLinkProtocol
    
    MAVLinkProtocol --> Serial
    MAVLinkProtocol --> TCP
    MAVLinkProtocol --> UDP
    MAVLinkProtocol --> WebRTC
    MAVLinkProtocol --> Bluetooth
    
    Serial --> MessageParser
    TCP --> MessageParser
    UDP --> MessageParser
    WebRTC --> MessageParser
    Bluetooth --> MessageParser
    
    MessageParser --> DataValidator
    DataValidator --> StatisticsCollector
    
    MessageBuilder --> Serial
    MessageBuilder --> TCP
    MessageBuilder --> UDP
    MessageBuilder --> WebRTC
    MessageBuilder --> Bluetooth
    
    Vehicle --> Telemetry
    Vehicle --> Status
    Autopilot --> Commands
    Sensors --> Telemetry
    Actuators --> Status
    
    Telemetry --> MessageParser
    Commands --> MessageBuilder
    Parameters --> MessageParser
    Mission --> MessageBuilder
    Status --> MessageParser
```

---

## 영상 스트리밍 구조

```mermaid
graph TB
    subgraph "Video Source"
        Camera[Camera System]
        VideoEncoder[Video Encoder]
        VideoStreamer[Video Streamer]
    end
    
    subgraph "Network Transport"
        UDPStream[UDP Stream]
        TCPStream[TCP Stream]
        WebRTCStream[WebRTC Stream]
        RTSPStream[RTSP Stream]
    end
    
    subgraph "QGroundControl Video Processing"
        VideoManager[VideoManager]
        VideoReceiver[Video Receiver]
        VideoDecoder[Video Decoder]
        VideoRenderer[Video Renderer]
        
        subgraph "Video Formats"
            H264[H.264 Decoder]
            H265[H.265 Decoder]
            MJPEG[MJPEG Decoder]
            RawVideo[Raw Video]
        end
        
        subgraph "Video Processing"
            FrameBuffer[Frame Buffer]
            VideoFilter[Video Filter]
            VideoScaler[Video Scaler]
            VideoRecorder[Video Recorder]
        end
    end
    
    subgraph "Display System"
        QMLRenderer[QML Renderer]
        OpenGLRenderer[OpenGL Renderer]
        VideoWidget[Video Widget]
        FullscreenView[Fullscreen View]
    end
    
    Camera --> VideoEncoder
    VideoEncoder --> VideoStreamer
    
    VideoStreamer --> UDPStream
    VideoStreamer --> TCPStream
    VideoStreamer --> WebRTCStream
    VideoStreamer --> RTSPStream
    
    UDPStream --> VideoReceiver
    TCPStream --> VideoReceiver
    WebRTCStream --> VideoReceiver
    RTSPStream --> VideoReceiver
    
    VideoReceiver --> VideoManager
    VideoManager --> VideoDecoder
    
    VideoDecoder --> H264
    VideoDecoder --> H265
    VideoDecoder --> MJPEG
    VideoDecoder --> RawVideo
    
    H264 --> FrameBuffer
    H265 --> FrameBuffer
    MJPEG --> FrameBuffer
    RawVideo --> FrameBuffer
    
    FrameBuffer --> VideoFilter
    VideoFilter --> VideoScaler
    VideoScaler --> VideoRecorder
    
    VideoScaler --> QMLRenderer
    VideoScaler --> OpenGLRenderer
    
    QMLRenderer --> VideoWidget
    OpenGLRenderer --> VideoWidget
    VideoWidget --> FullscreenView
```

---

## 통신 프로토콜 계층

```mermaid
graph TD
    subgraph "Application Layer"
        QGCApp[QGroundControl Application]
        VehicleApp[Vehicle Application]
    end
    
    subgraph "Presentation Layer"
        MAVLinkProtocol[MAVLink Protocol]
        VideoProtocol[Video Protocol]
        CustomProtocol[Custom Protocol]
    end
    
    subgraph "Session Layer"
        ConnectionManager[Connection Manager]
        SessionHandler[Session Handler]
        Authentication[Authentication]
    end
    
    subgraph "Transport Layer"
        TCP[TCP]
        UDP[UDP]
        SCTP[SCTP - WebRTC]
        Serial[Serial]
        Bluetooth[Bluetooth]
    end
    
    subgraph "Network Layer"
        IP[IP Protocol]
        Routing[Routing]
        NAT[NAT Traversal]
    end
    
    subgraph "Data Link Layer"
        Ethernet[Ethernet]
        WiFi[WiFi]
        Cellular[Cellular]
        Radio[Radio]
    end
    
    subgraph "Physical Layer"
        Cable[Cable]
        Wireless[Wireless]
        Optical[Optical]
    end
    
    QGCApp --> MAVLinkProtocol
    QGCApp --> VideoProtocol
    QGCApp --> CustomProtocol
    
    VehicleApp --> MAVLinkProtocol
    VehicleApp --> VideoProtocol
    VehicleApp --> CustomProtocol
    
    MAVLinkProtocol --> ConnectionManager
    VideoProtocol --> SessionHandler
    CustomProtocol --> Authentication
    
    ConnectionManager --> TCP
    ConnectionManager --> UDP
    SessionHandler --> SCTP
    Authentication --> Serial
    Authentication --> Bluetooth
    
    TCP --> IP
    UDP --> IP
    SCTP --> IP
    Serial --> IP
    Bluetooth --> IP
    
    IP --> Routing
    IP --> NAT
    
    Routing --> Ethernet
    Routing --> WiFi
    Routing --> Cellular
    Routing --> Radio
    
    Ethernet --> Cable
    WiFi --> Wireless
    Cellular --> Wireless
    Radio --> Wireless
```

---

## 비디오 처리 파이프라인

```mermaid
flowchart LR
    A[Video Source] --> B[Network Transport]
    B --> C[Video Receiver]
    C --> D[Demuxer]
    D --> E[Video Decoder]
    E --> F[Frame Processing]
    F --> G[Display Renderer]
    
    subgraph "Video Source"
        A1[Camera]
        A2[Video File]
        A3[Network Stream]
    end
    
    subgraph "Network Transport"
        B1[UDP]
        B2[TCP]
        B3[WebRTC]
        B4[RTSP]
    end
    
    subgraph "Video Receiver"
        C1[Buffer Management]
        C2[Packet Assembly]
        C3[Error Correction]
    end
    
    subgraph "Demuxer"
        D1[Stream Separation]
        D2[Format Detection]
        D3[Metadata Extraction]
    end
    
    subgraph "Video Decoder"
        E1[H.264 Decoder]
        E2[H.265 Decoder]
        E3[MJPEG Decoder]
        E4[Hardware Acceleration]
    end
    
    subgraph "Frame Processing"
        F1[Frame Buffer]
        F2[Image Scaling]
        F3[Color Correction]
        F4[Frame Rate Control]
    end
    
    subgraph "Display Renderer"
        G1[QML Renderer]
        G2[OpenGL Renderer]
        G3[Software Renderer]
        G4[Hardware Renderer]
    end
    
    A1 --> B1
    A2 --> B2
    A3 --> B3
    
    B1 --> C1
    B2 --> C2
    B3 --> C3
    B4 --> C1
    
    C1 --> D1
    C2 --> D2
    C3 --> D3
    
    D1 --> E1
    D2 --> E2
    D3 --> E3
    
    E1 --> F1
    E2 --> F2
    E3 --> F3
    E4 --> F4
    
    F1 --> G1
    F2 --> G2
    F3 --> G3
    F4 --> G4
```

---

## 실시간 데이터 흐름

```mermaid
sequenceDiagram
    participant QGC as QGroundControl
    participant LinkManager as LinkManager
    participant MAVLink as MAVLink Protocol
    participant Vehicle as Vehicle
    participant VideoManager as VideoManager
    participant Camera as Camera
    
    Note over QGC,Camera: 1. 연결 수립
    QGC->>LinkManager: connectLink()
    LinkManager->>MAVLink: initializeProtocol()
    MAVLink->>Vehicle: establishConnection()
    Vehicle->>MAVLink: connectionEstablished()
    MAVLink->>LinkManager: linkConnected()
    LinkManager->>QGC: linkConnected()
    
    Note over QGC,Camera: 2. 비디오 스트림 시작
    QGC->>VideoManager: startVideoStream()
    VideoManager->>Camera: requestVideoStream()
    Camera->>VideoManager: videoStreamStarted()
    VideoManager->>QGC: videoStreamActive()
    
    Note over QGC,Camera: 3. 실시간 데이터 교환
    loop Telemetry Data
        Vehicle->>MAVLink: sendTelemetry()
        MAVLink->>LinkManager: processTelemetry()
        LinkManager->>QGC: telemetryReceived()
    end
    
    loop Video Frames
        Camera->>VideoManager: sendVideoFrame()
        VideoManager->>QGC: videoFrameReceived()
        QGC->>VideoManager: renderFrame()
    end
    
    loop Command Data
        QGC->>LinkManager: sendCommand()
        LinkManager->>MAVLink: processCommand()
        MAVLink->>Vehicle: executeCommand()
        Vehicle->>MAVLink: commandAcknowledged()
        MAVLink->>LinkManager: commandResult()
        LinkManager->>QGC: commandCompleted()
    end
    
    Note over QGC,Camera: 4. 연결 종료
    QGC->>LinkManager: disconnectLink()
    LinkManager->>MAVLink: closeConnection()
    MAVLink->>Vehicle: disconnect()
    Vehicle->>MAVLink: disconnected()
    MAVLink->>LinkManager: linkDisconnected()
    LinkManager->>QGC: linkDisconnected()
    
    QGC->>VideoManager: stopVideoStream()
    VideoManager->>Camera: stopVideoStream()
    Camera->>VideoManager: videoStreamStopped()
    VideoManager->>QGC: videoStreamInactive()
```

---

## 성능 최적화

### 데이터 통신 최적화

```mermaid
graph LR
    subgraph "Communication Optimization"
        A[Protocol Selection] --> B[Connection Pooling]
        B --> C[Data Compression]
        C --> D[Error Correction]
        D --> E[Load Balancing]
        
        A1[UDP for Real-time] --> A
        A2[TCP for Reliable] --> A
        A3[WebRTC for P2P] --> A
        
        B1[Connection Reuse] --> B
        B2[Keep-Alive] --> B
        B3[Connection Limits] --> B
        
        C1[MAVLink Compression] --> C
        C2[Video Compression] --> C
        C3[Custom Compression] --> C
        
        D1[FEC - Forward Error Correction] --> D
        D2[ARQ - Automatic Repeat Request] --> D
        D3[CRC Checks] --> D
        
        E1[Multiple Links] --> E
        E2[Failover] --> E
        E3[Load Distribution] --> E
    end
    
    subgraph "Performance Benefits"
        F[Reduced Latency]
        G[Increased Throughput]
        H[Better Reliability]
        I[Resource Efficiency]
    end
    
    A --> F
    B --> G
    C --> H
    D --> I
    E --> F
```

### 비디오 스트리밍 최적화

```mermaid
graph TB
    subgraph "Video Optimization"
        A[Codec Selection] --> B[Bitrate Control]
        B --> C[Frame Rate Control]
        C --> D[Resolution Scaling]
        D --> E[Hardware Acceleration]
        
        A1[H.264 for Compatibility] --> A
        A2[H.265 for Efficiency] --> A
        A3[AV1 for Future] --> A
        
        B1[Adaptive Bitrate] --> B
        B2[Bandwidth Monitoring] --> B
        B3[Quality Adjustment] --> B
        
        C1[Variable Frame Rate] --> C
        C2[Frame Dropping] --> C
        C3[Smooth Playback] --> C
        
        D1[Resolution Scaling] --> D
        D2[Aspect Ratio] --> D
        D3[Display Optimization] --> D
        
        E1[GPU Decoding] --> E
        E2[Hardware Encoder] --> E
        E3[Memory Management] --> E
    end
    
    subgraph "Quality Metrics"
        F[Low Latency < 100ms]
        G[High Quality > 720p]
        H[Smooth Playback 30fps]
        I[Bandwidth Efficient]
    end
    
    A --> F
    B --> G
    C --> H
    D --> I
    E --> F
```

### 성능 지표 모니터링

| 구성 요소 | 측정 지표 | 목표값 | 최적화 방법 |
|-----------|-----------|--------|-------------|
| **데이터 통신** | RTT | < 50ms | 프로토콜 선택, 연결 풀링 |
| **데이터 처리량** | Throughput | > 1MB/s | 압축, 다중 링크 |
| **패킷 손실률** | Packet Loss | < 1% | FEC, 재전송 |
| **비디오 지연** | Video Latency | < 100ms | 하드웨어 가속, 버퍼 최적화 |
| **비디오 품질** | Resolution | > 720p | 적응형 비트레이트 |
| **CPU 사용률** | CPU Usage | < 30% | 하드웨어 가속, 스레드 최적화 |
| **메모리 사용률** | Memory Usage | < 500MB | 메모리 풀, 가비지 컬렉션 |
| **배터리 소모** | Battery Drain | < 10%/hour | 전력 관리, 백그라운드 최적화 |

---

## 주요 기능 요약

### 1. **다중 통신 프로토콜 지원**
- **Serial**: 안정적인 직접 연결
- **TCP**: 신뢰성 높은 데이터 전송
- **UDP**: 실시간 저지연 통신
- **WebRTC**: P2P 연결 및 NAT 통과
- **Bluetooth**: 근거리 무선 통신

### 2. **MAVLink 프로토콜**
- **표준화된 메시지**: 드론 제어 표준
- **다중 메시지 타입**: 텔레메트리, 명령, 파라미터
- **버전 호환성**: MAVLink 1.0/2.0 지원
- **확장성**: 커스텀 메시지 지원

### 3. **비디오 스트리밍**
- **다중 코덱**: H.264, H.265, MJPEG
- **적응형 스트리밍**: 네트워크 상태에 따른 품질 조정
- **하드웨어 가속**: GPU 디코딩 지원
- **녹화 기능**: 실시간 비디오 저장

### 4. **실시간 처리**
- **저지연 통신**: < 50ms RTT
- **고처리량**: > 1MB/s 데이터 전송
- **안정성**: 자동 재연결, 에러 복구
- **확장성**: 다중 차량 지원

### 5. **성능 최적화**
- **메모리 관리**: 효율적인 버퍼 관리
- **CPU 최적화**: 멀티스레딩, 하드웨어 가속
- **네트워크 최적화**: 연결 풀링, 압축
- **전력 관리**: 배터리 효율성

이 도식화를 통해 QGroundControl의 데이터 통신 및 영상 스트리밍 구조를 명확히 이해할 수 있습니다.
