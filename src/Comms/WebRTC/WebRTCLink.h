#pragma once

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QThread>

#include "LinkInterface.h"
#include "WebRTCConfiguration.h"
#include "WebRTCWorker.h"

class WebRTCLink : public LinkInterface
{
    Q_OBJECT
    Q_PROPERTY(QString rtcStatusMessage READ rtcStatusMessage NOTIFY rtcStatusMessageChanged)
    Q_PROPERTY(RTCModuleSystemInfo rtcModuleSystemInfo READ rtcModuleSystemInfo NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(WebRTCStats webRtcStats READ webRtcStats NOTIFY webRtcStatsChanged)
    Q_PROPERTY(VideoMetrics videoMetrics READ videoMetrics NOTIFY videoMetricsChanged)
    Q_PROPERTY(RTCModuleVersionInfo rtcModuleVersionInfo READ rtcModuleVersionInfo NOTIFY rtcModuleVersionInfoChanged)

    // WebRTC 통계 프로퍼티 (QML에서 편리하게 접근하기 위해)
    Q_PROPERTY(int webRtcRtt READ webRtcRtt NOTIFY webRtcStatsChanged)
    Q_PROPERTY(QString iceCandidate READ iceCandidate NOTIFY webRtcStatsChanged)

    // 송수신 속도
    Q_PROPERTY(double webRtcSent READ webRtcSent NOTIFY webRtcStatsChanged)
    Q_PROPERTY(double webRtcRecv READ webRtcRecv NOTIFY webRtcStatsChanged)

    // 비디오 통계
    Q_PROPERTY(double rtcVideoRate READ rtcVideoRate NOTIFY webRtcStatsChanged)
    Q_PROPERTY(int rtcVideoPacketCount READ rtcVideoPacketCount NOTIFY webRtcStatsChanged)
    Q_PROPERTY(qint64 rtcVideoBytesReceived READ rtcVideoBytesReceived NOTIFY webRtcStatsChanged)

    // RTC Module 시스템 정보 개별 프로퍼티
    Q_PROPERTY(double rtcModuleCpuUsage READ rtcModuleCpuUsage NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleCpuTemperature READ rtcModuleCpuTemperature NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleMemoryUsage READ rtcModuleMemoryUsage NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleNetworkRx READ rtcModuleNetworkRx NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(double rtcModuleNetworkTx READ rtcModuleNetworkTx NOTIFY rtcModuleSystemInfoChanged)
    Q_PROPERTY(QString rtcModuleNetworkInterface READ rtcModuleNetworkInterface NOTIFY rtcModuleSystemInfoChanged)

    // RTC Module 버전 정보 개별 프로퍼티
    Q_PROPERTY(QString rtcModuleCurrentVersion READ rtcModuleCurrentVersion NOTIFY rtcModuleVersionInfoChanged)
    Q_PROPERTY(QString rtcModuleLatestVersion READ rtcModuleLatestVersion NOTIFY rtcModuleVersionInfoChanged)
    Q_PROPERTY(bool rtcModuleUpdateAvailable READ rtcModuleUpdateAvailable NOTIFY rtcModuleVersionInfoChanged)

    // Video Metrics 개별 프로퍼티
    Q_PROPERTY(double videoRtspPacketsPerSec READ videoRtspPacketsPerSec NOTIFY videoMetricsChanged)
    Q_PROPERTY(double videoDecodedFramesPerSec READ videoDecodedFramesPerSec NOTIFY videoMetricsChanged)
    Q_PROPERTY(double videoEncodedFramesPerSec READ videoEncodedFramesPerSec NOTIFY videoMetricsChanged)
    Q_PROPERTY(double videoTeeFramesPerSec READ videoTeeFramesPerSec NOTIFY videoMetricsChanged)
    Q_PROPERTY(double videoSrtFramesPerSec READ videoSrtFramesPerSec NOTIFY videoMetricsChanged)
    Q_PROPERTY(double videoRtpFramesPerSec READ videoRtpFramesPerSec NOTIFY videoMetricsChanged)

   public:
    explicit WebRTCLink(SharedLinkConfigurationPtr &config, QObject *parent = nullptr);
    ~WebRTCLink();

    Q_INVOKABLE void sendCustomMessage(const QString& message);

    bool isConnected() const override;
    void connectLink();
    void reconnectLink();  // 재연결 메서드 추가
    bool isReconnecting() const;  // 자동 재연결 상태 확인

    QString rtcStatusMessage() const { return _rtcStatusMessage; }

    // 비디오 스트림 상태 확인
    bool isVideoStreamActive() const;

    // RTC Module 시스템 정보 getter
    const RTCModuleSystemInfo& rtcModuleSystemInfo() const { return _rtcModuleSystemInfo; }

    // WebRTC 통계 정보 getter
    const WebRTCStats& webRtcStats() const { return _webRtcStats; }

    // 비디오 메트릭 정보 getter
    const VideoMetrics& videoMetrics() const { return _videoMetrics; }

    // RTC Module 버전 정보 getter
    const RTCModuleVersionInfo& rtcModuleVersionInfo() const { return _rtcModuleVersionInfo; }

    // WebRTC 통계 getter 메서드들
    int webRtcRtt() const { return _webRtcStats.rttMs; }
    QString iceCandidate() const { return _webRtcStats.iceCandidate; }

    // 송수신 속도 getter
    double webRtcSent() const { return _webRtcStats.webRtcSent; }
    double webRtcRecv() const { return _webRtcStats.webRtcRecv; }

    // 비디오 통계 getter
    double rtcVideoRate() const { return _webRtcStats.videoRateKBps; }
    int rtcVideoPacketCount() const { return _webRtcStats.videoPacketCount; }
    qint64 rtcVideoBytesReceived() const { return _webRtcStats.videoBytesReceived; }

    // RTC Module 시스템 정보 개별 getter 메서드들
    double rtcModuleCpuUsage() const { return _rtcModuleSystemInfo.cpuUsage; }
    double rtcModuleCpuTemperature() const { return _rtcModuleSystemInfo.cpuTemperature; }
    double rtcModuleMemoryUsage() const { return _rtcModuleSystemInfo.memoryUsage; }
    double rtcModuleNetworkRx() const { return _rtcModuleSystemInfo.networkRx; }
    double rtcModuleNetworkTx() const { return _rtcModuleSystemInfo.networkTx; }
    QString rtcModuleNetworkInterface() const { return _rtcModuleSystemInfo.networkInterface; }

    // RTC Module 버전 정보 개별 getter 메서드들
    QString rtcModuleCurrentVersion() const { return _rtcModuleVersionInfo.currentVersion; }
    QString rtcModuleLatestVersion() const { return _rtcModuleVersionInfo.latestVersion; }
    bool rtcModuleUpdateAvailable() const { return _rtcModuleVersionInfo.updateAvailable; }

    // Video Metrics 개별 getter 메서드들
    double videoRtspPacketsPerSec() const { return _videoMetrics.rtspPacketsPerSec; }
    double videoDecodedFramesPerSec() const { return _videoMetrics.decodedFramesPerSec; }
    double videoEncodedFramesPerSec() const { return _videoMetrics.encodedFramesPerSec; }
    double videoTeeFramesPerSec() const { return _videoMetrics.teeFramesPerSec; }
    double videoSrtFramesPerSec() const { return _videoMetrics.srtFramesPerSec; }
    double videoRtpFramesPerSec() const { return _videoMetrics.rtpFramesPerSec; }

   protected:
    bool _connect() override;
    void disconnect() override;
    void _writeBytes(const QByteArray& bytes) override;

   private slots:
    void _onConnected();
    void _onDisconnected();
    void _onErrorOccurred(const QString &errorString);
    void _onDataReceived(const QByteArray &data);
    void _onDataSent(const QByteArray &data);
    void _onRtcStatusMessageChanged(const QString& message);
    void _onRtcModuleSystemInfoUpdated(const RTCModuleSystemInfo& systemInfo);
    void _onWebRtcStatsUpdated(const WebRTCStats& stats);
    void _onVideoMetricsUpdated(const VideoMetrics& videoMetrics);
    void _onRtcModuleVersionInfoUpdated(const RTCModuleVersionInfo& versionInfo);

   signals:
    void rtcStatusMessageChanged();
    void videoStreamReady(const QString& uri);
    void videoStatsUpdated(double KBps, int packets, qint64 totalBytes);
    void rtcModuleSystemInfoChanged(const RTCModuleSystemInfo& systemInfo);
    void webRtcStatsChanged(const WebRTCStats& stats);
    void videoMetricsChanged(const VideoMetrics& videoMetrics);
    void rtcModuleVersionInfoChanged(const RTCModuleVersionInfo& versionInfo);

   private:
    const WebRTCConfiguration *_rtcConfig = nullptr;
    WebRTCWorker *_worker = nullptr;
    QThread *_workerThread = nullptr;
    QString _rtcStatusMessage = "";

    // RTC Module 시스템 정보
    RTCModuleSystemInfo _rtcModuleSystemInfo;

    // WebRTC 통계 정보
    WebRTCStats _webRtcStats;

    // 비디오 메트릭 정보
    VideoMetrics _videoMetrics;

    // RTC Module 버전 정보
    RTCModuleVersionInfo _rtcModuleVersionInfo;
};
