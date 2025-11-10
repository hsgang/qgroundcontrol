/****************************************************************************
 *
 * Copyright (C) 2025. All rights reserved.
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "AndroidBatteryMonitor.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QJniEnvironment>

QGC_LOGGING_CATEGORY(AndroidBatteryMonitorLog, "qgc.android.androidbatterymonitor")

// Battery status constants from Android BatteryManager
constexpr int BATTERY_STATUS_UNKNOWN = 1;
constexpr int BATTERY_STATUS_CHARGING = 2;
constexpr int BATTERY_STATUS_DISCHARGING = 3;
constexpr int BATTERY_STATUS_NOT_CHARGING = 4;
constexpr int BATTERY_STATUS_FULL = 5;

// Battery health constants
constexpr int BATTERY_HEALTH_UNKNOWN = 1;
constexpr int BATTERY_HEALTH_GOOD = 2;
constexpr int BATTERY_HEALTH_OVERHEAT = 3;
constexpr int BATTERY_HEALTH_DEAD = 4;
constexpr int BATTERY_HEALTH_OVER_VOLTAGE = 5;
constexpr int BATTERY_HEALTH_UNSPECIFIED_FAILURE = 6;
constexpr int BATTERY_HEALTH_COLD = 7;

// Static instance
AndroidBatteryMonitor* AndroidBatteryMonitor::_instance = nullptr;

// JNI callback - called from Java when battery status changes
static void jniBatteryChanged(JNIEnv* env, jobject obj,
                             jint level, jint scale, jint temperature,
                             jint voltage, jint status, jint health, jint plugged)
{
    Q_UNUSED(env);
    Q_UNUSED(obj);

    if (AndroidBatteryMonitor::instance()) {
        AndroidBatteryMonitor::instance()->updateBatteryInfo(
            level, scale, temperature, voltage, status, health, plugged
        );
    }
}

AndroidBatteryMonitor::AndroidBatteryMonitor(QObject* parent)
    : QObject(parent)
    , _batteryPercent(-1)
    , _batteryTemperature(0.0f)
    , _batteryVoltage(0.0f)
    , _isCharging(false)
    , _isFullyCharged(false)
    , _batteryStatus(BATTERY_STATUS_UNKNOWN)
    , _batteryHealth(BATTERY_HEALTH_UNKNOWN)
    , _pluggedType(0)
{
    qCDebug(AndroidBatteryMonitorLog) << "AndroidBatteryMonitor created";
}

AndroidBatteryMonitor::~AndroidBatteryMonitor()
{
    qCDebug(AndroidBatteryMonitorLog) << "AndroidBatteryMonitor destroyed";
}

AndroidBatteryMonitor* AndroidBatteryMonitor::instance()
{
    if (!_instance) {
        _instance = new AndroidBatteryMonitor();
    }
    return _instance;
}

void AndroidBatteryMonitor::setNativeMethods()
{
    qCDebug(AndroidBatteryMonitorLog) << "Registering battery monitor native functions";

    const JNINativeMethod javaMethods[] {
        {
            "nativeBatteryChanged",
            "(IIIIIII)V",
            reinterpret_cast<void*>(jniBatteryChanged)
        }
    };

    QJniEnvironment jniEnv;
    (void) jniEnv.checkAndClearExceptions();

    // Find the QGCBatteryMonitor Java class
    constexpr const char* className = "org/mavlink/qgroundcontrol/QGCBatteryMonitor";
    jclass batteryClass = jniEnv->FindClass(className);
    if (!batteryClass) {
        qCWarning(AndroidBatteryMonitorLog) << "Couldn't find class:" << className;
        (void) jniEnv.checkAndClearExceptions();
        return;
    }

    const jint val = jniEnv->RegisterNatives(batteryClass, javaMethods, std::size(javaMethods));
    if (val < 0) {
        qCWarning(AndroidBatteryMonitorLog) << "Error registering battery monitor methods:" << val;
    } else {
        qCDebug(AndroidBatteryMonitorLog) << "Battery monitor native functions registered";
    }

    (void) jniEnv.checkAndClearExceptions();
}

void AndroidBatteryMonitor::updateBatteryInfo(int level, int scale, int temperature,
                                             int voltage, int status, int health, int plugged)
{
    bool changed = false;

    // Calculate battery percentage
    int newPercent = -1;
    if (level >= 0 && scale > 0) {
        newPercent = (level * 100) / scale;
    }

    if (_batteryPercent != newPercent) {
        _batteryPercent = newPercent;
        changed = true;
    }

    // Temperature is in tenths of degree Celsius
    float newTemp = temperature / 10.0f;
    if (_batteryTemperature != newTemp) {
        _batteryTemperature = newTemp;
        changed = true;
    }

    // Voltage is in millivolts
    float newVoltage = voltage / 1000.0f;
    if (_batteryVoltage != newVoltage) {
        _batteryVoltage = newVoltage;
        changed = true;
    }

    // Update charging status
    bool newCharging = (status == BATTERY_STATUS_CHARGING || status == BATTERY_STATUS_FULL);
    if (_isCharging != newCharging) {
        _isCharging = newCharging;
        changed = true;
    }

    bool newFullyCharged = (status == BATTERY_STATUS_FULL);
    if (_isFullyCharged != newFullyCharged) {
        _isFullyCharged = newFullyCharged;
        changed = true;
    }

    if (_batteryStatus != status) {
        _batteryStatus = status;
        changed = true;
    }

    if (_batteryHealth != health) {
        _batteryHealth = health;
        changed = true;
    }

    if (_pluggedType != plugged) {
        _pluggedType = plugged;
        changed = true;
    }

    if (changed) {
        qCDebug(AndroidBatteryMonitorLog)
            << "Battery updated:"
            << "level=" << _batteryPercent << "%"
            << "temp=" << _batteryTemperature << "°C"
            << "voltage=" << _batteryVoltage << "V"
            << "status=" << statusText()
            << "health=" << healthText()
            << "plugged=" << _pluggedType;

        emit batteryChanged();
    }
}

QString AndroidBatteryMonitor::statusText() const
{
    switch (_batteryStatus) {
        case BATTERY_STATUS_CHARGING:
            return QStringLiteral("Charging");
        case BATTERY_STATUS_DISCHARGING:
            return QStringLiteral("Discharging");
        case BATTERY_STATUS_NOT_CHARGING:
            return QStringLiteral("Not Charging");
        case BATTERY_STATUS_FULL:
            return QStringLiteral("Full");
        case BATTERY_STATUS_UNKNOWN:
        default:
            return QStringLiteral("Unknown");
    }
}

QString AndroidBatteryMonitor::healthText() const
{
    switch (_batteryHealth) {
        case BATTERY_HEALTH_GOOD:
            return QStringLiteral("Good");
        case BATTERY_HEALTH_OVERHEAT:
            return QStringLiteral("Overheat");
        case BATTERY_HEALTH_DEAD:
            return QStringLiteral("Dead");
        case BATTERY_HEALTH_OVER_VOLTAGE:
            return QStringLiteral("Over Voltage");
        case BATTERY_HEALTH_UNSPECIFIED_FAILURE:
            return QStringLiteral("Failure");
        case BATTERY_HEALTH_COLD:
            return QStringLiteral("Cold");
        case BATTERY_HEALTH_UNKNOWN:
        default:
            return QStringLiteral("Unknown");
    }
}
