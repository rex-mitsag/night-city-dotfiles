import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

ShellRoot {
    id: root

    property string volumeText: "󰕾 --%"
    property string networkText: "󰤭 Offline"
    property string bluetoothText: "󰂯 OFF"
    property string notificationText: "󰂚  0"

    property bool volumePopupVisible: false
    property var audioBars: []

    // =========================================================
    // MUSIC VISUALIZER
    // =========================================================

    Process {
        id: cavaProcess

        command: ["cava"]

        stdout: SplitParser {
            onRead: data => {
                let values = data.trim().split(";")
                let bars = []

                for (let value of values) {
                    let number = parseInt(value)

                    if (!isNaN(number))
                        bars.push(number)
                }

                if (bars.length > 0)
                    audioBars = bars
            }
        }
    }

    Component.onCompleted: {
        cavaProcess.running = true
    }

    // =========================================================
    // NIGHT CITY PALETTE
    // =========================================================

    readonly property color bg:       "#070709"
    readonly property color panel:    "#0D0B0B"
    readonly property color red:      "#FF3B30"
    readonly property color cyan:     "#00F0FF"
    readonly property color white:    "#E8E3D8"
    readonly property color darkRed:  "#3A0F12"
    readonly property color yellow:   "#F3E600"


    // =========================================================
    // VOLUME
    // =========================================================

    Process {
        id: volumeProcess

        command: [
            "wpctl",
            "get-volume",
            "@DEFAULT_AUDIO_SINK@"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                let parts = output.split(" ")

                if (parts.length < 2)
                    return

                let volume = Math.round(parseFloat(parts[1]) * 100)

                if (output.includes("[MUTED]"))
                    volumeText = "󰖁 " + volume + "%"
                else
                    volumeText = "󰕾 " + volume + "%"
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            volumeProcess.exec([
                "wpctl",
                "get-volume",
                "@DEFAULT_AUDIO_SINK@"
            ])
        }
    }


    // =========================================================
    // NETWORK
    // =========================================================

    Process {
        id: networkProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "DEVICE,TYPE,STATE,CONNECTION",
            "device"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                let connected = false

                for (let line of lines) {
                    let parts = line.split(":")

                    if (parts.length >= 4 &&
                        parts[1] === "wifi" &&
                        parts[2] === "connected") {

                        networkText = "󰤨 " + parts[3]
                        connected = true
                        break
                    }
                }

                if (!connected)
                    networkText = "󰤭 Offline"
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true

        onTriggered: {
            networkProcess.exec([
                "nmcli",
                "-t",
                "-f",
                "DEVICE,TYPE,STATE,CONNECTION",
                "device"
            ])
        }
    }


    // =========================================================
    // BLUETOOTH
    // =========================================================

    Process {
        id: bluetoothProcess

        command: [
            "bluetoothctl",
            "show"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text

                if (!output.includes("Powered: yes")) {
                    bluetoothText = "󰂲 OFF"
                    return
                }

                bluetoothDeviceProcess.exec([
                    "bluetoothctl",
                    "devices",
                    "Connected"
                ])
            }
        }
    }

    Process {
        id: bluetoothDeviceProcess

        command: [
            "bluetoothctl",
            "devices",
            "Connected"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()

                if (output === "") {
                    bluetoothText = "󰂯 OFF"
                    return
                }

                let lines = output.split("\n")
                let line = lines[0]

                let parts = line.split(" ")

                if (parts.length >= 3) {
                    let deviceName = parts.slice(2).join(" ")
                    bluetoothText = "󰂯 ON  " + deviceName
                } else {
                    bluetoothText = "󰂯 ON"
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true

        onTriggered: {
            bluetoothProcess.exec([
                "bluetoothctl",
                "show"
            ])
        }
    }


    // =========================================================
    // NOTIFICATIONS
    // =========================================================

    Process {
        id: notificationProcess

        command: [
            "swaync-client",
            "-c"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let count = parseInt(this.text.trim())

                if (isNaN(count))
                    count = 0

                notificationText = "󰂚  " + count
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            notificationProcess.exec([
                "swaync-client",
                "-c"
            ])
        }
    }


    // =========================================================
    // CLOCK
    // =========================================================

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }


    // =========================================================
    // TOP PANEL
    // =========================================================

    PanelWindow {
        id: topPanel

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 36
        exclusiveZone: 36

        color: "transparent"


        // =====================================================
        // LEFT PANEL — WORKSPACES
        // =====================================================

        Rectangle {
            id: leftPanel

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }

            implicitWidth: workspaceRow.implicitWidth + 28

            color: "transparent"

            ShapePath {
                strokeColor: bg
                strokeWidth: 1
                fillColor: bg

                joinStyle: ShapePath.MiterJoin

                startX: 0
                startY: 0

                // Top-left → top-right
                PathLine {
                    x: datePanel.width
                    y: 0
                }

                // Right side → bottom-right
                PathLine {
                    x: datePanel.width
                    y: datePanel.height - 8
                }

                // Bottom-right diagonal
                PathLine {
                    x: datePanel.width - 8
                    y: datePanel.height
                }

                // Bottom edge → square bottom-left
                PathLine {
                    x: 0
                    y: datePanel.height
                }

                // Left side → close
                PathLine {
                    x: 0
                    y: 0
                }
            }

            Row {
                id: workspaceRow

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                anchors.leftMargin: 14

                spacing: 6


                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {

                        required property var modelData

                        width: 32
                        height: 26

                        color: modelData.focused
                            ? red
                            : bg

                        border.width: 1

                        border.color: modelData.focused
                            ? red
                            : bg


                        Text {
                            anchors.centerIn: parent

                            text: modelData.name || modelData.id

                            color: modelData.focused
                                ? white
                                : cyan

                            font.family: "GeistMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: true
                        }


                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                modelData.activate()
                            }
                        }
                    }
                }
            }
        }


        // =====================================================
        // CENTER PANEL — CLOCK / MUSIC WAVE / DATE
        // =====================================================

        Rectangle {
            id: centerPanel

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
            }

            implicitWidth: 380
            color: "transparent"


            // =================================================
            // CLOCK — LEFT
            // =================================================

            Shape {
                id: clockPanel

                anchors {
                    right: musicPanel.left
                    rightMargin: 0
                    top: musicPanel.top
                }

                width: clockText.implicitWidth + 24
                height: musicPanel.height - 8

                ShapePath {
                    strokeColor: bg
                    strokeWidth: 1
                    fillColor: bg

                    joinStyle: ShapePath.MiterJoin

                    startX: 0
                    startY: 0

                    // Top-left → top-right
                    PathLine {
                        x: clockPanel.width
                        y: 0
                    }

                    // Right side
                    PathLine {
                        x: clockPanel.width
                        y: clockPanel.height
                    }

                    // Bottom edge → start of left diagonal
                    PathLine {
                        x: 8
                        y: clockPanel.height
                    }

                    // Bottom-left diagonal
                    PathLine {
                        x: 0
                        y: clockPanel.height - 8
                    }

                    // Left side → close
                    PathLine {
                        x: 0
                        y: 0
                    }
                }

                Text {
                    id: clockText

                    anchors.centerIn: parent

                    text: Qt.formatDateTime(
                        clock.date,
                        "HH:mm:ss"
                    )

                    color: cyan

                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true

                    renderType: Text.NativeRendering
                }
            }


            // =================================================
            // IDLE — CENTER
            // =================================================

            Shape {
                id: musicPanel

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                width: 180
                height: 34

                ShapePath {
                    strokeColor: red
                    strokeWidth: 1
                    fillColor: red

                    joinStyle: ShapePath.MiterJoin

                    startX: 0
                    startY: 0

                    // Top-left → top-right
                    PathLine {
                        x: musicPanel.width
                        y: 0
                    }

                    // Right side
                    PathLine {
                        x: musicPanel.width
                        y: musicPanel.height - 8
                    }

                    // Bottom-right diagonal
                    PathLine {
                        x: musicPanel.width - 8
                        y: musicPanel.height
                    }

                    // Bottom edge
                    PathLine {
                        x: 8
                        y: musicPanel.height
                    }

                    // Bottom-left diagonal
                    PathLine {
                        x: 0
                        y: musicPanel.height - 8
                    }

                    // Left side → close
                    PathLine {
                        x: 0
                        y: 0
                    }
                }


                // =================================================
                // IDLE DISPLAY
                // =================================================

                Text {
                    visible: !parent.waveActive
                    anchors.centerIn: parent

                    text: "NIGHT CITY"
                    color: white
                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 15
                    font.bold: true

                    renderType: Text.NativeRendering
                }

            }


            // =================================================
            // DATE — RIGHT
            // =================================================

            Shape {
                id: datePanel

                anchors {
                    left: musicPanel.right
                    leftMargin: 0
                    top: musicPanel.top
                }

                width: dateText.implicitWidth + 24
                height: musicPanel.height - 8

                ShapePath {
                    strokeColor: bg
                    strokeWidth: 1
                    fillColor: bg

                    joinStyle: ShapePath.MiterJoin

                    startX: 0
                    startY: 0

                    // Top-left → top-right
                    PathLine {
                        x: datePanel.width
                        y: 0
                    }

                    // Right side → bottom-right
                    PathLine {
                        x: datePanel.width
                        y: datePanel.height - 8
                    }

                    // Bottom-right diagonal
                    PathLine {
                        x: datePanel.width - 8
                        y: datePanel.height
                    }

                    // Bottom edge → square bottom-left
                    PathLine {
                        x: 0
                        y: datePanel.height
                    }

                    // Left side → close
                    PathLine {
                        x: 0
                        y: 0
                    }
                }

                Text {
                    id: dateText

                    anchors.centerIn: parent

                    text: Qt.formatDateTime(
                        clock.date,
                        "dd-MMM-yy"
                    )

                    color: cyan

                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true

                    renderType: Text.NativeRendering
                }
            }
        }


        // =====================================================
        // RIGHT PANEL
        // =====================================================

        Shape {
            id: rightPanel

            anchors {
                right: parent.right
                rightMargin: -2
                top: parent.top
                bottom: parent.bottom
            }

            implicitWidth: systemRow.implicitWidth + 28

            ShapePath {
                strokeColor: bg
                strokeWidth: 1
                fillColor: bg

                joinStyle: ShapePath.MiterJoin

                startX: 0
                startY: 0

                // Top-left → top-right
                PathLine {
                    x: rightPanel.width
                    y: 0
                }

                // Right side
                PathLine {
                    x: rightPanel.width
                    y: rightPanel.height
                }

                // Bottom edge → start of left diagonal
                PathLine {
                    x: 8
                    y: rightPanel.height
                }

                // Bottom-left diagonal
                PathLine {
                    x: 0
                    y: rightPanel.height - 8
                }

                // Left side → close
                PathLine {
                    x: 0
                    y: 0
                }
            }

            RowLayout {
                id: systemRow

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                anchors.rightMargin: 14

                spacing: 14


                // -------------------------------------------------
                // VOLUME
                // -------------------------------------------------

                Text {
                    text: volumeText

                    color: cyan

                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 13


                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            volumePopupVisible = !volumePopupVisible

                            if(volumePopupVisible)
                                refreshAudioStreams()
                        }
                    }
                }


                // -------------------------------------------------
                // WI-FI
                // -------------------------------------------------

                Text {
                    text: networkText

                    color: cyan

                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 13
                }


                // -------------------------------------------------
                // BLUETOOTH
                // -------------------------------------------------

                Text {
                    text: bluetoothText

                    color: cyan

                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 13
                }
            }
        }
    }

    property var audioStreams: []

    Process {
        id: streamProcess

        command: [
            "wpctl",
            "status",
            "-n"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n")
                let streams = []
                let insideStreams = false

                for (let line of lines) {

                    if (line.includes("└─ Streams:")) {
                        insideStreams = true
                        continue
                    }

                    if (!insideStreams)
                        continue

                    /*
                    * Stop when we reach the next
                    * top-level PipeWire section.
                    */
                    if (line.match(/^[^ \t│├└]/))
                        break

                    /*
                    * Application stream:
                    *
                    *         73. Zen
                    *         80. Spotify
                    */
                    let match = line.match(/^\s+(\d+)\.\s+(.+?)\s*$/)

                    if (!match)
                        continue

                    let id = parseInt(match[1])
                    let name = match[2].trim()

                    /*
                    * Ignore node/channel entries such as
                    * "75. output_FL".
                    *
                    * We only want the parent stream IDs.
                    */
                    if (name.startsWith("output_") ||
                        name.startsWith("input_") ||
                        name.startsWith("monitor_"))
                        continue

                    if (name === "cava")
                        continue

                    streams.push({
                        id: id,
                        name: name
                    })
                }

                audioStreams = streams
            }
        }
    }

    Timer {
        interval: 1000
        running: volumePopupVisible
        repeat: true

        onTriggered: {
            streamProcess.exec([
                "wpctl",
                "status",
                "-n"
            ])
        }
    }

    function refreshAudioStreams() {
        streamProcess.exec([
            "wpctl",
            "status",
            "-n"
        ])
    }

    PanelWindow {
        id: volumePopup

        visible: volumePopupVisible

        anchors {
            top: true
            right: true
        }

        margins {
            top: 48
            right: 14
        }

        implicitWidth: 380
        implicitHeight: 112 + (audioStreams.length * 72)

        color: "transparent"

        Rectangle {
            anchors.fill: parent

            color: bg

            border.width: 2
            border.color: red

            radius: 4

            Column {
                anchors.fill: parent
                anchors.margins: 16

                spacing: 12

                Text {
                    text: "AUDIO // MIXER"

                    color: cyan

                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 16
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: darkRed
                }

                Text {
                    text: "APPLICATION STREAMS"

                    color: red

                    font.family: "GeistMono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: audioStreams

                        delegate: Rectangle {
                            required property var modelData

                            width: parent.width
                            height: 72

                            color: panel

                            border.width: 1
                            border.color: darkRed

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }

                                width: 3
                                color: cyan
                            }

                            Column {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }

                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.topMargin: 9

                                spacing: 7

                                Row {
                                    width: parent.width
                                    height: 18

                                    Text {
                                        text: "󰓃  " + modelData.name

                                        color: white

                                        font.family: "GeistMono Nerd Font"
                                        font.pixelSize: 11
                                        font.bold: true

                                        elide: Text.ElideRight

                                        width: parent.width - 45
                                    }

                                    Text {
                                        text: "ID:" + modelData.id

                                        color: "#B58B2A"

                                        font.family: "GeistMono Nerd Font"
                                        font.pixelSize: 8

                                        anchors.right: parent.right
                                    }
                                }

                                Row {
                                    width: parent.width
                                    height: 20

                                    spacing: 8

                                    Text {
                                        text: "󰖁 MUTE"

                                        color: red

                                        font.family: "GeistMono Nerd Font"
                                        font.pixelSize: 9
                                        font.bold: true

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: {
                                                Quickshell.execDetached([
                                                    "wpctl",
                                                    "set-mute",
                                                    modelData.id.toString(),
                                                    "toggle"
                                                ])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: audioStreams.length === 0

                        width: parent.width

                        text: "NO ACTIVE AUDIO STREAMS"

                        horizontalAlignment: Text.AlignHCenter

                        color: "#B58B2A"

                        font.family: "GeistMono Nerd Font"
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
