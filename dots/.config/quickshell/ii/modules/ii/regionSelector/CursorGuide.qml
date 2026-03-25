import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    property var action
    property var selectionMode
    property string displayText: ""

    readonly property bool hasDisplayText: root.displayText !== ""

    readonly property var actionMetadata: ({
            [RegionSelection.SnipAction.Copy]: {
                description: Translation.tr("Copy region (LMB) or annotate (RMB)"),
                icon: "content_cut"
            },
            [RegionSelection.SnipAction.Edit]: {
                description: Translation.tr("Copy region (LMB) or annotate (RMB)"),
                icon: "content_cut"
            },
            [RegionSelection.SnipAction.Search]: {
                description: Translation.tr("Image Search"),
                icon: "image_search"
            },
            [RegionSelection.SnipAction.CharRecognition]: {
                description: Translation.tr("Recognize text"),
                icon: "document_scanner"
            },
            [RegionSelection.SnipAction.Record]: {
                description: Translation.tr("Record region"),
                icon: "videocam"
            },
            [RegionSelection.SnipAction.RecordWithSound]: {
                description: Translation.tr("Record region"),
                icon: "videocam"
            }
        })

    property string description: {
        if (root.hasDisplayText)
            return "";
        return root.actionMetadata[root.action]?.description ?? "";
    }
    property string materialSymbol: {
        if (root.hasDisplayText)
            return "";
        return root.actionMetadata[root.action]?.icon ?? "";
    }

    property bool showDescription: true
    function hideDescription() {
        root.showDescription = false;
    }
    Timer {
        id: descTimeout
        interval: 1000
        running: !root.hasDisplayText
        onTriggered: {
            root.hideDescription();
        }
    }
    onActionChanged: {
        root.showDescription = true;
        descTimeout.restart();
    }

    property int margins: 8
    implicitWidth: content.implicitWidth + margins * 2
    implicitHeight: content.implicitHeight + margins * 2

    Rectangle {
        id: content
        anchors.centerIn: parent

        property real padding: 8
        implicitHeight: 38
        implicitWidth: {
            if (root.hasDisplayText)
                return displayTextItem.implicitWidth + padding * 2;
            return root.showDescription ? contentRow.implicitWidth + padding * 2 : implicitHeight;
        }
        clip: true

        topLeftRadius: 6
        bottomLeftRadius: implicitHeight - topLeftRadius
        bottomRightRadius: bottomLeftRadius
        topRightRadius: bottomLeftRadius

        color: Appearance.colors.colPrimary

        Behavior on topLeftRadius {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        StyledText {
            id: displayTextItem
            visible: root.hasDisplayText
            anchors.centerIn: parent
            color: Appearance.colors.colOnPrimary
            font.family: Appearance.font.family.monospace
            text: root.displayText
        }

        Row {
            id: contentRow
            visible: !root.hasDisplayText
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: content.padding
            }
            spacing: 12

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 22
                color: Appearance.colors.colOnPrimary
                animateChange: true
                text: root.materialSymbol
            }

            FadeLoader {
                id: descriptionLoader
                anchors.verticalCenter: parent.verticalCenter
                shown: root.showDescription
                sourceComponent: StyledText {
                    color: Appearance.colors.colOnPrimary
                    text: root.description
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                }
            }
        }
    }
}
