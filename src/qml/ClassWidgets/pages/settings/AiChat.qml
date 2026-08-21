import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    title: qsTr("AI Conversation")

    function saveValue(key, value, refreshWake) {
        Configs.set(key, value)
        if (refreshWake)
            AiChatService.refreshWakeListener()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        InfoBar {
            Layout.fillWidth: true
            severity: Severity.Warning
            title: qsTr("Local API key storage")
            text: qsTr("Your API key is stored in the local configs.json file so the desktop app can call your selected provider. Keep this file private and do not share it.")
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Enable AI Conversation")
            description: qsTr("Allow the AI Widget, text conversations, microphone transcription, and optional offline voice wake-up")
            icon.name: "ic_fluent_bot_20_regular"

            Switch {
                id: enabledSwitch
                property bool initialized: false
                enabled: !Configs.isKeyLocked("ai_chat.enabled")
                onCheckedChanged: if (initialized) root.saveValue("ai_chat.enabled", checked, true)
                Component.onCompleted: {
                    checked = Configs.data.ai_chat.enabled
                    initialized = true
                }
            }
        }

        Text {
            text: qsTr("Provider")
            typography: Typography.BodyStrong
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Base URL")
            description: qsTr("The root address of an OpenAI-compatible API. A /v1 suffix is added automatically when needed.")
            icon.name: "ic_fluent_cloud_20_regular"

            TextField {
                id: baseUrlInput
                Layout.preferredWidth: 360
                placeholderText: "https://api.openai.com"
                enabled: !Configs.isKeyLocked("ai_chat.base_url")
                selectByMouse: true
                Component.onCompleted: text = Configs.data.ai_chat.base_url
                onEditingFinished: root.saveValue("ai_chat.base_url", text.trim(), false)
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("API Key")
            description: qsTr("The key is hidden in this page, but remains stored locally for the configured provider.")
            icon.name: "ic_fluent_key_20_regular"

            TextField {
                id: apiKeyInput
                Layout.preferredWidth: 360
                placeholderText: qsTr("Enter API key")
                echoMode: TextInput.Password
                passwordCharacter: "•"
                enabled: !Configs.isKeyLocked("ai_chat.api_key")
                selectByMouse: true
                Component.onCompleted: text = Configs.data.ai_chat.api_key
                onEditingFinished: root.saveValue("ai_chat.api_key", text, false)
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Chat Model")
            description: qsTr("The model sent to the /v1/chat/completions endpoint")
            icon.name: "ic_fluent_sparkle_20_regular"

            TextField {
                Layout.preferredWidth: 260
                placeholderText: "gpt-4o"
                enabled: !Configs.isKeyLocked("ai_chat.model")
                selectByMouse: true
                Component.onCompleted: text = Configs.data.ai_chat.model
                onEditingFinished: root.saveValue("ai_chat.model", text.trim(), false)
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Transcription Model")
            description: qsTr("The model sent to the /v1/audio/transcriptions endpoint after microphone recording")
            icon.name: "ic_fluent_mic_20_regular"

            TextField {
                Layout.preferredWidth: 260
                placeholderText: "whisper-1"
                enabled: !Configs.isKeyLocked("ai_chat.transcription_model")
                selectByMouse: true
                Component.onCompleted: text = Configs.data.ai_chat.transcription_model
                onEditingFinished: root.saveValue("ai_chat.transcription_model", text.trim(), false)
            }
        }

        Text {
            text: qsTr("Voice Wake-up")
            typography: Typography.BodyStrong
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Enable Voice Wake-up")
            description: qsTr("Listen locally through the default microphone for the wake phrase below")
            icon.name: "ic_fluent_hearing_20_regular"

            Switch {
                id: wakeSwitch
                property bool initialized: false
                enabled: enabledSwitch.checked && !Configs.isKeyLocked("ai_chat.wake_enabled")
                onCheckedChanged: if (initialized) root.saveValue("ai_chat.wake_enabled", checked, true)
                Component.onCompleted: {
                    checked = Configs.data.ai_chat.wake_enabled
                    initialized = true
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Wake Phrase")
            description: qsTr("Enter the words you want to say to start AI listening. Any non-empty text is supported.")
            icon.name: "ic_fluent_chat_bubbles_question_20_regular"

            TextField {
                Layout.preferredWidth: 300
                placeholderText: qsTr("For example: Hello Widget")
                enabled: enabledSwitch.checked && !Configs.isKeyLocked("ai_chat.wake_phrase")
                selectByMouse: true
                Component.onCompleted: text = Configs.data.ai_chat.wake_phrase
                onEditingFinished: root.saveValue("ai_chat.wake_phrase", text.trim(), true)
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Wake-up Language and Model")
            description: qsTr("The Windows package includes a Chinese model. To use another language, select that language's local Vosk model folder below.")
            icon.name: "ic_fluent_translate_20_regular"

            ColumnLayout {
                Layout.preferredWidth: 430
                spacing: 8

                TextField {
                    id: wakeLanguageInput
                    Layout.fillWidth: true
                    placeholderText: "zh-CN"
                    enabled: enabledSwitch.checked && !Configs.isKeyLocked("ai_chat.wake_language")
                    selectByMouse: true
                    Component.onCompleted: text = Configs.data.ai_chat.wake_language
                    onEditingFinished: root.saveValue("ai_chat.wake_language", text.trim(), false)
                }

                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: wakeModelPathInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("Use bundled Chinese model")
                        enabled: enabledSwitch.checked && !Configs.isKeyLocked("ai_chat.wake_model_path")
                        selectByMouse: true
                        Component.onCompleted: text = Configs.data.ai_chat.wake_model_path
                        onEditingFinished: root.saveValue("ai_chat.wake_model_path", text.trim(), true)
                    }
                    Button {
                        text: qsTr("Choose folder")
                        enabled: enabledSwitch.checked && !Configs.isKeyLocked("ai_chat.wake_model_path")
                        onClicked: {
                            const selectedPath = AiChatService.selectWakeModelDirectory()
                            if (selectedPath.length > 0)
                                wakeModelPathInput.text = selectedPath
                        }
                    }
                    Button {
                        text: qsTr("Use bundled")
                        enabled: wakeModelPathInput.text.length > 0 && !Configs.isKeyLocked("ai_chat.wake_model_path")
                        onClicked: {
                            wakeModelPathInput.clear()
                            root.saveValue("ai_chat.wake_model_path", "", true)
                        }
                    }
                }
            }
        }

        InfoBar {
            Layout.fillWidth: true
            severity: AiChatService.wakeAvailable ? Severity.Success : Severity.Info
            title: AiChatService.wakeAvailable ? qsTr("Voice wake-up is ready") : qsTr("Voice wake-up status")
            text: AiChatService.wakeAvailable
                  ? qsTr("Vosk is listening locally for your wake phrase.")
                  : (AiChatService.wakeAvailabilityMessage.length > 0
                     ? AiChatService.wakeAvailabilityMessage
                     : qsTr("Voice wake-up will be ready after AI Conversation is enabled and the selected Vosk model is available."))
        }

        Text {
            text: qsTr("Voice Reading")
            typography: Typography.BodyStrong
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Read Replies Aloud")
            description: qsTr("After an AI reply is complete, generate speech through the OpenAI-compatible /v1/audio/speech endpoint and show an animated reading card below the conversation.")
            icon.name: "ic_fluent_speaker_2_20_regular"

            Switch {
                id: ttsSwitch
                property bool initialized: false
                enabled: enabledSwitch.checked && !Configs.isKeyLocked("ai_chat.tts_enabled")
                onCheckedChanged: if (initialized) root.saveValue("ai_chat.tts_enabled", checked, false)
                Component.onCompleted: {
                    checked = Configs.data.ai_chat.tts_enabled
                    initialized = true
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Speech Model and Voice")
            description: qsTr("Enter the text-to-speech model and voice supported by your provider. Defaults are tts-1 and alloy.")
            icon.name: "ic_fluent_sound_wave_circle_20_regular"

            RowLayout {
                spacing: 8
                TextField {
                    Layout.preferredWidth: 175
                    placeholderText: "tts-1"
                    enabled: ttsSwitch.checked && !Configs.isKeyLocked("ai_chat.tts_model")
                    selectByMouse: true
                    Component.onCompleted: text = Configs.data.ai_chat.tts_model
                    onEditingFinished: root.saveValue("ai_chat.tts_model", text.trim(), false)
                }
                TextField {
                    Layout.preferredWidth: 175
                    placeholderText: "alloy"
                    enabled: ttsSwitch.checked && !Configs.isKeyLocked("ai_chat.tts_voice")
                    selectByMouse: true
                    Component.onCompleted: text = Configs.data.ai_chat.tts_voice
                    onEditingFinished: root.saveValue("ai_chat.tts_voice", text.trim(), false)
                }
            }
        }

        Text {
            text: qsTr("AI Behavior")
            typography: Typography.BodyStrong
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("System Prompt")
            description: qsTr("Optional instructions sent before each conversation. Leave blank to use the provider default behavior.")
            icon.name: "ic_fluent_text_grammar_checkmark_20_regular"

            TextArea {
                Layout.preferredWidth: 420
                Layout.preferredHeight: 106
                placeholderText: qsTr("Optional instructions for the assistant")
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                enabled: !Configs.isKeyLocked("ai_chat.system_prompt")
                Component.onCompleted: text = Configs.data.ai_chat.system_prompt
                onEditingFinished: root.saveValue("ai_chat.system_prompt", text, false)
            }
        }
    }

    Component.onCompleted: AiChatService.refreshWakeListener()
}
