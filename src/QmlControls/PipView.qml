/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Window

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.FactSystem

Item {
    id:         _root
    width:      _pipSize
    height:     _pipSize * (9/16)
    visible:    item2 && item2.pipState !== item2.pipState.window && show

    property bool   isViewer3DOpen:         false

    property var    item1:                  null    // Required
    property var    item2:                  null    // Optional, may come and go
    property string item1IsFullSettingsKey          // Settings key to save whether item1 was saved in full mode
    property bool   show:                   true

    readonly property string _pipExpandedSettingsKey: "IsPIPVisible"

    property var    _fullItem
    property var    _pipOrWindowItem
    property alias  _windowContentItem: window.contentItem
    property alias  _pipContentItem:    pipContent
    property bool   _isExpanded:        true
    property real   _pipSize:           parent.width * 0.2
    property real   _maxSize:           0.30                // Percentage of parent control size
    property real   _minSize:           0.20
    property bool   _componentComplete: false

    property var    _settingsManager:   QGroundControl.settingsManager
    property Fact   _mapProviderFact:   _settingsManager.flightMapSettings.mapProvider
    property Fact   _mapTypeFact:       _settingsManager.flightMapSettings.mapType
    property var    _mapEngineManager:  QGroundControl.mapEngineManager
    property var    _mapTypeList:       _mapEngineManager.mapTypeList(_mapProviderFact.rawValue)

    Component.onCompleted: {
        _initForItems()
        _componentComplete = true
    }

    onItem2Changed: _initForItems()

    function showWindow() {
        window.width = _root.width
        window.height = _root.height
        window.show()
    }

    function _initForItems() {
        var item1IsFull = QGroundControl.loadBoolGlobalSetting(item1IsFullSettingsKey, true)
        if (item1 && item2) {
            item1.pipState.state = item1IsFull ? item1.pipState.fullState : item1.pipState.pipState
            item2.pipState.state = item1IsFull ? item2.pipState.pipState : item2.pipState.fullState
            _fullItem = item1IsFull ? item1 : item2
            _pipOrWindowItem = item1IsFull ? item2 : item1
        } else {
            item1.pipState.state = item1.pipState.fullState
            _fullItem = item1
            _pipOrWindowItem = null
        }
        _setPipIsExpanded(QGroundControl.loadBoolGlobalSetting(_pipExpandedSettingsKey, true))
    }

    function _swapPip() {
        var item1IsFull = false
        if (item1.pipState.state === item1.pipState.fullState) {
            item1.pipState.state = item1.pipState.pipState
            item2.pipState.state = item2.pipState.fullState
            _fullItem = item2
            _pipOrWindowItem = item1
            item1IsFull = false
        } else {
            item1.pipState.state = item1.pipState.fullState
            item2.pipState.state = item2.pipState.pipState
            _fullItem = item1
            _pipOrWindowItem = item2
            item1IsFull = true
        }
        QGroundControl.saveBoolGlobalSetting(item1IsFullSettingsKey, item1IsFull)
    }

    function _setPipIsExpanded(isExpanded) {
        QGroundControl.saveBoolGlobalSetting(_pipExpandedSettingsKey, isExpanded)
        _isExpanded = isExpanded
    }

    Window {
        id:         window
        visible:    false
        onClosing: {
            var item = contentItem.children[0]
            if (item) {
                item.pipState.windowAboutToClose()
                item.pipState.state = item.pipState.pipState
            }
        }
    }

    Item {
        id:             pipContent
        anchors.fill:   parent
        visible:        _isExpanded
        clip:           true
    }

    MouseArea {
        id:             pipMouseArea
        anchors.fill:   parent
        enabled:        _isExpanded
        preventStealing: true
        hoverEnabled:   true
        onClicked:      {
            if(ScreenTools.isMobile){
                _swapPip()
            }
        }
    }

    // MouseArea to drag in order to resize the PiP area
    MouseArea {
        id:             pipResize
        anchors.top:    parent.top
        anchors.right:  parent.right
        height:         ScreenTools.minTouchPixels
        width:          height
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        property real initialX:     0
        property real initialWidth: 0

        // When we push the mouse button down, we un-anchor the mouse area to prevent a resizing loop
        onPressed: (mouse) => {
            pipResize.anchors.top = undefined // Top doesn't seem to 'detach'
            pipResize.anchors.right = undefined // This one works right, which is what we really need
            pipResize.initialX = mouse.x
            pipResize.initialWidth = _root.width
        }

        // When we let go of the mouse button, we re-anchor the mouse area in the correct position
        onReleased: {
            pipResize.anchors.top = _root.top
            pipResize.anchors.right = _root.right
        }

        // Drag
        onPositionChanged: (mouse) => {
            if (pipResize.pressed) {
                var parentWidth = _root.parent.width
                var newWidth = pipResize.initialWidth + mouse.x - pipResize.initialX
                if (newWidth < parentWidth * _maxSize && newWidth > parentWidth * _minSize) {
                    _pipSize = newWidth
                }
            }
        }
    }

    // Resize icon
    Image {
        source:         "/qmlimages/pipResize.svg"
        fillMode:       Image.PreserveAspectFit
        mipmap: true
        anchors.right:  parent.right
        anchors.top:    parent.top
        visible:        _isExpanded && (ScreenTools.isMobile || pipMouseArea.containsMouse)
        height:         ScreenTools.defaultFontPixelHeight * 2.5
        width:          ScreenTools.defaultFontPixelHeight * 2.5
        sourceSize.height:  height
    }

    // Check min/max constraints on pip size when when parent is resized
    Connections {
        target: _root.parent

        function onWidthChanged() {
            if (!_componentComplete) {
                // Wait until first time setup is done
                return
            }
            var parentWidth = _root.parent.width
            if (_root.width > parentWidth * _maxSize) {
                _pipSize = parentWidth * _maxSize
            } else if (_root.width < parentWidth * _minSize) {
                _pipSize = parentWidth * _minSize
            }
        }
    }

    // Pip to Window

    Image {
        id:             hidePIP
        source:         "/qmlimages/pipHide.svg"
        mipmap:         true
        fillMode:       Image.PreserveAspectFit
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        visible:        _isExpanded && (ScreenTools.isMobile || pipMouseArea.containsMouse)
        height:         ScreenTools.defaultFontPixelHeight * 2.5
        width:          ScreenTools.defaultFontPixelHeight * 2.5
        sourceSize.height:  height
        MouseArea {
            anchors.fill:   parent
            onClicked:      _root._setPipIsExpanded(false)
        }
    }

    Rectangle {
        id:                     showPip
        anchors.left :          parent.left
        anchors.bottom:         parent.bottom
        height:                 ScreenTools.defaultFontPixelHeight * 2
        width:                  ScreenTools.defaultFontPixelHeight * 2
        radius:                 ScreenTools.defaultFontPixelHeight / 3
        visible:                !_isExpanded && ScreenTools.isMobile
        color:                  _fullItem.pipState.isDark ? Qt.rgba(0,0,0,0.75) : Qt.rgba(0,0,0,0.5)
        Image {
            width:              parent.width  * 0.75
            height:             parent.height * 0.75
            sourceSize.height:  height
            source:             "/res/buttonRight.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.verticalCenter:     parent.verticalCenter
            anchors.horizontalCenter:   parent.horizontalCenter
        }
        MouseArea {
            anchors.fill:   parent
            onClicked:      _root._setPipIsExpanded(true)
        }
    }


    Item {
        id: toolStrip
        width:  pipToolStrip.width
        height: pipToolStrip.height
        visible: !ScreenTools.isMobile

        anchors.right:          parent.left
        anchors.rightMargin:    ScreenTools.defaultFontPixelHeight / 5
        anchors.bottom:         parent.bottom

        ToolStrip {
            id: pipToolStrip
            model:  pipToolStripList.model
            maxHeight:          width * 5

            ToolStripActionList {
                id: pipToolStripList
                model: [
                    ToolStripAction {
                        text: qsTr("Swap")
                        iconSource: "/InstrumentValueIcons/copy.svg"
                        onTriggered: _root._swapPip()
                        visible:    _isExpanded
                    },

                    ToolStripAction {
                        property bool _is3DViewOpen:            isViewer3DOpen //viewer3DWindow.isOpen
                        property bool _viewer3DEnabled:       QGroundControl.settingsManager.viewer3DSettings.enabled.rawValue

                        id: view3DIcon
                        visible: _viewer3DEnabled && (item1.pipState.state === item1.pipState.fullState)
                        text:           qsTr("3D View")
                        iconSource:     "/qmlimages/Viewer3D/City3DMapIcon.svg"
                        onTriggered:{
                            if(_is3DViewOpen === false){
                                viewer3DWindow.open()
                            }else{
                                viewer3DWindow.close()
                            }
                        }

                        on_Is3DViewOpenChanged: {
                            if(_is3DViewOpen === true){
                                view3DIcon.iconSource =     "/InstrumentValueIcons/outlineMap.svg"
                                text=           qsTr("2D View")
                            }else{
                                iconSource =     "/qmlimages/Viewer3D/City3DMapIcon.svg"
                                text =           qsTr("3D View")
                            }
                        }
                    },

                    ToolStripAction {
                        text: qsTr("Layer")
                        iconSource: "/InstrumentValueIcons/layers.svg"
                        onTriggered: {
                            var currentIndex = _mapTypeList.indexOf(_mapTypeFact.rawValue)
                            var nextIndex = (currentIndex + 1) % _mapTypeList.length
                            _mapTypeFact.rawValue = _mapTypeList[nextIndex]
                        }
                        visible:    true //_isExpanded
                    },
                    ToolStripAction {
                        text: qsTr("Show PIP")
                        iconSource: "/InstrumentValueIcons/cheveron-outline-right.svg"
                        onTriggered: _root._setPipIsExpanded(true)
                        visible:    !_isExpanded
                    },
                    ToolStripAction {
                        text: qsTr("Hide PIP")
                        iconSource: "/InstrumentValueIcons/cheveron-outline-left.svg"
                        onTriggered: _root._setPipIsExpanded(false)
                        visible:    _isExpanded
                    }
                ]
            }
        }
    }
}