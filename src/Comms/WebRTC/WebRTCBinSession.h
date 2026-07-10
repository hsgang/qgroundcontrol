#pragma once

// -----------------------------------------------------------------------------
// WebRTCBinSession — PoC WebRTC receive path built on GStreamer `webrtcbin`.
//
// This is an ALTERNATIVE to the libdatachannel WebRTCWorker, used to validate
// that webrtcbin (with its built-in rtpbin NACK/RTX jitter buffer) delivers the
// clean, low-latency video a browser gets from the same drone — which the
// libdatachannel + hand-rolled appsrc bridge does not.
//
// Scope of this first cut (desktop PoC):
//   * Reuses SignalingServerManager (auth, WS, GCS registration, offer/answer/ICE).
//   * Role: answerer. The drone sends the offer (sendonly video + datachannels).
//   * Video: webrtcbin recv pad -> decodebin -> videoconvert -> autovideosink
//     (a standalone window). Proves media quality without touching the QGC QML
//     sink. Wiring into QGCQVideoSinkController is the NEXT increment.
//   * Data channels: on-data-channel is logged; the MAVLink byte bridge to
//     WebRTCLink is a TODO (see .cc).
//
// The existing libdatachannel path is untouched; this compiles only when
// GStreamer video streaming is enabled and is selected behind a build flag.
// -----------------------------------------------------------------------------

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QJsonObject>
#include <QtCore/QHash>
#include <QtCore/QLoggingCategory>
#include <QtCore/QMutex>

#include <atomic>

class QTimer;

#include <gst/gst.h>

// The GStreamer WebRTC library is flagged "unstable API"; without this define its
// headers emit a #warning, which MSVC rejects as an invalid preprocessor command.
#ifndef GST_USE_UNSTABLE_API
#define GST_USE_UNSTABLE_API
#endif
#include <gst/webrtc/webrtc.h>

#include "WebRTCTypes.h"    // RTCModuleSystemInfo / VideoMetrics / RTCModuleVersionInfo
#include "WebRTCStats.h"    // WebRTCStats

Q_DECLARE_LOGGING_CATEGORY(WebRTCBinLog)

class SignalingServerManager;

/// Turn servers arrive from the /bundle response as one-or-more url + a shared
/// time-limited username/credential. webrtcbin wants a single URI per server in
/// the form turn(s)://username:credential@host:port.
struct WebRTCBinTurn {
    QStringList urls;
    QString     username;
    QString     credential;
};

class WebRTCBinSession : public QObject
{
    Q_OBJECT

public:
    struct Config {
        QString gcsId;             ///< our GCS id (e.g. "gcs_XXXX")
        QString targetDroneId;     ///< drone we pair with
        QString stunServer;        ///< "stun://host:port" (optional)
        WebRTCBinTurn turn;        ///< time-limited TURN from /bundle (optional)
        bool    showDebugWindow = false; ///< true: standalone autovideosink; false: render inside QGC
    };

    explicit WebRTCBinSession(const Config &config, QObject *parent = nullptr);
    ~WebRTCBinSession() override;

    /// Build the pipeline, register the GCS, and start listening for the drone offer.
    bool start();
    /// Tear down the pipeline and unregister.
    void stop();

    /// Send bytes on the "mavlink" data channel (no-op until the channel opens).
    void sendMavlink(const QByteArray &data);

signals:
    void connected();
    void disconnected();
    void errorOccurred(const QString &reason);
    /// Emitted for every payload received on the "mavlink" data channel (binary).
    void mavlinkDataReceived(const QByteArray &data);
    /// Emitted after a payload is handed to the "mavlink" data channel, so the link
    /// can keep its sent-byte statistics in sync with the libdatachannel path.
    void bytesSent(const QByteArray &data);

    // Parsed from the "custom" data channel's JSON status messages.
    void rtcModuleSystemInfoUpdated(const RTCModuleSystemInfo &info);
    void videoMetricsUpdated(const VideoMetrics &metrics);
    void rtcModuleVersionInfoUpdated(const RTCModuleVersionInfo &info);

    // RTT / bitrate / selected-candidate, polled from webrtcbin get-stats.
    void webRtcStatsUpdated(const WebRTCStats &stats);

private slots:
    /// Signaling messages from the drone (offer / candidate), via SignalingServerManager.
    void _onSignalingMessage(const QJsonObject &message);
    void _onRegistrationSuccessful();

private:
    // --- GStreamer glue (run on the GLib/GStreamer side; hop to Qt where needed) ---
    bool _buildPipeline();
    void _applyIceServers();
    void _handleOffer(const QString &sdp, const QString &fromDroneId);
    void _handleRemoteCandidate(const QString &candidate, const QString &sdpMid);

    // webrtcbin signal callbacks (static -> instance)
    static void _onIceCandidate(GstElement *webrtc, guint mlineIndex, gchar *candidate, gpointer userData);
    static void _onPadAdded(GstElement *webrtc, GstPad *pad, gpointer userData);
    static void _onDataChannel(GstElement *webrtc, GstElement *channel, gpointer userData);
    // Connection/ICE state monitoring. binSession had no state observation at all,
    // so a mid-session drop (e.g. the ~30-40s ICE consent-freshness failure) left no
    // GCS-side trace. These surface the transition that actually tears the link down.
    static void _onConnectionStateNotify(GstElement *webrtc, GParamSpec *pspec, gpointer userData);
    static void _onIceConnectionStateNotify(GstElement *webrtc, GParamSpec *pspec, gpointer userData);
    static void _onDataChannelMessage(GstElement *channel, GBytes *data, gpointer userData);
    static void _onCustomChannelMessageString(GstElement *channel, gchar *str, gpointer userData);
    // "mavlink" data channel lifecycle -> _mavlinkChannelOpen (send gating).
    static void _onMavlinkChannelOpen(GstElement *channel, gpointer userData);
    static void _onMavlinkChannelClosed(GstElement *channel, gpointer userData);
    static void _onMavlinkChannelError(GstElement *channel, GError *error, gpointer userData);
    static void _onDecodebinPadAdded(GstElement *decodebin, GstPad *pad, gpointer userData);
    // appsink new-sample: forward depayed elementary H264 into QGC's VideoManager pipeline.
    static GstFlowReturn _onEncodedSample(GstElement *appsink, gpointer userData);

    // Pin the offered video codec (with its extmap/rtcp-fb) as the transceiver's
    // codec-preferences before create-answer. webrtcbin, as answerer, otherwise drops
    // the drone's transport-wide-cc (TWCC) extmap from the answer, so the drone never
    // enables congestion-control feedback. Requires the rtphdrexttwcc header-extension
    // element from gst-plugins-good to actually re-emit the extension.
    void _applyAnswerCodecPreferences();

    // create-answer promise -> set-local-description -> send answer
    static void _onAnswerCreated(GstPromise *promise, gpointer userData);
    void _sendLocalDescription(GstWebRTCSessionDescription *desc);

    // Periodic webrtcbin get-stats -> WebRTCStats.
    void _pollStats();
    static void _onStatsPromise(GstPromise *promise, gpointer userData);

    // Map the drone's sdpMid (e.g. "video", "0") to the m-line index webrtcbin needs.
    int _mlineIndexForMid(const QString &sdpMid) const;

    Config _config;
    SignalingServerManager *_signaling = nullptr;

    GstElement *_pipeline = nullptr;   ///< top-level pipeline
    GstElement *_webrtc   = nullptr;   ///< webrtcbin
    GstBus     *_bus      = nullptr;
    GstElement *_mavlinkChannel = nullptr;  ///< GstWebRTCDataChannel for "mavlink" (reffed)
    GstElement *_customChannel  = nullptr;  ///< GstWebRTCDataChannel for "custom" status (reffed)

    /// Guards _mavlinkChannel: set on the GStreamer signalling thread (on-data-channel),
    /// read/sent-on from the Qt thread (sendMavlink), unreffed in stop().
    mutable QMutex     _mavlinkChannelMutex;
    /// True only while the channel's ready-state is OPEN; gates sendMavlink so we don't
    /// push MAVLink before SCTP is up (early heartbeats/param requests would be dropped).
    std::atomic_bool   _mavlinkChannelOpen{false};
    /// Throttle for the buffered-amount high-watermark warning (ms since epoch).
    qint64             _lastBufferWarnMs = 0;

    bool _started = false;
    bool _remoteDescriptionSet = false;

    /// Reffed caps of the offer's video m-line (codec + extmap + rtcp-fb), captured in
    /// _handleOffer and pinned onto the transceiver in _applyAnswerCodecPreferences.
    GstCaps *_offerVideoCaps = nullptr;

    /// sdpMid ("video", "0", …) -> m-line index, filled from the drone's offer so
    /// remote ICE candidates (which carry sdpMid) can be mapped to the index
    /// webrtcbin's add-ice-candidate expects.
    QHash<QString, int> _midToMline;
    QString _fromDroneId;

    QTimer *_statsTimer   = nullptr;
    quint64 _lastVideoBytes = 0;
    qint64  _lastStatsMs    = 0;
    int     _statsDumpCount = 0;
};
