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
