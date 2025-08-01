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

import QGroundControl

import QGroundControl.ScreenTools

/// The PreFlightCheckButton supports creating a button which the user then has to verify/click to confirm a check.
/// It also supports failing the check based on values from within the system: telemetry or QGC app values. These
/// controls are normally placed within a PreFlightCheckGroup.
///
/// Two types of checks may be included on the button:
///     Manual - This is simply a check which the user must verify and confirm. It is not based on any system state.
///     Telemetry - This type of check can fail due to some state within the system. A telemetry check failure can be
///                 a hard stop in that there is no way to pass the checklist until the system state resolves itself.
///                 Or it can also optionally be override by the user.
/// If a button uses both manual and telemetry checks, the telemetry check takes precendence and must be passed first.
QGCButton {
    property string name:                           ""
    property string manualText:                     ""      ///< text to show for a manual check, "" signals no manual check
    property string telemetryTextFailure                    ///< text to show if telemetry check failed (override not allowed)
    property bool   telemetryFailure:               false   ///< true: telemetry check failing, false: telemetry check passing
    property bool   allowTelemetryFailureOverride:  false   ///< true: user can click past telemetry failure
    property bool   passed:                         _manualState === _statePassed && _telemetryState === _statePassed
    property bool   failed:                         _manualState === _stateFailed || _telemetryState === _stateFailed

    property int _manualState:          manualText === "" ? _statePassed : _statePending
    property int _telemetryState:       _statePassed
    property int _horizontalPadding:    ScreenTools.defaultFontPixelWidth
    property int _verticalPadding:      Math.round(ScreenTools.defaultFontPixelHeight / 2)
    property real _stateFlagWidth:      ScreenTools.defaultFontPixelWidth * 3

    readonly property int _statePending:    0   ///< Telemetry check is failing or manual check not yet verified, user can click to make it pass
    readonly property int _stateFailed:     1   ///< Telemetry check is failing, user cannot click to make it pass
    readonly property int _statePassed:     2   ///< Check has passed

    readonly property color _passedColor:   "#86cc6a"
    readonly property color _pendingColor:  "white"//"#f7a81f"
    readonly property color _failedColor:   "#c31818"

    property string _text: "<b>" + name +"</b>: " +
                           ((_telemetryState !== _statePassed) ?
                               telemetryTextFailure :
                               (_manualState !== _statePassed ? manualText : qsTr("Passed")))
    property color  _color: _telemetryState === _statePassed && _manualState === _statePassed ?
                                _passedColor :
                                (_telemetryState == _stateFailed ?
                                     _failedColor :
                                     (_telemetryState === _statePending || _manualState === _statePending ?
                                          _pendingColor :
                                          _failedColor))
    property string  _mark: _telemetryState === _statePassed && _manualState === _statePassed ?
                                "/InstrumentValueIcons/checkmark.svg" :
                                (_telemetryState == _stateFailed ?
                                     "/InstrumentValueIcons/close.svg" :
                                     (_telemetryState === _statePending || _manualState === _statePending ?
                                          "" :
                                          "/InstrumentValueIcons/close.svg"))

    width:          40 * ScreenTools.defaultFontPixelWidth
    topPadding:     _verticalPadding
    bottomPadding:  _verticalPadding
    leftPadding:    (_horizontalPadding * 2) + _stateFlagWidth
    rightPadding:   _horizontalPadding

    background: Rectangle {
        color:          qgcPal.button
        border.color:   qgcPal.button;
        radius:         ScreenTools.defaultFontPixelHeight / 4

        Rectangle {
            color:          "transparent"//_color
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:   parent.left
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
            //anchors.top:    parent.top
            //anchors.bottom: parent.bottom
            width:          _stateFlagWidth
            height:         width
            radius:         width / 2
            border.color:   _color
            border.width:   2

            QGCColoredImage {
                anchors.fill: parent
                source:    _mark
                sourceSize.width: ScreenTools.defaultFontPixelHeight * 1.2
                sourceSize.height: ScreenTools.defaultFontPixelHeight * 1.2
                color:      _color
            }
        }
    }

    contentItem: QGCLabel {
        wrapMode:               Text.WordWrap
        horizontalAlignment:    Text.AlignHCenter
        color:                  qgcPal.buttonText
        text:                   _text
    }

    function _updateTelemetryState() {
        if (telemetryFailure) {
            // We have a new telemetry failure, reset user pass
            _telemetryState = allowTelemetryFailureOverride ? _statePending : _stateFailed
        } else {
            _telemetryState = _statePassed
        }
    }

    onTelemetryFailureChanged:              _updateTelemetryState()
    onAllowTelemetryFailureOverrideChanged: _updateTelemetryState()

    onClicked: {
        if (telemetryFailure && !allowTelemetryFailureOverride) {
            // No way to proceed past this failure
            return
        }
        if (telemetryFailure && allowTelemetryFailureOverride && _telemetryState !== _statePassed) {
            // User is allowed to proceed past this failure
            _telemetryState = _statePassed
            return
        }
        if (manualText !== "") {
            // User is confirming a manual check
            _manualState = (_manualState === _statePassed) ? _statePending : _statePassed
        }
    }

    onPassedChanged: callButtonPassedChanged()
    onParentChanged: callButtonPassedChanged()

    function callButtonPassedChanged() {
        if (typeof parent.buttonPassedChanged === "function") {
            parent.buttonPassedChanged()
        }
    }

    function reset() {
        _manualState = manualText === "" ? _statePassed : _statePending
        if (telemetryFailure) {
            _telemetryState = allowTelemetryFailureOverride ? _statePending : _stateFailed
        } else {
            _telemetryState = _statePassed
        }
    }

}
