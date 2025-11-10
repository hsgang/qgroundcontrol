package org.mavlink.qgroundcontrol;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.util.Log;

/**
 * Monitors Android device battery status and provides information to native C++ code.
 * This class registers a BroadcastReceiver to listen for battery state changes
 * and forwards the information through JNI to the Qt/QML layer.
 */
public class QGCBatteryMonitor {
    private static final String TAG = QGCBatteryMonitor.class.getSimpleName();

    private static QGCBatteryMonitor m_instance = null;
    private BroadcastReceiver m_batteryReceiver = null;
    private Context m_context = null;

    // Battery state
    private int m_level = -1;
    private int m_scale = 100;
    private int m_temperature = 0;
    private int m_voltage = 0;
    private int m_status = BatteryManager.BATTERY_STATUS_UNKNOWN;
    private int m_health = BatteryManager.BATTERY_HEALTH_UNKNOWN;
    private int m_plugged = 0;

    /**
     * Native method called when battery information changes.
     * This will be implemented on the C++ side.
     *
     * @param level Battery level (0-100)
     * @param scale Battery scale (typically 100)
     * @param temperature Battery temperature in tenths of degree Celsius
     * @param voltage Battery voltage in millivolts
     * @param status Battery status (charging, discharging, etc.)
     * @param health Battery health status
     * @param plugged How the device is plugged in (AC, USB, wireless, etc.)
     */
    private static native void nativeBatteryChanged(
        int level,
        int scale,
        int temperature,
        int voltage,
        int status,
        int health,
        int plugged
    );

    /**
     * Private constructor for singleton pattern.
     */
    private QGCBatteryMonitor() {
        m_instance = this;
    }

    /**
     * Returns the singleton instance.
     *
     * @return The QGCBatteryMonitor instance
     */
    public static QGCBatteryMonitor getInstance() {
        if (m_instance == null) {
            m_instance = new QGCBatteryMonitor();
        }
        return m_instance;
    }

    /**
     * Initializes the battery monitor with the given context.
     * This should be called from the Activity's onCreate method.
     *
     * @param context The application context
     */
    public static void initialize(Context context) {
        Log.i(TAG, "Initializing battery monitor");
        getInstance().startMonitoring(context);
    }

    /**
     * Cleans up the battery monitor.
     * This should be called from the Activity's onDestroy method.
     *
     * @param context The application context
     */
    public static void cleanup(Context context) {
        Log.i(TAG, "Cleaning up battery monitor");
        getInstance().stopMonitoring(context);
    }

    /**
     * Starts monitoring battery status changes.
     *
     * @param context The application context
     */
    private void startMonitoring(Context context) {
        if (m_batteryReceiver != null) {
            Log.w(TAG, "Battery monitor already running");
            return;
        }

        m_context = context;

        m_batteryReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context ctx, Intent intent) {
                if (Intent.ACTION_BATTERY_CHANGED.equals(intent.getAction())) {
                    updateBatteryInfo(intent);
                }
            }
        };

        // Register receiver for battery changes
        IntentFilter filter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
        Intent batteryStatus = context.registerReceiver(m_batteryReceiver, filter);

        // Get initial battery status immediately
        if (batteryStatus != null) {
            updateBatteryInfo(batteryStatus);
        }

        Log.i(TAG, "Battery monitor started");
    }

    /**
     * Stops monitoring battery status changes.
     *
     * @param context The application context
     */
    private void stopMonitoring(Context context) {
        if (m_batteryReceiver != null) {
            try {
                context.unregisterReceiver(m_batteryReceiver);
                m_batteryReceiver = null;
                Log.i(TAG, "Battery monitor stopped");
            } catch (Exception e) {
                Log.e(TAG, "Error stopping battery monitor", e);
            }
        }
    }

    /**
     * Extracts battery information from the intent and notifies native code.
     *
     * @param intent The battery changed intent
     */
    private void updateBatteryInfo(Intent intent) {
        // Extract all battery information
        m_level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        m_scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100);
        m_temperature = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0);
        m_voltage = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0);
        m_status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, BatteryManager.BATTERY_STATUS_UNKNOWN);
        m_health = intent.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN);
        m_plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0);

        // Calculate battery percentage
        int percent = -1;
        if (m_level >= 0 && m_scale > 0) {
            percent = (m_level * 100) / m_scale;
        }

        Log.d(TAG, String.format(
            "Battery: %d%%, temp: %.1f°C, voltage: %.3fV, status: %d, health: %d, plugged: %d",
            percent,
            m_temperature / 10.0f,
            m_voltage / 1000.0f,
            m_status,
            m_health,
            m_plugged
        ));

        // Notify native C++ code
        try {
            nativeBatteryChanged(m_level, m_scale, m_temperature, m_voltage, m_status, m_health, m_plugged);
        } catch (Exception e) {
            Log.e(TAG, "Error calling native battery changed", e);
        }
    }

    /**
     * Returns the current battery level (0-100).
     * Can be called from Java code for debugging.
     *
     * @return Battery level percentage, or -1 if unknown
     */
    public int getBatteryPercent() {
        if (m_level >= 0 && m_scale > 0) {
            return (m_level * 100) / m_scale;
        }
        return -1;
    }

    /**
     * Returns whether the device is currently charging.
     *
     * @return true if charging or fully charged, false otherwise
     */
    public boolean isCharging() {
        return m_status == BatteryManager.BATTERY_STATUS_CHARGING ||
               m_status == BatteryManager.BATTERY_STATUS_FULL;
    }
}
