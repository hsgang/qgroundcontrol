/****************************************************************************
 *
 * Copyright (C) 2025. All rights reserved.
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QObject>
#include <QtCore/QLoggingCategory>
#include <jni.h>

Q_DECLARE_LOGGING_CATEGORY(AndroidBatteryMonitorLog)

/**
 * @class AndroidBatteryMonitor
 * @brief Provides Android device battery information to QML
 *
 * This class monitors the Android device's battery status and exposes it to QML
 * through Qt properties. It receives updates from the Java layer through JNI callbacks.
 *
 * Battery status constants (from Android BatteryManager):
 * - BATTERY_STATUS_UNKNOWN = 1
 * - BATTERY_STATUS_CHARGING = 2
 * - BATTERY_STATUS_DISCHARGING = 3
 * - BATTERY_STATUS_NOT_CHARGING = 4
 * - BATTERY_STATUS_FULL = 5
 *
 * Battery health constants:
 * - BATTERY_HEALTH_UNKNOWN = 1
 * - BATTERY_HEALTH_GOOD = 2
 * - BATTERY_HEALTH_OVERHEAT = 3
 * - BATTERY_HEALTH_DEAD = 4
 * - BATTERY_HEALTH_OVER_VOLTAGE = 5
 * - BATTERY_HEALTH_UNSPECIFIED_FAILURE = 6
 * - BATTERY_HEALTH_COLD = 7
 *
 * Plugged status:
 * - 0 = Not plugged in
 * - 1 = AC charger
 * - 2 = USB port
 * - 4 = Wireless
 */
class AndroidBatteryMonitor : public QObject
{
    Q_OBJECT

    // Battery level as percentage (0-100, or -1 if unknown)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY batteryChanged)

    // Battery temperature in degrees Celsius
    Q_PROPERTY(float batteryTemperature READ batteryTemperature NOTIFY batteryChanged)

    // Battery voltage in volts
    Q_PROPERTY(float batteryVoltage READ batteryVoltage NOTIFY batteryChanged)

    // Is the device currently charging or fully charged
    Q_PROPERTY(bool isCharging READ isCharging NOTIFY batteryChanged)

    // Is the device fully charged
    Q_PROPERTY(bool isFullyCharged READ isFullyCharged NOTIFY batteryChanged)

    // Battery status (charging, discharging, full, etc.)
    Q_PROPERTY(int batteryStatus READ batteryStatus NOTIFY batteryChanged)

    // Battery health status
    Q_PROPERTY(int batteryHealth READ batteryHealth NOTIFY batteryChanged)

    // How the device is plugged in (0=unplugged, 1=AC, 2=USB, 4=wireless)
    Q_PROPERTY(int pluggedType READ pluggedType NOTIFY batteryChanged)

    // Human-readable battery status string
    Q_PROPERTY(QString statusText READ statusText NOTIFY batteryChanged)

    // Human-readable battery health string
    Q_PROPERTY(QString healthText READ healthText NOTIFY batteryChanged)

public:
    explicit AndroidBatteryMonitor(QObject *parent = nullptr);
    ~AndroidBatteryMonitor();

    // Returns the singleton instance
    static AndroidBatteryMonitor* instance();

    // Registers native methods with Java
    static void setNativeMethods();

    // Property getters
    int batteryPercent() const { return _batteryPercent; }
    float batteryTemperature() const { return _batteryTemperature; }
    float batteryVoltage() const { return _batteryVoltage; }
    bool isCharging() const { return _isCharging; }
    bool isFullyCharged() const { return _isFullyCharged; }
    int batteryStatus() const { return _batteryStatus; }
    int batteryHealth() const { return _batteryHealth; }
    int pluggedType() const { return _pluggedType; }
    QString statusText() const;
    QString healthText() const;

    // Called by JNI when battery information changes
    void updateBatteryInfo(int level, int scale, int temperature,
                          int voltage, int status, int health, int plugged);

signals:
    // Emitted whenever battery information changes
    void batteryChanged();

private:
    static AndroidBatteryMonitor* _instance;

    int _batteryPercent;      // 0-100, or -1 if unknown
    float _batteryTemperature; // Degrees Celsius
    float _batteryVoltage;     // Volts
    bool _isCharging;
    bool _isFullyCharged;
    int _batteryStatus;
    int _batteryHealth;
    int _pluggedType;
};
