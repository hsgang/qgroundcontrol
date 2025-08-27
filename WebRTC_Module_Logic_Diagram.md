# WebRTC 모듈 로직 도식화

## 목차
1. [시스템 아키텍처](#시스템-아키텍처)
2. [클래스 구조](#클래스-구조)
3. [연결 수립 과정](#연결-수립-과정)
4. [데이터 전송 흐름](#데이터-전송-흐름)
5. [시그널링 메시지 처리](#시그널링-메시지-처리)
6. [에러 처리 및 복구](#에러-처리-및-복구)
7. [성능 최적화](#성능-최적화)

---

## 시스템 아키텍처

```mermaid
graph TB
    subgraph "QGroundControl Application"
        QGC[QGroundControl App]
        LinkManager[LinkManager]
        WebRTCLink[WebRTCLink Interface]
    end
    
    subgraph "WebRTC Module"
        WebRTCWorker[WebRTCWorker Engine]
        WebRTCConfig[WebRTCConfiguration]
        SignalingManager[SignalingServerManager]
        
        subgraph "Core Components"
            PeerConnection[PeerConnection]
            DataChannels[Data Channels]
            VideoTracks[Video Tracks]
            SCTPSettings[SCTP Settings]
        end
        
        subgraph "Data Processing"
            MavlinkProcessor[MAVLink Processor]
            CustomProcessor[Custom Message Processor]
            VideoProcessor[Video Processor]
        end
        
        subgraph "Statistics & Monitoring"
            StatsCollector[Statistics Collector]
            HealthMonitor[Health Monitor]
            RTTMonitor[RTT Monitor]
        end
    end
    
    subgraph "External Services"
        SignalingServer[Signaling Server]
        STUNServer[STUN Server]
        TURNServer[TURN Server]
        VideoManager[Video Manager]
    end
    
    subgraph "Remote Peers"
        RemotePeer[Remote Peer]
    end
    
    QGC --> LinkManager
    LinkManager --> WebRTCLink
    WebRTCLink --> WebRTCWorker
    WebRTCWorker --> WebRTCConfig
    WebRTCWorker --> SignalingManager
    
    WebRTCWorker --> PeerConnection
    PeerConnection --> DataChannels
    PeerConnection --> VideoTracks
    PeerConnection --> SCTPSettings
    
    DataChannels --> MavlinkProcessor
    DataChannels --> CustomProcessor
    VideoTracks --> VideoProcessor
    
    MavlinkProcessor --> StatsCollector
    CustomProcessor --> StatsCollector
    VideoProcessor --> StatsCollector
    
    StatsCollector --> HealthMonitor
    HealthMonitor --> RTTMonitor
    
    SignalingManager --> SignalingServer
    STUNServer --> PeerConnection
    TURNServer --> PeerConnection
    VideoProcessor --> VideoManager
    
    SignalingServer --> RemotePeer
```

---

## 클래스 구조

```mermaid
classDiagram
    class WebRTCLink {
        +WebRTCWorker* worker
        +WebRTCConfiguration* config
        +connectLink()
        +disconnectLink()
        +writeBytes()
        +readBytes()
    }
    
    class WebRTCWorker {
        -WebRTCConfiguration* _config
        -std::shared_ptr~rtc::PeerConnection~ _peerConnection
        -std::shared_ptr~rtc::DataChannel~ _mavlinkDataChannel
        -std::shared_ptr~rtc::DataChannel~ _customDataChannel
        -SignalingServerManager* _signalingManager
        -QTimer* _statsTimer
        -QTimer* _reconnectTimer
        +start()
        +stop()
        +writeData()
        -_setupPeerConnection()
        -_setupMavlinkDataChannel()
        -_setupCustomDataChannel()
        -_handleTrackReceived()
    }
    
    class WebRTCConfiguration {
        -QString _roomId
        -QString _peerId
        -QString _targetPeerId
        +setRoomId()
        +setPeerId()
        +setTargetPeerId()
        +stunServer()
        +turnServer()
    }
    
    class SignalingServerManager {
        -QWebSocket* _webSocket
        -QString _serverUrl
        -QString _roomId
        -QString _peerId
        +connectToServer()
        +disconnectFromServer()
        +registerPeer()
        +sendSignalingMessage()
        -_handleWebSocketMessage()
    }
    
    WebRTCLink --> WebRTCWorker
    WebRTCLink --> WebRTCConfiguration
    WebRTCWorker --> WebRTCConfiguration
    WebRTCWorker --> SignalingServerManager
```

---

## 연결 수립 과정

```mermaid
sequenceDiagram
    participant QGC as QGroundControl
    participant WebRTCLink as WebRTCLink
    participant WebRTCWorker as WebRTCWorker
    participant SignalingManager as SignalingManager
    participant SignalingServer as Signaling Server
    participant STUN as STUN Server
    participant TURN as TURN Server
    participant RemotePeer as Remote Peer
    
    Note over QGC,RemotePeer: 1. 초기화 단계
    QGC->>WebRTCLink: connectLink()
    WebRTCLink->>WebRTCWorker: start()
    WebRTCWorker->>WebRTCWorker: initializeLogger()
    WebRTCWorker->>WebRTCWorker: _setupSignalingManager()
    
    Note over QGC,RemotePeer: 2. SCTP 설정 적용
    WebRTCWorker->>WebRTCWorker: _setupPeerConnection()
    WebRTCWorker->>WebRTCWorker: rtcSetSctpSettings()
    
    Note over QGC,RemotePeer: 3. ICE 서버 설정
    WebRTCWorker->>STUN: Configure STUN Server
    WebRTCWorker->>TURN: Configure TURN Server
    
    Note over QGC,RemotePeer: 4. PeerConnection 생성
    WebRTCWorker->>WebRTCWorker: Create PeerConnection
    WebRTCWorker->>WebRTCWorker: Setup Data Channels
    WebRTCWorker->>WebRTCWorker: Setup Video Tracks
    
    Note over QGC,RemotePeer: 5. 시그널링 서버 연결
    WebRTCWorker->>SignalingManager: registerPeer()
    SignalingManager->>SignalingServer: WebSocket Connect
    SignalingServer->>SignalingManager: Connection Established
    SignalingManager->>SignalingServer: Register Peer
    
    Note over QGC,RemotePeer: 6. Offer/Answer 교환
    alt Answerer Mode (QGC)
        RemotePeer->>SignalingServer: Send Offer
        SignalingServer->>SignalingManager: Receive Offer
        SignalingManager->>WebRTCWorker: handleRemoteDescription()
        WebRTCWorker->>WebRTCWorker: Create Answer
        WebRTCWorker->>SignalingManager: handleLocalDescription()
        SignalingManager->>SignalingServer: Send Answer
        SignalingServer->>RemotePeer: Receive Answer
    else Offerer Mode (QGC)
        WebRTCWorker->>WebRTCWorker: Create Offer
        WebRTCWorker->>SignalingManager: handleLocalDescription()
        SignalingManager->>SignalingServer: Send Offer
        SignalingServer->>RemotePeer: Receive Offer
        RemotePeer->>SignalingServer: Send Answer
        SignalingServer->>SignalingManager: Receive Answer
        SignalingManager->>WebRTCWorker: handleRemoteDescription()
    end
    
    Note over QGC,RemotePeer: 7. ICE Candidate 교환
    WebRTCWorker->>SignalingManager: handleLocalCandidate()
    SignalingManager->>SignalingServer: Send ICE Candidates
    SignalingServer->>RemotePeer: Forward ICE Candidates
    RemotePeer->>SignalingServer: Send ICE Candidates
    SignalingServer->>SignalingManager: Forward ICE Candidates
    SignalingManager->>WebRTCWorker: handleRemoteCandidate()
    
    Note over QGC,RemotePeer: 8. 연결 수립 완료
    WebRTCWorker->>WebRTCWorker: ICE Connection Established
    WebRTCWorker->>WebRTCWorker: Data Channels Open
    WebRTCWorker->>WebRTCWorker: Video Tracks Active
    WebRTCWorker->>WebRTCLink: Connection Ready
    WebRTCLink->>QGC: Link Connected
```

---

## 데이터 전송 흐름

```mermaid
flowchart TD
    A[QGroundControl App] --> B[WebRTCLink::writeBytes]
    B --> C[WebRTCWorker::writeData]
    
    C --> D{Data Channel Open?}
    D -->|No| E[Queue Data / Error]
    D -->|Yes| F[Send via DataChannel]
    
    F --> G[rtc::binary Data]
    G --> H[Remote Peer]
    
    H --> I[Remote Processing]
    I --> J[Response Data]
    J --> K[DataChannel onMessage]
    
    K --> L{Message Type?}
    L -->|Binary| M[MAVLink Data]
    L -->|Text| N[Custom Message]
    
    M --> O[Process MAVLink]
    N --> P[Process Custom]
    
    O --> Q[Update Statistics]
    P --> Q
    
    Q --> R[Emit bytesReceived]
    R --> S[QGroundControl App]
    
    subgraph "Statistics Collection"
        T[DataChannelSentCalc]
        U[DataChannelReceivedCalc]
        V[RTT Calculation]
    end
    
    F --> T
    K --> U
    Q --> V
```

---

## 시그널링 메시지 처리

```mermaid
stateDiagram-v2
    [*] --> Disconnected
    
    Disconnected --> Connecting : WebSocket Connect
    Connecting --> Connected : Connection Established
    Connected --> Registered : Peer Registration
    Registered --> WaitingForMessages : Ready for Signaling
    
    WaitingForMessages --> ProcessingOffer : Receive Offer
    ProcessingOffer --> CreatingAnswer : Valid Offer
    CreatingAnswer --> SendingAnswer : Answer Created
    SendingAnswer --> WaitingForCandidates : Answer Sent
    
    WaitingForMessages --> CreatingOffer : Initiate Connection
    CreatingOffer --> SendingOffer : Offer Created
    SendingOffer --> WaitingForAnswer : Offer Sent
    WaitingForAnswer --> ProcessingAnswer : Receive Answer
    ProcessingAnswer --> WaitingForCandidates : Answer Processed
    
    WaitingForCandidates --> ExchangingCandidates : ICE Candidates
    ExchangingCandidates --> Connected : ICE Connection Established
    ExchangingCandidates --> ExchangingCandidates : More Candidates
    
    Connected --> DataChannelOpen : Data Channel Ready
    DataChannelOpen --> VideoStreamActive : Video Track Ready
    VideoStreamActive --> Operational : Full Connection Ready
    
    Operational --> Disconnected : Connection Lost
    Operational --> Operational : Data Exchange
    
    Disconnected --> [*] : Cleanup Complete
```

---

## 에러 처리 및 복구

```mermaid
flowchart TD
    A[Error Detection] --> B{Error Type?}
    
    B -->|Connection Lost| C[Connection Recovery]
    B -->|Data Channel Error| D[Data Channel Recovery]
    B -->|Video Stream Error| E[Video Stream Recovery]
    B -->|Signaling Error| F[Signaling Recovery]
    B -->|ICE Failure| G[ICE Recovery]
    
    C --> H[Attempt Reconnection]
    D --> I[Recreate Data Channel]
    E --> J[Restart Video Track]
    F --> K[Reconnect Signaling]
    G --> L[ICE Restart]
    
    H --> M{Recovery Success?}
    I --> M
    J --> M
    K --> M
    L --> M
    
    M -->|Yes| N[Resume Normal Operation]
    M -->|No| O[Increment Failure Count]
    
    O --> P{Failure Count > Threshold?}
    P -->|Yes| Q[Mark Connection Unhealthy]
    P -->|No| R[Retry Recovery]
    
    Q --> S[Emit Error Signal]
    R --> H
    
    N --> T[Reset Failure Count]
    S --> U[Notify Application]
    
    T --> V[Continue Operation]
    U --> V
    
    subgraph "Error Handling Strategies"
        W[Exponential Backoff]
        X[Circuit Breaker Pattern]
        Y[Graceful Degradation]
    end
    
    O --> W
    Q --> X
    S --> Y
```

---

## 성능 최적화

### SCTP 설정 최적화

```mermaid
graph LR
    subgraph "SCTP Configuration"
        A[rtcSetSctpSettings] --> B[Buffer Settings]
        A --> C[Congestion Control]
        A --> D[Retransmission Settings]
        A --> E[Heartbeat Settings]
        
        B --> F[recvBufferSize: 256KB]
        B --> G[sendBufferSize: 256KB]
        B --> H[maxChunksOnQueue: 1000]
        
        C --> I[initialCongestionWindow: 10]
        C --> J[maxBurst: 5]
        C --> K[congestionControlModule: RFC2581]
        
        D --> L[minRetransmitTimeoutMs: 1000]
        D --> M[maxRetransmitTimeoutMs: 5000]
        D --> N[initialRetransmitTimeoutMs: 3000]
        D --> O[maxRetransmitAttempts: 5]
        
        E --> P[heartbeatIntervalMs: 10000]
        E --> Q[delayedSackTimeMs: 200]
    end
    
    subgraph "Performance Benefits"
        R[Improved Throughput]
        S[Reduced Latency]
        T[Better Reliability]
        U[Efficient Resource Usage]
    end
    
    F --> R
    G --> R
    I --> S
    K --> S
    L --> T
    O --> T
    H --> U
    P --> U
```

### 타이머 기반 동기화

```mermaid
gantt
    title WebRTC Timer Management
    dateFormat X
    axisFormat %L
    
    section Statistics Timer
    Stats Update    :0, 1000
    Stats Update    :1000, 1000
    Stats Update    :2000, 1000
    
    section RTT Timer
    RTT Measurement :0, 1000
    RTT Measurement :1000, 1000
    RTT Measurement :2000, 1000
    
    section Reconnect Timer
    Reconnect Check :0, 5000
    Reconnect Check :5000, 5000
    Reconnect Check :10000, 5000
    
    section Health Check
    Health Monitor  :0, 3000
    Health Monitor  :3000, 3000
    Health Monitor  :6000, 3000
```

### 성능 지표 모니터링

| 구성 요소 | 측정 지표 | 목표값 | 모니터링 방법 |
|-----------|-----------|--------|---------------|
| **연결 성능** | 연결 시간 | < 2초 | 시그널링 완료까지 시간 |
| **데이터 전송** | RTT | < 50ms | Ping/Pong 메시지 |
| **처리량** | 데이터 속도 | > 100KB/s | 바이트 카운터 |
| **품질** | 패킷 손실률 | < 5% | 시퀀스 번호 분석 |
| **안정성** | 연결 지속시간 | > 1시간 | 연결 상태 모니터링 |
| **SCTP 성능** | 버퍼 사용률 | < 80% | SCTP 통계 모니터링 |

---

## 주요 기능 요약

### 1. **다중 프로토콜 지원**
- MAVLink 데이터 채널
- 커스텀 메시지 채널
- H.264 비디오 스트림

### 2. **자동 재연결**
- 지수 백오프 알고리즘
- 회로 차단기 패턴
- 우아한 성능 저하

### 3. **실시간 모니터링**
- RTT 측정
- 처리량 계산
- 연결 상태 추적

### 4. **성능 최적화**
- SCTP 설정 튜닝
- 버퍼 크기 최적화
- 혼잡 제어 알고리즘

### 5. **에러 처리**
- 포괄적인 에러 감지
- 자동 복구 메커니즘
- 사용자 알림 시스템

이 도식화를 통해 WebRTC 모듈의 전체적인 구조와 동작 방식을 명확히 이해할 수 있습니다.
