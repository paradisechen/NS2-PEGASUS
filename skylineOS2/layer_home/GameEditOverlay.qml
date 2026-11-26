// skylineOS 2 — GameEditOverlay.qml (Switch 2 Centered Artwork + Background + Name Overlay, with Console & Year in Game Page Edit Info)
import QtQuick 2.12
import QtGraphicalEffects 1.0

FocusScope {
    id: editRoot
    anchors.fill: parent
    z: 300
    visible: isOpen || sheet.y < (parent.height - 1) || dimBg.opacity > 0.01

    property bool isOpen: false
    property bool fromDetail: false
    property var targetGame: null

    property string draftTitle: ""
    property string draftCover: ""
    property string draftBg: ""
    property string draftConsole: ""
    property string draftYear: ""

    property string focusZone: "cover" // "cover" | "bg" | "title" | "console" | "year" | "save" | "close"
    property bool pickerOpen: false
    property string pickerTarget: "cover" // "cover" | "bg"
    property string pickerFolder: "/storage/emulated/0/Pictures"
    property int pickerIndex: 0
    property var pickerModelObj: null

    property var consoleChoices: [
        "Nintendo Switch",
        "Nintendo 3DS",
        "GameCube",
        "Wii",
        "Wii U",
        "Nintendo 64",
        "SNES",
        "NES",
        "Game Boy Advance",
        "PSP",
        "PlayStation 2",
        "Android"
    ]

    signal closed()

    ListModel { id: deviceImagesModel }

    function readOrigTitle(g) {
        return g ? String(g.title || "") : "";
    }

    function normalizedPickerUrl(rawPath) {
        var p = String(rawPath || "").trim();
        if (p === "") p = "/storage/emulated/0/Pictures";
        if (p.indexOf("file://") === 0) return p;
        if (p.indexOf("/") !== 0) p = "/" + p;
        return "file://" + p;
    }

    function initPickerModel() {
        if (pickerModelObj) {
            try { pickerModelObj.folder = normalizedPickerUrl(pickerFolder); } catch (e) {}
            return;
        }
        var candidates = [
            'import QtQuick 2.12; import Qt.labs.folderlistmodel 2.12; FolderListModel { showDirs: false; showDotAndDotDot: false; nameFilters: ["*.png","*.jpg","*.jpeg","*.webp","*.gif","*.bmp"] }',
            'import QtQuick 2.12; import Qt.labs.folderlistmodel 2.1; FolderListModel { showDirs: false; showDotAndDotDot: false; nameFilters: ["*.png","*.jpg","*.jpeg","*.webp","*.gif","*.bmp"] }',
            'import QtQuick 2.12; import Qt.labs.folderlistmodel 2.0; FolderListModel { showDirs: false; showDotAndDotDot: false; nameFilters: ["*.png","*.jpg","*.jpeg","*.webp","*.gif","*.bmp"] }'
        ];
        for (var c = 0; c < candidates.length; c++) {
            try {
                var obj = Qt.createQmlObject(candidates[c], editRoot, "editPickerFolder_" + c);
                if (obj) {
                    pickerModelObj = obj;
                    obj.folder = normalizedPickerUrl(pickerFolder);
                    return;
                }
            } catch (err) {}
        }
    }

    function syncPickerImages() {
        deviceImagesModel.clear();
        if (pickerModelObj && pickerModelObj.count > 0) {
            for (var i = 0; i < pickerModelObj.count && i < 60; i++) {
                var u = "";
                var n = "";
                try {
                    u = String(pickerModelObj.get(i, "fileURL") || pickerModelObj.get(i, "fileUrl") || "");
                    n = String(pickerModelObj.get(i, "fileName") || "Image");
                } catch (e) {}
                if (u !== "") deviceImagesModel.append({ name: n, url: u });
            }
        }
        pickerIndex = 0;
    }

    Connections {
        target: editRoot.pickerModelObj
        ignoreUnknownSignals: true
        onCountChanged: editRoot.syncPickerImages()
        onStatusChanged: editRoot.syncPickerImages()
    }

    function open(game, showFullMeta) {
        if (!game) return;
        targetGame = game;
        fromDetail = Boolean(showFullMeta);
        pickerOpen = false;
        draftTitle = getGameTitle(game);
        draftCover = getGameCover(game);
        draftBg = getGameBg(game);
        draftConsole = (typeof getGameConsole === "function")
            ? getGameConsole(game)
            : ((game.collections && game.collections.count > 0) ? String(game.collections.get(0).name || "") : "Nintendo Switch");
        if (draftConsole === "") draftConsole = "Nintendo Switch";
        draftYear = (typeof getGameYear === "function")
            ? getGameYear(game)
            : ((game.release && new Date(game.release).getFullYear() > 1950) ? String(new Date(game.release).getFullYear()) : "");
        focusZone = "cover";
        isOpen = true;
        editRoot.forceActiveFocus();
        Qt.callLater(function() { sheetFocus.forceActiveFocus(); });
    }

    function close() {
        pickerOpen = false;
        isOpen = false;
        backSfx.play();
        closed();
    }

    function openDevicePicker(which) {
        pickerTarget = which;
        var defDir = (api.memory.has("Photos Directory") && api.memory.get("Photos Directory") !== "")
            ? String(api.memory.get("Photos Directory"))
            : "/storage/emulated/0/Pictures";
        pickerFolder = defDir;
        initPickerModel();
        syncPickerImages();
        pickerOpen = true;
        selectSfx.play();
        Qt.callLater(function() { pickerFocus.forceActiveFocus(); });
    }

    function applyPickedImage(urlStr) {
        var clean = String(urlStr || "").trim();
        if (clean !== "") {
            if (pickerTarget === "cover") draftCover = clean;
            else draftBg = clean;
            turnOnSfx.play();
        }
        pickerOpen = false;
        Qt.callLater(function() { sheetFocus.forceActiveFocus(); });
    }

    function openPathKeyboardForPicker() {
        var cur = (pickerTarget === "cover") ? draftCover : draftBg;
        var label = (pickerTarget === "cover")
            ? tr("Main Photo URL / Local Path:")
            : tr("Game Background URL / Local Path:");
        openSwitchKeyboard(label, cur, true, 320, function(val) {
            var v = String(val || "").trim();
            if (pickerTarget === "cover") editRoot.draftCover = v;
            else editRoot.draftBg = v;
            editRoot.pickerOpen = false;
            turnOnSfx.play();
            editRoot.forceActiveFocus();
            sheetFocus.forceActiveFocus();
        }, function() {
            editRoot.forceActiveFocus();
            if (editRoot.pickerOpen) pickerFocus.forceActiveFocus();
            else sheetFocus.forceActiveFocus();
        });
    }

    function openTitleKeyboard() {
        selectSfx.play();
        openSwitchKeyboard(tr("Edit Game Name:"), draftTitle, false, 120, function(val) {
            var v = String(val || "").trim();
            if (v !== "") editRoot.draftTitle = v;
            turnOnSfx.play();
            editRoot.forceActiveFocus();
            sheetFocus.forceActiveFocus();
        }, function() {
            editRoot.forceActiveFocus();
            sheetFocus.forceActiveFocus();
        });
    }

    function openConsoleKeyboard() {
        selectSfx.play();
        openSwitchKeyboard(tr("Console Type:"), draftConsole, false, 64, function(val) {
            var v = String(val || "").trim();
            if (v !== "") editRoot.draftConsole = v;
            turnOnSfx.play();
            editRoot.forceActiveFocus();
            sheetFocus.forceActiveFocus();
        }, function() {
            editRoot.forceActiveFocus();
            sheetFocus.forceActiveFocus();
        });
    }

    function openYearKeyboard() {
        selectSfx.play();
        openSwitchKeyboard(tr("Release Year:"), draftYear, false, 8, function(val) {
            editRoot.draftYear = String(val || "").trim();
            turnOnSfx.play();
            editRoot.forceActiveFocus();
            sheetFocus.forceActiveFocus();
        }, function() {
            editRoot.forceActiveFocus();
            sheetFocus.forceActiveFocus();
        });
    }

    function stepConsole(dir) {
        navSound.play();
        var curIdx = consoleChoices.indexOf(draftConsole);
        if (curIdx < 0) curIdx = 0;
        var nextIdx = (curIdx + dir + consoleChoices.length) % consoleChoices.length;
        draftConsole = consoleChoices[nextIdx];
    }

    function stepYear(dir) {
        navSound.play();
        var num = parseInt(draftYear, 10);
        if (isNaN(num) || num < 1970 || num > 2035) num = 2024;
        else num = Math.max(1972, Math.min(2032, num + dir));
        draftYear = String(num);
    }

    function saveChanges() {
        if (!targetGame) return;
        var orig = readOrigTitle(targetGame);
        var cleanTitle = String(draftTitle || "").trim();
        var cleanCover = String(draftCover || "").trim();
        var cleanBg = String(draftBg || "").trim();

        if (cleanTitle === "" || cleanTitle === orig) api.memory.unset("CUSTOM_TITLE::" + orig);
        else api.memory.set("CUSTOM_TITLE::" + orig, cleanTitle);

        if (cleanCover === "") api.memory.unset("CUSTOM_COVER::" + orig);
        else api.memory.set("CUSTOM_COVER::" + orig, cleanCover);

        if (cleanBg === "") api.memory.unset("CUSTOM_BG::" + orig);
        else api.memory.set("CUSTOM_BG::" + orig, cleanBg);

        if (fromDetail) {
            var cleanConsole = String(draftConsole || "").trim();
            var origConsole = (targetGame.collections && targetGame.collections.count > 0) ? String(targetGame.collections.get(0).name || "") : "";
            if (cleanConsole === "" || cleanConsole === origConsole) api.memory.unset("CUSTOM_CONSOLE::" + orig);
            else api.memory.set("CUSTOM_CONSOLE::" + orig, cleanConsole);

            var cleanYear = String(draftYear || "").trim();
            var origYear = (targetGame.release && new Date(targetGame.release).getFullYear() > 1950) ? String(new Date(targetGame.release).getFullYear()) : "";
            if (cleanYear === "" || cleanYear === origYear) api.memory.unset("CUSTOM_YEAR::" + orig);
            else api.memory.set("CUSTOM_YEAR::" + orig, cleanYear);
        }

        gameOverrideVersion++;
        turnOnSfx.play();
        isOpen = false;
        closed();
    }

    property bool isDarkSheet: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color sheetBg: isDarkSheet ? "#22242A" : "#EBEBEB"
    property color sheetCard: isDarkSheet ? "#2C2F37" : "#FFFFFF"
    property color sheetText: isDarkSheet ? "#F3F4F6" : "#24272D"
    property color sheetMuted: isDarkSheet ? "#9CA3AF" : "#6B7280"
    property color sheetDivider: isDarkSheet ? "#3B3F4A" : "#CCCCCC"

    ShaderEffectSource {
        id: editBlurSrc
        sourceItem: gameDetailOpen ? gameDetailScreen : (softwareScreen.visible ? softwareScreen : homeScreen)
        live: editRoot.visible
        visible: false
    }

    FastBlur {
        anchors.fill: parent
        source: editBlurSrc
        radius: editRoot.isOpen ? 24 : 0
        visible: radius > 0.5
        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: dimBg
        anchors.fill: parent
        color: "#000000"
        opacity: editRoot.isOpen ? 0.54 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; enabled: editRoot.isOpen; onClicked: editRoot.close() }
    }

    // Bottom Switch 2 Sheet matching UserSelectOverlay.qml
    Rectangle {
        id: sheet
        width: parent.width
        height: editRoot.fromDetail ? Math.round(parent.height * 0.68) : Math.round(parent.height * 0.56)
        x: 0
        y: editRoot.isOpen ? (parent.height - height) : parent.height
        color: editRoot.sheetBg
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: editRoot.sheetDivider }

        // Top Header + Hairline Divider matching UserSelectOverlay.qml
        Item {
            id: editHeaderBar
            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
            height: Math.round(screenheight * 0.095)

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: editRoot.pickerOpen
                    ? (editRoot.pickerTarget === "cover" ? tr("Select Main Photo") : tr("Select Game Background"))
                    : (editRoot.fromDetail ? tr("Edit Info") : tr("Edit Game"))
                color: editRoot.sheetText
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.040)
                font.bold: true
            }

            Text {
                visible: editRoot.pickerOpen
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: tr("B · Back")
                color: editRoot.sheetMuted
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.022)
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        backSfx.play();
                        editRoot.pickerOpen = false;
                        sheetFocus.forceActiveFocus();
                    }
                }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: editRoot.sheetDivider }
        }

        // Main Centered Editor Content
        FocusScope {
            id: sheetFocus
            visible: !editRoot.pickerOpen
            focus: editRoot.isOpen && !editRoot.pickerOpen
            anchors {
                top: editHeaderBar.bottom
                bottom: editFooter.top
                left: parent.left
                right: parent.right
                leftMargin: screenmargin
                rightMargin: screenmargin
            }

            Keys.onLeftPressed: {
                if (editRoot.focusZone === "bg") { navSound.play(); editRoot.focusZone = "cover"; }
                else if (editRoot.focusZone === "close") { navSound.play(); editRoot.focusZone = "save"; }
                else if (editRoot.focusZone === "console") { editRoot.stepConsole(-1); }
                else if (editRoot.focusZone === "year") { editRoot.stepYear(-1); }
            }
            Keys.onRightPressed: {
                if (editRoot.focusZone === "cover") { navSound.play(); editRoot.focusZone = "bg"; }
                else if (editRoot.focusZone === "save") { navSound.play(); editRoot.focusZone = "close"; }
                else if (editRoot.focusZone === "console") { editRoot.stepConsole(1); }
                else if (editRoot.focusZone === "year") { editRoot.stepYear(1); }
            }
            Keys.onUpPressed: {
                navSound.play();
                if (editRoot.focusZone === "title") editRoot.focusZone = "cover";
                else if (editRoot.focusZone === "console") editRoot.focusZone = "title";
                else if (editRoot.focusZone === "year") editRoot.focusZone = "console";
                else if (editRoot.focusZone === "save" || editRoot.focusZone === "close") {
                    editRoot.focusZone = editRoot.fromDetail ? "year" : "title";
                }
            }
            Keys.onDownPressed: {
                navSound.play();
                if (editRoot.focusZone === "cover" || editRoot.focusZone === "bg") editRoot.focusZone = "title";
                else if (editRoot.focusZone === "title") editRoot.focusZone = editRoot.fromDetail ? "console" : "save";
                else if (editRoot.focusZone === "console") editRoot.focusZone = "year";
                else if (editRoot.focusZone === "year") editRoot.focusZone = "save";
            }
            Keys.onBackPressed: {
                event.accepted = true;
                editRoot.close();
            }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (editRoot.focusZone === "cover") editRoot.openDevicePicker("cover");
                    else if (editRoot.focusZone === "bg") editRoot.openDevicePicker("bg");
                    else if (editRoot.focusZone === "title") editRoot.openTitleKeyboard();
                    else if (editRoot.focusZone === "console") editRoot.openConsoleKeyboard();
                    else if (editRoot.focusZone === "year") editRoot.openYearKeyboard();
                    else if (editRoot.focusZone === "save") editRoot.saveChanges();
                    else editRoot.close();
                } else if ((event.key === Qt.Key_X || api.keys.isDetails(event)) && !event.isAutoRepeat) {
                    event.accepted = true;
                    editRoot.saveChanges();
                } else if ((api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape || event.key === Qt.Key_Plus || event.key === Qt.Key_Equal || event.key === Qt.Key_M || event.key === Qt.Key_Menu) && !event.isAutoRepeat) {
                    event.accepted = true;
                    editRoot.close();
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Math.round(screenheight * 0.022)
                width: Math.min(parent.width, vpx(640))

                // Centered Main Photo (Artwork) + Game Background Side-by-Side
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(24)

                    // Cover Artwork Card
                    Rectangle {
                        property bool isCur: editRoot.focusZone === "cover"
                        property int artH: Math.max(vpx(108), Math.round(screenheight * 0.175))
                        width: artH
                        height: artH
                        radius: vpx(10)
                        color: editRoot.sheetCard
                        clip: true
                        border.width: isCur ? vpx(4) : 1
                        border.color: isCur ? theme.accent : editRoot.sheetDivider
                        scale: isCur ? 1.03 : 1.0
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                        Image {
                            anchors.fill: parent
                            source: editRoot.draftCover
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                        }
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: vpx(26)
                            color: "#BB000000"
                            Text {
                                anchors.centerIn: parent
                                text: tr("Main Photo")
                                color: "#FFFFFF"
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.018)
                                font.bold: true
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: editRoot.focusZone = "cover"
                            onClicked: { editRoot.focusZone = "cover"; editRoot.openDevicePicker("cover"); }
                        }
                    }

                    // Game Background Card
                    Rectangle {
                        property bool isCur: editRoot.focusZone === "bg"
                        property int artH: Math.max(vpx(108), Math.round(screenheight * 0.175))
                        width: Math.round(artH * 1.68)
                        height: artH
                        radius: vpx(10)
                        color: editRoot.sheetCard
                        clip: true
                        border.width: isCur ? vpx(4) : 1
                        border.color: isCur ? theme.accent : editRoot.sheetDivider
                        scale: isCur ? 1.03 : 1.0
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                        Image {
                            anchors.fill: parent
                            source: editRoot.draftBg
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                        }
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: vpx(26)
                            color: "#BB000000"
                            Text {
                                anchors.centerIn: parent
                                text: tr("Background")
                                color: "#FFFFFF"
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.018)
                                font.bold: true
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: editRoot.focusZone = "bg"
                            onClicked: { editRoot.focusZone = "bg"; editRoot.openDevicePicker("bg"); }
                        }
                    }
                }

                // Centered Game Name Field (ONLY metadata shown in quick mode)
                Rectangle {
                    property bool isCur: editRoot.focusZone === "title"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, vpx(440))
                    height: Math.max(vpx(42), Math.round(screenheight * 0.064))
                    radius: vpx(8)
                    color: editRoot.sheetCard
                    border.width: isCur ? vpx(3) : 1
                    border.color: isCur ? theme.accent : editRoot.sheetDivider

                    Text {
                        anchors { fill: parent; leftMargin: vpx(16); rightMargin: vpx(16) }
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: editRoot.draftTitle !== "" ? editRoot.draftTitle : tr("Game Name")
                        color: editRoot.sheetText
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.028)
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: editRoot.focusZone = "title"
                        onClicked: { editRoot.focusZone = "title"; editRoot.openTitleKeyboard(); }
                    }
                }

                // Nintendo-style Simple Metadata Options — ONLY visible when opened via Game Page -> Edit Info
                Column {
                    visible: editRoot.fromDetail
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, vpx(440))
                    spacing: vpx(10)

                    // Console Type Selector
                    Rectangle {
                        property bool isCur: editRoot.focusZone === "console"
                        width: parent.width
                        height: Math.max(vpx(38), Math.round(screenheight * 0.056))
                        radius: vpx(8)
                        color: editRoot.sheetCard
                        border.width: isCur ? vpx(3) : 1
                        border.color: isCur ? theme.accent : editRoot.sheetDivider

                        Row {
                            anchors { fill: parent; leftMargin: vpx(16); rightMargin: vpx(12) }
                            Text {
                                width: parent.width * 0.36
                                anchors.verticalCenter: parent.verticalCenter
                                text: tr("Console")
                                color: editRoot.sheetMuted
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.022)
                            }
                            Row {
                                width: parent.width * 0.64
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: vpx(8)

                                Rectangle {
                                    width: vpx(30); height: vpx(28); radius: vpx(6)
                                    color: editRoot.sheetBg
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "<"; color: editRoot.sheetText; font.family: titleFont.name; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: { editRoot.focusZone = "console"; editRoot.stepConsole(-1); } }
                                }
                                Text {
                                    width: parent.width - vpx(76)
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: editRoot.draftConsole
                                    color: editRoot.sheetText
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    font.bold: true
                                    elide: Text.ElideRight
                                    MouseArea { anchors.fill: parent; onClicked: { editRoot.focusZone = "console"; editRoot.openConsoleKeyboard(); } }
                                }
                                Rectangle {
                                    width: vpx(30); height: vpx(28); radius: vpx(6)
                                    color: editRoot.sheetBg
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: ">"; color: editRoot.sheetText; font.family: titleFont.name; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: { editRoot.focusZone = "console"; editRoot.stepConsole(1); } }
                                }
                            }
                        }
                    }

                    // Release Year Stepper
                    Rectangle {
                        property bool isCur: editRoot.focusZone === "year"
                        width: parent.width
                        height: Math.max(vpx(38), Math.round(screenheight * 0.056))
                        radius: vpx(8)
                        color: editRoot.sheetCard
                        border.width: isCur ? vpx(3) : 1
                        border.color: isCur ? theme.accent : editRoot.sheetDivider

                        Row {
                            anchors { fill: parent; leftMargin: vpx(16); rightMargin: vpx(12) }
                            Text {
                                width: parent.width * 0.36
                                anchors.verticalCenter: parent.verticalCenter
                                text: tr("Year")
                                color: editRoot.sheetMuted
                                font.family: titleFont.name
                                font.pixelSize: Math.round(screenheight * 0.022)
                            }
                            Row {
                                width: parent.width * 0.64
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: vpx(8)

                                Rectangle {
                                    width: vpx(30); height: vpx(28); radius: vpx(6)
                                    color: editRoot.sheetBg
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "-"; color: editRoot.sheetText; font.family: titleFont.name; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: { editRoot.focusZone = "year"; editRoot.stepYear(-1); } }
                                }
                                Text {
                                    width: parent.width - vpx(76)
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: editRoot.draftYear !== "" ? editRoot.draftYear : tr("Unset")
                                    color: editRoot.draftYear !== "" ? editRoot.sheetText : editRoot.sheetMuted
                                    font.family: titleFont.name
                                    font.pixelSize: Math.round(screenheight * 0.022)
                                    font.bold: true
                                    MouseArea { anchors.fill: parent; onClicked: { editRoot.focusZone = "year"; editRoot.openYearKeyboard(); } }
                                }
                                Rectangle {
                                    width: vpx(30); height: vpx(28); radius: vpx(6)
                                    color: editRoot.sheetBg
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { anchors.centerIn: parent; text: "+"; color: editRoot.sheetText; font.family: titleFont.name; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: { editRoot.focusZone = "year"; editRoot.stepYear(1); } }
                                }
                            }
                        }
                    }
                }

                // Centered Save Button Row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(14)

                    Rectangle {
                        property bool isCur: editRoot.focusZone === "save"
                        width: vpx(160)
                        height: Math.max(vpx(38), Math.round(screenheight * 0.056))
                        radius: height / 2
                        color: theme.accent
                        border.width: isCur ? vpx(3) : 0
                        border.color: "#FFFFFF"
                        scale: isCur ? 1.04 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: tr("Save")
                            color: "#FFFFFF"
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.024)
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: editRoot.focusZone = "save"
                            onClicked: editRoot.saveChanges()
                        }
                    }
                }
            }
        }

        // Inline Device Image Picker (for Cover Art / Background Upload from Device)
        FocusScope {
            id: pickerFocus
            visible: editRoot.pickerOpen
            focus: editRoot.isOpen && editRoot.pickerOpen
            anchors {
                top: editHeaderBar.bottom
                bottom: editFooter.top
                left: parent.left
                right: parent.right
                leftMargin: screenmargin
                rightMargin: screenmargin
                topMargin: vpx(10)
                bottomMargin: vpx(8)
            }

            Keys.onLeftPressed: {
                if (deviceImagesModel.count > 0) {
                    navSound.play();
                    editRoot.pickerIndex = (editRoot.pickerIndex > 0) ? (editRoot.pickerIndex - 1) : (deviceImagesModel.count - 1);
                    pickerGrid.positionViewAtIndex(editRoot.pickerIndex, GridView.Contain);
                }
            }
            Keys.onRightPressed: {
                if (deviceImagesModel.count > 0) {
                    navSound.play();
                    editRoot.pickerIndex = (editRoot.pickerIndex + 1) % deviceImagesModel.count;
                    pickerGrid.positionViewAtIndex(editRoot.pickerIndex, GridView.Contain);
                }
            }
            Keys.onUpPressed: {
                if (deviceImagesModel.count > 0) {
                    navSound.play();
                    editRoot.pickerIndex = Math.max(0, editRoot.pickerIndex - 5);
                    pickerGrid.positionViewAtIndex(editRoot.pickerIndex, GridView.Contain);
                }
            }
            Keys.onDownPressed: {
                if (deviceImagesModel.count > 0) {
                    navSound.play();
                    editRoot.pickerIndex = Math.min(deviceImagesModel.count - 1, editRoot.pickerIndex + 5);
                    pickerGrid.positionViewAtIndex(editRoot.pickerIndex, GridView.Contain);
                }
            }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (deviceImagesModel.count > 0 && editRoot.pickerIndex >= 0 && editRoot.pickerIndex < deviceImagesModel.count) {
                        editRoot.applyPickedImage(deviceImagesModel.get(editRoot.pickerIndex).url);
                    } else {
                        editRoot.openPathKeyboardForPicker();
                    }
                } else if ((event.key === Qt.Key_Y || api.keys.isFilters(event)) && !event.isAutoRepeat) {
                    event.accepted = true;
                    editRoot.openPathKeyboardForPicker();
                } else if ((api.keys.isCancel(event) || event.key === Qt.Key_B || event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace) && !event.isAutoRepeat) {
                    event.accepted = true;
                    backSfx.play();
                    editRoot.pickerOpen = false;
                    sheetFocus.forceActiveFocus();
                }
            }

            Column {
                anchors.fill: parent
                spacing: vpx(10)

                Row {
                    width: parent.width
                    spacing: vpx(10)

                    Repeater {
                        model: [
                            { label: "Pictures", dir: "/storage/emulated/0/Pictures" },
                            { label: "Downloads", dir: "/storage/emulated/0/Download" },
                            { label: "DCIM", dir: "/storage/emulated/0/DCIM" }
                        ]
                        delegate: Rectangle {
                            property bool active: editRoot.pickerFolder === modelData.dir
                            width: vpx(108); height: vpx(32); radius: vpx(8)
                            color: active ? theme.accent : editRoot.sheetCard
                            border.width: 1; border.color: active ? theme.accent : editRoot.sheetDivider
                            Text {
                                anchors.centerIn: parent
                                text: tr(modelData.label)
                                color: active ? "#FFFFFF" : editRoot.sheetText
                                font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.019); font.bold: active
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    navSound.play();
                                    editRoot.pickerFolder = modelData.dir;
                                    editRoot.initPickerModel();
                                    editRoot.syncPickerImages();
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: vpx(176); height: vpx(32); radius: vpx(8)
                        color: editRoot.sheetCard
                        border.width: 1; border.color: theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: tr("Y · Custom Path / URL")
                            color: theme.accent
                            font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.018); font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: editRoot.openPathKeyboardForPicker()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - vpx(44)

                    GridView {
                        id: pickerGrid
                        anchors.fill: parent
                        clip: true
                        visible: deviceImagesModel.count > 0
                        cellWidth: Math.floor(width / 5)
                        cellHeight: Math.round(cellWidth * 0.72)
                        model: deviceImagesModel
                        delegate: Item {
                            width: pickerGrid.cellWidth
                            height: pickerGrid.cellHeight
                            property bool isCur: index === editRoot.pickerIndex

                            Rectangle {
                                anchors { fill: parent; margins: vpx(5) }
                                radius: vpx(8)
                                color: editRoot.sheetCard
                                clip: true
                                border.width: isCur ? vpx(3) : 1
                                border.color: isCur ? theme.accent : editRoot.sheetDivider

                                Image {
                                    anchors.fill: parent
                                    source: url
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    smooth: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: editRoot.pickerIndex = index
                                    onClicked: { editRoot.pickerIndex = index; editRoot.applyPickedImage(url); }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: deviceImagesModel.count === 0
                        text: tr("No images found in this folder — tap Y · Custom Path / URL above")
                        color: editRoot.sheetMuted
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.022)
                    }
                }
            }
        }

        // Bottom Footer Row matching UserSelectOverlay.qml
        Item {
            id: editFooter
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
            height: Math.round(screenheight * 0.088)
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: editRoot.sheetDivider }
            Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: vpx(24)
                Row {
                    spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: editRoot.sheetText; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "B"; color: editRoot.sheetBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: editRoot.pickerOpen ? tr("Back") : tr("Close"); color: editRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); anchors.verticalCenter: parent.verticalCenter }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (editRoot.pickerOpen) {
                                backSfx.play();
                                editRoot.pickerOpen = false;
                                sheetFocus.forceActiveFocus();
                            } else {
                                editRoot.close();
                            }
                        }
                    }
                }
                Row {
                    spacing: vpx(8); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: editRoot.sheetText; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "A"; color: editRoot.sheetBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: editRoot.pickerOpen ? tr("Select") : tr("OK"); color: editRoot.sheetText; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.023); anchors.verticalCenter: parent.verticalCenter }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (editRoot.pickerOpen) {
                                if (deviceImagesModel.count > 0 && editRoot.pickerIndex >= 0 && editRoot.pickerIndex < deviceImagesModel.count)
                                    editRoot.applyPickedImage(deviceImagesModel.get(editRoot.pickerIndex).url);
                                else
                                    editRoot.openPathKeyboardForPicker();
                            } else {
                                editRoot.saveChanges();
                            }
                        }
                    }
                }
            }
        }
    }
}
