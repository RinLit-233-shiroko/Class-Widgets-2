; Invisible deployment engine used by the modern QML installer front-end.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef BuildDir
  #define BuildDir "..\..\dist\Class Widgets 2"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist\installer-payload"
#endif

#define AppName "Class Widgets 2"
#define AppPublisher "Class Widgets"
#define MainExe "Class Widgets 2.exe"
#define SettingsExe "Class Widgets 2 Settings.exe"
#define PluginPlazaExe "Class Widgets 2 Plugin Plaza.exe"

[Setup]
AppId={{FA5A58DE-9A84-46D0-9255-2F5D4F72B4D5}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\Programs\Class Widgets 2
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=yes
DisableFinishedPage=yes
DisableStartupPrompt=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#OutputDir}
OutputBaseFilename=ClassWidgets2Engine
SetupIconFile=..\assets\logo.ico
UninstallDisplayIcon={app}\{#MainExe}
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\assets\.cw2-installed"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#MainExe}"; WorkingDir: "{app}"
Name: "{autoprograms}\{#AppName}\{#AppName} Settings"; Filename: "{app}\{#SettingsExe}"; WorkingDir: "{app}"
Name: "{autoprograms}\{#AppName}\{#AppName} Plugin Plaza"; Filename: "{app}\{#PluginPlazaExe}"; WorkingDir: "{app}"
Name: "{autoprograms}\{#AppName}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
