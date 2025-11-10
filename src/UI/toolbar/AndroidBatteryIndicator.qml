/****************************************************************************
 *
 * (c) 2009-2025 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

// Android Battery Indicator - Shows device battery status in toolbar
Item {
    id:             control
    width:          batteryRow.width * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: Qt.platform.os === "android"

    QGCPalette { id: qgcPal }

    Component {
        id: batteryInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Device Battery Status")

                GridLayout {
                    columns: 2
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 2
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.5

                    QGCLabel {
                        text: qsTr("Battery Level:")
                        font.bold: true
                    }
                    QGCLabel {
                        text: QGroundControl.androidBattery.batteryPercent + "%"
                        color: {
                            var percent = QGroundControl.androidBattery.batteryPercent;
                            if (percent > 50) return qgcPal.colorGreen;
                            if (percent > 20) return qgcPal.colorOrange;
                            return qgcPal.colorRed;
                        }
                        font.bold: true
                        font.pixelSize: ScreenTools.largeFontPointSize
                    }

                    QGCLabel { text: qsTr("Status:") }
                    QGCLabel {
                        text: QGroundControl.androidBattery.statusText
                        color: QGroundControl.androidBattery.isCharging ? qgcPal.colorGreen : qgcPal.buttonText
                    }

                    QGCLabel { text: qsTr("Temperature:") }
                    QGCLabel {
                        text: QGroundControl.androidBattery.batteryTemperature.toFixed(1) + "°C"
                        color: {
                            var temp = QGroundControl.androidBattery.batteryTemperature;
                            if (temp > 45) return qgcPal.colorRed;
                            if (temp < 0) return qgcPal.colorBlue;
                            return qgcPal.buttonText;
                        }
                    }

                    QGCLabel { text: qsTr("Voltage:") }
                    QGCLabel {
                        text: QGroundControl.androidBattery.batteryVoltage.toFixed(3) + "V"
                    }

                    QGCLabel { text: qsTr("Health:") }
                    QGCLabel {
                        text: QGroundControl.androidBattery.healthText
                        color: {
                            var health = QGroundControl.androidBattery.healthText;
                            if (health === "Good") return qgcPal.colorGreen;
                            if (health === "Overheat" || health === "Dead") return qgcPal.colorRed;
                            return qgcPal.colorOrange;
                        }
                    }

                    QGCLabel { text: qsTr("Power Source:") }
                    QGCLabel {
                        text: {
                            var plugged = QGroundControl.androidBattery.pluggedType;
                            if (plugged === 0) return qsTr("Battery");
                            if (plugged === 1) return qsTr("AC Charger");
                            if (plugged === 2) return qsTr("USB");
                            if (plugged === 4) return qsTr("Wireless");
                            return qsTr("Other");
                        }
                    }

                    QGCLabel { text: qsTr("Fully Charged:") }
                    QGCLabel {
                        text: QGroundControl.androidBattery.isFullyCharged ? qsTr("Yes") : qsTr("No")
                        color: QGroundControl.androidBattery.isFullyCharged ? qgcPal.colorGreen : qgcPal.buttonText
                    }
                }

                // Visual battery representation
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3
                    Layout.topMargin: ScreenTools.defaultFontPixelHeight
                    color: "transparent"

                    // Battery outline
                    Rectangle {
                        id: batteryOutline
                        anchors.centerIn: parent
                        width: parent.width * 0.8
                        height: parent.height * 0.7
                        color: "transparent"
                        border.color: qgcPal.text
                        border.width: 2
                        radius: 4

                        // Battery fill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            width: (parent.width - 8) * (QGroundControl.androidBattery.batteryPercent / 100)
                            color: {
                                var percent = QGroundControl.androidBattery.batteryPercent;
                                if (percent > 50) return qgcPal.colorGreen;
                                if (percent > 20) return qgcPal.colorOrange;
                                return qgcPal.colorRed;
                            }
                            radius: 2
                        }

                        // Charging bolt
                        QGCLabel {
                            anchors.centerIn: parent
                            text: "⚡"
                            font.pixelSize: ScreenTools.largeFontPointSize
                            color: "white"
                            visible: QGroundControl.androidBattery.isCharging
                        }
                    }

                    // Battery terminal
                    Rectangle {
                        anchors.left: batteryOutline.right
                        anchors.verticalCenter: batteryOutline.verticalCenter
                        width: 6
                        height: batteryOutline.height * 0.4
                        color: qgcPal.text
                        radius: 2
                    }
                }
            }
        }
    }

    Row {
        id:             batteryRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth * 0.5

        // Battery icon
        Item {
            width:              height * 1.5
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom

            // Battery body
            Rectangle {
                id: batteryBody
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.85
                height: parent.height * 0.6
                color: qgcPal.window
                border.color: qgcPal.windowTransparentText
                border.width: 2
                radius: 2

                // Battery fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 2
                    width: Math.max(0, (parent.width - 4) * (QGroundControl.androidBattery.batteryPercent / 100))
                    color: {
                        var percent = QGroundControl.androidBattery.batteryPercent;
                        if (percent > 50) return qgcPal.colorGreen;
                        if (percent > 20) return qgcPal.colorOrange;
                        return qgcPal.colorRed;
                    }
                    radius: 1
                }

                // Low battery warning flash
                SequentialAnimation on opacity {
                    running: QGroundControl.androidBattery.batteryPercent < 15 &&
                            !QGroundControl.androidBattery.isCharging
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }

            // Battery terminal
            Rectangle {
                anchors.left: batteryBody.right
                anchors.verticalCenter: batteryBody.verticalCenter
                width: 3
                height: batteryBody.height * 0.5
                color: qgcPal.windowTransparentText
                radius: 1
            }

            // Charging indicator
            QGCColoredImage {
                anchors.centerIn: batteryBody
                width: batteryBody.height * 0.5
                height: width
                source: "/InstrumentValueIcons/bolt.svg"
                fillMode: Image.PreserveAspectFit
                sourceSize.height: height
                color: "white"
                visible: QGroundControl.androidBattery.isCharging

                SequentialAnimation on scale {
                    running: visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.2; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                }
            }
        }

        // Battery percentage text
        QGCLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: QGroundControl.androidBattery.batteryPercent + "%"
            color: {
                var percent = QGroundControl.androidBattery.batteryPercent;
                if (percent > 50) return qgcPal.windowTransparentText;
                if (percent > 20) return qgcPal.colorOrange;
                return qgcPal.colorRed;
            }
            font.bold: QGroundControl.androidBattery.batteryPercent < 20
        }

        Rectangle {
            width:              1
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            color:              qgcPal.text
            opacity:            0.5
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(batteryInfoPage, control)
    }

    // Battery change monitoring
    Connections {
        target: QGroundControl.androidBattery

        function onBatteryChanged() {
            // Log critical battery levels
            if (QGroundControl.androidBattery.batteryPercent < 10 &&
                !QGroundControl.androidBattery.isCharging) {
                console.warn("Critical battery level:", QGroundControl.androidBattery.batteryPercent + "%");
            }
        }
    }
}
