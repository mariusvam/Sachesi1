import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import AppLibrary 1.0
import "UI" 1.0

Item {
    id: main
    property string newLine: i.newLine
    property string details: ""
    property string lasterror: "\n"
    onNewLineChanged: details += i.newLine
    visible: i.knownBattery > -1
    anchors.fill: parent

    Rectangle {
        visible: i.dgProgress >= 0
        anchors {bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
        width: parent.width / 3; height: Math.min(parent.height / 2, width + 20); radius: 8
        z: 5
        color: "lightgray"
        opacity: 0.6
        Text {
            id: titleText
            text: i.firmwareUpdate ? "Firmware Update" : "Install"
            font.pointSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
        CircleProgress {
            width: parent.width - 10; height: Math.min(parent.height - 20, width);
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
            currentValue: i.dgProgress
            text: i.curInstallName
        }
    }

    DropArea {
        anchors.fill: parent
        onDropped: {
            if (drop.hasUrls) {
                i.install(drop.urls);
                tabs.currentIndex = 1
            }
        }
    }
    ColumnLayout {
        anchors {fill: parent; margins: 15 }
        Label {
            Layout.fillWidth: true
            text: "To install <b>.bar</b> files such as applications or firmware, you can just <b>Drag and Drop</b> to this page. Otherwise, select the options below:"
            wrapMode: Text.Wrap
            font.pointSize: 12
        }
        Row {
            spacing: 15
            FileDialog {
                id: install_files
                title: "Install applications to device"
                folder: settings.installFolder
                onAccepted: {
                    i.install(fileUrls)
                    tabs.currentIndex = 1
                    settings.installFolder = folder;
                }

                selectMultiple: true
                nameFilters: [ "Blackberry Installable (*.bar)" ]
            }
            Button {
                text: "Install Folder"
                onClicked: {
                    if (i.installing)
                        details += "Error: Your device can only process one task at a time. Please wait for previous install to complete.<br>;"
                    else if (i.backing || i.restoring)
                        details += "Error: Your device can only process one task at a time. Please wait for backup/restore process to complete.<br>"
                    else {
                        install_files.title = "Select Folder"
                        install_files.selectFolder = true;
                        install_files.open();
                    }
                }
            }
            Button {
                text: "Install Files"
                onClicked: {
                    if (i.installing)
                        details += "Error: Your device can only process one task at a time. Please wait for previous install to complete.<br>;"
                    else if (i.backing || i.restoring)
                        details += "Error: Your device can only process one task at a time. Please wait for backup/restore process to complete.<br>"
                    else {
                        install_files.title = "Select Files"
                        install_files.selectFolder = false;
                        install_files.selectMultiple = true;
                        install_files.open();
                    }
                }
            }
        }
        GroupBox {
            title: "Advanced Tools"
            visible: settings.advanced
            RowLayout {
                Button {
                    id: wipe
                    text: "Wipe"
                    onClicked: i.wipe();
                }
                Button {
                    id: factorywipe
                    text: "Factory Reset"
                    onClicked: i.factorywipe();
                }
                Button {
                    id: reboot
                    text: "Reboot"
                    onClicked: i.reboot();
                }
            }
        }
        TabView {
            id: tabs
            Layout.alignment: Qt.AlignBottom
            Layout.fillHeight: true
            Layout.fillWidth: true
            Button {
                anchors { top: parent.top; topMargin:-height; right: parent.right }
                id: list_files
                text: "Refresh"
                onClicked: i.scanProps();
            }
            Component.onCompleted: { addTab("Apps", app_tab); addTab("Log", log_tab); }
        }
    }

    // Log
    Component {
        id: log_tab
        TextArea {
            id: updateMessage
            width: tabs.width; height: tabs.height
            textFormat: TextEdit.RichText
            selectByKeyboard: true
            wrapMode: TextEdit.WrapAnywhere
            readOnly: true
            text: details
        }
    }

    // Applications
    Component {
        id: app_tab
        Item {
            Button {
                visible: appView.count > 0
                property bool uninstalling: false
                anchors {right: parent.left; rightMargin: -2; top: parent.top }
                enabled: !i.installing
                onEnabledChanged: if (enabled && uninstalling) { uninstalling = false; }
                iconSource: "trash.png"
                tooltip: "Uninstall Marked"
                width: 26; height: 26
                opacity: uninstalling ? 0.6 : 1.0
                onClicked: { if (i.uninstallMarked()) uninstalling = true; }
                BusyIndicator {
                    visible: parent.uninstalling
                    anchors.fill: parent
                }
            }
            Button {
                visible: appView.count > 0
                anchors {right: parent.left; rightMargin: -1; bottom: parent.bottom }
                iconSource: "text.png"
                tooltip: "Show Installed Apps"
                width: 24; height: 24
                onClicked: i.exportInstalled();
            }
            Text {
                visible: appView.count == 0
                anchors.centerIn: parent
                font.pointSize: 14
                text: "Use 'Refresh' to update list"
            }
            ScrollView {
                anchors.fill: parent
                ListView {
                    id: appView
                    anchors.fill: parent
                    spacing: 3
                    clip: true
                    model: i.appList
                    delegate: Item {
                        visible: type !== "";
                        width: parent.width - 3
                        height: type === "" ? 0 : 26
                        Rectangle {
                            anchors.fill: parent
                            color: { switch(type) {
                                case "os": return "red";
                                case "radio": return "maroon";
                                case "application": if (friendlyName.indexOf("sys.data") === 0) return "purple"; else  return "steelblue";
                                default: return "transparent";
                                }
                            }
                            opacity: 0.2
                        }
                        CheckBox {
                            text: friendlyName
                            checked: isMarked
                            onCheckedChanged: isMarked = checked;
                        }
                        Label {
                            anchors.right: parent.right
                            text: version
                            font.pointSize: 12;
                        }
                    }
                }
            }
        }
    }
}
