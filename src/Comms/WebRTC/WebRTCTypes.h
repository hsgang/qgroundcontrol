#pragma once

// WebRTC status value types shared by the WebRTC link/session and the QML indicators.
// Moved out of WebRTCWorker.h so they outlive the libdatachannel worker.

#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QJsonObject>
#include <QtCore/QDateTime>
#include <QtCore/QMetaType>
#include <QtCore/QtMath>

// RTC 모듈 시스템 정보를 효율적으로 묶어서 전달하기 위한 구조체
struct RTCModuleSystemInfo {
    double cpuUsage = 0.0;
    double cpuTemperature = 0.0;
    double memoryUsage = 0.0;
    double networkRx = 0.0;
    double networkTx = 0.0;
    QString networkInterface = "";

    // JSON에서 파싱하는 생성자
    RTCModuleSystemInfo(const QJsonObject& json) {
        cpuUsage = json["cpu_usage"].toDouble();
        cpuTemperature = json["cpu_temperature"].toDouble();
        memoryUsage = json["memory_usage_percent"].toDouble();
        networkRx = json["network_rx_mbps"].toDouble();
        networkTx = json["network_tx_mbps"].toDouble();
        networkInterface = json["network_interface"].toString();
    }

    // 기본 생성자
    RTCModuleSystemInfo() = default;

    // 비교 연산자 (변경 감지용)
    bool operator==(const RTCModuleSystemInfo& other) const {
        return qFuzzyCompare(cpuUsage, other.cpuUsage) &&
               qFuzzyCompare(cpuTemperature, other.cpuTemperature) &&
               qFuzzyCompare(memoryUsage, other.memoryUsage) &&
               qFuzzyCompare(networkRx, other.networkRx) &&
               qFuzzyCompare(networkTx, other.networkTx) &&
               networkInterface == other.networkInterface;
    }

    bool operator!=(const RTCModuleSystemInfo& other) const {
        return !(*this == other);
    }

    // 유효성 검사
    bool isValid() const {
        return cpuUsage >= 0.0 && cpuUsage <= 100.0 &&
               cpuTemperature >= -50.0 && cpuTemperature <= 150.0 &&
               memoryUsage >= 0.0 && memoryUsage <= 100.0 &&
               networkRx >= 0.0 && networkTx >= 0.0;
    }

    // 디버그 출력용
    QString toString() const {
        return QString("CPU: %1%%, Temp: %2°C, Mem: %3%%, Net: %4/%5 Mbps (%6)")
               .arg(cpuUsage, 0, 'f', 1)
               .arg(cpuTemperature, 0, 'f', 1)
               .arg(memoryUsage, 0, 'f', 1)
               .arg(networkRx, 0, 'f', 2)
               .arg(networkTx, 0, 'f', 2)
               .arg(networkInterface);
    }
};

// 비디오 메트릭 정보를 효율적으로 묶어서 전달하기 위한 구조체
struct VideoMetrics {
    double rtspPacketsPerSec = 0.0;
    double decodedFramesPerSec = 0.0;
    double encodedFramesPerSec = 0.0;
    double teeFramesPerSec = 0.0;
    double srtFramesPerSec = 0.0;
    double rtpFramesPerSec = 0.0;
    qint64 timestamp = 0;

    // JSON에서 파싱하는 생성자
    VideoMetrics(const QJsonObject& json) {
        timestamp = json["timestamp"].toVariant().toLongLong();

        QJsonObject perSecond = json["per_second"].toObject();
        rtspPacketsPerSec = perSecond["rtsp_packets_ps"].toDouble();
        decodedFramesPerSec = perSecond["decoded_frames_ps"].toDouble();
        encodedFramesPerSec = perSecond["encoded_frames_ps"].toDouble();
        teeFramesPerSec = perSecond["tee_frames_ps"].toDouble();
        srtFramesPerSec = perSecond["srt_frames_ps"].toDouble();
        rtpFramesPerSec = perSecond["rtp_frames_ps"].toDouble();
    }

    // 기본 생성자
    VideoMetrics() = default;

    // 비교 연산자 (변경 감지용)
    bool operator==(const VideoMetrics& other) const {
        return qFuzzyCompare(rtspPacketsPerSec, other.rtspPacketsPerSec) &&
               qFuzzyCompare(decodedFramesPerSec, other.decodedFramesPerSec) &&
               qFuzzyCompare(encodedFramesPerSec, other.encodedFramesPerSec) &&
               qFuzzyCompare(teeFramesPerSec, other.teeFramesPerSec) &&
               qFuzzyCompare(srtFramesPerSec, other.srtFramesPerSec) &&
               qFuzzyCompare(rtpFramesPerSec, other.rtpFramesPerSec) &&
               timestamp == other.timestamp;
    }

    bool operator!=(const VideoMetrics& other) const {
        return !(*this == other);
    }

    // 유효성 검사
    bool isValid() const {
        return rtspPacketsPerSec >= 0.0 && decodedFramesPerSec >= 0.0 &&
               encodedFramesPerSec >= 0.0 && teeFramesPerSec >= 0.0 &&
               srtFramesPerSec >= 0.0 && rtpFramesPerSec >= 0.0 &&
               timestamp > 0;
    }

    // 디버그 출력용
    QString toString() const {
        return QString("RTSP: %1 pkt/s, Decoded: %2 fps, Encoded: %3 fps, RTP: %6 fps")
               .arg(rtspPacketsPerSec, 0, 'f', 1)
               .arg(decodedFramesPerSec, 0, 'f', 1)
               .arg(encodedFramesPerSec, 0, 'f', 1)
               .arg(rtpFramesPerSec, 0, 'f', 1);
    }
};

// RTC 모듈 버전 정보를 저장하기 위한 구조체
struct RTCModuleVersionInfo {
    QString currentVersion = "";
    QString latestVersion = "";
    qint64 timestamp = 0;
    bool updateAvailable = false;

    // JSON에서 파싱하는 생성자
    RTCModuleVersionInfo(const QJsonObject& json) {
        currentVersion = json["current_version"].toString();
        latestVersion = json["latest_version"].toString();
        timestamp = json["timestamp"].toVariant().toLongLong();
        updateAvailable = _compareVersions(currentVersion, latestVersion) < 0;
    }

    // 기본 생성자
    RTCModuleVersionInfo() = default;

    // 비교 연산자 (변경 감지용)
    bool operator==(const RTCModuleVersionInfo& other) const {
        return currentVersion == other.currentVersion &&
               latestVersion == other.latestVersion &&
               timestamp == other.timestamp &&
               updateAvailable == other.updateAvailable;
    }

    bool operator!=(const RTCModuleVersionInfo& other) const {
        return !(*this == other);
    }

    // 유효성 검사
    bool isValid() const {
        return !currentVersion.isEmpty() && !latestVersion.isEmpty() && timestamp > 0;
    }

    // 디버그 출력용
    QString toString() const {
        return QString("Current: %1, Latest: %2, Update: %3, Time: %4")
               .arg(currentVersion)
               .arg(latestVersion)
               .arg(updateAvailable ? "Available" : "Up to date")
               .arg(QDateTime::fromMSecsSinceEpoch(timestamp).toString("yyyy-MM-dd hh:mm:ss"));
    }

private:
    // 버전 비교 함수 (semantic versioning 지원)
    int _compareVersions(const QString& v1, const QString& v2) const {
        QStringList parts1 = v1.split('.');
        QStringList parts2 = v2.split('.');

        int maxLength = qMax(parts1.size(), parts2.size());

        for (int i = 0; i < maxLength; ++i) {
            int num1 = (i < parts1.size()) ? parts1[i].toInt() : 0;
            int num2 = (i < parts2.size()) ? parts2[i].toInt() : 0;

            if (num1 < num2) return -1;
            if (num1 > num2) return 1;
        }

        return 0; // 동일한 버전
    }
};

Q_DECLARE_METATYPE(RTCModuleSystemInfo)
Q_DECLARE_METATYPE(VideoMetrics)
Q_DECLARE_METATYPE(RTCModuleVersionInfo)
