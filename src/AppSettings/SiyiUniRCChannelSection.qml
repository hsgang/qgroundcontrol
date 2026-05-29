import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

SettingsGroupLayout {
    Layout.fillWidth: true
    heading:          qsTr("UniRC 7 Channel Mapping / Reverse")

    property var _siyi:     QGroundControl.siyi
    property var _uniRC:    _siyi ? _siyi.uniRC : null
    property var _mappings: _uniRC ? _uniRC.channelMappings : []
    property var _reverses: _uniRC ? _uniRC.channelReverses : []

    QGCPalette { id: qgcPal }

    // type+entityId → physical switch label (per UniRC 7 SDK manual)
    function _mappingName(type, entityId) {
        if (type === 0) {
            switch (entityId) {
            case 0: return "J1"
            case 1: return "J2"
            case 2: return "J3"
            case 3: return "J4"
            case 4: return "LD1"
            case 5: return "RD1"
            case 8: return "J5"
            case 9: return "J6"
            }
        } else if (type === 1) {
            const keys = ["S1","S2","S3","S4","L1","L2","R1","R2","R3","M1","M2","M3","M4","M5","M6"]
            if (entityId >= 0 && entityId < keys.length) return keys[entityId]
        } else if (type === 2) {
            return entityId === 1 ? "RSSI" : "NULL"
        } else if (type === 5) {
            return entityId === 0 ? "SA" : (entityId === 1 ? "SB" : "?")
        } else if (type === 3) {
            return "NULL"
        }
        return "T" + type + "/E" + entityId
    }
    function _isUnmapped(type, entityId) {
        return (type === 2 && entityId === 0) || type === 3
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelWidth
        QGCLabel {
            Layout.fillWidth: true
            text: qsTr("Tap a row's slider to flip reverse direction.")
            color: Qt.darker(qgcPal.text, 1.5)
            font.pointSize: ScreenTools.smallFontPointSize
            wrapMode: Text.WordWrap
        }
        QGCButton {
            text: qsTr("Refresh")
            enabled: _uniRC && _uniRC.isConnected
            onClicked: {
                _uniRC.requestChannelMappings()
                _uniRC.requestChannelReverses()
            }
        }
    }

    // Header strip
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + ScreenTools.defaultFontPixelHeight / 3
        color: Qt.rgba(qgcPal.windowShade.r, qgcPal.windowShade.g, qgcPal.windowShade.b, 0.6)
        radius: ScreenTools.defaultFontPixelWidth / 2

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin:  ScreenTools.defaultFontPixelWidth
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth
            spacing: ScreenTools.defaultFontPixelWidth

            QGCLabel { text: qsTr("Channel");   font.bold: true; Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 7 }
            QGCLabel { text: qsTr("Mapped To"); font.bold: true; Layout.fillWidth: true }
            QGCLabel { text: qsTr("Reverse");   font.bold: true; Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 16; horizontalAlignment: Text.AlignRight }
        }
    }

    Repeater {
        model: 16

        delegate: Rectangle {
            required property int index
            property var  mapping:    index < _mappings.length ? _mappings[index] : null
            property int  reverse:    index < _reverses.length ? _reverses[index] : 0
            property bool unmapped:   mapping ? _isUnmapped(mapping.type, mapping.entityId) : true
            property bool _hovered:   rowMouse.containsMouse

            Layout.fillWidth: true
            Layout.preferredHeight: rowLayout.implicitHeight + ScreenTools.defaultFontPixelHeight / 3
            color:  _hovered ? Qt.rgba(qgcPal.buttonHighlight.r, qgcPal.buttonHighlight.g, qgcPal.buttonHighlight.b, 0.08) : "transparent"
            radius: ScreenTools.defaultFontPixelWidth / 2

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.leftMargin:  ScreenTools.defaultFontPixelWidth
                anchors.rightMargin: ScreenTools.defaultFontPixelWidth
                spacing: ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 7
                    text: "CH " + (index + 1)
                    color: unmapped ? Qt.darker(qgcPal.text, 1.7) : qgcPal.text
                }
                QGCLabel {
                    Layout.fillWidth: true
                    text: mapping ? _mappingName(mapping.type, mapping.entityId) : "-"
                    color: unmapped ? Qt.darker(qgcPal.text, 1.7) : qgcPal.text
                    font.bold: !unmapped
                }
                QGCCheckBoxSlider {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 16
                    text:    checked ? qsTr("Reversed") : qsTr("Normal")
                    checked: reverse === -1
                    enabled: _uniRC && _uniRC.isConnected && !unmapped
                    onToggled: _uniRC.setChannelReverse(index + 1, checked)
                }
            }
        }
    }
}
