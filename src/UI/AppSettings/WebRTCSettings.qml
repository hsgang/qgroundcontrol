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
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

ColumnLayout {
    spacing: _rowSpacing
    width:  _columnLayoutWidth

    function saveSettings() {
        subEditConfig.gcsId = gcsIdField.text
        subEditConfig.targetDroneId = targetDroneIdField.text
    }

    ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        RowLayout {
            spacing: _colSpacing
            QGCLabel { text: qsTr("GCS ID") }
            QGCTextField {
                id:                     gcsIdField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.gcsId
                placeholderText:        qsTr("자동 생성 (gcs_xxxxx)")

                onEditingFinished: {
                    saveSettings()
                }
            }
        }

        RowLayout {
            spacing: _colSpacing
            QGCLabel { text: qsTr("Vehicle ID") }
            QGCTextField {
                id:                     targetDroneIdField
                Layout.preferredWidth:  _secondColumnWidth * 0.7
                Layout.fillWidth:       true
                text:                   subEditConfig.targetDroneId
                placeholderText:        qsTr("연결할 드론의 ID를 입력")

                onEditingFinished: {
                    saveSettings()
                }
            }
        }
    }
}
