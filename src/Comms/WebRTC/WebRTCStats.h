#pragma once

#include <QtCore/QString>
#include <QtCore/QMetaType>
#include <QtCore/QtMath>

// WebRTC 통계 정보를 효율적으로 묶어서 전달하기 위한 구조체
struct WebRTCStats {
    int rttMs = 0;  // 통합 RTT (dual-path에서는 더 낮은 값)
    int rttDirectMs = 0;  // Direct 경로 RTT
    int rttRelayMs = 0;   // Relay 경로 RTT

    // ICE Candidate 정보
    QString iceCandidateDirect;  // Direct 경로의 선택된 candidate pair
    QString iceCandidateRelay;   // Relay 경로의 선택된 candidate pair

    // 통합 송수신 속도 (dual-path에서는 합산)
    double webRtcSent = 0.0;
    double webRtcRecv = 0.0;

    // Direct 경로 송수신 속도
    double webRtcSentDirect = 0.0;
    double webRtcRecvDirect = 0.0;

    // Relay 경로 송수신 속도
    double webRtcSentRelay = 0.0;
    double webRtcRecvRelay = 0.0;

    // 통합 비디오 통계
    double videoRateKBps = 0.0;
    int videoPacketCount = 0;
    qint64 videoBytesReceived = 0;

    // Direct 경로 비디오 통계
    double videoRateDirectKBps = 0.0;
    int videoPacketCountDirect = 0;
    qint64 videoBytesReceivedDirect = 0;

    // Relay 경로 비디오 통계
    double videoRateRelayKBps = 0.0;
    int videoPacketCountRelay = 0;
    qint64 videoBytesReceivedRelay = 0;

    // 기본 생성자
    WebRTCStats() = default;

    // 비교 연산자 (변경 감지용)
    bool operator==(const WebRTCStats& other) const {
        return rttMs == other.rttMs &&
               rttDirectMs == other.rttDirectMs &&
               rttRelayMs == other.rttRelayMs &&
               iceCandidateDirect == other.iceCandidateDirect &&
               iceCandidateRelay == other.iceCandidateRelay &&
               qFuzzyCompare(webRtcSent, other.webRtcSent) &&
               qFuzzyCompare(webRtcRecv, other.webRtcRecv) &&
               qFuzzyCompare(webRtcSentDirect, other.webRtcSentDirect) &&
               qFuzzyCompare(webRtcRecvDirect, other.webRtcRecvDirect) &&
               qFuzzyCompare(webRtcSentRelay, other.webRtcSentRelay) &&
               qFuzzyCompare(webRtcRecvRelay, other.webRtcRecvRelay) &&
               qFuzzyCompare(videoRateKBps, other.videoRateKBps) &&
               videoPacketCount == other.videoPacketCount &&
               videoBytesReceived == other.videoBytesReceived &&
               qFuzzyCompare(videoRateDirectKBps, other.videoRateDirectKBps) &&
               videoPacketCountDirect == other.videoPacketCountDirect &&
               videoBytesReceivedDirect == other.videoBytesReceivedDirect &&
               qFuzzyCompare(videoRateRelayKBps, other.videoRateRelayKBps) &&
               videoPacketCountRelay == other.videoPacketCountRelay &&
               videoBytesReceivedRelay == other.videoBytesReceivedRelay;
    }

    bool operator!=(const WebRTCStats& other) const {
        return !(*this == other);
    }

    // 유효성 검사
    bool isValid() const {
        return rttMs >= 0 && webRtcSent >= 0.0 && webRtcRecv >= 0.0 &&
               videoRateKBps >= 0.0 && videoPacketCount >= 0 && videoBytesReceived >= 0;
    }

    // 디버그 출력용
    QString toString() const {
        QString rttStr;
        if (rttDirectMs > 0 || rttRelayMs > 0) {
            rttStr = QString("RTT: %1ms (Direct: %2ms [%3], Relay: %4ms [%5])")
                     .arg(rttMs)
                     .arg(rttDirectMs > 0 ? QString::number(rttDirectMs) : "N/A")
                     .arg(iceCandidateDirect.isEmpty() ? "N/A" : iceCandidateDirect)
                     .arg(rttRelayMs > 0 ? QString::number(rttRelayMs) : "N/A")
                     .arg(iceCandidateRelay.isEmpty() ? "N/A" : iceCandidateRelay);
        } else {
            rttStr = QString("RTT: %1ms").arg(rttMs);
        }

        QString dataRateStr;
        if (webRtcSentDirect > 0 || webRtcSentRelay > 0) {
            dataRateStr = QString("Sent: %1 KB/s (Direct: %2, Relay: %3), Recv: %4 KB/s (Direct: %5, Relay: %6)")
                          .arg(webRtcSent, 0, 'f', 2)
                          .arg(webRtcSentDirect > 0 ? QString::number(webRtcSentDirect, 'f', 2) : "N/A")
                          .arg(webRtcSentRelay > 0 ? QString::number(webRtcSentRelay, 'f', 2) : "N/A")
                          .arg(webRtcRecv, 0, 'f', 2)
                          .arg(webRtcRecvDirect > 0 ? QString::number(webRtcRecvDirect, 'f', 2) : "N/A")
                          .arg(webRtcRecvRelay > 0 ? QString::number(webRtcRecvRelay, 'f', 2) : "N/A");
        } else {
            dataRateStr = QString("Sent: %1 KB/s, Recv: %2 KB/s")
                          .arg(webRtcSent, 0, 'f', 2)
                          .arg(webRtcRecv, 0, 'f', 2);
        }

        QString videoRateStr;
        if (videoRateDirectKBps > 0 || videoRateRelayKBps > 0) {
            videoRateStr = QString("Video: %1 KB/s (Direct: %2 KB/s [%3 pkts], Relay: %4 KB/s [%5 pkts])")
                           .arg(videoRateKBps, 0, 'f', 2)
                           .arg(videoRateDirectKBps, 0, 'f', 2)
                           .arg(videoPacketCountDirect)
                           .arg(videoRateRelayKBps, 0, 'f', 2)
                           .arg(videoPacketCountRelay);
        } else {
            videoRateStr = QString("Video: %1 KB/s (%2 packets, %3 bytes)")
                           .arg(videoRateKBps, 0, 'f', 2)
                           .arg(videoPacketCount)
                           .arg(videoBytesReceived);
        }

        return QString("%1, %2, %3")
               .arg(rttStr)
               .arg(dataRateStr)
               .arg(videoRateStr);
    }
};

Q_DECLARE_METATYPE(WebRTCStats)
