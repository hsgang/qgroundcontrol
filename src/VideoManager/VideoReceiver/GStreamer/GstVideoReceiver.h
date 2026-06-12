#pragma once

#include <QtCore/QMutex>
#include <QtCore/QQueue>
#include <QtCore/QThread>
#include <QtCore/QTimer>
#include <QtCore/QWaitCondition>

#include <glib.h>
#include <gst/gstelement.h>
#include <gst/gstpad.h>

#include "VideoReceiver.h"

typedef std::function<void()> Task;

/*===========================================================================*/

class GstVideoWorker : public QThread
{
    Q_OBJECT

public:
    explicit GstVideoWorker(QObject *parent = nullptr);
    ~GstVideoWorker();
    bool needDispatch() const;
    void dispatch(Task task);
    void shutdown();

private:
    void run() final;

    QWaitCondition _taskQueueUpdate;
    QMutex _taskQueueSync;
    QQueue<Task> _taskQueue;
    bool _shutdown = false;
};

/*===========================================================================*/

typedef struct _GstElement GstElement;

class GstVideoReceiver : public VideoReceiver
{
    Q_OBJECT
    Q_PROPERTY(QString decoderName       READ decoderName       NOTIFY decoderStatsChanged)
    Q_PROPERTY(quint64 processedFrames   READ processedFrames   NOTIFY decoderStatsChanged)
    Q_PROPERTY(quint64 droppedFrames     READ droppedFrames     NOTIFY decoderStatsChanged)
    Q_PROPERTY(qint64  currentJitterNs   READ currentJitterNs   NOTIFY decoderStatsChanged)
    Q_PROPERTY(double  qosProportion     READ qosProportion     NOTIFY decoderStatsChanged)
    Q_PROPERTY(int     qosQuality        READ qosQuality        NOTIFY decoderStatsChanged)

public:
    explicit GstVideoReceiver(QObject *parent = nullptr);
    ~GstVideoReceiver();

    QString decoderName()     const { return _decoderName; }
    quint64 processedFrames() const { return _processedFrames; }
    quint64 droppedFrames()   const { return _droppedFrames; }
    qint64  currentJitterNs() const { return _currentJitterNs; }
    double  qosProportion()   const { return _qosProportion; }
    int     qosQuality()      const { return _qosQuality; }

    // Internal RTP mode: feed RTP packets directly via pushRtpPacket() instead of
    // pulling from a URI (e.g. WebRTC track frames). The pipeline is built from
    // appsrc instead of _makeSource().
    enum class InternalCodec { H264, H265 };
    void enableInternalRtpMode(InternalCodec codec);
    void preparePipeline();
    void pushRtpPacket(QByteArray packet);

public slots:
    void start(uint32_t timeout) override;
    void stop() override;
    void startDecoding(void *sink) override;
    void stopDecoding() override;
    void startRecording(const QString &videoFile, FILE_FORMAT format) override;
    void stopRecording() override;
    void takeScreenshot(const QString &imageFile) override;

signals:
    void decoderStatsChanged();
    void latencyChanged();
    // Internal RTP mode: the decode branch requested a fresh keyframe (e.g. the
    // depayloader detected loss). The transport layer (WebRTC) translates this into
    // an RTCP PLI back to the sender. Throttled in _onUpstreamKeyframeRequest().
    void keyframeRequested();

private slots:
    void _watchdog();
    void _handleEOS();

private:
    GstElement *_makeSource(const QString &input);
    GstElement *_makeDecoder();
    GstElement *_makeInternalRtpSource();
    GstElement *_makeFileSink(const QString &videoFile, FILE_FORMAT format);

    void _onNewSourcePad(GstPad *pad);
    void _onNewDecoderPad(GstPad *pad);
    bool _addDecoder(GstElement *src);
    void _ensureVideoSinkInPipeline();
    bool _addVideoSink(GstPad *pad);
    void _noteTeeFrame();
    void _noteVideoSinkFrame();
    void _noteEndOfStream();
    /// -Unlink the branch from the src pad
    /// -Send an EOS event at the beginning of that branch
    bool _unlinkBranch(GstElement *from);
    void _shutdownDecodingBranch();
    void _shutdownRecordingBranch();
    void _logDecodebin3SelectedCodec(GstElement *decodebin3);

    bool _needDispatch();
    void _dispatchSignal(Task emitter);

    static gboolean _onBusMessage(GstBus *bus, GstMessage *message, gpointer user_data);
    static void _onNewPad(GstElement *element, GstPad *pad, gpointer data);
    static void _wrapWithGhostPad(GstElement *element, GstPad *pad, gpointer data);
    static void _linkPad(GstElement *element, GstPad *pad, gpointer data);
    static gboolean _padProbe(GstElement *element, GstPad *pad, gpointer user_data);
#if !defined(QGC_GST_BUILD_VERSION_MAJOR) || (QGC_GST_BUILD_VERSION_MAJOR == 1 && QGC_GST_BUILD_VERSION_MINOR < 28)
    static gboolean _filterParserCaps(GstElement *bin, GstPad *pad, GstElement *element, GstQuery *query, gpointer data);
#endif
    static GstPadProbeReturn _teeProbe(GstPad *pad, GstPadProbeInfo *info, gpointer user_data);
    static GstPadProbeReturn _videoSinkProbe(GstPad *pad, GstPadProbeInfo *info, gpointer user_data);
    static GstPadProbeReturn _eosProbe(GstPad *pad, GstPadProbeInfo *info, gpointer user_data);
    static GstPadProbeReturn _keyframeWatch(GstPad *pad, GstPadProbeInfo *info, gpointer user_data);
    // Internal RTP mode: catch the upstream force-key-unit event the depayloader emits
    // on loss and re-emit it as keyframeRequested() (-> RTCP PLI in the WebRTC layer).
    static GstPadProbeReturn _onUpstreamKeyframeRequest(GstPad *pad, GstPadProbeInfo *info, gpointer user_data);

    GstElement *_decoder = nullptr;
    GstElement *_decoderValve = nullptr;
    GstElement *_fileSink = nullptr;
    GstElement *_pipeline = nullptr;
    GstElement *_recorderValve = nullptr;
    GstElement *_source = nullptr;
    GstElement *_tee = nullptr;
    GstElement *_appsrc = nullptr;          // owned by _source bin when _useInternalRtp
    bool        _appsrcDataPushed = false;
    bool        _useInternalRtp = false;
    InternalCodec _internalCodec = InternalCodec::H264;
    // Watchdog timeout for internal RTP mode (matches VideoManager's non-RTSP default).
    // Must be > 0: _watchdog() compares second-truncated timestamps, so with timeout=0
    // a healthy stream still trips `elapsed(1) > 0` whenever the 1Hz tick lands just
    // after a second boundary — tearing down a perfectly good pipeline.
    static constexpr uint32_t kInternalRtpTimeoutSecs = 3;
    // Internal RTP keyframe (PLI) request throttling. A depayloader can emit a
    // force-key-unit per lost-packet burst; cap outgoing requests so we don't flood
    // the sender with RTCP feedback while still recovering quickly after loss.
    gint64 _lastKeyframeRequestUs = 0;
    static constexpr gint64 kKeyframeRequestMinIntervalUs = 500000;  // 500 ms
    GstElement *_videoSink = nullptr;
    GstVideoWorker *_worker = nullptr;
    gulong _teeProbeId = 0;
    gulong _videoSinkProbeId = 0;
    gulong _eosProbeId = 0;
    GstPad *_eosProbePad = nullptr;  // ref-held: probe install pad, kept so removal targets the right pad regardless of _decoder lifecycle
    gulong _keyframeWatchId = 0;
    bool _recordingStopRequested = false;

    QString _decoderName;
    quint64 _processedFrames = 0;
    quint64 _droppedFrames = 0;
    qint64  _currentJitterNs = 0;
    double  _qosProportion = 1.0;
    int     _qosQuality = 1000000;

    static constexpr const char *_kFileMux[FILE_FORMAT_MAX + 1] = {
        "matroskamux",
        "qtmux",
        "mp4mux"
    };
};
