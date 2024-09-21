/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "AudioOutput.h"
#include "Fact.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QRegularExpression>
#include <QtCore/qapplicationstatic.h>
#include <QtTextToSpeech/QTextToSpeech>

QGC_LOGGING_CATEGORY(AudioOutputLog, "qgc.audio.audiooutput");
// qt.speech.tts.flite
// qt.speech.tts.android

const QHash<QString, QString> AudioOutput::_textHash = {
    { "ERR",            "error" },
    { "POSCTL",         "Position Control" },
    { "ALTCTL",         "Altitude Control" },
    { "AUTO_RTL",       "auto return to launch" },
    { "RTL",            "return To launch" },
    { "ACCEL",          "accelerometer" },
    { "RC_MAP_MODE_SW", "RC mode switch" },
    { "REJ",            "rejected" },
    { "WP",             "waypoint" },
    { "CMD",            "command" },
    { "COMPID",         "component eye dee" },
    { "PARAMS",         "parameters" },
    { "ID",             "I.D." },
    { "ADSB",           "A.D.S.B." },
    { "EKF",            "E.K.F." },
    { "PREARM",         "pre arm" },
    { "PITOT",          "pee toe" },
    { "GPS",            "G P S" },
    { "SERVOX_FUNCTION","Servo X Function" },
};

Q_APPLICATION_STATIC(AudioOutput, _audioOutput);

AudioOutput::AudioOutput(QObject *parent)
    : QObject(parent)
    , _engine(new QTextToSpeech(QStringLiteral("none"), this))
{
    // qCDebug(AudioOutputLog) << Q_FUNC_INFO << this;

    if (!QTextToSpeech::availableEngines().isEmpty()) {
        if (_engine->setEngine(QString())) {
            // Autoselect engine by priority
            qCDebug(AudioOutputLog) << Q_FUNC_INFO << "engine:" << _engine->engine();
            if (_engine->availableLocales().contains(QLocale("en_US"))) {
                _engine->setLocale(QLocale("en_US"));
            }

            (void) connect(this, &AudioOutput::mutedChanged, [this](bool muted) {
                qCDebug(AudioOutputLog) << Q_FUNC_INFO << "muted:" << muted;
                (void) QMetaObject::invokeMethod(_engine, "setVolume", Qt::AutoConnection, muted ? 0. : 1.);
            });
        }
    }

#ifdef QT_DEBUG
    (void) connect(_engine, &QTextToSpeech::stateChanged, [](QTextToSpeech::State state) {
        qCDebug(AudioOutputLog) << Q_FUNC_INFO << "State:" << state;
    });
    (void) connect(_engine, &QTextToSpeech::errorOccurred, [](QTextToSpeech::ErrorReason reason, const QString &errorString) {
        qCDebug(AudioOutputLog) << Q_FUNC_INFO << "Error: (" << reason << ") " << errorString;
    });
    (void) connect(_engine, &QTextToSpeech::volumeChanged, [](double volume) {
        qCDebug(AudioOutputLog) << Q_FUNC_INFO << "volume:" << volume;
    });
#endif
}

AudioOutput::~AudioOutput()
{
    // qCDebug(AudioOutputLog) << Q_FUNC_INFO << this;
}

AudioOutput *AudioOutput::instance()
{
    return _audioOutput();
}

void AudioOutput::init(Fact *mutedFact)
{
    Q_CHECK_PTR(mutedFact);

    (void) connect(mutedFact, &Fact::valueChanged, this, [this](QVariant value) {
        setMuted(value.toBool());
    });

    setMuted(mutedFact->rawValue().toBool());
}

void AudioOutput::say(const QString &text, AudioOutput::TextMods textMods)
{
    if (_muted) {
        return;
    }

    if (!_engine->engineCapabilities().testFlag(QTextToSpeech::Capability::Speak)) {
        qCWarning(AudioOutputLog) << Q_FUNC_INFO << "Speech Not Supported:" << text;
        return;
    }

    if (_textQueueSize > kMaxTextQueueSize) {
        (void) QMetaObject::invokeMethod(_engine, "stop", Qt::AutoConnection, QTextToSpeech::BoundaryHint::Default);
    }

    QString outText = AudioOutput::fixTextMessageForAudio(text);

    if (textMods.testFlag(AudioOutput::TextMod::Translate)) {
        outText = QCoreApplication::translate("AudioOutput", outText.toStdString().c_str());
    }

    qsizetype index = -1;
    (void) QMetaObject::invokeMethod(_engine, "enqueue", Qt::AutoConnection, qReturnArg(index), outText);
    if (index != -1) {
        _textQueueSize = index;
    }
}

bool AudioOutput::getMillisecondString(const QString &string, QString &match, int &number)
{
    static const QRegularExpression regexp("([0-9]+ms)");

    bool result = false;

    for (const QRegularExpressionMatch &tempMatch : regexp.globalMatch(string)) {
        if (tempMatch.hasMatch()) {
            match = tempMatch.captured(0);
            number = tempMatch.captured(0).replace("ms", "").toInt();
            result = true;
            break;
        }
    }

    return result;
}

QString AudioOutput::fixTextMessageForAudio(const QString &string)
{
    QString result = string;

    for (const QString &word: string.split(' ', Qt::SkipEmptyParts)) {
        if (_textHash.contains(word.toUpper())) {
            result.replace(word, _textHash.value(word.toUpper()));
        }
    }
    //-- Look for codified terms
    if(result.contains("ERR ", Qt::CaseInsensitive)) {
        result.replace("ERR ", "error ", Qt::CaseInsensitive);
    }
    if(result.contains("ERR:", Qt::CaseInsensitive)) {
        result.replace("ERR:", "error.", Qt::CaseInsensitive);
    }
    if(result.contains("POSCTL", Qt::CaseInsensitive)) {
        result.replace("POSCTL", "Position Control", Qt::CaseInsensitive);
    }
    if(result.contains("ALTCTL", Qt::CaseInsensitive)) {
        result.replace("ALTCTL", "Altitude Control", Qt::CaseInsensitive);
    }
    if(result.contains("AUTO_RTL", Qt::CaseInsensitive)) {
        result.replace("AUTO_RTL", "auto Return To Launch", Qt::CaseInsensitive);
    } else if(result.contains("RTL", Qt::CaseInsensitive)) {
        result.replace("RTL", "Return To Launch", Qt::CaseInsensitive);
    }
    if(result.contains("RC_MAP_MODE_SW", Qt::CaseInsensitive)) {
        result.replace("RC_MAP_MODE_SW", "RC mode switch", Qt::CaseInsensitive);
    }
    if(result.contains("REJ.", Qt::CaseInsensitive)) {
        result.replace("REJ.", "Rejected", Qt::CaseInsensitive);
    }
    if(result.contains("WP", Qt::CaseInsensitive)) {
        result.replace("WP", "way point", Qt::CaseInsensitive);
    }
    if(result.contains("CMD", Qt::CaseInsensitive)) {
        result.replace("CMD", "command", Qt::CaseInsensitive);
    }
    if(result.contains("COMPID", Qt::CaseInsensitive)) {
        result.replace("COMPID", "component eye dee", Qt::CaseInsensitive);
    }
    if(result.contains(" params ", Qt::CaseInsensitive)) {
        result.replace(" params ", " parameters ", Qt::CaseInsensitive);
    }
    if(result.contains(" id ", Qt::CaseInsensitive)) {
        result.replace(" id ", " eye dee ", Qt::CaseInsensitive);
    }
    if(result.contains(" ADSB ", Qt::CaseInsensitive)) {
        result.replace(" ADSB ", " Hey Dee Ess Bee ", Qt::CaseInsensitive);
    }
    if(result.contains(" EKF ", Qt::CaseInsensitive)) {
        result.replace(" EKF ", " Eee Kay Eff ", Qt::CaseInsensitive);
    }
    if(result.contains("PREARM", Qt::CaseInsensitive)) {
        result.replace("PREARM", tr("pre arm"), Qt::CaseInsensitive);
    }
    if(result.contains("PITOT", Qt::CaseInsensitive)) {
        result.replace("PITOT", "pee toe", Qt::CaseInsensitive);
    }
    if(result.contains("RC not found", Qt::CaseInsensitive)) {
        result.replace("RC not found", tr("RC not found"), Qt::CaseInsensitive);
    }
    if(result.contains("3D Accel calibration needed", Qt::CaseInsensitive)) {
        result.replace("3D Accel calibration needed", tr("3D Accel calibration needed"), Qt::CaseInsensitive);
    }
    if(result.contains("Throttle below failsafe", Qt::CaseInsensitive)) {
        result.replace("Throttle below failsafe", tr("Throttle below failsafe"), Qt::CaseInsensitive);
    }
    if(result.contains("ACCEL ", Qt::CaseInsensitive)) {
        result.replace("ACCEL ", "accelerometer ", Qt::CaseInsensitive);
    }
    if(result.contains("low voltage failsafe", Qt::CaseInsensitive)) {
        result.replace("low voltage failsafe", tr("low voltage failsafe"), Qt::CaseInsensitive);
    }
    if(result.contains("AHRS: waiting for home", Qt::CaseInsensitive)) {
        result.replace("AHRS: waiting for home", tr("AHRS: waiting for home"), Qt::CaseInsensitive);
    }

    // Convert negative numbers
    static const QRegularExpression negNumRegex(QStringLiteral("(-)[0-9]*\\.?[0-9]"));
    QRegularExpressionMatch negNumRegexMatch = negNumRegex.match(result);
    while (negNumRegexMatch.hasMatch()) {
        if (!negNumRegexMatch.captured(1).isNull()) {
            result.replace(negNumRegexMatch.capturedStart(1), negNumRegexMatch.capturedEnd(1) - negNumRegexMatch.capturedStart(1), QStringLiteral(" negative "));
        }
        negNumRegexMatch = negNumRegex.match(result);
    }

    // Convert real number with decimal point
    static const QRegularExpression realNumRegex(QStringLiteral("([0-9]+)(\\.)([0-9]+)"));
    QRegularExpressionMatch realNumRegexMatch = realNumRegex.match(result);
    while (realNumRegexMatch.hasMatch()) {
        if (!realNumRegexMatch.captured(2).isNull()) {
            result.replace(realNumRegexMatch.capturedStart(2), realNumRegexMatch.capturedEnd(2) - realNumRegexMatch.capturedStart(2), QStringLiteral(" point "));
        }
        realNumRegexMatch = realNumRegex.match(result);
    }

    // Convert meter postfix after real number
    static const QRegularExpression realNumMeterRegex(QStringLiteral("[0-9]*\\.?[0-9]\\s?(m)([^A-Za-z]|$)"));
    QRegularExpressionMatch realNumMeterRegexMatch = realNumMeterRegex.match(result);
    while (realNumMeterRegexMatch.hasMatch()) {
        if (!realNumMeterRegexMatch.captured(1).isNull()) {
            result.replace(realNumMeterRegexMatch.capturedStart(1), realNumMeterRegexMatch.capturedEnd(1) - realNumMeterRegexMatch.capturedStart(1), QStringLiteral(" meters"));
        }
        realNumMeterRegexMatch = realNumMeterRegex.match(result);
    }

    QString match;
    int number;
    if (getMillisecondString(string, match, number) && (number > 1000)) {
        QString newNumber;
        if (number < 60000) {
            const int seconds = number / 1000;
            newNumber = QStringLiteral("%1 second%2").arg(seconds).arg(seconds > 1 ? "s" : "");
        } else {
            const int minutes = number / 60000;
            const int seconds = (number - (minutes * 60000)) / 1000;
            newNumber = QStringLiteral("%1 minute%2").arg(minutes).arg(minutes > 1 ? "s" : "");
            if (seconds) {
                (void) newNumber.append(QStringLiteral(" and %1 second%2").arg(seconds).arg(seconds > 1 ? "s" : ""));
            }
        }
        result.replace(match, newNumber);
    }

    return result;
}
