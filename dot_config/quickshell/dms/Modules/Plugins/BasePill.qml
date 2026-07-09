import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import QtQuick.Effects

Item {
    id: root

    property var axis: null
    property string section: "center"
    property var popoutTarget: null
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 48
    property real barSpacing: 4
    property var barConfig: null
    property var blurBarWindow: null
    property alias content: contentLoader.sourceComponent
    property bool isVerticalOrientation: axis?.isVertical ?? false
    property bool isFirst: false
    property bool isLast: false
    property real sectionSpacing: 0
    property bool enableBackgroundHover: true
    property bool enableCursor: true
    readonly property bool isMouseHovered: mouseArea.containsMouse
    property bool isLeftBarEdge: false
    property bool isRightBarEdge: false
    property bool isTopBarEdge: false
    property bool isBottomBarEdge: false
    readonly property real dpr: parentScreen ? CompositorService.getScreenScale(parentScreen) : 1
    readonly property real horizontalPadding: (barConfig?.removeWidgetPadding ?? false) ? 0 : Theme.snap((barConfig?.widgetPadding ?? 12) * (widgetThickness / 30), dpr)
    readonly property real visualWidth: Theme.snap(isVerticalOrientation ? widgetThickness : (contentLoader.item ? (contentLoader.item.implicitWidth + horizontalPadding * 2) : 0), dpr)
    readonly property real visualHeight: Theme.snap(isVerticalOrientation ? (contentLoader.item ? (contentLoader.item.implicitHeight + horizontalPadding * 2) : 0) : widgetThickness, dpr)
    readonly property alias visualContent: visualContent
    readonly property real barEdgeExtension: 1000
    readonly property real gapExtension: sectionSpacing
    readonly property real leftMargin: !isVerticalOrientation ? (isLeftBarEdge && isFirst ? barEdgeExtension : (isFirst ? gapExtension : gapExtension / 2)) : 0
    readonly property real rightMargin: !isVerticalOrientation ? (isRightBarEdge && isLast ? barEdgeExtension : (isLast ? gapExtension : gapExtension / 2)) : 0
    readonly property real topMargin: isVerticalOrientation ? (isTopBarEdge && isFirst ? barEdgeExtension : (isFirst ? gapExtension : gapExtension / 2)) : 0
    readonly property real bottomMargin: isVerticalOrientation ? (isBottomBarEdge && isLast ? barEdgeExtension : (isLast ? gapExtension : gapExtension / 2)) : 0

    // default
    // solid
    // striped
    property string backgroundStyle: "default"
    property color stripeColor1: Theme.primary
    property color stripeColor2: Theme.secondary
    property real stripeOpacity: 0.2
    property int stripeWidth: 21
    property int stripeSpacing: 30
    property real stripeAngle: 30
    property bool stripeAnimation: false
    property real stripeAnimationSpeed: 40
    property bool stripeEdgeBlurEnabled: false
    // 0-1
    property real stripeEdgeBlurAmount: 0.4

    property color solidColor: Theme.primary
    property real solidOpacity: 1

    signal clicked
    signal rightClicked(real rootX, real rootY)
    signal wheel(var wheelEvent)

    function triggerRipple(sourceItem, mouseX, mouseY) {
        const pos = sourceItem.mapToItem(visualContent, mouseX, mouseY);
        rippleLayer.trigger(pos.x, pos.y);
    }

    width: isVerticalOrientation ? barThickness : visualWidth
    height: isVerticalOrientation ? visualHeight : barThickness

    Item {
        readonly property real borderWidth: (barConfig?.widgetOutlineEnabled ?? false) ? (barConfig?.widgetOutlineThickness ?? 1) : 0
        
        id: visualContent
        width: root.visualWidth
        height: root.visualHeight
        anchors.centerIn: parent

        Rectangle {
            id: outline
            antialiasing: true
            anchors.centerIn: parent
            width: {
                const borderWidth = (barConfig?.widgetOutlineEnabled ?? false) ? (barConfig?.widgetOutlineThickness ?? 1) : 0;
                return parent.width + borderWidth * 2;
            }
            height: {
                const borderWidth = (barConfig?.widgetOutlineEnabled ?? false) ? (barConfig?.widgetOutlineThickness ?? 1) : 0;
                return parent.height + borderWidth * 2;
            }
            // radius: (barConfig?.noBackground ?? false) ? 0 : Theme.cornerRadius
            radius: (barConfig?.noBackground ?? false) ? 0 : (Theme.cornerRadius > 0 ? Theme.cornerRadius + borderWidth : 0)
            color: "transparent"
            border.width: {
                if (barConfig?.widgetOutlineEnabled ?? false) {
                    return barConfig?.widgetOutlineThickness ?? 1;
                }
                return 0;
            }
            border.color: {
                if (!(barConfig?.widgetOutlineEnabled ?? false)) {
                    return "transparent";
                }
                const colorOption = barConfig?.widgetOutlineColor || "primary";
                const opacity = barConfig?.widgetOutlineOpacity ?? 1.0;
                switch (colorOption) {
                case "surfaceText":
                    return Theme.withAlpha(Theme.surfaceText, opacity);
                case "secondary":
                    return Theme.withAlpha(Theme.secondary, opacity);
                case "primary":
                    return Theme.withAlpha(Theme.primary, opacity);
                default:
                    return Theme.withAlpha(Theme.primary, opacity);
                }
            }
        }

        // Item {
        //     anchors.fill: parent

        //     Rectangle {
        //         id: background
        //         anchors.fill: parent
        //         antialiasing: true
        //         layer.enabled: true
        //         layer.samples: 8
        //         layer.effect: MultiEffect {
        //             shadowEnabled: true
        //             shadowBlur: 0.5
        //             shadowColor: Qt.rgba(0, 0, 0, 0.40)
        //             shadowVerticalOffset: 3
        //             shadowHorizontalOffset: 1
        //             autoPaddingEnabled: true
        //         }

        //         radius: (barConfig?.noBackground ?? false) ? 0 : Theme.cornerRadius

        //         color: {
        //             if (barConfig?.noBackground ?? false)
        //                 return "transparent";
                
        //             if (root.backgroundStyle === "solid") {
        //                 const c = Qt.color(root.solidColor)
        //                 return Qt.rgba(c.r, c.g, c.b, root.solidOpacity)
        //             }
                
        //             const rawTransparency = (root.barConfig && root.barConfig.widgetTransparency !== undefined) ? root.barConfig.widgetTransparency : 1.0;
        //             const isHovered = root.enableBackgroundHover && (mouseArea.containsMouse || (root.isHovered || false));
        //             const transparency = isHovered ? Math.max(0.3, rawTransparency) : rawTransparency;
        //             const baseColor = isHovered ? BlurService.hoverColor(Theme.widgetBaseHoverColor) : Theme.widgetBaseBackgroundColor;
                
        //             if (Theme.widgetBackgroundHasAlpha) {
        //                 return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * transparency);
        //             }
        //             return Theme.withAlpha(baseColor, transparency);
        //         }

        //         Rectangle {
        //             id: stripeBackground
        //             anchors.fill: parent
        //             visible: root.backgroundStyle === "striped"
        //             radius: background.radius
        //             color: "transparent"
        //             antialiasing: true
        //             layer.enabled: true
        //             layer.samples: 8
        //             layer.effect: MultiEffect {
        //                 maskEnabled: stripeBackground.radius > 0
        //                 maskSource: stripeMask
        //             }

        //             Rectangle {
        //                 antialiasing: true
        //                 id: stripeMask
        //                 anchors.fill: parent
        //                 radius: stripeBackground.radius
        //                 color: "black"        
        //                 visible: false        
        //                 layer.enabled: true
        //                 layer.samples: 8
        //             }

        //             Item {
        //                 id: stripeContainer
        //                 width: parent.width * 2
        //                 height: parent.height
        //                 x: 0
                        
        //                 Repeater {
        //                     model: Math.ceil((stripeContainer.width + stripeContainer.height) / root.stripeSpacing) + 10

        //                     Rectangle {
        //                         id: individualStripe
        //                         width: root.stripeWidth
        //                         height: stripeContainer.height * 5
        //                         rotation: root.stripeAngle
        //                         x: index * root.stripeSpacing - stripeContainer.height
        //                         y: -(height - stripeContainer.height) / 2
        //                         color: index % 2 ? root.stripeColor1 : root.stripeColor2
        //                         opacity: root.stripeOpacity

        //                         layer.enabled: root.stripeEdgeBlurEnabled
        //                         layer.samples: 8
        //                         layer.effect: MultiEffect {
        //                             blurEnabled: true
        //                             blur: root.stripeEdgeBlurAmount
        //                             blurMax: 64
                                    
        //                             autoPaddingEnabled: true 
        //                         }
        //                     }
        //                 }

        //                 NumberAnimation {
        //                     id: stripeAnimation
        //                     target: stripeContainer
        //                     property: "x"
        //                     from: 0
        //                     to: -root.stripeSpacing * 2
        //                     duration: 1000 * (root.stripeSpacing * 2) / root.stripeAnimationSpeed
        //                     loops: Animation.Infinite
        //                     running: root.stripeAnimation
        //                 }
        //             }
        //         }
        //     }
        // }

        Item {
            anchors.fill: parent

            // 1. 底层：只负责绘制基础背景色和阴影
            Rectangle {
                id: background
                anchors.fill: parent
                antialiasing: true
                layer.enabled: true
                layer.samples: 8
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.5
                    shadowColor: Qt.rgba(0, 0, 0, 0.40)
                    shadowVerticalOffset: 3
                    shadowHorizontalOffset: 1
                    autoPaddingEnabled: true
                }
                radius: (barConfig?.noBackground ?? false) ? 0 : Theme.cornerRadius
                color: {
                    if (barConfig?.noBackground ?? false) return "transparent";
                    if (root.backgroundStyle === "solid") {
                        const c = Qt.color(root.solidColor)
                        return Qt.rgba(c.r, c.g, c.b, root.solidOpacity)
                    } else if(root.backgroundStyle === "striped") {
                        const c = Qt.color(root.solidColor)
                        return Qt.rgba(c.r, c.g, c.b, root.stripeOpacity)
                    }
                    const rawTransparency = (root.barConfig && root.barConfig.widgetTransparency !== undefined) ? root.barConfig.widgetTransparency : 1.0;
                    const isHovered = root.enableBackgroundHover && (mouseArea.containsMouse || (root.isHovered || false));
                    const transparency = isHovered ? Math.max(0.3, rawTransparency) : rawTransparency;
                    const baseColor = isHovered ? BlurService.hoverColor(Theme.widgetBaseHoverColor) : Theme.widgetBaseBackgroundColor;
                    if (Theme.widgetBackgroundHasAlpha) return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * transparency);
                    return Theme.withAlpha(baseColor, transparency);
                }
            }

            // 2. 条纹层：与 background 平级
            Rectangle {
                id: stripeBackground
                anchors.fill: parent
                visible: root.backgroundStyle === "striped"
                radius: background.radius
                color: "transparent"
                antialiasing: true
                layer.enabled: true
                layer.samples: 8
                layer.effect: MultiEffect {
                    maskEnabled: stripeBackground.radius > 0
                    maskSource: stripeMask
                    
                    maskThresholdMin: 0.5
                    // 1.0 表示在边缘像素上开启完全平滑的混合过渡，彻底消灭狗牙
                    maskSpreadAtMin: 1.0
                }

                Rectangle {
                    id: stripeMask
                    anchors.fill: parent // 恢复 1:1 填满，不再需要 margin 缩进
                    radius: stripeBackground.radius
                    color: "black"        
                    visible: false        
                    antialiasing: true
                    
                    layer.enabled: true
                    layer.smooth: true
                    layer.samples: 8 // 渲染出高精度、平滑的圆角遮罩纹理
                }

                Item {
                    id: stripeContainer
                    width: parent.width * 2
                    height: parent.height
                    x: 0
                    
                    Repeater {
                        model: Math.ceil((stripeContainer.width + stripeContainer.height) / root.stripeSpacing) + 10
                        Rectangle {
                            id: individualStripe
                            width: root.stripeWidth
                            height: stripeContainer.height * 5
                            rotation: root.stripeAngle
                            x: index * root.stripeSpacing - stripeContainer.height
                            y: -(height - stripeContainer.height) / 2
                            color: index % 2 ? root.stripeColor1 : root.stripeColor2
                            opacity: root.stripeOpacity

                            layer.enabled: root.stripeEdgeBlurEnabled
                            layer.samples: 8
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: root.stripeEdgeBlurAmount
                                blurMax: 64
                                autoPaddingEnabled: true 
                            }
                        }
                    }

                    NumberAnimation {
                        id: stripeAnimation
                        target: stripeContainer
                        property: "x"
                        from: 0
                        to: -root.stripeSpacing * 2
                        duration: 1000 * (root.stripeSpacing * 2) / root.stripeAnimationSpeed
                        loops: Animation.Infinite
                        running: root.stripeAnimation
                    }
                }
            }
        }

        DankRipple {
            id: rippleLayer
            rippleColor: Theme.surfaceText
            cornerRadius: background.radius
        }

        Loader {
            id: contentLoader
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: mouseArea
        z: -1
        x: -root.leftMargin
        y: -root.topMargin
        width: root.width + root.leftMargin + root.rightMargin
        height: root.height + root.topMargin + root.bottomMargin
        hoverEnabled: true
        cursorShape: root.enableCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                const rPos = mouseArea.mapToItem(root, mouse.x, mouse.y);
                root.rightClicked(rPos.x, rPos.y);
                return;
            }
            const ripplePos = mouseArea.mapToItem(visualContent, mouse.x, mouse.y);
            rippleLayer.trigger(ripplePos.x, ripplePos.y);
            if (popoutTarget) {
                if (popoutTarget.setBarContext) {
                    const pos = root.axis?.edge === "left" ? 2 : (root.axis?.edge === "right" ? 3 : (root.axis?.edge === "top" ? 0 : 1));
                    const bottomGap = root.barConfig ? (root.barConfig.bottomGap !== undefined ? root.barConfig.bottomGap : 0) : 0;
                    popoutTarget.setBarContext(pos, bottomGap);
                }

                if (popoutTarget.setTriggerPosition) {
                    const globalPos = root.visualContent.mapToItem(null, 0, 0);
                    const currentScreen = parentScreen || Screen;
                    const barPosition = root.axis?.edge === "left" ? 2 : (root.axis?.edge === "right" ? 3 : (root.axis?.edge === "top" ? 0 : 1));
                    const pos = SettingsData.getPopupTriggerPosition(globalPos, currentScreen, barThickness, root.visualWidth, root.barSpacing, barPosition, root.barConfig);
                    popoutTarget.setTriggerPosition(pos.x, pos.y, pos.width, section, currentScreen, barPosition, barThickness, root.barSpacing, root.barConfig);
                }
            }
            root.clicked();
        }
        onWheel: function (wheelEvent) {
            wheelEvent.accepted = false;
            root.wheel(wheelEvent);
        }
    }

    property bool _blurRegistered: false
    readonly property bool _shouldBlur: BlurService.enabled && blurBarWindow && blurBarWindow.registerBlurWidget && !(barConfig?.noBackground ?? false) && root.visible && root.width > 0

    on_ShouldBlurChanged: _updateBlurRegistration()

    function _updateBlurRegistration() {
        if (_shouldBlur && !_blurRegistered) {
            blurBarWindow.registerBlurWidget(visualContent);
            _blurRegistered = true;
        } else if (!_shouldBlur && _blurRegistered) {
            if (blurBarWindow && blurBarWindow.unregisterBlurWidget)
                blurBarWindow.unregisterBlurWidget(visualContent);
            _blurRegistered = false;
        }
    }

    Component.onCompleted: _updateBlurRegistration()
    Component.onDestruction: {
        if (_blurRegistered && blurBarWindow && blurBarWindow.unregisterBlurWidget)
            blurBarWindow.unregisterBlurWidget(visualContent);
    }
}