/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl

import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools


Item {
    id:     _root
    height: monitorColumn.height

    property bool twoColumn: false

    readonly property int _pwmMin:      900
    readonly property int _pwmMax:      2100
    readonly property int _pwmRange:    _pwmMax - _pwmMin

    RCChannelMonitorController {
        id:             controller
    }

    // Live channel monitor control component
    Component {
        id: channelMonitorDisplayComponent

        Item {
            height: ScreenTools.defaultFontPixelHeight

            property int    rcValue:    1500

            property int            __lastRcValue:      1500
            readonly property int   __rcValueMaxJitter: 2
            property color          __barColor:         qgcPal.windowShade

            // Bar
            Rectangle {
                id:                     bar
                anchors.verticalCenter: parent.verticalCenter
                width:                  parent.width
                height:                 parent.height / 2
                color:                  __barColor
            }

            // Center point
            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                width:                      ScreenTools.defaultFontPixelWidth / 2
                height:                     parent.height
                color:                      qgcPal.window
            }

            // Indicator
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width:                  2 //parent.height * 0.75
                height:                 parent.height * 0.8 //width
                x:                      (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * parent.width) - (width / 2)
                //radius:                 width / 2
                color:                  qgcPal.colorOrange
                visible:                mapped && (rcValue !== 0)
            }

            QGCLabel {
                anchors.fill:           parent
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
                text:                   rcValue
                visible:                mapped
            }

            QGCLabel {
                anchors.fill:           parent
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
                text:                   qsTr("Not Mapped")
                visible:                !mapped
            }

            ColorAnimation {
                id:         barAnimation
                target:     bar
                property:   "color"
                from:       "yellow"
                to:         __barColor
                duration:   1500
            }
        }
    } // Component - channelMonitorDisplayComponent

    GridLayout {
        id:         monitorColumn
        width:      parent.width
        columns:    twoColumn ? 2 : 1

        QGCLabel {
            Layout.columnSpan:  parent.columns
            text:               qsTr("Channel Monitor")
        }

        Connections {
            target: controller

            function onChannelRCValueChanged(channel, rcValue) {
                if (channelMonitorRepeater.itemAt(channel)) {
                    channelMonitorRepeater.itemAt(channel).loader.item.rcValue = rcValue
                }
            }
        }

        Repeater {
            id:     channelMonitorRepeater
            model:  controller.channelCount

            RowLayout {
                // Need this to get to loader from Connections above
                property Item loader: theLoader

                QGCLabel {
                    id:     channelLabel
                    text:   modelData + 1
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 2.4
                }

                Loader {
                    id:                 theLoader
                    Layout.fillWidth:   true
                    //height:                 ScreenTools.defaultFontPixelHeight
                    //width:                  parent.width - anchors.leftMargin - ScreenTools.defaultFontPixelWidth
                    sourceComponent:        channelMonitorDisplayComponent

                    property bool mapped:               true
                    readonly property bool reversed:    false
                }
            }
        }
    }
}
