#pragma once

#include <QtCore/QString>
#include <QtCore/QMetaType>
#include <QtCore/QtMath>

// WebRTC 통계 정보를 효율적으로 묶어서 전달하기 위한 구조체
struct WebRTCStats {
    int rttMs = 0;  // RTT (Round Trip Time)

    // ICE Candidate 정보
    QString iceCandidate;  // 선택된 candidate pair

    // 송수신 속도
    double webRtcSent = 0.0;
    double webRtcRecv = 0.0;

    // 비디오 통계
    double videoRateKBps = 0.0;
    int videoPacketCount = 0;
    qint64 videoBytesReceived = 0;

    // 기본 생성자
    WebRTCStats() = default;

    // 비교 연산자 (변경 감지용)
    bool operator==(const WebRTCStats& other) const {
        return rttMs == other.rttMs &&
               iceCandidate == other.iceCandidate &&
               qFuzzyCompare(webRtcSent, other.webRtcSent) &&
               qFuzzyCompare(webRtcRecv, other.webRtcRecv) &&
               qFuzzyCompare(videoRateKBps, other.videoRateKBps) &&
               videoPacketCount == other.videoPacketCount &&
               videoBytesReceived == other.videoBytesReceived;
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
        QString rttStr = QString("RTT: %1ms").arg(rttMs);
        if (!iceCandidate.isEmpty()) {
            rttStr += QString(" [%1]").arg(iceCandidate);
        }

        QString dataRateStr = QString("Sent: %1 KB/s, Recv: %2 KB/s")
                              .arg(webRtcSent, 0, 'f', 2)
                              .arg(webRtcRecv, 0, 'f', 2);

        QString videoRateStr = QString("Video: %1 KB/s (%2 packets, %3 bytes)")
                               .arg(videoRateKBps, 0, 'f', 2)
                               .arg(videoPacketCount)
                               .arg(videoBytesReceived);

        return QString("%1, %2, %3")
               .arg(rttStr)
               .arg(dataRateStr)
               .arg(videoRateStr);
    }
};

Q_DECLARE_METATYPE(WebRTCStats)
