#include "WebRTCBinSession.h"
#include "SignalingServerManager.h"
#include "QGCLoggingCategory.h"
#include "VideoManager.h"

#include <gst/app/app.h>

#include <QtCore/QByteArray>
#include <QtCore/QMetaObject>
#include <QtCore/QUrl>
#include <QtCore/QRegularExpression>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QTimer>
#include <QtCore/QDateTime>

#include <gst/sdp/sdp.h>
#include <gst/webrtc/webrtc.h>

#include <cstdlib>
#include <cstring>
#include <thread>

QGC_LOGGING_CATEGORY(WebRTCBinLog, "Comms.WebRTCBin")

// Built against gstreamer-webrtc-1.0 / gstreamer-sdp-1.0. Delivers the drone's
// H264 (via webrtcbin NACK/RTX) into VideoManager's external-encoded source and
// bridges the mavlink/custom data channels to the link. See WebRTCBinSession.h.

namespace {
// SCTP send-buffer thresholds. Low threshold matches the libdatachannel path
// (WebRTCWorker::BUFFER_LOW_THRESHOLD = 8 KB). The high watermark is a
// visibility guard: if the drone can't drain our sends (bulk param/mission
// upload over a slow link), warn instead of silently piling up latency.
constexpr guint64 kBufferedAmountLowThreshold = 8 * 1024;          // 8 KB
constexpr guint64 kBufferedAmountHighWarn     = 4 * 1024 * 1024;   // 4 MB
constexpr qint64  kBufferWarnIntervalMs       = 1000;

// Send `{ id, to, type, ... }` back to the drone via the shared signaling channel.
QJsonObject baseMessage(const QString &gcsId, const QString &droneId, const QString &type)
{
    QJsonObject m;
    m["id"]   = gcsId;
    m["to"]   = droneId;
    m["type"] = type;
    return m;
}

const char *connStateName(GstWebRTCPeerConnectionState s)
{
    switch (s) {
    case GST_WEBRTC_PEER_CONNECTION_STATE_NEW:          return "new";
    case GST_WEBRTC_PEER_CONNECTION_STATE_CONNECTING:   return "connecting";
    case GST_WEBRTC_PEER_CONNECTION_STATE_CONNECTED:    return "connected";
    case GST_WEBRTC_PEER_CONNECTION_STATE_DISCONNECTED: return "disconnected";
    case GST_WEBRTC_PEER_CONNECTION_STATE_FAILED:       return "failed";
    case GST_WEBRTC_PEER_CONNECTION_STATE_CLOSED:       return "closed";
    }
    return "?";
}

const char *iceStateName(GstWebRTCICEConnectionState s)
{
    switch (s) {
    case GST_WEBRTC_ICE_CONNECTION_STATE_NEW:          return "new";
    case GST_WEBRTC_ICE_CONNECTION_STATE_CHECKING:     return "checking";
    case GST_WEBRTC_ICE_CONNECTION_STATE_CONNECTED:    return "connected";
    case GST_WEBRTC_ICE_CONNECTION_STATE_COMPLETED:    return "completed";
    case GST_WEBRTC_ICE_CONNECTION_STATE_FAILED:       return "failed";
    case GST_WEBRTC_ICE_CONNECTION_STATE_DISCONNECTED: return "disconnected";
    case GST_WEBRTC_ICE_CONNECTION_STATE_CLOSED:       return "closed";
    }
    return "?";
}
} // namespace

WebRTCBinSession::WebRTCBinSession(const Config &config, QObject *parent)
    : QObject(parent)
    , _config(config)
{
}

WebRTCBinSession::~WebRTCBinSession()
{
    stop();
}

bool WebRTCBinSession::start()
{
    if (_started) {
        return true;
    }

    _signaling = SignalingServerManager::instance();
    if (!_signaling) {
        qCWarning(WebRTCBinLog) << "No SignalingServerManager instance";
        return false;
    }

    if (!_buildPipeline()) {
        return false;
    }

    // Drone -> us: offers and ICE candidates arrive on messageReceived.
    connect(_signaling, &SignalingServerManager::messageReceived,
            this, &WebRTCBinSession::_onSignalingMessage);
    connect(_signaling, &SignalingServerManager::registrationSuccessful,
            this, &WebRTCBinSession::_onRegistrationSuccessful);

    // Register as answerer; the drone will then send its offer.
    _signaling->registerGCS(_config.gcsId, _config.targetDroneId);

    // Poll webrtcbin stats (RTT / bitrate / candidate) once per second.
    _statsTimer = new QTimer(this);
    connect(_statsTimer, &QTimer::timeout, this, &WebRTCBinSession::_pollStats);
    _statsTimer->start(1000);

    _started = true;
    qCDebug(WebRTCBinLog) << "Started, registering GCS" << _config.gcsId
                          << "target" << _config.targetDroneId;
    return true;
}

void WebRTCBinSession::stop()
{
    if (_statsTimer) {
        _statsTimer->stop();
    }

    // Detach every signal handler carrying `this` as user-data before we hand the pipeline
    // to a background thread, so a late webrtcbin / ICE / data-channel callback can't fire
    // into a session that's about to be destroyed. (_onEncodedSample is intentionally
    // self-independent, so it stays safe even if it fires during the flush.)
    if (_webrtc) {
        g_signal_handlers_disconnect_by_data(_webrtc, this);
    }

    {
        QMutexLocker lock(&_mavlinkChannelMutex);
        _mavlinkChannelOpen.store(false);
        if (_mavlinkChannel) {
            g_signal_handlers_disconnect_by_data(_mavlinkChannel, this);
            g_object_unref(_mavlinkChannel);
            _mavlinkChannel = nullptr;
        }
    }
    if (_customChannel) {
        g_signal_handlers_disconnect_by_data(_customChannel, this);
        g_object_unref(_customChannel);
        _customChannel = nullptr;
    }

    // Tearing a *live* webrtcbin down to GST_STATE_NULL blocks the caller while GStreamer
    // joins the internal ICE/DTLS/nice threads. On the UI thread that froze the whole app
    // whenever the user disconnected an active connection. Hand the blocking teardown to a
    // detached thread that fully owns the pipeline; we've already dropped our pointers and
    // callbacks, so the session can be destroyed without waiting for it.
    GstElement *pipeline = _pipeline;
    GstBus     *bus      = _bus;
    _pipeline = nullptr;
    _webrtc   = nullptr;
    _bus      = nullptr;
    if (pipeline) {
        std::thread([pipeline, bus]() {
            qCDebug(WebRTCBinLog) << "[teardown] setting pipeline to NULL";
            gst_element_set_state(pipeline, GST_STATE_NULL);
            if (bus) {
                gst_object_unref(bus);
            }
            gst_object_unref(pipeline);   // drops webrtcbin too (owned by the pipeline)
            qCDebug(WebRTCBinLog) << "[teardown] pipeline released";
        }).detach();
    } else if (bus) {
        gst_object_unref(bus);
    }

    gst_clear_caps(&_offerVideoCaps);
    _started = false;
    _remoteDescriptionSet = false;
}

bool WebRTCBinSession::_buildPipeline()
{
    _pipeline = gst_pipeline_new("webrtcbin-recv");
    _webrtc   = gst_element_factory_make("webrtcbin", "recv");
    if (!_pipeline || !_webrtc) {
        qCCritical(WebRTCBinLog) << "Failed to create pipeline/webrtcbin (plugin missing?)";
        return false;
    }

    // Bundle policy must match the drone's offer (a=group:BUNDLE ...). max-bundle
    // is the common browser default and what the drone's SDP used.
    g_object_set(_webrtc, "bundle-policy", 3 /* GST_WEBRTC_BUNDLE_POLICY_MAX_BUNDLE */, nullptr);

    gst_bin_add(GST_BIN(_pipeline), _webrtc);

    _applyIceServers();

    g_signal_connect(_webrtc, "on-ice-candidate", G_CALLBACK(_onIceCandidate), this);
    g_signal_connect(_webrtc, "pad-added",        G_CALLBACK(_onPadAdded),     this);
    g_signal_connect(_webrtc, "on-data-channel",  G_CALLBACK(_onDataChannel),  this);
    // Observe the peer/ICE lifecycle so a mid-session drop is traceable on the GCS.
    // The ~30-40s reconnect symptom shows here as ice-connection-state going
    // connected -> disconnected -> failed (ICE consent-freshness timeout).
    g_signal_connect(_webrtc, "notify::connection-state",     G_CALLBACK(_onConnectionStateNotify),    this);
    g_signal_connect(_webrtc, "notify::ice-connection-state", G_CALLBACK(_onIceConnectionStateNotify), this);

    // TWCC in the answer needs the rtphdrexttwcc header-extension element. If the
    // bundle lacks it, no codec-preferences trick can put the extmap back — flag it
    // once at startup so a missing plugin is obvious in the GCS log.
    if (GstElementFactory *twccFactory = gst_element_factory_find("rtphdrexttwcc")) {
        qCDebug(WebRTCBinLog) << "rtphdrexttwcc present: transport-wide-cc can be negotiated in the answer";
        gst_object_unref(twccFactory);
    } else {
        qCWarning(WebRTCBinLog) << "rtphdrexttwcc NOT found: webrtcbin cannot echo the drone's "
                                   "transport-wide-cc extmap (bundle gst-plugins-good RTP header extensions)";
    }

    _bus = gst_element_get_bus(_pipeline);
    // TODO: attach a bus watch to surface errors/state to Qt (omitted in PoC).

    if (gst_element_set_state(_pipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) {
        qCCritical(WebRTCBinLog) << "Pipeline failed to reach PLAYING";
        return false;
    }
    return true;
}

void WebRTCBinSession::_applyIceServers()
{
    if (!_config.stunServer.isEmpty()) {
        g_object_set(_webrtc, "stun-server", _config.stunServer.toUtf8().constData(), nullptr);
    }

    // webrtcbin wants turn(s)://user:credential@host:port. The /bundle response
    // gives urls like "turn:host:3478" plus a shared username/credential, so we
    // splice the credentials into the authority.
    const QString user = QString::fromUtf8(QUrl::toPercentEncoding(_config.turn.username));
    const QString cred = QString::fromUtf8(QUrl::toPercentEncoding(_config.turn.credential));
    for (const QString &url : _config.turn.urls) {
        QString u = url.trimmed();
        if (u.isEmpty()) continue;
        const QString scheme = u.startsWith(QStringLiteral("turns:")) ? QStringLiteral("turns://")
                                                                       : QStringLiteral("turn://");
        QString hostPort = u;
        hostPort.remove(QRegularExpression(QStringLiteral("^turns?:(//)?")));
        const QString full = scheme + user + QStringLiteral(":") + cred + QStringLiteral("@") + hostPort;
        gboolean ok = FALSE;
        g_signal_emit_by_name(_webrtc, "add-turn-server", full.toUtf8().constData(), &ok);
        qCDebug(WebRTCBinLog) << "add-turn-server" << full << "ok=" << ok;
    }
}

void WebRTCBinSession::_onSignalingMessage(const QJsonObject &message)
{
    const QString type = message["type"].toString();
    if (type == "offer") {
        _handleOffer(message["sdp"].toString(), message["from"].toString());
    } else if (type == "candidate") {
        _handleRemoteCandidate(message["candidate"].toString(), message["sdpMid"].toString());
    }
    // registered/drones:list/etc. are handled by SignalingServerManager itself.
}

void WebRTCBinSession::_onRegistrationSuccessful()
{
    qCDebug(WebRTCBinLog) << "GCS registered; waiting for drone offer";
}

int WebRTCBinSession::_mlineIndexForMid(const QString &sdpMid) const
{
    if (_midToMline.contains(sdpMid)) {
        return _midToMline.value(sdpMid);
    }
    bool isNum = false;
    const int asNum = sdpMid.toInt(&isNum);
    return isNum ? asNum : 0;   // pragmatic fallback
}

void WebRTCBinSession::_handleOffer(const QString &sdp, const QString &fromDroneId)
{
    if (_config.targetDroneId.size() && fromDroneId != _config.targetDroneId) {
        qCWarning(WebRTCBinLog) << "Ignoring offer from unexpected drone" << fromDroneId;
        return;
    }
    _fromDroneId = fromDroneId;

    const QByteArray sdpUtf8 = sdp.toUtf8();
    GstSDPMessage *sdpMsg = nullptr;
    if (gst_sdp_message_new(&sdpMsg) != GST_SDP_OK ||
        gst_sdp_message_parse_buffer(reinterpret_cast<const guint8 *>(sdpUtf8.constData()),
                                     sdpUtf8.size(), sdpMsg) != GST_SDP_OK) {
        qCWarning(WebRTCBinLog) << "Failed to parse offer SDP";
        if (sdpMsg) gst_sdp_message_free(sdpMsg);
        return;
    }

    // Build sdpMid -> m-line index map from the offer for later ICE candidates, and
    // capture the video m-line's caps (codec + extmap + rtcp-fb) so we can pin them as
    // the answer's codec-preferences. The offer already carries the transport-wide-cc
    // extmap; re-emitting it verbatim is what keeps TWCC alive in our answer.
    _midToMline.clear();
    gst_clear_caps(&_offerVideoCaps);
    const guint nMedia = gst_sdp_message_medias_len(sdpMsg);
    for (guint i = 0; i < nMedia; ++i) {
        const GstSDPMedia *media = gst_sdp_message_get_media(sdpMsg, i);
        const gchar *mid = gst_sdp_media_get_attribute_val(media, "mid");
        if (mid) {
            _midToMline.insert(QString::fromUtf8(mid), static_cast<int>(i));
        }

        if (!_offerVideoCaps && g_strcmp0(gst_sdp_media_get_media(media), "video") == 0) {
            // Assemble ONLY the offered codec caps (payload/clock-rate/encoding-name/
            // fmtp) for every payload type. Deliberately NOT gst_sdp_media_attributes_to_caps:
            // that folds in the transport/session attributes (setup, ice-ufrag/pwd,
            // fingerprint, mid, ssrc, rtcp-*), and webrtcbin then emits every one of them
            // verbatim into the answer — producing duplicate/conflicting a=setup,
            // a=ice-ufrag and a=fingerprint lines that leave DTLS stuck at "new".
            GstCaps *caps = gst_caps_new_empty();
            const guint nFmts = gst_sdp_media_formats_len(media);
            for (guint f = 0; f < nFmts; ++f) {
                const gchar *fmt = gst_sdp_media_get_format(media, f);
                if (!fmt) continue;
                const gint pt = atoi(fmt);
                GstCaps *fmtCaps = gst_sdp_media_get_caps_from_media(media, pt);
                if (!fmtCaps) continue;
                // get_caps_from_media names the structure "application/x-unknown" here;
                // webrtcbin only matches codec-preferences that are "application/x-rtp",
                // so without this rename the whole video m-line is rejected (port 0,
                // dropped from the BUNDLE group) and DTLS never starts.
                for (guint j = 0; j < gst_caps_get_size(fmtCaps); ++j) {
                    gst_structure_set_name(gst_caps_get_structure(fmtCaps, j), "application/x-rtp");
                }
                gst_caps_append(caps, fmtCaps);   // takes ownership of fmtCaps
            }

            // Add ONLY the header-extension mappings (a=extmap:<id>[/dir] <uri>) as
            // extmap-<id>=<uri> caps fields. This is the one attribute we need to keep so
            // webrtcbin re-emits the drone's transport-wide-cc extmap in the answer.
            const guint nAttrs = gst_sdp_media_attributes_len(media);
            for (guint a = 0; a < nAttrs; ++a) {
                const GstSDPAttribute *attr = gst_sdp_media_get_attribute(media, a);
                if (!attr || g_strcmp0(attr->key, "extmap") != 0 || !attr->value) {
                    continue;
                }
                // value = "<id>[/<direction>] <uri>"
                const gchar *space = strchr(attr->value, ' ');
                if (!space) continue;
                QByteArray idPart(attr->value, static_cast<int>(space - attr->value));
                const int slash = idPart.indexOf('/');
                if (slash >= 0) idPart.truncate(slash);          // drop "/sendrecv" etc.
                const QByteArray uri = QByteArray(space + 1).trimmed();
                if (idPart.isEmpty() || uri.isEmpty()) continue;
                const QByteArray field = "extmap-" + idPart;
                for (guint sIdx = 0; sIdx < gst_caps_get_size(caps); ++sIdx) {
                    gst_structure_set(gst_caps_get_structure(caps, sIdx),
                                      field.constData(), G_TYPE_STRING, uri.constData(), nullptr);
                }
            }

            if (!gst_caps_is_empty(caps)) {
                _offerVideoCaps = caps;   // reffed; freed in stop()
            } else {
                gst_caps_unref(caps);
            }
        }
    }

    GstWebRTCSessionDescription *offer =
        gst_webrtc_session_description_new(GST_WEBRTC_SDP_TYPE_OFFER, sdpMsg); // takes ownership of sdpMsg

    // set-remote-description; when it completes, create the answer.
    GstPromise *promise = gst_promise_new_with_change_func(
        [](GstPromise *p, gpointer userData) {
            gst_promise_unref(p);
            auto *self = static_cast<WebRTCBinSession *>(userData);
            self->_remoteDescriptionSet = true;
            // The transceiver only exists once the remote offer is applied; pin the
            // offered codec (incl. TWCC extmap) as its codec-preferences *before*
            // create-answer so webrtcbin echoes the extension back to the drone.
            self->_applyAnswerCodecPreferences();
            // create-answer -> _onAnswerCreated
            GstPromise *answerPromise =
                gst_promise_new_with_change_func(_onAnswerCreated, userData, nullptr);
            g_signal_emit_by_name(self->_webrtc, "create-answer", nullptr, answerPromise);
        },
        this, nullptr);

    g_signal_emit_by_name(_webrtc, "set-remote-description", offer, promise);
    gst_webrtc_session_description_free(offer);
}

void WebRTCBinSession::_applyAnswerCodecPreferences()
{
    if (!_webrtc || !_offerVideoCaps) {
        return;
    }

    // ON by default: pin the offered codec (with its extmap) as codec-preferences so
    // webrtcbin echoes the TWCC extmap into the answer. If this ever breaks the link
    // (a caps mismatch makes webrtcbin reject the video m-line, which under BUNDLE also
    // kills DTLS + the data channels), set QGC_WEBRTC_PIN_TWCC=0 to fall back to the
    // known-good negotiation without a rebuild.
    const QByteArray pinEnv = qgetenv("QGC_WEBRTC_PIN_TWCC");
    if (pinEnv == "0" || pinEnv.compare("false", Qt::CaseInsensitive) == 0) {
        qCDebug(WebRTCBinLog) << "codec-preferences pin disabled via QGC_WEBRTC_PIN_TWCC=0";
        return;
    }

    // Video is the first (and only) RTP transceiver in the drone's bundle; the
    // datachannel m-line is not a transceiver, so index 0 is the video transceiver.
    GstWebRTCRTPTransceiver *transceiver = nullptr;
    g_signal_emit_by_name(_webrtc, "get-transceiver", 0, &transceiver);
    if (!transceiver) {
        qCWarning(WebRTCBinLog) << "No transceiver[0]; cannot pin codec-preferences (TWCC will be dropped)";
        return;
    }

    g_object_set(transceiver, "codec-preferences", _offerVideoCaps, nullptr);

    gchar *capsStr = gst_caps_to_string(_offerVideoCaps);
    qCDebug(WebRTCBinLog) << "Pinned answer codec-preferences:" << capsStr;
    g_free(capsStr);

    gst_object_unref(transceiver);
}

void WebRTCBinSession::_onAnswerCreated(GstPromise *promise, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);

    const GstStructure *reply = gst_promise_get_reply(promise);
    GstWebRTCSessionDescription *answer = nullptr;
    gst_structure_get(reply, "answer", GST_TYPE_WEBRTC_SESSION_DESCRIPTION, &answer, nullptr);
    gst_promise_unref(promise);

    if (!answer) {
        qCWarning(WebRTCBinLog) << "create-answer produced no answer";
        return;
    }

    // set-local-description (fire-and-forget), then ship the SDP to the drone.
    GstPromise *local = gst_promise_new();
    g_signal_emit_by_name(self->_webrtc, "set-local-description", answer, local);
    gst_promise_interrupt(local);
    gst_promise_unref(local);

    self->_sendLocalDescription(answer);
    gst_webrtc_session_description_free(answer);
}

void WebRTCBinSession::_sendLocalDescription(GstWebRTCSessionDescription *desc)
{
    gchar *sdpText = gst_sdp_message_as_text(desc->sdp);
    const QString sdp = QString::fromUtf8(sdpText);
    g_free(sdpText);

    // Confirm at a glance whether the TWCC extmap survived into the answer we ship.
    // If false while the offer had it, webrtcbin dropped the extension (rtphdrexttwcc
    // missing, or codec-preferences didn't take) and the drone won't enable TWCC.
    qCDebug(WebRTCBinLog) << "Answer transport-wide-cc extmap present:"
                          << sdp.contains(QStringLiteral("transport-wide-cc"));

    // Dump the full answer webrtcbin produced. This is our create-answer output — it
    // proves the SDP negotiation layer is webrtcbin (not libdatachannel) and lets the
    // drone side inspect exactly what we send (fmtp echo, setup role, extmap, etc.).
    qCDebug(WebRTCBinLog).noquote() << "Answer SDP (from webrtcbin create-answer):\n" << sdp;

    // Hop to the Qt thread to touch the signaling manager safely.
    const QString gcsId = _config.gcsId;
    const QString droneId = _fromDroneId.isEmpty() ? _config.targetDroneId : _fromDroneId;
    QMetaObject::invokeMethod(this, [this, gcsId, droneId, sdp]() {
        if (!_signaling) return;
        QJsonObject m = baseMessage(gcsId, droneId, "answer");
        m["sdp"] = sdp;
        _signaling->sendMessage(m);
        qCDebug(WebRTCBinLog) << "Sent answer to" << droneId;
    }, Qt::QueuedConnection);
}

void WebRTCBinSession::_handleRemoteCandidate(const QString &candidate, const QString &sdpMid)
{
    if (!_webrtc) return;
    const int mline = _mlineIndexForMid(sdpMid);
    g_signal_emit_by_name(_webrtc, "add-ice-candidate", static_cast<guint>(mline),
                          candidate.toUtf8().constData());
}

void WebRTCBinSession::_onIceCandidate(GstElement * /*webrtc*/, guint mlineIndex,
                                       gchar *candidate, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    const QString cand = QString::fromUtf8(candidate);
    // Report our sdpMid by reverse-mapping the m-line index when we know it.
    QString mid;
    for (auto it = self->_midToMline.constBegin(); it != self->_midToMline.constEnd(); ++it) {
        if (it.value() == static_cast<int>(mlineIndex)) { mid = it.key(); break; }
    }

    const QString gcsId = self->_config.gcsId;
    const QString droneId = self->_fromDroneId.isEmpty() ? self->_config.targetDroneId : self->_fromDroneId;
    QMetaObject::invokeMethod(self, [self, gcsId, droneId, cand, mid]() {
        if (!self->_signaling) return;
        QJsonObject m = baseMessage(gcsId, droneId, "candidate");
        m["candidate"] = cand;
        m["sdpMid"]    = mid;
        self->_signaling->sendMessage(m);
    }, Qt::QueuedConnection);
}

void WebRTCBinSession::_onConnectionStateNotify(GstElement *webrtc, GParamSpec * /*pspec*/, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    GstWebRTCPeerConnectionState state = GST_WEBRTC_PEER_CONNECTION_STATE_NEW;
    g_object_get(webrtc, "connection-state", &state, nullptr);
    qCDebug(WebRTCBinLog) << "[conn-state]" << connStateName(state);

    if (state == GST_WEBRTC_PEER_CONNECTION_STATE_FAILED ||
        state == GST_WEBRTC_PEER_CONNECTION_STATE_CLOSED) {
        QMetaObject::invokeMethod(self, [self]() { emit self->disconnected(); }, Qt::QueuedConnection);
    }
}

void WebRTCBinSession::_onIceConnectionStateNotify(GstElement *webrtc, GParamSpec * /*pspec*/, gpointer /*userData*/)
{
    GstWebRTCICEConnectionState state = GST_WEBRTC_ICE_CONNECTION_STATE_NEW;
    g_object_get(webrtc, "ice-connection-state", &state, nullptr);
    // A connected -> disconnected -> failed run here is an ICE consent-freshness
    // timeout; ICE staying connected while the data channel closes is instead an
    // SCTP-only teardown (peer-initiated), a different failure entirely.
    qCDebug(WebRTCBinLog) << "[ice-state]" << iceStateName(state);
}

void WebRTCBinSession::_onPadAdded(GstElement * /*webrtc*/, GstPad *pad, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    if (GST_PAD_DIRECTION(pad) != GST_PAD_SRC) {
        return;   // only interested in the drone's outgoing media (our recv src pads)
    }

    // Render inside QGC with one jitter buffer end-to-end: webrtcbin already did
    // NACK/RTX + jitter buffering, so depay + parse the recovered stream to elementary
    // H264 (byte-stream/au) and hand it to VideoManager's external-encoded source
    // (GstVideoReceiver appsrc -> tee -> decode/record/sink -> FlyView). No second
    // jitter buffer or depay downstream; QGC decode/record/metrics/overlay are reused.
    VideoManager::instance()->enableWebRtcEncodedMode();

    GstElement *depay   = gst_element_factory_make("rtph264depay", nullptr);
    GstElement *parse   = gst_element_factory_make("h264parse", nullptr);
    GstElement *capsf   = gst_element_factory_make("capsfilter", nullptr);
    GstElement *appsink = gst_element_factory_make("appsink", nullptr);
    if (!depay || !parse || !capsf || !appsink) {
        qCWarning(WebRTCBinLog) << "depay/parse/capsfilter/appsink create failed";
        gst_clear_object(&depay); gst_clear_object(&parse);
        gst_clear_object(&capsf); gst_clear_object(&appsink);
        return;
    }
    g_object_set(parse, "config-interval", -1, nullptr);
    GstCaps *caps = gst_caps_from_string("video/x-h264, stream-format=(string)byte-stream, alignment=(string)au");
    g_object_set(capsf, "caps", caps, nullptr);
    gst_clear_caps(&caps);
    g_object_set(appsink, "emit-signals", TRUE, "sync", FALSE,
                 "max-buffers", 8, "drop", FALSE, nullptr);
    g_signal_connect(appsink, "new-sample", G_CALLBACK(_onEncodedSample), self);

    gst_bin_add_many(GST_BIN(self->_pipeline), depay, parse, capsf, appsink, nullptr);
    gst_element_sync_state_with_parent(depay);
    gst_element_sync_state_with_parent(parse);
    gst_element_sync_state_with_parent(capsf);
    gst_element_sync_state_with_parent(appsink);
    if (!gst_element_link_many(depay, parse, capsf, appsink, nullptr)) {
        qCWarning(WebRTCBinLog) << "Failed to link depay -> parse -> capsfilter -> appsink";
    }
    GstPad *sink = gst_element_get_static_pad(depay, "sink");
    if (gst_pad_link(pad, sink) != GST_PAD_LINK_OK) {
        qCWarning(WebRTCBinLog) << "Failed to link webrtcbin pad -> rtph264depay";
    }
    gst_object_unref(sink);
    // NOTE: no connected() here — the link is "connected" when the mavlink data channel
    // opens (see _onDataChannel / _onMavlinkChannelOpen), not when video starts flowing.
}

GstFlowReturn WebRTCBinSession::_onEncodedSample(GstElement *appsink, gpointer /*userData*/)
{
    GstSample *sample = nullptr;
    g_signal_emit_by_name(appsink, "pull-sample", &sample);
    if (!sample) {
        return GST_FLOW_OK;
    }
    GstBuffer *buffer = gst_sample_get_buffer(sample);
    GstMapInfo map;
    if (buffer && gst_buffer_map(buffer, &map, GST_MAP_READ)) {
        QByteArray h264(reinterpret_cast<const char *>(map.data), static_cast<int>(map.size));
        gst_buffer_unmap(buffer, &map);
        VideoManager::instance()->pushWebRtcEncoded(h264);
    }
    gst_sample_unref(sample);
    return GST_FLOW_OK;
}

void WebRTCBinSession::_onDataChannel(GstElement * /*webrtc*/, GstElement *channel, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);

    gchar *label = nullptr;
    g_object_get(channel, "label", &label, nullptr);
    const QString name = QString::fromUtf8(label ? label : "");
    g_free(label);

    qCDebug(WebRTCBinLog) << "Data channel opened:" << name;

    if (name == QStringLiteral("mavlink")) {
        // Hold a ref so we can send on it; wire incoming payloads to the link.
        // GstWebRTCDataChannel is a GObject (not a GstObject), so use g_object_ref.
        {
            QMutexLocker lock(&self->_mavlinkChannelMutex);
            self->_mavlinkChannel = static_cast<GstElement *>(g_object_ref(channel));
        }

        // Match the libdatachannel path's flow-control: keep webrtcbin's SCTP send
        // buffer from silently piling up latency on bursty param/mission uploads.
        g_object_set(channel, "buffered-amount-low-threshold",
                     kBufferedAmountLowThreshold, nullptr);

        g_signal_connect(channel, "on-message-data", G_CALLBACK(_onDataChannelMessage),   self);
        g_signal_connect(channel, "on-open",         G_CALLBACK(_onMavlinkChannelOpen),   self);
        g_signal_connect(channel, "on-close",        G_CALLBACK(_onMavlinkChannelClosed), self);
        g_signal_connect(channel, "on-error",        G_CALLBACK(_onMavlinkChannelError),  self);

        // The channel may already be OPEN by the time on-data-channel fires; seed the
        // send gate from the current ready-state so we don't miss the on-open edge.
        GstWebRTCDataChannelState state = GST_WEBRTC_DATA_CHANNEL_STATE_CONNECTING;
        g_object_get(channel, "ready-state", &state, nullptr);
        const bool alreadyOpen = (state == GST_WEBRTC_DATA_CHANNEL_STATE_OPEN);
        self->_mavlinkChannelOpen.store(alreadyOpen);

        // connected() means "the mavlink channel can carry MAVLink". Emit it from a
        // single place keyed on the channel being OPEN: here if it already is, otherwise
        // _onMavlinkChannelOpen fires it on the CONNECTING->OPEN edge. (Do NOT emit it
        // from the video pad path — video flowing is not the link being up.)
        if (alreadyOpen) {
            QMetaObject::invokeMethod(self, [self]() { emit self->connected(); }, Qt::QueuedConnection);
        }
    } else if (name == QStringLiteral("custom")) {
        // RTC module status (system_info / video_metrics / version_check) arrives here
        // as JSON *strings*, so use on-message-string (not -data).
        self->_customChannel = static_cast<GstElement *>(g_object_ref(channel));
        g_signal_connect(channel, "on-message-string", G_CALLBACK(_onCustomChannelMessageString), self);
    }
}

void WebRTCBinSession::_onCustomChannelMessageString(GstElement * /*channel*/, gchar *str, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    if (!str) return;

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(QByteArray(str), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        return;
    }
    const QJsonObject obj = doc.object();
    const QString msgType = obj.value(QStringLiteral("type")).toString();

    if (msgType == QStringLiteral("system_info")) {
        RTCModuleSystemInfo info(obj);
        if (info.isValid()) {
            QMetaObject::invokeMethod(self, [self, info]() { emit self->rtcModuleSystemInfoUpdated(info); }, Qt::QueuedConnection);
        }
    } else if (msgType == QStringLiteral("video_metrics")) {
        VideoMetrics metrics(obj);
        if (metrics.isValid()) {
            QMetaObject::invokeMethod(self, [self, metrics]() { emit self->videoMetricsUpdated(metrics); }, Qt::QueuedConnection);
        }
    } else if (msgType == QStringLiteral("version_check")) {
        RTCModuleVersionInfo info(obj);
        if (info.isValid()) {
            QMetaObject::invokeMethod(self, [self, info]() { emit self->rtcModuleVersionInfoUpdated(info); }, Qt::QueuedConnection);
        }
    }
}

void WebRTCBinSession::_onDataChannelMessage(GstElement * /*channel*/, GBytes *data, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    if (!data) return;

    gsize size = 0;
    gconstpointer p = g_bytes_get_data(data, &size);
    if (!p || size == 0) return;

    QByteArray bytes(static_cast<const char *>(p), static_cast<int>(size));
    QMetaObject::invokeMethod(self, [self, bytes]() {
        emit self->mavlinkDataReceived(bytes);
    }, Qt::QueuedConnection);
}

void WebRTCBinSession::sendMavlink(const QByteArray &data)
{
    if (data.isEmpty()) return;

    // Gate on the channel actually being OPEN. Sending before SCTP is up (the window
    // between on-data-channel and on-open) is silently dropped by webrtcbin, which
    // would lose the initial heartbeats / param requests that bring the vehicle up.
    if (!_mavlinkChannelOpen.load()) {
        return;
    }

    {
        QMutexLocker lock(&_mavlinkChannelMutex);
        if (!_mavlinkChannel) {
            return;
        }

        // Back-pressure visibility: if the drone can't drain our sends fast enough
        // (bulk param/mission upload over a slow link), the SCTP send buffer grows and
        // adds latency. Warn (throttled) rather than pile up silently.
        guint64 buffered = 0;
        g_object_get(_mavlinkChannel, "buffered-amount", &buffered, nullptr);
        if (buffered > kBufferedAmountHighWarn) {
            const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
            if (nowMs - _lastBufferWarnMs > kBufferWarnIntervalMs) {
                _lastBufferWarnMs = nowMs;
                qCWarning(WebRTCBinLog) << "mavlink send buffer high:" << buffered
                                        << "bytes queued (drone not draining?)";
            }
        }

        GBytes *bytes = g_bytes_new(data.constData(), static_cast<gsize>(data.size()));
        g_signal_emit_by_name(_mavlinkChannel, "send-data", bytes);
        g_bytes_unref(bytes);
    }

    // Emit outside the lock: mirrors the libdatachannel path so the link keeps its
    // sent-byte statistics, without re-entering the mutex on a direct connection.
    emit bytesSent(data);
}

void WebRTCBinSession::sendCustom(const QString &text)
{
    if (text.isEmpty() || !_customChannel) {
        return;
    }
    // The "custom" channel is string-based (drone reads it via on-message-string).
    // Only send once it's OPEN — webrtcbin drops sends on a not-yet-open channel.
    GstWebRTCDataChannelState state = GST_WEBRTC_DATA_CHANNEL_STATE_CONNECTING;
    g_object_get(_customChannel, "ready-state", &state, nullptr);
    if (state != GST_WEBRTC_DATA_CHANNEL_STATE_OPEN) {
        return;
    }
    g_signal_emit_by_name(_customChannel, "send-string", text.toUtf8().constData());
}

void WebRTCBinSession::_onMavlinkChannelOpen(GstElement * /*channel*/, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    self->_mavlinkChannelOpen.store(true);
    qCDebug(WebRTCBinLog) << "mavlink data channel OPEN";
    // Now that the channel can actually carry MAVLink, mark the link connected.
    QMetaObject::invokeMethod(self, [self]() { emit self->connected(); }, Qt::QueuedConnection);
}

void WebRTCBinSession::_onMavlinkChannelClosed(GstElement * /*channel*/, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    self->_mavlinkChannelOpen.store(false);

    // Capture the transport state at close time. If ICE/DTLS are still connected then
    // only the SCTP data channel went away (peer-initiated close) — NOT an ICE/consent
    // or transport drop. This distinction is exactly what the ~30-40s reconnect needs:
    // a clean on-close with conn-state=connected means the drone closed the channel.
    GstWebRTCPeerConnectionState conn = GST_WEBRTC_PEER_CONNECTION_STATE_NEW;
    GstWebRTCICEConnectionState  ice  = GST_WEBRTC_ICE_CONNECTION_STATE_NEW;
    if (self->_webrtc) {
        g_object_get(self->_webrtc, "connection-state", &conn, "ice-connection-state", &ice, nullptr);
    }
    qCWarning(WebRTCBinLog) << "mavlink data channel CLOSED (clean on-close) — conn-state:"
                            << connStateName(conn) << "ice-state:" << iceStateName(ice)
                            << "(transport up => SCTP-only, peer-initiated close)";

    QMetaObject::invokeMethod(self, [self]() { emit self->disconnected(); }, Qt::QueuedConnection);
}

void WebRTCBinSession::_onMavlinkChannelError(GstElement * /*channel*/, GError *error, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    self->_mavlinkChannelOpen.store(false);
    const QString reason = error ? QString::fromUtf8(error->message) : QStringLiteral("unknown");

    // Same transport snapshot as the clean-close path: an error here with ICE/DTLS
    // still connected means the SCTP association failed while the transport is fine
    // (peer/SCTP-level fault), not an ICE/consent or DTLS drop.
    GstWebRTCPeerConnectionState conn = GST_WEBRTC_PEER_CONNECTION_STATE_NEW;
    GstWebRTCICEConnectionState  ice  = GST_WEBRTC_ICE_CONNECTION_STATE_NEW;
    if (self->_webrtc) {
        g_object_get(self->_webrtc, "connection-state", &conn, "ice-connection-state", &ice, nullptr);
    }
    qCWarning(WebRTCBinLog) << "mavlink data channel ERROR:" << reason
                            << "— conn-state:" << connStateName(conn) << "ice-state:" << iceStateName(ice);
    QMetaObject::invokeMethod(self, [self, reason]() {
        emit self->errorOccurred(reason);
        // A data-channel error is terminal for MAVLink, so treat it exactly like an
        // on-close: emit disconnected() to tear the link down and reconnect. Otherwise
        // the error path only logged and the link lingered "connected" with a silently
        // dead channel until the vehicle hit a comm-loss timeout.
        emit self->disconnected();
    }, Qt::QueuedConnection);
}

namespace {
struct StatsScan {
    guint64 bytesReceived   = 0;
    guint64 packetsReceived = 0;
    double  jitterSec       = -1.0;   // inbound-rtp interarrival jitter (seconds)
};

// webrtcbin (libnice) doesn't surface an ICE/RTCP round-trip time for a recvonly
// receiver, so we report interarrival jitter from the inbound-rtp stat instead as
// the link-quality number.
gboolean _scanStat(GQuark /*fieldId*/, const GValue *value, gpointer user)
{
    if (!G_VALUE_HOLDS(value, GST_TYPE_STRUCTURE)) {
        return TRUE;
    }
    const GstStructure *s = gst_value_get_structure(value);
    auto *sc = static_cast<StatsScan *>(user);

    GstWebRTCStatsType type;
    if (!gst_structure_get(s, "type", GST_TYPE_WEBRTC_STATS_TYPE, &type, nullptr)) {
        return TRUE;
    }

    if (type == GST_WEBRTC_STATS_INBOUND_RTP) {
        guint64 u64 = 0;
        if (gst_structure_get_uint64(s, "bytes-received", &u64))   { sc->bytesReceived   += u64; }
        if (gst_structure_get_uint64(s, "packets-received", &u64)) { sc->packetsReceived += u64; }
        double j = 0.0;
        if (gst_structure_get_double(s, "jitter", &j)) { sc->jitterSec = j; }
    }
    return TRUE;
}
} // namespace

void WebRTCBinSession::_pollStats()
{
    if (!_webrtc) return;
    GstPromise *promise = gst_promise_new_with_change_func(_onStatsPromise, this, nullptr);
    g_signal_emit_by_name(_webrtc, "get-stats", nullptr, promise);
}

void WebRTCBinSession::_onStatsPromise(GstPromise *promise, gpointer userData)
{
    auto *self = static_cast<WebRTCBinSession *>(userData);
    const GstStructure *reply = gst_promise_get_reply(promise);
    if (!reply) { gst_promise_unref(promise); return; }

    // Dump the raw stats structure a few times so the actual field names (esp. RTT
    // and the selected candidate pair) can be confirmed against this drone/webrtcbin.
    if (self->_statsDumpCount < 3) {
        self->_statsDumpCount++;
        gchar *txt = gst_structure_to_string(reply);
        qCDebug(WebRTCBinLog) << "[get-stats]" << txt;
        g_free(txt);
    }

    StatsScan sc;
    gst_structure_foreach(reply, _scanStat, &sc);
    gst_promise_unref(promise);

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    WebRTCStats stats;
    stats.videoBytesReceived = static_cast<qint64>(sc.bytesReceived);
    stats.videoPacketCount   = static_cast<int>(sc.packetsReceived);
    // No ICE/RTCP RTT available on a recvonly webrtcbin receiver — report interarrival
    // jitter (ms) as the link-quality number.
    if (sc.jitterSec >= 0.0) {
        stats.jitterMs = static_cast<int>(sc.jitterSec * 1000.0 + 0.5);
    }
    if (self->_lastStatsMs > 0 && nowMs > self->_lastStatsMs && sc.bytesReceived >= self->_lastVideoBytes) {
        const double dtSec = (nowMs - self->_lastStatsMs) / 1000.0;
        const double dBytes = static_cast<double>(sc.bytesReceived - self->_lastVideoBytes);
        stats.videoRateKBps = (dBytes / dtSec) / 1024.0;
        stats.webRtcRecv    = stats.videoRateKBps;
    }
    self->_lastVideoBytes = sc.bytesReceived;
    self->_lastStatsMs    = nowMs;

    QMetaObject::invokeMethod(self, [self, stats]() { emit self->webRtcStatsUpdated(stats); }, Qt::QueuedConnection);
}
