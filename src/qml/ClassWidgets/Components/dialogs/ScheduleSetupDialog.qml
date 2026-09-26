import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


Dialog {
    id: root

    property int currentStep: 0
    property int selectedMode: 0
    property int selectedFormat: 0
    property string selectedFile: ""
    property string suggestedName: qsTr("New Schedule")
    property string enteredName: ""
    property string startDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property int maxWeekCycle: 2
    property string errorText: ""

    readonly property string effectiveName: enteredName.length > 0 ? enteredName : suggestedName
    readonly property bool nameValid: effectiveName.length > 0
        && !AppCentral.scheduleManager.checkNameExists(effectiveName)

    // Page transition state, mirroring the Tutorial window's left/right hand-off animation
    property bool navigationPending: false
    property int pendingStep: -1
    property int normalExitDirection: 0
    property bool suppressHeightAnimation: false

    property ParallelAnimation normalPageExit: ParallelAnimation {
        NumberAnimation {
            target: pageStack.currentItem
            property: "x"
            to: pageStack.width * 0.25 * root.normalExitDirection
            duration: 220
            easing.type: Easing.Bezier
            easing.bezierCurve: [1, 0, 1, 1, 1, 1]
        }
        NumberAnimation {
            target: pageStack.currentItem
            property: "opacity"
            to: 0
            duration: 140
            easing.type: Easing.OutCubic
        }
        onStopped: {
            if (root.navigationPending)
                root.finishNavigation()
        }
    }

    readonly property var modeOptions: [
        {
            title: qsTr("New Schedule"),
            description: qsTr("Create a new Class Widgets 2 schedule file."),
            icon: "ic_fluent_add_20_regular"
        },
        {
            title: qsTr("Import from File"),
            description: qsTr("Import a Class Widgets 2, iCalendar, CSES, or Class Widgets 1 schedule file."),
            icon: "ic_fluent_arrow_import_20_regular"
        }
    ]

    readonly property var formatOptions: [
        {
            title: qsTr("Class Widgets 2 Schedule"),
            description: "*.json",
            image: PathManager.images("icons/cw2_editor.png"),
            id: "cw2"
        },
        {
            title: qsTr("iCalendar Calendar"),
            description: "*.ics / *.ical",
            icon: "ic_fluent_calendar_20_regular",
            image: "",
            id: "ics",
            beta: true
        },
        {
            title: qsTr("CSES Schedule Exchange Format"),
            description: "*.yml / *.yaml",
            icon: "ic_fluent_document_data_20_regular",
            image: PathManager.images("icons/smart_teach.svg"),
            id: "cses"
        },
        {
            title: qsTr("Class Widgets 1 Schedule"),
            description: "*.json",
            icon: "ic_fluent_document_multiple_20_regular",
            image: PathManager.images("icons/cw1.png"),
            id: "cw1"
        }
    ]

    signal scheduleCreated()

    title: {
        if (currentStep === 0) return qsTr("New Schedule")
        if (currentStep === 1) return qsTr("Import Your Schedule")
        return qsTr("Prepare Your Schedule")
    }
    modal: true
    width: 500

    function resetDialog() {
        currentStep = 0
        selectedMode = 0
        selectedFormat = 0
        selectedFile = ""
        errorText = ""
        suggestedName = makeValidName(qsTr("New Schedule"))
        enteredName = ""
        startDate = Qt.formatDate(new Date(), "yyyy-MM-dd")
        maxWeekCycle = 2
        navigationPending = false
        pendingStep = -1
        normalPageExit.stop()
        suppressHeightAnimation = true

        if (pageStack.depth > 1)
            pageStack.pop(pageStack.get(0), StackView.Immediate)

        pageStack.currentItem.x = 0
        pageStack.currentItem.opacity = 1
        suppressHeightAnimation = false
    }

    function makeValidName(base) {
        let candidate = base
        let n = 0
        while (n < 100 && AppCentral.scheduleManager.checkNameExists(candidate)) {
            n += 1
            candidate = base + " " + n
        }
        return candidate
    }

    function fileStem(path) {
        const file = String(path).split(/[\\/]/).pop()
        return file.replace(/\.[^.]+$/, "")
    }

    function refreshImportCycle() {
        if (selectedMode !== 1 || !selectedFile)
            return

        const cycle = AppCentral.scheduleManager.scheduleIO.getImportMaxWeekCycle(
            selectedFile,
            formatOptions[selectedFormat].id,
            startDate
        )
        maxWeekCycle = cycle > 0 ? cycle : 1
    }

    function switchTo(step) {
        if (pageStack.busy || navigationPending || step < 0 || step > 2
                || step === currentStep)
            return

        pendingStep = step
        normalExitDirection = step > currentStep ? -1 : 1
        navigationPending = true
        normalPageExit.start()
    }

    function finishNavigation() {
        const step = pendingStep
        pendingStep = -1
        navigationPending = false

        if (step > currentStep)
            pageStack.push(step === 1 ? pageTwoComponent : pageThreeComponent)
        else
            pageStack.pop()
        currentStep = step
    }

    function goNext() {
        errorText = ""

        if (currentStep === 0) {
            if (selectedMode === 0)
                switchTo(2)
            else
                switchTo(1)
            return
        }

        if (currentStep === 1) {
            selectedFile = AppCentral.scheduleManager.scheduleIO.selectImportFile(
                formatOptions[selectedFormat].id
            )
            if (!selectedFile)
                return

            const formatId = formatOptions[selectedFormat].id
            if (!AppCentral.scheduleManager.scheduleIO.validateImportFile(selectedFile, formatId)) {
                errorText = qsTr("The selected file is not valid.")
                selectedFile = ""
                return
            }

            suggestedName = makeValidName(fileStem(selectedFile))
            enteredName = ""
            refreshImportCycle()
            switchTo(2)
            return
        }

        finish()
    }

    function goBack() {
        errorText = ""
        if (currentStep === 2) {
            switchTo(selectedMode === 0 ? 0 : 1)
            return
        }
        if (currentStep === 1)
            switchTo(0)
    }

    function finish() {
        if (!nameValid) {
            errorText = qsTr("Please enter a valid and unused name.")
            return
        }

        let success = false
        if (selectedMode === 0) {
            success = AppCentral.scheduleManager.create(
                effectiveName,
                startDate,
                maxWeekCycle
            )
        } else {
            success = AppCentral.scheduleManager.scheduleIO.importScheduleFile(
                selectedFile,
                formatOptions[selectedFormat].id,
                startDate,
                effectiveName
            )
        }

        if (success) {
            close()
            scheduleCreated()
        } else {
            errorText = qsTr("Failed to complete the schedule. Please check the file and try again.")
        }
    }

    onAboutToShow: resetDialog()
    onClosed: selectedFile = ""

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        StackView {
            id: pageStack
            Layout.fillWidth: true
            Layout.preferredHeight: currentItem ? currentItem.implicitHeight : 0
            clip: true
            initialItem: pageOneComponent

            Behavior on Layout.preferredHeight {
                enabled: !root.suppressHeightAnimation
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            // Hand-off navigation (same as the Tutorial window): the outgoing page is
            // animated out by normalPageExit before push/pop, so the exit transitions
            // below only snap the old page out of the way instantly, while entering
            // pages slide in from the side with a fade.
            pushEnter: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        from: pageStack.width * 0.25
                        to: 0
                        duration: 220
                        easing.type: Easing.Bezier
                        easing.bezierCurve: [0, 0, 0, 1, 1, 1]
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            pushExit: Transition {
                PropertyAction { property: "x"; value: -pageStack.width * 0.25 }
                PropertyAction { property: "opacity"; value: 0 }
            }

            popEnter: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        from: -pageStack.width * 0.25
                        to: 0
                        duration: 220
                        easing.type: Easing.Bezier
                        easing.bezierCurve: [0, 0, 0, 1, 1, 1]
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            popExit: Transition {
                PropertyAction { property: "x"; value: pageStack.width * 0.25 }
                PropertyAction { property: "opacity"; value: 0 }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: errorText.length > 0
            text: errorText
            color: Colors.proxy.systemCriticalColor
            typography: Typography.Caption
            wrapMode: Text.WordWrap
        }
    }

    footer: DialogButtonBox {
        id: dialogButtons

        Button {
            Layout.fillWidth: true
            Layout.preferredWidth: dialogButtons.availableWidth / 2
            text: root.currentStep === 0 ? qsTr("Cancel") : qsTr("Back")

            onClicked: {
                if (root.currentStep === 0)
                    root.close()
                else
                    root.goBack()
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.preferredWidth: dialogButtons.availableWidth / 2
            highlighted: true
            text: root.currentStep === 2 ? qsTr("Finish") : qsTr("Continue")
            enabled: root.currentStep !== 2 || root.nameValid

            onClicked: root.goNext()
        }
    }

    Component {
        id: pageOneComponent

        ColumnLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: qsTr("Create a brand-new schedule or import an existing schedule file.")
                typography: Typography.Body
                wrapMode: Text.WordWrap
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                clip: true
                interactive: false
                model: root.modeOptions
                onItemClicked: function(index) { root.selectedMode = index }
                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        root.selectedMode = currentIndex
                }

                delegate: ListViewDelegate {
                    highlighted: root.selectedMode === index

                    contentItem: RowLayout {
                        spacing: 12

                        Icon {
                            name: modelData.icon
                            size: 16
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                typography: Typography.Body
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.description
                                typography: Typography.Caption
                                color: Colors.proxy.textSecondaryColor
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: pageTwoComponent

        ColumnLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: qsTr("Choose the file format to import.")
                typography: Typography.Body
                wrapMode: Text.WordWrap
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                clip: true
                spacing: 4
                interactive: false
                model: root.formatOptions
                onItemClicked: function(index) { root.selectedFormat = index }
                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        root.selectedFormat = currentIndex
                }

                delegate: ListViewDelegate {
                    highlighted: root.selectedFormat === index

                    contentItem: RowLayout {
                        spacing: 12

                        Icon {
                            size: 16
                            Layout.alignment: Qt.AlignVCenter
                            source: modelData.image && modelData.image.length > 0
                                ? modelData.image : ""
                            name: modelData.image && modelData.image.length > 0
                                ? "" : modelData.icon
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                spacing: 6

                                Text {
                                    text: modelData.title
                                    typography: Typography.Body
                                }

                                InfoBadge {
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: modelData.beta === true
                                    text: "Beta"
                                    solid: false
                                    severity: Severity.Warning
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.description
                                typography: Typography.Caption
                                color: Colors.proxy.textSecondaryColor
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: pageThreeComponent

        ColumnLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: root.selectedMode === 0
                    ? qsTr("Finish the initial setup to create your new schedule.")
                    : qsTr("Confirm the details to finish importing.")
                typography: Typography.Body
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.preferredWidth: 200
                        Layout.maximumWidth: 200
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Name")
                            typography: Typography.Body
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("This name will be used by default. You can change it anytime.")
                            typography: Typography.Caption
                            color: Colors.proxy.textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        TextField {
                            id: nameField
                            Layout.preferredWidth: 200
                            placeholderText: root.suggestedName

                            Component.onCompleted: root.enteredName = ""

                            onTextChanged: root.enteredName = text
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            visible: root.enteredName.length > 0
                            typography: Typography.Caption
                            wrapMode: Text.WordWrap
                            color: root.nameValid
                                ? Colors.proxy.systemSuccessColor
                                : Colors.proxy.systemCriticalColor
                            text: {
                                if (!root.nameValid)
                                    return qsTr("Cannot duplicate existing name (⊙x⊙;)")
                                return qsTr("Great! That's it. ヾ(≧▽≦*)o")
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.preferredWidth: 200
                        Layout.maximumWidth: 200
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Start date")
                            typography: Typography.Body
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("The first day of the schedule, used for multi-week rotation. Usually a Monday.")
                            typography: Typography.Caption
                            color: Colors.proxy.textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    CalendarDatePicker {
                        id: datePicker
                        Layout.preferredWidth: 120
                        Layout.alignment: Qt.AlignVCenter
                        textFormat: "yyyy/M/d"

                        Component.onCompleted: selectedDate = new Date(root.startDate)

                        onDateSelected: function(d) {
                            root.startDate = Qt.formatDate(d, "yyyy-MM-dd")
                            root.refreshImportCycle()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.selectedMode === 0

                    ColumnLayout {
                        Layout.preferredWidth: 200
                        Layout.maximumWidth: 200
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Maximum Rotation Weeks")
                            typography: Typography.Body
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Most schools alternate weekly (every 2 weeks). Choose as needed.")
                            typography: Typography.Caption
                            color: Colors.proxy.textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: qsTr("Every")
                            typography: Typography.Body
                        }

                        SpinBox {
                            id: maxWeekCycleBox
                            Layout.preferredWidth: 124
                            from: 1
                            to: 12
                            value: root.maxWeekCycle

                            onValueChanged: {
                                if (root.selectedMode === 0)
                                    root.maxWeekCycle = value
                            }
                        }

                        Text {
                            text: qsTr("weeks")
                            typography: Typography.Body
                        }
                    }
                }
            }
        }
    }
}
